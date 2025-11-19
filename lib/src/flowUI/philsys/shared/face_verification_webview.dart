import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class FaceVerificationWebView extends StatefulWidget {
  const FaceVerificationWebView({super.key});
  @override
  State<FaceVerificationWebView> createState() => _FaceVerificationWebViewState();
}

enum _FlowState { loading, webView, error }

class _FaceVerificationWebViewState extends State<FaceVerificationWebView> {
  var _currentState = _FlowState.loading;
  String? _verificationUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startVerificationProcess();
  }

  Future<void> _startVerificationProcess() async {
    try {
      await _requestPermissions();
      final publicKey = context.read<Verification>().flowState.toolSettings['scan_qr']?['publicKey'];
      if (publicKey == null) {
        throw Exception("Public key for liveness check is not configured.");
      }

      final finalUrl = "https://liveness.everify.gov.ph/?t=basic&liveness=0&awst=$publicKey";
      if (mounted) {
        setState(() {
          _verificationUrl = finalUrl;
          _currentState = _FlowState.webView;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _currentState = _FlowState.error;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera]!.isPermanentlyDenied || statuses[Permission.microphone]!.isPermanentlyDenied) {
      throw Exception("Please enable camera and microphone access in your device settings.");
    }
    if (statuses[Permission.camera]!.isDenied || statuses[Permission.microphone]!.isDenied) {
      throw Exception("Camera and Microphone permissions are required for face verification.");
    }
  }

  void _handleVerificationResult(Map<String, dynamic> result) {
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Face Verification')), body: _buildBody());
  }

  Widget _buildBody() {
    switch (_currentState) {
      case _FlowState.loading:
        return const Center(child: CircularProgressIndicator());
      case _FlowState.error:
        return _ErrorView(message: _errorMessage ?? "An unknown error occurred.", onTryAgain: _startVerificationProcess);
      case _FlowState.webView:
        return InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_verificationUrl!)),
          initialSettings: InAppWebViewSettings(mediaPlaybackRequiresUserGesture: false, allowsInlineMediaPlayback: true, isInspectable: true),
          onPermissionRequest: (_, request) async => PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT),
          onLoadStop: (controller, url) {
            controller.evaluateJavascript(source: """
              window.addEventListener('message', (event) => {
                if (event.origin === 'https://liveness.everify.gov.ph') {
                  window.flutter_inappwebview.callHandler('verificationResult', event.data);
                }
              });
            """);
          },
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(
              handlerName: 'verificationResult',
              callback: (args) {
                if (args.isNotEmpty && args[0] is String) {
                  try {
                    _handleVerificationResult(json.decode(args[0]) as Map<String, dynamic>);
                  } catch (e) {
                    _handleVerificationResult({'status': 'ERROR', 'message': 'Failed to parse result from webview'});
                  }
                }
              },
            );
          },
          onLoadError: (_, __, code, message) {
            if (mounted)
              setState(() {
                _errorMessage = "Failed to load page. Code: $code, Message: $message";
                _currentState = _FlowState.error;
              });
          },
        );
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onTryAgain;
  const _ErrorView({required this.message, required this.onTryAgain});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $message', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onTryAgain, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
