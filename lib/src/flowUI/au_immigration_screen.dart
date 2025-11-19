import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AuImmigrationScreen extends StatefulWidget {
  const AuImmigrationScreen({super.key});
  @override
  State<AuImmigrationScreen> createState() => _AuImmigrationScreenState();
}

class _AuImmigrationScreenState extends State<AuImmigrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _immigrationCardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<Verification>();
      final data = provider.flowState.collectedData;
      _familyNameController.text = data['lastName'] ?? '';
      _givenNameController.text = data['firstName'] ?? '';
      _dobController.text = data['dob'] ?? '';
    });
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _givenNameController.dispose();
    _dobController.dispose();
    _immigrationCardController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(1900), lastDate: now);
    if (picked != null) {
      setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<Verification>();
    final success = await provider.submitAuImmigrationData(
      context,
      familyName: _familyNameController.text,
      givenName: _givenNameController.text,
      dob: _dobController.text,
      immigrationCardNumber: _immigrationCardController.text,
    );

    if (!mounted) return;
    if (success) {
      provider.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Verification failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextFormField(
            controller: _familyNameController,
            decoration: const InputDecoration(labelText: 'Family Name*'),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Please enter your family name.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _givenNameController,
            decoration: const InputDecoration(labelText: 'Given Name*'),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Please enter your given name.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: _selectDate,
            decoration: InputDecoration(
              labelText: 'Date of Birth*',
              suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary),
            ),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Please select your date of birth.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _immigrationCardController,
            decoration: const InputDecoration(labelText: 'Immigration Card Number*'),
            validator: (value) {
              final regex = RegExp(r'^[a-zA-Z]{3}[0-9]{6}$');
              if (value == null || value.isEmpty) {
                return 'Please enter your immigration card number.';
              }
              if (!regex.hasMatch(value)) {
                return 'Format must be 3 letters followed by 6 numbers.';
              }
              return null;
            },
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
