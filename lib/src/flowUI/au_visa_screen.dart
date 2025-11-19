import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AuVisaScreen extends StatefulWidget {
  const AuVisaScreen({super.key});
  @override
  State<AuVisaScreen> createState() => _AuVisaScreenState();
}

class _AuVisaScreenState extends State<AuVisaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _countryOfIssueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<Verification>();
      final data = provider.flowState.collectedData;
      _familyNameController.text = data['lastName'] ?? '';
      _givenNameController.text = data['firstName'] ?? '';
      _dobController.text = data['dob'] ?? '';
      _passportNumberController.text = data['docNumber'] ?? '';
    });
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _givenNameController.dispose();
    _dobController.dispose();
    _passportNumberController.dispose();
    _countryOfIssueController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(1900), lastDate: now);
    if (picked != null) setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<Verification>();
    final success = await provider.submitAuVisaData(
      context,
      familyName: _familyNameController.text,
      givenName: _givenNameController.text,
      dob: _dobController.text,
      passportNumber: _passportNumberController.text,
      countryOfIssue: _countryOfIssueController.text,
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
          _buildTextField(controller: _givenNameController, label: 'Given Name*'),
          _buildDateField(),
          _buildTextField(controller: _passportNumberController, label: 'Passport Number*'),
          _buildTextField(controller: _countryOfIssueController, label: 'Country of Issue*'),
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

  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (v) => (v?.trim().isEmpty ?? true) ? '$label is required.' : null,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: _dobController,
        readOnly: true,
        onTap: _selectDate,
        decoration: InputDecoration(labelText: 'Date of Birth*', suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary)),
        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Date of Birth is required.' : null,
      ),
    );
  }
}
