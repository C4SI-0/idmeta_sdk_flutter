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

  // State for the native liveness check (FacePlus)
  static const _platform = MethodChannel('net.idrnd.iad/liveness');
  String _livenessStatus = 'Initializing liveness check...';
  bool _hasLivenessCheckStarted = false;

  @override
  void initState() {
    super.initState();
    // Auto-start the liveness check if configured
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<Verification>().flowState.useFacePlus && !_hasLivenessCheckStarted) {
        setState(() {
          _hasLivenessCheckStarted = true;
        });
        _startLivenessCheck();
      }
    });
  }

  // --- Standard Biometric Camera Logic ---
  Future<void> _onPictureCaptured(XFile image) async {
    final get = context.read<Verification>();
    final success = await get.submitBiometricVerification(context, image: image);
    if (!mounted) return;
    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Verification failed.')));
      await _cameraViewKey.currentState?.resumeCamera();
    }
  }

  // --- Native Liveness (FacePlus) Logic ---
  Future<void> _startLivenessCheck() async {
    final provider = context.read<Verification>();
    setState(() => _livenessStatus = 'Please look at the camera...');

    try {
      final String result = await _platform.invokeMethod('startLiveness', {
        'authToken': provider.flowState.userToken,
        'templateId': provider.flowState.templateId,
        'verificationId': provider.flowState.verificationId,
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

  @override
  Widget build(BuildContext context) {
    final provider = context.read<Verification>();

    print("Tokenn: ${provider.flowState.userToken}");

    // Read the config flag to decide which UI to build.
    final useFacePlus = context.select((Verification p) => p.flowState.useFacePlus);

    if (useFacePlus) {
      return _buildFacePlusView();
    } else {
      return _buildStandardCameraView();
    }
  }

  // Widget for the standard camera view
  Widget _buildStandardCameraView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text("Face Verification", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("Please position your face in the center of the frame.", textAlign: TextAlign.center),
          const SizedBox(height: 30),
          SizedBox(
            height: 500,
            child: BiometricCameraView(
              key: _cameraViewKey,
              onPictureCaptured: _onPictureCaptured,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for the native FacePlus liveness view
  Widget _buildFacePlusView() {
    // We watch the provider's isLoading flag to disable the retry button during the liveness check.
    final isLoading = context.watch<Verification>().isLoading;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
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
      ),
    );
  }
}
