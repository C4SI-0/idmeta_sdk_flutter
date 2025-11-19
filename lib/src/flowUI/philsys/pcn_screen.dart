import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:provider/provider.dart';
import 'shared/face_verification_widget.dart';
import 'shared/submit_button.dart';
import 'shared/face_verification_webview.dart';

class PcnScreen extends StatefulWidget {
  final VoidCallback onBack;
  const PcnScreen({super.key, required this.onBack});

  @override
  State<PcnScreen> createState() => _PcnScreenState();
}

class _PcnScreenState extends State<PcnScreen> {
  final _pcnController = TextEditingController();
  FaceVerificationStatus _faceStatus = FaceVerificationStatus.initial;
  String? _faceSessionId;
  String? _faceErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<Verification>();
      _pcnController.text = provider.flowState.collectedData['docNumber'] ?? '';
    });
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
    if (_pcnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your PCN.')));
      return;
    }
    if (_faceStatus != FaceVerificationStatus.success || _faceSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete face verification first.')));
      return;
    }

    final provider = context.read<Verification>();
    final success = await provider.submitPhilSysData(
      context,
      faceLivenessSessionId: _faceSessionId!,
      pcn: _pcnController.text,
    );

    if (success && mounted) {
      provider.nextScreen(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Verification failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Align(
            alignment: Alignment.topLeft,
            child: TextButton.icon(icon: const Icon(Icons.arrow_back), label: const Text('Back to selection'), onPressed: widget.onBack)),
        const SizedBox(height: 24),
        const Text('Step 1: PCN Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _pcnController,
          decoration: const InputDecoration(labelText: 'Personal Control Number (PCN) *'),
        ),
        const SizedBox(height: 8),
        const Text('Your PCN can be found on your identification document.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 40),
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
    );
  }
}
