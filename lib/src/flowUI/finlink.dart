import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FinLinkScreen extends StatefulWidget {
  const FinLinkScreen({super.key});
  @override
  State<FinLinkScreen> createState() => _FinLinkScreenState();
}

class _FinLinkScreenState extends State<FinLinkScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<Verification>();
      final data = provider.flowState.collectedData;
      _firstNameController.text = data['firstName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _dobController.text = data['dob'] ?? '';
      _idNumberController.text = data['docNumber'] ?? '';
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
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

    final formData = {
      "firstName": _firstNameController.text,
      "lastName": _lastNameController.text,
      "dateOfBirth": _dobController.text,
      "phoneNumber": "+63${_phoneController.text}", // Hardcoded country code as in old UI
      "email": _emailController.text,
      "idNumber": _idNumberController.text,
    };

    final provider = context.read<Verification>();
    final success = await provider.submitFinlinkData(context, formData: formData);

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
          _buildTextField(controller: _firstNameController, label: 'First Name*', validator: _requiredValidator),
          _buildTextField(controller: _lastNameController, label: 'Last Name*', validator: _requiredValidator),
          _buildDateField(),
          _buildPhoneField(),
          _buildTextField(controller: _emailController, label: 'Email', keyboardType: TextInputType.emailAddress, validator: _emailValidator),
          _buildTextField(controller: _idNumberController, label: 'ID Number', keyboardType: TextInputType.text),
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

  // --- Reusable Field Validators ---
  String? _requiredValidator(String? value) => (value?.trim().isEmpty ?? true) ? 'This field is required.' : null;
  String? _emailValidator(String? value) =>
      (value != null && value.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) ? 'Please enter a valid email.' : null;

  // --- Reusable Widget Builders ---
  Widget _buildTextField(
      {required TextEditingController controller, required String label, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        validator: validator,
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
        decoration: InputDecoration(
          labelText: 'Date of Birth*',
          suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary),
        ),
        validator: _requiredValidator,
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: 'Phone Number*',
          prefixText: '+63 ',
        ),
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Phone number is required.';
          if (value!.length != 10) return 'Must be a 10-digit number.';
          return null;
        },
      ),
    );
  }
}
