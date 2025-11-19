import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../verification/verification.dart';

class PhNationalPoliceScreen extends StatefulWidget {
  const PhNationalPoliceScreen({super.key});
  @override
  State<PhNationalPoliceScreen> createState() => _PhNationalPoliceScreenState();
}

class _PhNationalPoliceScreenState extends State<PhNationalPoliceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _surnameController = TextEditingController();
  final _clearanceController = TextEditingController();

  @override
  void dispose() {
    _surnameController.dispose();
    _clearanceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final get = context.read<Verification>();
    final success = await get.submitPhNationalPolice(
      context,
      surname: _surnameController.text,
      clearanceNo: _clearanceController.text,
    );

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
            controller: _surnameController,
            decoration: const InputDecoration(labelText: 'Surname*'),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter your surname.' : null,
          ),
          const SizedBox(height: 24),
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
