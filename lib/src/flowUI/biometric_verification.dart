import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../verification/verification.dart';
import '../widgets/biometric_camera_view.dart';

class BiometricVerificationScreen extends StatefulWidget {
  const BiometricVerificationScreen({super.key});
  @override
  State<BiometricVerificationScreen> createState() => _BiometricVerificationScreenState();
}

class _BiometricVerificationScreenState extends State<BiometricVerificationScreen> {
  // Common state
  final _cameraViewKey = GlobalKey<BiometricCameraViewState>();
  XFile? _capturedImage; // Store captured image for Standard Mode

  // State for the native liveness check (FacePlus)
  static const _platform = MethodChannel('net.idrnd.iad/liveness');
  String _livenessStatus = 'Initializing liveness check...';
  bool _hasLivenessCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final verification = context.read<Verification>();

      // 1. Register the submit function to the Sticky Footer
      verification.setContinueAction(_submit);

      // Auto-start FacePlus if configured
      if (mounted && verification.flowState.useFacePlus && !_hasLivenessCheckStarted) {
        setState(() {
          _hasLivenessCheckStarted = true;
        });
        _startLivenessCheck();
      }
    });
  }

  /// Unified Submit Logic for the Sticky Button
  Future<void> _submit() async {
    final provider = context.read<Verification>();
    final useFacePlus = provider.flowState.useFacePlus;

    if (useFacePlus) {
      // Logic for FacePlus
      await _startLivenessCheck();
    } else {
      // Logic for Standard Camera
      if (_capturedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please capture a photo first.'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      final success = await provider.submitBiometricVerification(context, image: _capturedImage!);

      if (!mounted) return;

      if (success) {
        provider.nextScreen(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Verification failed.')));
      }
    }
  }

  // --- Standard Biometric Camera Logic ---
  void _onPictureCaptured(XFile image) {
    setState(() {
      _capturedImage = image;
    });
  }

  // --- FacePlus Logic ---
  Future<void> _startLivenessCheck() async {
    final provider = context.read<Verification>();
    final token = provider.flowState.userToken;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication token is missing.')));
      return;
    }

    setState(() => _livenessStatus = 'Please look at the camera...');

    try {
      final String result = await _platform.invokeMethod('startLiveness', {
        'authToken': token,
        'templateId': provider.flowState.templateId ?? '',
        'verificationId': provider.flowState.verificationId ?? '',
      });

      if (!mounted) return;
      setState(() => _livenessStatus = result);

      if (result == "Success") {
        provider.nextScreen(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final status = "Error: ${e.message}";
      setState(() => _livenessStatus = status);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
    }
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
    final useFacePlus = context.select((Verification p) => p.flowState.useFacePlus);
    final settings = context.watch<Verification>().designSettings?.settings;
    final textColor = settings?.textColor ?? Colors.black;

    // Standard Column instead of ScrollView to fill available height
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (useFacePlus) Expanded(child: _buildFacePlusView()) else Expanded(child: _buildStandardCameraView(textColor)),
        ],
      ),
    );
  }

  // Widget for the standard camera view
  Widget _buildStandardCameraView(Color textColor) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            // ClipRRect ensures corners are rounded
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _capturedImage == null
                  ? BiometricCameraView(
                      key: _cameraViewKey,
                      onPictureCaptured: _onPictureCaptured,
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                        // Retake Button Overlay
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

        // Guide Button at bottom
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
            style: TextStyle(decoration: TextDecoration.underline, color: textColor, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // Widget for the native FacePlus liveness view
  Widget _buildFacePlusView() {
    final isLoading = context.watch<Verification>().isLoading;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.shield_outlined, size: 100, color: Colors.blueAccent),
          const SizedBox(height: 24),
          const Text("Liveness Check", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(_livenessStatus, style: const TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: isLoading ? null : _startLivenessCheck,
            child: const Text('Retry Liveness Check'),
          ),
        ],
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
