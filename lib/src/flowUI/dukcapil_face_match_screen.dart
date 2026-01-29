import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../verification/verification.dart';

class DukcapilFaceMatchScreen extends StatefulWidget {
  const DukcapilFaceMatchScreen({super.key});

  @override
  State<DukcapilFaceMatchScreen> createState() => _DukcapilFaceMatchScreenState();
}

class _DukcapilFaceMatchScreenState extends State<DukcapilFaceMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nikController = TextEditingController();

  File? _manualSelfieImage;
  Uint8List? _documentFaceBytes;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();

      // 1. Register the submit function
      get.setContinueAction(_submitForm);

      // 2. Restore / Prefill Data
      final data = get.flowState.collectedData;

      // Logic: Saved Manual Input -> Extracted Data -> Empty
      _nameController.text = data['dukcapil_fm_name'] ?? data['fullName'] ?? data['firstName'] ?? '';
      _nikController.text = data['dukcapil_fm_nik'] ?? data['docNumber'] ?? '';
      _dobController.text = data['dukcapil_fm_dob'] ?? data['dob'] ?? '';

      // Image Restoration Logic
      // 1. Check for manually saved image path (from user going back)
      if (data['dukcapil_fm_image_path'] != null) {
        final f = File(data['dukcapil_fm_image_path']);
        if (f.existsSync()) {
          setState(() => _manualSelfieImage = f);
          return; // Skip document face logic if we have a manual override
        }
      }

      // 2. If no manual image, check for document extracted face
      if (_manualSelfieImage == null) {
        final docFaceBase64 = data['faceImageBase64'] as String?;
        if (docFaceBase64 != null) {
          setState(() {
            _documentFaceBytes = base64Decode(docFaceBase64);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    final pickedFile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _manualSelfieImage = File(pickedFile.path);
        _documentFaceBytes = null; // Clear doc face if user picks manually
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    DateTime initial;
    try {
      initial = _dobController.text.isNotEmpty ? DateFormat('yyyy-MM-dd').parse(_dobController.text) : now;
    } catch (_) {
      initial = now;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    File? imageToSend;

    // Determine which image to send
    if (_manualSelfieImage != null) {
      imageToSend = _manualSelfieImage;
    } else if (_documentFaceBytes != null) {
      // Convert bytes to file for upload
      final tempDir = await getTemporaryDirectory();
      imageToSend = await File('${tempDir.path}/temp_face_${DateTime.now().millisecondsSinceEpoch}.jpg').writeAsBytes(_documentFaceBytes!);
    }

    if (imageToSend == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a face image.')));
      return;
    }

    final get = context.read<Verification>();

    // 3. Save Data Locally
    get.updateStepData({
      'dukcapil_fm_name': _nameController.text,
      'dukcapil_fm_nik': _nikController.text,
      'dukcapil_fm_dob': _dobController.text,
      // Only save path if it's a manual image that persists on disk
      'dukcapil_fm_image_path': _manualSelfieImage?.path,
    });

    final success = await get.submitDukcapilFaceMatchData(
      context,
      name: _nameController.text,
      dob: _dobController.text,
      nik: _nikController.text,
      image: imageToSend,
    );

    // Cleanup temp file if created from bytes
    if (_documentFaceBytes != null && await imageToSend.exists()) {
      await imageToSend.delete().catchError((e) => debugPrint("Error deleting temp file: $e"));
    }

    if (!mounted) return;
    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Dukcapil Face Match failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Wrapped in SingleChildScrollView for sticky footer compatibility
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Using Card/Container style for consistency
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name*'),
                      validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter a name.' : null,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nikController,
                      decoration: const InputDecoration(labelText: 'NIK Number*'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) return 'Please enter a NIK number.';
                        if (value!.length != 16) return 'NIK must be 16 digits.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _selectDate,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth*',
                        hintText: 'YYYY-MM-DD',
                        suffixIcon: Icon(Icons.calendar_today, color: theme.colorScheme.secondary),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please select a date of birth.' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildImagePicker(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), // Padding for sticky footer
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Face Image*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          if (_manualSelfieImage != null)
            _buildImagePreview(_manualSelfieImage!, isFromDocument: false)
          else if (_documentFaceBytes != null)
            _buildImagePreview(_documentFaceBytes!, isFromDocument: true)
          else
            _buildPickerButtons(),
        ],
      ),
    );
  }

  Widget _buildPickerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text('Gallery'),
          onPressed: () => _pickImage(fromCamera: false),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Camera'),
          onPressed: () => _pickImage(fromCamera: true),
        ),
      ],
    );
  }

  Widget _buildImagePreview(dynamic image, {required bool isFromDocument}) {
    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image is File ? Image.file(image, height: 200, fit: BoxFit.cover) : Image.memory(image as Uint8List, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          if (isFromDocument)
            TextButton(
              onPressed: () => setState(() {
                _documentFaceBytes = null;
              }),
              child: const Text("Use a different photo"),
            )
          else
            TextButton(
              onPressed: () => setState(() {
                _manualSelfieImage = null;
              }),
              child: const Text("Remove photo", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
