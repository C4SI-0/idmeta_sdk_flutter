import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../verification/verification.dart';

class PhNbiClearanceScreen extends StatefulWidget {
  const PhNbiClearanceScreen({super.key});
  @override
  State<PhNbiClearanceScreen> createState() => _PhNbiClearanceScreenState();
}

class _PhNbiClearanceScreenState extends State<PhNbiClearanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clearanceController = TextEditingController();

  @override
  void dispose() {
    _clearanceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final get = context.read<Verification>();
    final success = await get.submitPhNbiClearance(context, clearanceNo: _clearanceController.text);

    if (!mounted) return;
    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Verification failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: <Widget>[
          TextFormField(
            controller: _clearanceController,
            decoration: const InputDecoration(labelText: 'Clearance Number*'),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter the clearance number.' : null,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _submitForm,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
