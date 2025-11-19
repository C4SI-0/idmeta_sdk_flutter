import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:provider/provider.dart';

enum UploadMode { file, camera }

class KtpExtractionScreen extends StatefulWidget {
  const KtpExtractionScreen({super.key});
  @override
  State<KtpExtractionScreen> createState() => _KtpExtractionScreenState();
}

class _KtpExtractionScreenState extends State<KtpExtractionScreen> with WidgetsBindingObserver {
  // State
  UploadMode _uploadMode = UploadMode.file;
  File? _selectedFile;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No cameras found.")));
      return;
    }
    final camera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );
    _cameraController = CameraController(camera, ResolutionPreset.high, enableAudio: false);
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final image = await _cameraController!.takePicture();
      _cameraController!.pausePreview();
      setState(() => _capturedImage = image);
    } catch (e) {
      debugPrint("Error capturing image: $e");
    }
  }

  Future<void> _submit() async {
    File? fileToSubmit;
    if (_uploadMode == UploadMode.file) {
      fileToSubmit = _selectedFile;
    } else if (_capturedImage != null) {
      fileToSubmit = File(_capturedImage!.path);
    }

    if (fileToSubmit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a file or capture an image.")));
      return;
    }

    final provider = context.read<Verification>();
    final success = await provider.submitKtpExtraction(context, imageFile: fileToSubmit);
    if (!mounted) return;
    if (success) {
      provider.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Submission failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(children: [
          Expanded(
              child: RadioListTile<UploadMode>(
            title: const Text("Upload File"),
            value: UploadMode.file,
            groupValue: _uploadMode,
            onChanged: (v) {
              _cameraController?.dispose();
              setState(() {
                _uploadMode = v!;
                _isCameraInitialized = false;
                _capturedImage = null;
              });
            },
          )),
          Expanded(
              child: RadioListTile<UploadMode>(
            title: const Text("Camera"),
            value: UploadMode.camera,
            groupValue: _uploadMode,
            onChanged: (v) {
              setState(() {
                _uploadMode = v!;
                _selectedFile = null;
              });
              _initializeCamera();
            },
          )),
        ]),
        const SizedBox(height: 24),
        if (_uploadMode == UploadMode.file) _buildFileUploadView(),
        if (_uploadMode == UploadMode.camera) _buildCameraView(),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _submit,
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildFileUploadView() {
    final isImage = _selectedFile != null && ['jpg', 'jpeg', 'png'].contains(_selectedFile!.path.split('.').last.toLowerCase());
    return Column(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text('Choose KTP File'),
          onPressed: _pickFile,
        ),
        if (_selectedFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: isImage
                ? Image.file(_selectedFile!, height: 200)
                : ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(_selectedFile!.path.split('/').last),
                    trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedFile = null)),
                  ),
          ),
      ],
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized) return const Center(heightFactor: 5, child: CircularProgressIndicator());
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _capturedImage == null ? CameraPreview(_cameraController!) : Image.file(File(_capturedImage!.path)),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          icon: Icon(_capturedImage == null ? Icons.camera_alt : Icons.refresh),
          label: Text(_capturedImage == null ? 'Capture' : 'Retake'),
          onPressed: () {
            if (_capturedImage != null) {
              _cameraController?.resumePreview();
              setState(() => _capturedImage = null);
            } else {
              _captureImage();
            }
          },
        ),
      ],
    );
  }
}
