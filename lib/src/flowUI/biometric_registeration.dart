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
    if (!_formKey.currentState!.validate() || _capturedImage == null) return;

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

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<Verification>().isLoading;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Full Name*'),
              validator: (value) => (value?.isEmpty ?? true) ? 'Please enter your name.' : null,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: (isLoading || _capturedImage == null) ? null : _submit,
              child: isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Register and Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
