import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../verification/verification.dart';

const List<String> genderOptions = ['Male', 'Female', 'Not specified'];

class AuPassportScreen extends StatefulWidget {
  const AuPassportScreen({super.key});

  @override
  State<AuPassportScreen> createState() => _AuPassportScreenState();
}

class _AuPassportScreenState extends State<AuPassportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _passportNumberController = TextEditingController();

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();
      final data = get.flowState.collectedData;

      _lastNameController.text = data['lastName'] ?? '';

      _givenNameController.text = data['firstName'] ?? '';

      _dobController.text = data['dob'] ?? '';
      _passportNumberController.text = data['docNumber'] ?? '';

      final sex = data['sex'] as String?;
      if (sex != null) {
        if (sex.toUpperCase().startsWith('M')) {
          _selectedGender = 'Male';
        } else if (sex.toUpperCase().startsWith('F')) {
          _selectedGender = 'Female';
        } else if (sex.toUpperCase().startsWith('X')) {
          _selectedGender = 'Not specified';
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _givenNameController.dispose();
    _dobController.dispose();
    _passportNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {}

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String genderApiValue = 'X';
    if (_selectedGender == 'Male') genderApiValue = 'M';
    if (_selectedGender == 'Female') genderApiValue = 'F';

    final get = context.read<Verification>();
    final success = await get.submitAuPassportData(
      context,
      lastName: _lastNameController.text,
      givenName: _givenNameController.text,
      dob: _dobController.text,
      gender: genderApiValue,
      passportNumber: _passportNumberController.text,
    );

    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Verification failed.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<Verification>().isLoading;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: <Widget>[
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: 'Family Name*'),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Family name is required.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _givenNameController,
            decoration: const InputDecoration(labelText: 'Given Name (Optional)'),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: _selectDate,
            decoration: InputDecoration(
              labelText: 'Date of Birth*',
              hintText: 'YYYY-MM-DD',
              suffixIcon: Icon(Icons.calendar_today, color: theme.colorScheme.secondary),
            ),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Date of birth is required.' : null,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            items: genderOptions.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() => _selectedGender = newValue);
            },
            decoration: const InputDecoration(labelText: 'Gender*'),
            validator: (value) => (value == null || value.isEmpty) ? 'Please select a gender.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passportNumberController,
            decoration: const InputDecoration(labelText: 'Travel Document Number*'),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) return 'Passport number is required.';

              final RegExp regex = RegExp(r'^[A-Z]{1,2}\d{7}$', caseSensitive: false);
              if (!regex.hasMatch(value!)) return 'Invalid format (e.g., E1234567).';
              return null;
            },
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: isLoading ? null : _submitForm,
            child:
                isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Next'),
          ),
        ],
      ),
    );
  }
}
