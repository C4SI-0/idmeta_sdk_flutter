import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:provider/provider.dart';

class BusinessAmlScreen extends StatefulWidget {
  const BusinessAmlScreen({super.key});
  @override
  State<BusinessAmlScreen> createState() => _BusinessAmlScreenState();
}

class _BusinessAmlScreenState extends State<BusinessAmlScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final get = context.read<Verification>();
    final success = await get.submitBusinessAml(context, businessName: _businessNameController.text);

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
            controller: _businessNameController,
            decoration: const InputDecoration(labelText: 'Business Name*'),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter the business name.' : null,
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
