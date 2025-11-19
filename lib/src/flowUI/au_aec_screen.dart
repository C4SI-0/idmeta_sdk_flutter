import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

class AuAecScreen extends StatefulWidget {
  const AuAecScreen({super.key});
  @override
  State<AuAecScreen> createState() => _AuAecScreenState();
}

class _AuAecScreenState extends State<AuAecScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _suburbController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _streetTypeController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _unitNumberController = TextEditingController();
  final _buildingNameController = TextEditingController();
  String? _selectedState;

  @override
  void dispose() {
    _familyNameController.dispose();
    _givenNameController.dispose();
    _dobController.dispose();
    _postcodeController.dispose();
    _suburbController.dispose();
    _streetNameController.dispose();
    _streetTypeController.dispose();
    _streetNumberController.dispose();
    _unitNumberController.dispose();
    _buildingNameController.dispose();
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
    final success = await provider.submitAuAecData(
      context,
      familyName: _familyNameController.text,
      givenName: _givenNameController.text,
      dob: _dobController.text.isNotEmpty ? _dobController.text : null,
      suburb: _suburbController.text,
      postcode: _postcodeController.text,
      state: _stateAbbreviations[_selectedState]!,
      streetName: _streetNameController.text.isNotEmpty ? _streetNameController.text : null,
      streetType: _streetTypeController.text.isNotEmpty ? _streetTypeController.text : null,
      streetNumber: _streetNumberController.text.isNotEmpty ? _streetNumberController.text : null,
      unitNumber: _unitNumberController.text.isNotEmpty ? _unitNumberController.text : null,
      habitationName: _buildingNameController.text.isNotEmpty ? _buildingNameController.text : null,
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
          _buildDateField(controller: _dobController, label: 'Date of Birth (Optional)'),
          _buildDropdown(),
          _buildTextField(
              controller: _postcodeController,
              label: 'Postcode*',
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]),
          _buildTextField(controller: _suburbController, label: 'Suburb*'),
          _buildTextField(controller: _streetNameController, label: 'Street Name', isRequired: false),
          _buildTextField(controller: _streetTypeController, label: 'Street Type', isRequired: false),
          _buildTextField(controller: _streetNumberController, label: 'Street Number', isRequired: false),
          _buildTextField(controller: _unitNumberController, label: 'Flat/Unit Number', isRequired: false),
          _buildTextField(controller: _buildingNameController, label: 'Building Name', isRequired: false),
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
  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      bool isRequired = true,
      TextInputType? keyboardType,
      List<TextInputFormatter>? formatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        inputFormatters: formatters,
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
        onTap: _selectDate,
        decoration: InputDecoration(labelText: label, suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary)),
        // Not required as per your old code
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: DropdownButtonFormField<String>(
        value: _selectedState,
        decoration: const InputDecoration(labelText: 'State*'),
        items: _states.map((String state) => DropdownMenuItem<String>(value: state, child: Text(state))).toList(),
        onChanged: (String? newValue) => setState(() => _selectedState = newValue),
        validator: (v) => (v == null) ? 'Please select a state.' : null,
      ),
    );
  }
}
