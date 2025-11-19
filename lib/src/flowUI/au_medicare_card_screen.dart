import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const List<String> _cardTypes = ["Green", "Blue", "Yellow"];
const Map<String, String> _cardTypeAbbreviations = {"Green": "G", "Blue": "B", "Yellow": "Y"};
const List<String> _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
final Map<String, String> _monthMap = {for (var i = 0; i < _months.length; i++) _months[i]: (i + 1).toString().padLeft(2, '0')};

class AuMedicareCardScreen extends StatefulWidget {
  const AuMedicareCardScreen({super.key});
  @override
  State<AuMedicareCardScreen> createState() => _AuMedicareCardScreenState();
}

class _AuMedicareCardScreenState extends State<AuMedicareCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name1Controller = TextEditingController();
  final _name2Controller = TextEditingController();
  final _name3Controller = TextEditingController();
  final _name4Controller = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _irnController = TextEditingController(); // Individual Reference Number
  final _dobController = TextEditingController();
  final _yearController = TextEditingController();
  String? _selectedMonth;
  String? _selectedCardType;

  @override
  void dispose() {
    _name1Controller.dispose();
    _name2Controller.dispose();
    _name3Controller.dispose();
    _name4Controller.dispose();
    _cardNumberController.dispose();
    _irnController.dispose();
    _dobController.dispose();
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
    final success = await provider.submitAuMedicareData(
      context,
      name1: _name1Controller.text.isNotEmpty ? _name1Controller.text : null,
      name2: _name2Controller.text.isNotEmpty ? _name2Controller.text : null,
      name3: _name3Controller.text.isNotEmpty ? _name3Controller.text : null,
      name4: _name4Controller.text.isNotEmpty ? _name4Controller.text : null,
      cardNumber: _cardNumberController.text,
      cardExpiry: cardExpiry,
      cardType: _cardTypeAbbreviations[_selectedCardType]!,
      individualReferenceNumber: _irnController.text,
      dob: _dobController.text.isNotEmpty ? _dobController.text : null,
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
          _buildTextField(controller: _name1Controller, label: 'Name 1 (Optional)', isRequired: false),
          _buildTextField(controller: _name2Controller, label: 'Name 2 (Optional)', isRequired: false),
          _buildTextField(controller: _name3Controller, label: 'Name 3 (Optional)', isRequired: false),
          _buildTextField(controller: _name4Controller, label: 'Name 4 (Optional)', isRequired: false),
          _buildTextField(
              controller: _cardNumberController,
              label: 'Card Number*',
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Card Number is required.';
                if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Must be 10 digits.';
                return null;
              }),
          _buildCardExpiryFields(),
          _buildDropdown(label: 'Card Type*', value: _selectedCardType, items: _cardTypes, onChanged: (v) => setState(() => _selectedCardType = v)),
          _buildTextField(
              controller: _irnController,
              label: 'Individual Reference Number*',
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'IRN is required.';
                if (!RegExp(r'^[1-9]$').hasMatch(v)) return 'Must be a number from 1 to 9.';
                return null;
              }),
          _buildDateField(controller: _dobController, label: 'Date of Birth (Optional)', isRequired: false),
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
      List<TextInputFormatter>? formatters,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        inputFormatters: formatters,
        validator: validator ?? ((v) => (isRequired && (v?.trim().isEmpty ?? true)) ? '$label is required.' : null),
      ),
    );
  }

  Widget _buildDateField({required TextEditingController controller, required String label, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: _selectDate,
        decoration: InputDecoration(labelText: label, suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary)),
        validator: (v) => (isRequired && (v?.trim().isEmpty ?? true)) ? '$label is required.' : null,
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
