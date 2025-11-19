import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import '../verification/verification.dart';
import 'utils/scanner.dart';

class QrVerificationScreen extends StatefulWidget {
  const QrVerificationScreen({super.key});
  @override
  State<QrVerificationScreen> createState() => _QrVerificationScreenState();
}

class _QrVerificationScreenState extends State<QrVerificationScreen> {
  Map<String, dynamic>? _decodedQrData;
  final _picker = ImagePicker();

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

  Future<void> _processQrString(String qrString) async {
    if (!qrString.trim().startsWith('{') || !qrString.trim().endsWith('}')) {
      _showErrorDialog("Invalid QR Code: The data is not in the expected JSON format.");
      return;
    }
    try {
      final decodedData = jsonDecode(qrString) as Map<String, dynamic>;
      if (decodedData.containsKey('signature')) {
        setState(() => _decodedQrData = decodedData);
      } else {
        _showErrorDialog("QR code format is incorrect. Missing 'signature' field.");
      }
    } catch (e) {
      _showErrorDialog("Invalid QR code: Could not parse JSON data.");
    }
  }

  Future<void> _pickAndDecodeImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    try {
      String? qrData = await QrCodeToolsPlugin.decodeFrom(pickedFile.path);
      if (!mounted) return;

      if (qrData != null && qrData.isNotEmpty) {
        await _processQrString(qrData);
      } else {
        _showErrorDialog("No QR code was found in the selected image.");
      }
    } catch (e) {
      _showErrorDialog("Failed to decode image. Please try a clearer picture.");
    }
  }

  Future<void> _submit() async {
    if (_decodedQrData == null) {
      _showErrorDialog("A valid QR code is required. Please scan or upload one.");
      return;
    }

    final get = context.read<Verification>();
    final success = await get.submitQrCode(context, qrPayload: _decodedQrData!);
    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      _showErrorDialog(get.errorMessage ?? 'QR Code verification failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Select QR Code Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _OptionButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    onPressed: () async {
                      final String? result = await Navigator.of(context).push<String?>(
                        MaterialPageRoute(builder: (_) => const _QRScannerPage()),
                      );
                      if (result != null) await _processQrString(result);
                    },
                  ),
                  _OptionButton(icon: Icons.image, label: 'Upload', onPressed: _pickAndDecodeImage),
                ],
              ),
              if (_decodedQrData != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Chip(
                    avatar: Icon(Icons.check_circle, color: Colors.green[700]),
                    label: const Text('QR Code Ready for Verification'),
                    backgroundColor: Colors.green.shade100,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _decodedQrData == null ? null : _submit,
          child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _OptionButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 100,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label),
        ]),
      ),
    );
  }
}

class _QRScannerPage extends StatefulWidget {
  const _QRScannerPage();
  @override
  State<_QRScannerPage> createState() => __QRScannerPageState();
}

class __QRScannerPageState extends State<_QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;

  TorchState _currentTorchState = TorchState.off;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code'), actions: [
        IconButton(
          icon: Icon(_currentTorchState == TorchState.on ? Icons.flash_on : Icons.flash_off),
          onPressed: () async {
            await controller.toggleTorch();

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
        Center(child: CustomPaint(painter: ScannerOverlayPainter(), child: const SizedBox(width: 250, height: 250))),
      ]),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
