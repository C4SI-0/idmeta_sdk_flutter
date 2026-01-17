import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:blinkid_flutter/microblink_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../verification/verification.dart';

enum UploadMethod { device, camera }

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({super.key});

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  bool _isInitializing = true;
  UploadMethod _uploadMethod = UploadMethod.device;

  // Image Data
  File? _displayFrontImage;
  File? _apiFrontImage;
  File? _displayBackImage;
  File? _apiBackImage;

  // Rotation Data
  double _frontRotation = 0;
  double _backRotation = 0;

  final _scannerService = DocumentScannerService();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();

      // 1. Register the submit function with the parent FlowScreen
      get.setContinueAction(_submit);

      final isManualDefault = get.flowState.isDocumentVerificationManualScan;

      if (!isManualDefault) {
        // If manual scan is NOT allowed, force camera and start scan
        setState(() {
          _uploadMethod = UploadMethod.camera;
        });
        _startScan();
      } else {
        // If manual scan IS allowed, default to device upload
        setState(() {
          _uploadMethod = UploadMethod.device;
          _isInitializing = false;
        });
      }
    });
  }

  /// The logic to run when the parent "Continue" button is pressed
  Future<void> _submit() async {
    final get = context.read<Verification>();
    final isMultiSide = get.flowState.isDocumentVerificationMultiSide;

    if (_apiFrontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Front side image is required.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (isMultiSide && _apiBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Back side image is required.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final success = await get.submitDocument(context, front: _apiFrontImage!, back: _apiBackImage);

    if (!mounted) return;

    if (success) {
      // Navigate to next screen (this clears the current action)
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Submission failed.')));
    }
  }

  Future<void> _startScan() async {
    setState(() => _isInitializing = true);
    final get = context.read<Verification>();
    final isMultiSide = get.flowState.isDocumentVerificationMultiSide;

    final ScanResult? result = isMultiSide ? await _scannerService.scanMultiSideDocument() : await _scannerService.scanSingleSideDocument();

    if (mounted && result != null) {
      setState(() {
        _displayFrontImage = result.displayImageFront;
        _apiFrontImage = result.apiImageFront;
        _displayBackImage = result.displayImageBack;
        _apiBackImage = result.apiImageBack;
        _frontRotation = 0;
        _backRotation = 0;
        _isInitializing = false;
        // Keep camera selected so if they want to rescan they can tap the box
        _uploadMethod = UploadMethod.camera;
      });
      // NOTE: Auto-submit removed to allow user review.
      // User must press the Sticky "Continue" button.
    } else if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _pickImage(int imageNumber) async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      final imageFile = File(pickedFile.path);
      setState(() {
        if (imageNumber == 1) {
          _displayFrontImage = imageFile;
          _apiFrontImage = imageFile;
          _frontRotation = 0;
        } else {
          _displayBackImage = imageFile;
          _apiBackImage = imageFile;
          _backRotation = 0;
        }
      });
    }
  }

  void _rotateImage(int imageNumber) {
    setState(() {
      if (imageNumber == 1) {
        _frontRotation += 90;
      } else {
        _backRotation += 90;
      }
    });
  }

  void _showImagePreview(File image, double rotationAngle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: rotationAngle * (math.pi / 180),
                child: Image.file(image, fit: BoxFit.contain),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showCaptureGuideDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 22, color: Colors.black87),
                        SizedBox(width: 10),
                        Text("Document Capture Guide", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Icon(Icons.cancel_outlined, color: Colors.grey, size: 26),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Tips for Best Results:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFF5F7F9), borderRadius: BorderRadius.circular(8)),
                          child: const Column(
                            children: [
                              _GuideItem(icon: Icons.lightbulb_outline, text: "Ensure good, even lighting"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.check_box_outline_blank, text: "Place document on a dark, non-reflective surface"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.grid_4x4, text: "Keep the document within the frame"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.shield_outlined, text: "Avoid shadows and glare"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.front_hand_outlined, text: "Hold the camera steady"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text("Common Issues to Avoid:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFF5F7F9), borderRadius: BorderRadius.circular(8)),
                          child: const Column(
                            children: [
                              _GuideItem(icon: Icons.broken_image_outlined, text: "Blurry or out-of-focus images"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.crop, text: "Partial document capture"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.pan_tool_outlined, text: "Fingers covering important information"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.brightness_low_outlined, text: "Poor lighting or shadows"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleContainerTap(int imageNumber) {
    if (_uploadMethod == UploadMethod.camera) {
      _startScan();
    } else {
      _pickImage(imageNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final get = context.watch<Verification>();
    final isMultiSide = get.flowState.isDocumentVerificationMultiSide;
    final isManualScanAllowed = get.flowState.isDocumentVerificationManualScan;

    final settings = get.designSettings?.settings;
    final textColor = settings?.textColor ?? Colors.black;
    final secondaryColor = settings?.secondaryColor ?? Colors.blue;

    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Top Toggle Section ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                if (isManualScanAllowed)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _uploadMethod = UploadMethod.device),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 0.75,
                            child: Radio<UploadMethod>(
                              value: UploadMethod.device,
                              groupValue: _uploadMethod,
                              activeColor: textColor,
                              onChanged: (val) => setState(() => _uploadMethod = val!),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const Icon(Icons.file_upload_outlined, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Upload from Device",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _uploadMethod = UploadMethod.camera);
                      _startScan();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: 0.75,
                          child: Radio<UploadMethod>(
                            value: UploadMethod.camera,
                            groupValue: _uploadMethod,
                            activeColor: textColor,
                            onChanged: (val) {
                              setState(() => _uploadMethod = val!);
                              _startScan();
                            },
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const Icon(Icons.camera_alt_outlined, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _uploadMethod == UploadMethod.camera ? "Open Document Scanner" : "Capture Using Camera",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Images Section ---
          if (_uploadMethod == UploadMethod.camera && _displayFrontImage == null)
            Column(
              children: [
                _buildSectionLabel("Scan Document", textColor),
                const SizedBox(height: 8),
                _buildUploadContainer(
                  image: null,
                  imageNumber: 1,
                  rotation: 0,
                  onTap: () => _startScan(),
                  onRemove: () {},
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  isCameraMode: true,
                ),
              ],
            )
          else if (isMultiSide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildSectionLabel("Front Image *", textColor),
                      const SizedBox(height: 8),
                      _buildUploadContainer(
                        image: _displayFrontImage,
                        imageNumber: 1,
                        rotation: _frontRotation,
                        onTap: () => _handleContainerTap(1),
                        onRemove: () => setState(() {
                          _displayFrontImage = null;
                          _apiFrontImage = null;
                          _frontRotation = 0;
                        }),
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                        isCameraMode: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _buildSectionLabel("Back Image *", textColor),
                      const SizedBox(height: 8),
                      _buildUploadContainer(
                        image: _displayBackImage,
                        imageNumber: 2,
                        rotation: _backRotation,
                        onTap: () => _handleContainerTap(2),
                        onRemove: () => setState(() {
                          _displayBackImage = null;
                          _apiBackImage = null;
                          _backRotation = 0;
                        }),
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                        isCameraMode: false,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildSectionLabel("Front Image *", textColor),
                const SizedBox(height: 8),
                _buildUploadContainer(
                  image: _displayFrontImage,
                  imageNumber: 1,
                  rotation: _frontRotation,
                  onTap: () => _handleContainerTap(1),
                  onRemove: () => setState(() {
                    _displayFrontImage = null;
                    _apiFrontImage = null;
                    _frontRotation = 0;
                  }),
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  isCameraMode: false,
                ),
              ],
            ),

          const SizedBox(height: 32),

          // --- Capture Guide Link ---
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: _showCaptureGuideDialog,
            icon: Icon(Icons.help_outline, size: 18, color: textColor),
            label: Text(
              "Document Capture Guide",
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Padding to ensure scroll doesn't cut off behind sticky footer if content is long
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Align(
      alignment: Alignment.center,
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500),
          children: [
            if (text.contains('*'))
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadContainer({
    required File? image,
    required int imageNumber,
    required double rotation,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    required Color textColor,
    required Color secondaryColor,
    required bool isCameraMode,
  }) {
    if (image != null) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => _showImagePreview(image, rotation),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: secondaryColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Transform.rotate(
                  angle: rotation * (math.pi / 180),
                  child: Image.file(image, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: InkWell(
              onTap: () => _rotateImage(imageNumber),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rotate_right, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(color: Colors.grey.shade400, strokeWidth: 1.5, gap: 5.0),
        child: Container(
          width: double.infinity,
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Icon(isCameraMode ? Icons.camera_alt_outlined : Icons.file_upload_outlined, size: 24, color: textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 8),
              Text(
                isCameraMode ? "Tap to Scan" : "Drag & drop or browse",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!isCameraMode) ...[
                const SizedBox(height: 4),
                Text(
                  "JPG, PNG, JPEG",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _GuideItem({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87))),
      ],
    );
  }
}

class ScanResult {
  final File displayImageFront;
  final File apiImageFront;
  final File? displayImageBack;
  final File? apiImageBack;
  ScanResult({required this.displayImageFront, required this.apiImageFront, this.displayImageBack, this.apiImageBack});
}

class DocumentScannerService {
  static const Map<String, String> _licenses = {
    'com.psslai.ko':
        'sRwCAA1jb20ucHNzbGFpLmtvAWxleUpEY21WaGRHVmtUMjRpT2pFM05UTTBOREV3T1RBNE1ERXNJa055WldGMFpXUkdiM0lpT2lKbVlqVTNNakZtT0MxaFlUTXlMVEpsTXpZdE1XTTFZaTB6TUROa016Wm1ZekV3T1dFaWZRPT1zCbYZmIAvF4MF2FxDdaAOM5njNhd2k2EIC6rBiBCMeAvmDA6skqViQ0u7ageG3EGE/8Mimu+tMM4ZsySTjRPf/c6x2RAsIhRLDa6HNCBaSeyHI4eGAXxZJSjki1+w',
    'com.traxionpay.app':
        'sRwCABJjb20udHJheGlvbnBheS5hcHABbGV5SkRjbVZoZEdWa1QyNGlPakUzTlRNME5ERXhNelV3TlRFc0lrTnlaV0YwWldSR2IzSWlPaUptWWpVM01qRm1PQzFoWVRNeUxUSmxNell0TVdNMVlpMHpNRE5rTXpabVl6RXdPV0VpZlE9PaB5Y1Ou5VdPjkSc2jxwmMffwzNFq1RdMHFNmcxlEUm5RuE6KUEpUTdlWo6Fe1U0gKZwyc8GHJT0DFvQ3cF+IV9DiGDID4wBa+R4lGdjI2l6IeWHG4QH6DylnxD6Kik=',
    'com.traxiontech.bibo':
        'sRwCABRjb20udHJheGlvbnRlY2guYmlibwFsZXlKRGNtVmhkR1ZrVDI0aU9qRTNOVE0wTkRFeU1UY3lORGdzSWtOeVpXRjBaV1JHYjNJaU9pSm1ZalUzTWpGbU9DMWhZVE15TFRKbE16WXRNV00xWWkwek1ETmtNelptWXpFd09XRWlmUT09XpNbFjrg+VSFAen7nClGxzKkeadW64bdmy6hV0FMpfrc5W33TVwQ5iGf2t409RREgFT5dGlUaZlHedH0aj7wQaNvWXN62pmsfN/zh5pOGDZeavpxfYYMaL2pzqpkgg==',
    'android.com.psslai.ko':
        'sRwCAA1jb20ucHNzbGFpLmtvAGxleUpEY21WaGRHVmtUMjRpT2pFM05UTTBOREV6TVRjeE1ERXNJa055WldGMFpXUkdiM0lpT2lKbVlqVTNNakZtT0MxaFlUTXlMVEpsTXpZdE1XTTFZaTB6TUROa016Wm1ZekV3T1dFaWZRPT0Kh1QG0Td+3pHFoowe0+1ZgiQb5gN2VFTSFf7IyGyO5OgW4YL8AGW7vsm38wnSwaC5BF8/tN9xnJ7jSI7VBfV/j1aIGdq1y5V+yy4Avj1Bp0+rKDOzZQ1VxRntYZm7',
    'android.com.traxionpay.app':
        'sRwCABJjb20udHJheGlvbnBheS5hcHAAbGV5SkRjbVZoZEdWa1QyNGlPakUzTlRNME5ERXpOREF4T0RFc0lrTnlaV0YwWldSR2IzSWlPaUptWWpVM01qRm1PQzFoWVRNeUxUSmxNell0TVdNMVlpMHpNRE5rTXpabVl6RXdPV0VpZlE9PYVyKUVZ40moRXa/ZA/u2fIirfo7NPGEpxai27HyK9G7449M/7NcviC2Hvw9wGkE8D2mhkEkw5iyD09qQkH//QhCWOWH5NlLeH9CsJp73/2f7yytF1GxiG8zyCsJ/p4=',
    'android.com.traxiontech.bibo':
        'sRwCABRjb20udHJheGlvbnRlY2guYmlibwBsZXlKRGNtVmhkR1ZrVDI0aU9qRTNOVE0wTkRFek5qVTRPRGdzSWtOeVpXRjBaV1JHYjNJaU9pSm1ZalUzTWpGbU9DMWhZVE15TFRKbE16WXRNV00xWWkwek1ETmtNelptWXpFd09XRWlmUT09BgRdLZ5+uhvjgUjEnifH/nzT2sqybFYvDuPXZVjQ3EyhK0AzJbM7+XrZ+KjSOZ5j1Q5Ela4DRDx/knLz7nB9xt9HFydbQO0PsCRpiRS7Z3+kHcUC0nyfpIIqJPbDew==',
  };
  static const String _defaultLicense =
      "sRwCABZjb20uaWQuaWRtZXRhX3Nkay5ob3N0AGxleUpEY21WaGRHVmtUMjRpT2pFM05EazNNelV5TnpVeE56Y3NJa055WldGMFpXUkdiM0lpT2lKbVlqVTNNakZtT0MxaFlUTXlMVEpsTXpZdE1XTTFZaTB6TUROa016Wm1ZekV3T1dFaWZRPT1ORyI35Qwc40ZjOtb4AU3o2ZeuIE2GIC2P9YN+k+e3HnvD0wL0wZ+fUAFmss8AqTZgZEVzWRGDeteQfTbnDtBGSgnaCfHVFIvYlOdhaBXF9GcWew2y6uhISvX0ctCOP7jIoz6YD30ZUkwScQ==";

  Future<String> _getLicenseKey() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final key = Platform.isAndroid ? 'android.${packageInfo.packageName}' : packageInfo.packageName;
    return _licenses[key] ?? _defaultLicense;
  }

  Future<File> _base64ToFile(String base64Str, String fileName) async {
    final bytes = base64Decode(base64Str);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<ScanResult?> scanMultiSideDocument() async {
    try {
      var idRecognizer = BlinkIdMultiSideRecognizer()
        ..returnFullDocumentImage = true
        ..saveCameraFrames = true;
      BlinkIdOverlaySettings settings = BlinkIdOverlaySettings();
      var results = await MicroblinkScanner.scanWithCamera(RecognizerCollection([idRecognizer]), settings, await _getLicenseKey());
      if (results.isEmpty) return null;
      for (var result in results) {
        if (result is BlinkIdMultiSideRecognizerResult) {
          if (result.fullDocumentFrontImage == null || result.frontCameraFrame == null) return null;
          final displayFront = await _base64ToFile(result.fullDocumentFrontImage!, "display_front.jpg");
          final apiFront = await _base64ToFile(result.frontCameraFrame!, "api_front.jpg");
          File? displayBack;
          File? apiBack;
          if (result.fullDocumentBackImage != null &&
              result.fullDocumentBackImage!.isNotEmpty &&
              result.backCameraFrame != null &&
              result.backCameraFrame!.isNotEmpty) {
            displayBack = await _base64ToFile(result.fullDocumentBackImage!, "display_back.jpg");
            apiBack = await _base64ToFile(result.backCameraFrame!, "api_back.jpg");
          }
          return ScanResult(displayImageFront: displayFront, apiImageFront: apiFront, displayImageBack: displayBack, apiImageBack: apiBack);
        }
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<ScanResult?> scanSingleSideDocument() async {
    try {
      var idRecognizer = BlinkIdSingleSideRecognizer()
        ..returnFullDocumentImage = true
        ..saveCameraFrames = true;
      BlinkIdOverlaySettings settings = BlinkIdOverlaySettings();
      var results = await MicroblinkScanner.scanWithCamera(RecognizerCollection([idRecognizer]), settings, await _getLicenseKey());
      if (results.isEmpty) return null;
      for (var result in results) {
        if (result is BlinkIdSingleSideRecognizerResult) {
          if (result.fullDocumentImage == null || result.cameraFrame == null) return null;
          final displayFront = await _base64ToFile(result.fullDocumentImage!, "display_front.jpg");
          final apiFront = await _base64ToFile(result.cameraFrame!, "api_front.jpg");
          return ScanResult(displayImageFront: displayFront, apiImageFront: apiFront);
        }
      }
      return null;
    } on PlatformException {
      return null;
    }
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  DashedBorderPainter({required this.color, this.strokeWidth = 1.0, this.gap = 5.0});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final Path path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));
    final Path dashedPath = _dashPath(path, width: 6, space: gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dest.addPath(metric.extractPath(distance, distance + width), Offset.zero);
        distance += width + space;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
