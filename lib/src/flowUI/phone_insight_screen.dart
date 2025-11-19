import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:provider/provider.dart';

class PhoneInsightScreen extends StatefulWidget {
  const PhoneInsightScreen({super.key});
  @override
  State<PhoneInsightScreen> createState() => _PhoneInsightScreenState();
}

class _PhoneInsightScreenState extends State<PhoneInsightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+');

  @override
  void dispose() {
    _phoneController.dispose();
    _countryCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<Verification>();
    final success = await provider.submitPhoneInsight(
      context,
      phoneNumber: _phoneController.text,
      countryCode: _countryCodeController.text,
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
        children: <Widget>[
          TextFormField(
            controller: _countryCodeController,
            decoration: const InputDecoration(labelText: 'Country Code*', hintText: 'e.g. +62'),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*'))],
            validator: (value) {
              if (value == null || value.length < 2) return 'Please enter a country code.';
              return null;
            },
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number*'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter a phone number.' : null,
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
