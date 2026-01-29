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

      // 1. Register the submit function to the Sticky Footer
      get.setContinueAction(_submit);

      // 2. Restore State (Prefill Name & Image if available)
      final data = get.flowState.collectedData;

      // Restore Name
      _usernameController.text = data['biometric_name'] ?? data['fullName'] ?? data['firstName'] ?? '';

      // Restore Image
      if (data['biometric_registration_image_path'] != null) {
        final file = File(data['biometric_registration_image_path']);
        if (file.existsSync()) {
          setState(() {
            _capturedImage = XFile(file.path);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validation: Form (Name)
    if (!_formKey.currentState!.validate()) return;

    // Validation: Image
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please capture a photo first.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final get = context.read<Verification>();

    // --- SAVE DATA LOCALLY BEFORE SUBMITTING ---
    get.updateStepData({
      'biometric_name': _usernameController.text,
      'fullName': _usernameController.text, // Update main key for consistency
      'biometric_registration_image_path': _capturedImage!.path,
    });
    // -------------------------------------------

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
      // Optional: Clear image on failure?
      // setState(() => _capturedImage = null);
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
                        const Text("Tips for Best Results:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7F9),
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

    // Use Form + Column. Expanded ensures camera takes remaining space.
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Full Name*'),
              validator: (value) => (value?.isEmpty ?? true) ? 'Please enter your name.' : null,
            ),
            const SizedBox(height: 16),

            // Camera / Image Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black, // Dark background for camera
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _capturedImage == null
                      ? BiometricCameraView(
                          onPictureCaptured: (image) {
                            setState(() => _capturedImage = image);
                          },
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Retake Photo'),
                                  onPressed: () => setState(() => _capturedImage = null),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Capture Guide Button
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
