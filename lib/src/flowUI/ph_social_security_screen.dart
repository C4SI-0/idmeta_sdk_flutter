import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../verification/verification.dart';

class PhSocialSecurityScreen extends StatefulWidget {
  const PhSocialSecurityScreen({super.key});

  @override
  State<PhSocialSecurityScreen> createState() => _PhSocialSecurityScreenState();
}

class _PhSocialSecurityScreenState extends State<PhSocialSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sssController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();

      final prefilledData = get.flowState.collectedData['docNumber'] ?? '';
      _sssController.text = prefilledData;
    });
  }

  @override
  void dispose() {
    _sssController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final get = context.read<Verification>();
    final success = await get.submitPhSocialSecurityData(
      context,
      sssNumber: _sssController.text,
    );

    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Verification failed.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<Verification>().isLoading;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: <Widget>[
          TextFormField(
            controller: _sssController,
            decoration: const InputDecoration(labelText: 'CRN/SS Number*'),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter the CRN/SS number.' : null,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: isLoading ? null : _submitForm,
            child:
                isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Next'),
          ),
        ],
      ),
    );
  }
}
