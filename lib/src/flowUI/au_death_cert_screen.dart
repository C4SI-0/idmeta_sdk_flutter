import 'package:flutter/material.dart';
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

class AuDeathCertScreen extends StatefulWidget {
  const AuDeathCertScreen({super.key});
  @override
  State<AuDeathCertScreen> createState() => _AuDeathCertScreenState();
}

class _AuDeathCertScreenState extends State<AuDeathCertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _doeController = TextEditingController(); // Date of Event
  final _regNumController = TextEditingController();
  final _regDateController = TextEditingController();
  final _certNumController = TextEditingController();
  String? _selectedState;

  @override
  void dispose() {
    _familyNameController.dispose();
    _givenNameController.dispose();
    _doeController.dispose();
    _regNumController.dispose();
    _regDateController.dispose();
    _certNumController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(1900), lastDate: now);
    if (picked != null) setState(() => controller.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<Verification>();
    final success = await provider.submitAuDeathCertData(
      context,
      familyName: _familyNameController.text,
      givenName: _givenNameController.text,
      doe: _doeController.text,
      registrationNumber: _regNumController.text,
      registrationState: _stateAbbreviations[_selectedState]!,
      registrationDate: _regDateController.text,
      certificateNumber: _certNumController.text,
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
          _buildDateField(controller: _doeController, label: 'Date of Event*'),
          _buildTextField(controller: _regNumController, label: 'Registration Number*'),
          _buildDropdown(),
          _buildDateField(controller: _regDateController, label: 'Registration Date*'),
          _buildTextField(controller: _certNumController, label: 'Certificate Number*'),
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

  Widget _buildDateField({required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(controller),
        decoration: InputDecoration(labelText: label, suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary)),
        validator: (v) => (v?.trim().isEmpty ?? true) ? '$label is required.' : null,
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: DropdownButtonFormField<String>(
        value: _selectedState,
        decoration: const InputDecoration(labelText: 'Registration State*'),
        items: _states.map((String state) => DropdownMenuItem<String>(value: state, child: Text(state))).toList(),
        onChanged: (String? newValue) => setState(() => _selectedState = newValue),
        validator: (v) => (v == null) ? 'Please select a state.' : null,
      ),
    );
  }
}
