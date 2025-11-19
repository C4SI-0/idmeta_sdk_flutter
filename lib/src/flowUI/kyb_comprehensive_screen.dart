import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:provider/provider.dart';

// Data for the Country Dropdown
const Map<String, String> _countryData = {
  "Australia": "AUS",
  "China": "CHN",
  "Hong Kong": "HKG",
  "India": "IND",
  "Indonesia": "IDN",
  "Japan": "JPN",
  "Malaysia": "MYS",
  "New Zealand": "NZL",
  "Philippines": "PHL",
  "Singapore": "SGP",
  "Thailand": "THA",
  "Taiwan": "TWN",
  "Vietnam": "VNM",
};
final List<String> _countryList = _countryData.keys.toList();

class KybComprehensiveScreen extends StatefulWidget {
  const KybComprehensiveScreen({super.key});
  @override
  State<KybComprehensiveScreen> createState() => _KybComprehensiveScreenState();
}

class _KybComprehensiveScreenState extends State<KybComprehensiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyRegController = TextEditingController();
  String? _selectedCountryName;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyRegController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<Verification>();
    final success = await provider.submitKybComprehensive(
      context,
      companyName: _companyNameController.text,
      registrationNumber: _companyRegController.text,
      countryCode: _countryData[_selectedCountryName]!,
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
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _selectedCountryName,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Country*'),
            items: _countryList.map((String country) => DropdownMenuItem<String>(value: country, child: Text(country))).toList(),
            onChanged: (String? newValue) => setState(() => _selectedCountryName = newValue),
            validator: (v) => (v == null) ? 'Please select a country.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _companyNameController,
            decoration: const InputDecoration(labelText: 'Company Name*'),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Please enter the company name.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _companyRegController,
            decoration: const InputDecoration(labelText: 'Company Registration Number*'),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Please enter the registration number.' : null,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _submitForm,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
