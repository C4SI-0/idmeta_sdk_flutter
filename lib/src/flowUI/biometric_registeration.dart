import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../verification/verification.dart';
import '../widgets/biometric_camera_view.dart';

class BiometricRegistrationScreen extends StatefulWidget {
  const BiometricRegistrationScreen({super.key});
  @override
  State<BiometricRegistrationScreen> createState() => _BiometricRegistrationScreenState();
}

class _BiometricRegistrationScreenState extends State<BiometricRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();

      // 1. Register the submit function with the parent Sticky Footer
      get.setContinueAction(_submit);

      // Prefill data
      final collectedData = get.flowState.collectedData;
      _usernameController.text = collectedData['fullName'] ?? collectedData['firstName'] ?? '';
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validation: Ensure image is captured
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please capture a photo first.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Validation: Ensure form is valid
    if (!_formKey.currentState!.validate()) return;

    final get = context.read<Verification>();
    final success = await get.submitBiometricRegistration(
      context,
      username: _usernameController.text,
      image: _capturedImage!,
    );

    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Registration failed.'),
        backgroundColor: Colors.red,
      ));

      setState(() {
        _capturedImage = null;
      });
    }
  }

  /// Displays the custom Selfie Capture Guide popup
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 22, color: Colors.black87),
                        SizedBox(width: 10),
                        Text(
                          "Selfie Capture Guide",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Icon(Icons.close, color: Colors.grey, size: 24),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Tips
                        const Text("Tips for Best Results:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7F9), // Light grey background
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            children: [
                              _GuideItem(icon: Icons.lightbulb_outline, text: "Ensure good, even lighting on your face"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.face_outlined, text: "Position your face within the oval guide"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.front_hand_outlined, text: "Hold the camera steady and at eye level"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.camera_alt_outlined, text: "Look directly at the camera"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.shield_outlined, text: "Remove glasses, hats, or face coverings"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section 2: Issues
                        const Text("Common Issues to Avoid:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            children: [
                              _GuideItem(icon: Icons.broken_image_outlined, text: "Blurry or out-of-focus images"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.brightness_low_outlined, text: "Poor lighting or shadows on face"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.vibration, text: "Camera shake or movement"),
                              SizedBox(height: 12),
                              _GuideItem(icon: Icons.error_outline, text: "Face partially outside the oval guide"),
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Verification>().designSettings?.settings;
    final textColor = settings?.textColor ?? Colors.black;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Full Name*'),
              validator: (value) => (value?.isEmpty ?? true) ? 'Please enter your name.' : null,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              child: _capturedImage == null
                  ? BiometricCameraView(
                      onPictureCaptured: (image) {
                        setState(() => _capturedImage = image);
                      },
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Registration Photo', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retake Photo'),
                          onPressed: () => setState(() => _capturedImage = null),
                        ),
                      ],
                    ),
            ),
          ),

          // --- Capture Guide Button ---
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: _showCaptureGuideDialog,
            icon: Icon(Icons.help_outline, size: 18, color: textColor),
            label: Text(
              "Selfie Capture Guide",
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widget for Guide Items ---
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
