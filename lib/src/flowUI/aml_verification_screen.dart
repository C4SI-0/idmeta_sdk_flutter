import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../verification/verification.dart';

const List<(String, String)> genderOptions = [
  ('Any', 'any'),
  ('Male', 'male'),
  ('Female', 'female'),
];

class AmlVerificationScreen extends StatefulWidget {
  const AmlVerificationScreen({super.key});

  @override
  State<AmlVerificationScreen> createState() => _AmlVerificationScreenState();
}

class _AmlVerificationScreenState extends State<AmlVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGenderValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();
      final prefilledData = get.flowState.collectedData;
      _nameController.text = prefilledData['fullName'] ?? prefilledData['firstName'] ?? '';
      _dobController.text = prefilledData['dob'] ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = _dobController.text.isNotEmpty ? (DateTime.tryParse(_dobController.text) ?? now) : now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final get = context.read<Verification>();

    final success = await get.submitAmlData(
      context,
      name: _nameController.text,
      dob: _dobController.text.isNotEmpty ? _dobController.text : null,
      gender: _selectedGenderValue,
    );

    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Submission failed.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<Verification>().isLoading;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: <Widget>[
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name*'),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter a name.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: _selectDate,
            decoration: InputDecoration(
              labelText: 'Date of Birth (Optional)',
              hintText: 'YYYY-MM-DD',
              suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedGenderValue,
            decoration: const InputDecoration(labelText: 'Gender (Optional)'),
            items: genderOptions.map(((String, String) option) {
              return DropdownMenuItem<String>(value: option.$2, child: Text(option.$1));
            }).toList(),
            onChanged: (String? newValue) => setState(() => _selectedGenderValue = newValue),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            child:
                isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Next'),
          ),
        ],
      ),
    );
  }
}
