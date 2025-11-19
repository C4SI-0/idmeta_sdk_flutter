import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AuCitizenCertScreen extends StatefulWidget {
  const AuCitizenCertScreen({super.key});
  @override
  State<AuCitizenCertScreen> createState() => _AuCitizenCertScreenState();
}

class _AuCitizenCertScreenState extends State<AuCitizenCertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _acquisitionDateController = TextEditingController();
  final _stockNumberController = TextEditingController();

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
    _acquisitionDateController.dispose();
    _stockNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(1900), lastDate: now);
    if (picked != null) {
      setState(() => controller.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<Verification>();
    final success = await provider.submitAuCitizenCertData(
      context,
      familyName: _familyNameController.text,
      givenName: _givenNameController.text.isNotEmpty ? _givenNameController.text : null,
      dob: _dobController.text,
      acquisitionDate: _acquisitionDateController.text,
      stockNumber: _stockNumberController.text,
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
          _buildTextField(controller: _familyNameController, label: 'Family Name*'),
          _buildTextField(controller: _givenNameController, label: 'Given Name', isRequired: false),
          _buildDateField(controller: _dobController, label: 'Date of Birth*'),
          _buildTextField(controller: _stockNumberController, label: 'Stock Number*'),
          _buildDateField(controller: _acquisitionDateController, label: 'Acquisition Date*'),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _submitForm,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  // --- Reusable Widget Builders ---
  Widget _buildTextField({required TextEditingController controller, required String label, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (v) => (isRequired && (v?.trim().isEmpty ?? true)) ? '$label is required.' : null,
      ),
    );
  }

  Widget _buildDateField({required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(controller),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary),
        ),
        validator: (v) => (v?.trim().isEmpty ?? true) ? '$label is required.' : null,
      ),
    );
  }
}
