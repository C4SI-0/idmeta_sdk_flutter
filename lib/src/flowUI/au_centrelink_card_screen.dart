import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const List<String> _cardTypes = ["PCC", "HCC", "SHC"];

class AuCentrelinkCardScreen extends StatefulWidget {
  const AuCentrelinkCardScreen({super.key});
  @override
  State<AuCentrelinkCardScreen> createState() => _AuCentrelinkCardScreenState();
}

class _AuCentrelinkCardScreenState extends State<AuCentrelinkCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _crnController = TextEditingController(); // Customer Reference Number
  String? _selectedCardType;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _cardExpiryController.dispose();
    _crnController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(1900), lastDate: now.add(const Duration(days: 365 * 10)));
    if (picked != null) setState(() => controller.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<Verification>();
    final success = await provider.submitAuCentrelinkData(
      context,
      name: _nameController.text,
      dob: _dobController.text,
      cardExpiry: _cardExpiryController.text,
      cardType: _selectedCardType!,
      customerReferenceNumber: _crnController.text,
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
          _buildTextField(controller: _nameController, label: 'Name*'),
          _buildDateField(controller: _dobController, label: 'Date of Birth*'),
          _buildDropdown(),
          _buildDateField(controller: _cardExpiryController, label: 'Card Expiry*'),
          _buildTextField(
              controller: _crnController,
              label: 'Customer Reference Number*',
              validator: (v) {
                final regex = RegExp(r'^[0-9]{9}[a-zA-Z]{1}$');
                if (v == null || v.isEmpty) return 'CRN is required.';
                if (!regex.hasMatch(v)) return 'Must be 9 numbers then 1 letter.';
                return null;
              }),
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

  Widget _buildTextField({required TextEditingController controller, required String label, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator ?? ((v) => (v?.trim().isEmpty ?? true) ? '$label is required.' : null),
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
        value: _selectedCardType,
        decoration: const InputDecoration(labelText: 'Card Type*'),
        items: _cardTypes.map((String type) => DropdownMenuItem<String>(value: type, child: Text(type))).toList(),
        onChanged: (String? newValue) => setState(() => _selectedCardType = newValue),
        validator: (v) => (v == null) ? 'Please select a card type.' : null,
      ),
    );
  }
}
