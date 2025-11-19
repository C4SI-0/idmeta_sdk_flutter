import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'shared/face_verification_widget.dart';
import 'shared/submit_button.dart';
import 'shared/face_verification_webview.dart';

class QrScannerScreen extends StatefulWidget {
  final VoidCallback onBack;
  const QrScannerScreen({super.key, required this.onBack});
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  String? _rawQrData;
  FaceVerificationStatus _faceStatus = FaceVerificationStatus.initial;
  String? _faceSessionId;
  String? _faceErrorMessage;

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _handleFaceVerification() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
        context,
        MaterialPageRoute(
            builder: (_) => MultiProvider(
                  // ✨ THE FIX: Re-provide the necessary providers ✨
                  providers: [
                    // Pass the existing instance of VerificationProvider down to the new route
                    ChangeNotifierProvider.value(
                      value: context.read<Verification>(),
                    ),
                  ],
                  child: const FaceVerificationWebView(),
                )));
    if (result != null && mounted) {
      final sessionId = result['session_id'];
      if (sessionId != null && sessionId is String && sessionId.isNotEmpty) {
        setState(() {
          _faceStatus = FaceVerificationStatus.success;
          _faceSessionId = sessionId;
        });
      } else {
        setState(() {
          _faceStatus = FaceVerificationStatus.failed;
          _faceErrorMessage = result['message']?.toString() ?? "Liveness verification failed";
        });
      }
    }
  }

  void _submit() async {
    if (_rawQrData == null) {
      _showErrorDialog("A valid QR code must be scanned.");
      return;
    }
    if (_faceStatus != FaceVerificationStatus.success || _faceSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete face verification first.')));
      return;
    }

    final provider = context.read<Verification>();
    final success = await provider.submitPhilSysData(context, faceLivenessSessionId: _faceSessionId!, qrData: _rawQrData!);

    if (success && mounted) {
      provider.nextScreen(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Verification failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(icon: const Icon(Icons.arrow_back), label: const Text('Back to selection'), onPressed: widget.onBack),
          const SizedBox(height: 16),
          const Text('Step 1: QR Code Scanner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Code'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () async {
              final String? result = await Navigator.of(context).push<String?>(
                MaterialPageRoute(builder: (_) => const _InternalQRScannerPage()),
              );
              if (result != null && mounted) {
                setState(() => _rawQrData = result);
              }
            },
          ),
          const SizedBox(height: 20),
          if (_rawQrData != null)
            Center(
              child: Chip(
                avatar: Icon(Icons.check_circle, color: Colors.green[700]),
                label: const Text('QR Code Data is Ready'),
                backgroundColor: Colors.green.shade100,
              ),
            ),
          const Spacer(),
          const Text('Step 2: Identity Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          FaceVerificationWidget(
            status: _faceStatus,
            errorMessage: _faceErrorMessage,
            onVerify: _handleFaceVerification,
          ),
          const SizedBox(height: 40),
          SubmitButton(
            isEnabled: _faceStatus == FaceVerificationStatus.success,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// The dedicated full-screen scanner page.
class _InternalQRScannerPage extends StatefulWidget {
  const _InternalQRScannerPage();
  @override
  State<_InternalQRScannerPage> createState() => __InternalQRScannerPageState();
}

class __InternalQRScannerPageState extends State<_InternalQRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;

  // Manually track the torch state because the controller no longer exposes it.
  TorchState _currentTorchState = TorchState.off;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code'), actions: [
        // The IconButton now uses our local state variable to display the correct icon.
        IconButton(
          color: _currentTorchState == TorchState.on ? Colors.amber : null,
          icon: Icon(_currentTorchState == TorchState.on ? Icons.flash_on : Icons.flash_off),
          onPressed: () async {
            // Toggle the torch using the controller's method.
            await controller.toggleTorch();
            // Manually update our local state to match.
            setState(() {
              _currentTorchState = _currentTorchState == TorchState.on ? TorchState.off : TorchState.on;
            });
          },
        ),
        IconButton(icon: const Icon(Icons.switch_camera), onPressed: () => controller.switchCamera()),
      ]),
      body: Stack(children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            if (!_isScanned && capture.barcodes.isNotEmpty) {
              final String? code = capture.barcodes.first.rawValue;
              if (code != null) {
                setState(() => _isScanned = true);
                Navigator.of(context).pop(code);
              }
            }
          },
        ),
        Center(child: CustomPaint(painter: _ScannerOverlayPainter(), child: const SizedBox(width: 250, height: 250))),
      ]),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// The custom painter for the scanner overlay corners.
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    const double cornerLength = 30;
    canvas.drawPath(
        Path()
          ..moveTo(0, cornerLength)
          ..lineTo(0, 0)
          ..lineTo(cornerLength, 0) // Top-left
          ..moveTo(size.width - cornerLength, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, cornerLength) // Top-right
          ..moveTo(0, size.height - cornerLength)
          ..lineTo(0, size.height)
          ..lineTo(cornerLength, size.height) // Bottom-left
          ..moveTo(size.width - cornerLength, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, size.height - cornerLength), // Bottom-right
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
