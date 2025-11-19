import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// --- Data for the State Dropdown ---
const Map<String, String> _stateAbbreviations = {
  "New South Wales": "NSW",
  "Victoria": "VIC",
  "Queensland": "QLD",
  "South Australia": "SA",
  "Western Australia": "WA",
  "Tasmania": "TAS",
  "Northern Territory": "NT",
  "Australian Capital Territory": "ACT",
};
final List<String> _states = _stateAbbreviations.keys.toList();

class AuDlScreen extends StatefulWidget {
  const AuDlScreen({super.key});
  @override
  State<AuDlScreen> createState() => _AuDlScreenState();
}

class _AuDlScreenState extends State<AuDlScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _licenceNumberController = TextEditingController();
  final _cardNumberController = TextEditingController();
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<Verification>();
      final data = provider.flowState.collectedData;
      _familyNameController.text = data['lastName'] ?? '';
      _givenNameController.text = data['firstName'] ?? '';
      _dobController.text = data['dob'] ?? '';
      _licenceNumberController.text = data['docNumber'] ?? '';
    });
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _givenNameController.dispose();
    _middleNameController.dispose();
    _dobController.dispose();
    _licenceNumberController.dispose();
    _cardNumberController.dispose();
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
    final success = await provider.submitAuDlData(
      context,
      familyName: _familyNameController.text,
      middleName: _middleNameController.text.isNotEmpty ? _middleNameController.text : null,
      givenName: _givenNameController.text,
      dob: _dobController.text,
      cardNumber: _cardNumberController.text.isNotEmpty ? _cardNumberController.text : null,
      licenceNumber: _licenceNumberController.text,
      stateOfIssue: _stateAbbreviations[_selectedState]!,
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
          _buildTextField(controller: _middleNameController, label: 'Middle Name', isRequired: false),
          _buildDateField(),
          _buildTextField(controller: _licenceNumberController, label: 'Licence Number*'),
          _buildTextField(controller: _cardNumberController, label: 'Card Number', isRequired: false),
          _buildDropdown(),
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

  // Reusable widget builders
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

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: DropdownButtonFormField<String>(
        value: _selectedState,
        decoration: const InputDecoration(labelText: 'State of Issue*'),
        items: _states.map((String state) => DropdownMenuItem<String>(value: state, child: Text(state))).toList(),
        onChanged: (String? newValue) => setState(() => _selectedState = newValue),
        validator: (v) => (v == null) ? 'Please select a state.' : null,
      ),
    );
  }
}
