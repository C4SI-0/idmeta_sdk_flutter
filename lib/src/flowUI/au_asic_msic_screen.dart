import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const List<String> _cardTypes = ["ASIC", "MSIC"];
const List<String> _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
final Map<String, String> _monthMap = {for (var i = 0; i < _months.length; i++) _months[i]: (i + 1).toString().padLeft(2, '0')};

class AuAsicMsicScreen extends StatefulWidget {
  const AuAsicMsicScreen({super.key});
  @override
  State<AuAsicMsicScreen> createState() => _AuAsicMsicScreenState();
}

class _AuAsicMsicScreenState extends State<AuAsicMsicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _yearController = TextEditingController();
  String? _selectedMonth;
  String? _selectedCardType;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _cardNumberController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(1900), lastDate: now);
    if (picked != null) setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final cardExpiry = '${_yearController.text}-${_monthMap[_selectedMonth!]}';

    final provider = context.read<Verification>();
    final success = await provider.submitAuAsicMsicData(
      context,
      fullName: _fullNameController.text,
      dob: _dobController.text,
      cardNumber: _cardNumberController.text,
      cardExpiry: cardExpiry,
      cardType: _selectedCardType!,
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
          _buildTextField(controller: _fullNameController, label: 'Full Name*'),
          _buildDateField(),
          _buildTextField(controller: _cardNumberController, label: 'Card Number*'),
          _buildCardExpiryFields(),
          _buildDropdown(
            label: 'Card Type*',
            value: _selectedCardType,
            items: _cardTypes,
            onChanged: (v) => setState(() => _selectedCardType = v),
          ),
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

  Widget _buildDropdown({required String label, String? value, required List<String> items, required void Function(String?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (v) => (v == null) ? 'Please select an option.' : null,
      ),
    );
  }

  Widget _buildCardExpiryFields() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMonth,
              decoration: const InputDecoration(labelText: 'Expiry Month*'),
              items: _months.map((String month) => DropdownMenuItem<String>(value: month, child: Text(month))).toList(),
              onChanged: (v) => setState(() => _selectedMonth = v),
              validator: (v) => (v == null) ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(labelText: 'Expiry Year*'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              validator: (v) {
                if (v == null || v.length != 4) return '4 digits';
                if (int.tryParse(v) == null || int.parse(v) < DateTime.now().year) return 'Invalid';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
