import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum PrcVerificationType { byName, byLicence }

class PhPrcScreen extends StatefulWidget {
  const PhPrcScreen({super.key});
  @override
  State<PhPrcScreen> createState() => _PhPrcScreenState();
}

class _PhPrcScreenState extends State<PhPrcScreen> {
  final _formKey = GlobalKey<FormState>();

  final _professionController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _licenceController = TextEditingController();
  final _dobController = TextEditingController();

  PrcVerificationType _verificationType = PrcVerificationType.byName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();
      final prefilledData = get.flowState.collectedData;

      _professionController.text = prefilledData['profession'] ?? '';
      _firstNameController.text = prefilledData['firstName'] ?? '';
      _lastNameController.text = prefilledData['lastName'] ?? '';
      _licenceController.text = prefilledData['docNumber'] ?? '';
      _dobController.text = prefilledData['dob'] ?? '';
    });
  }

  @override
  void dispose() {
    _professionController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _licenceController.dispose();
    _dobController.dispose();
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

    final get = context.read<Verification>();
    final success = await get.submitPhPrcData(
      context,
      profession: _professionController.text,
      firstName: _verificationType == PrcVerificationType.byName ? _firstNameController.text : null,
      lastName: _verificationType == PrcVerificationType.byName ? _lastNameController.text : null,
      licenseNo: _verificationType == PrcVerificationType.byLicence ? _licenceController.text : null,
      dob: _verificationType == PrcVerificationType.byLicence ? _dobController.text : null,
    );

    if (!mounted) return;
    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Verification failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Row(children: [
            Expanded(
                child: RadioListTile<PrcVerificationType>(
              title: const Text("By Name"),
              value: PrcVerificationType.byName,
              groupValue: _verificationType,
              onChanged: (v) => setState(() => _verificationType = v!),
            )),
            Expanded(
                child: RadioListTile<PrcVerificationType>(
              title: const Text("By Licence"),
              value: PrcVerificationType.byLicence,
              groupValue: _verificationType,
              onChanged: (v) => setState(() => _verificationType = v!),
            )),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _professionController,
            decoration: const InputDecoration(labelText: 'Profession*'),
            validator: (v) => (v?.isEmpty ?? true) ? 'Profession is required.' : null,
          ),
          const SizedBox(height: 24),
          if (_verificationType == PrcVerificationType.byName) ...[
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name*'),
              validator: (v) => (v?.isEmpty ?? true) ? 'First Name is required.' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name*'),
              validator: (v) => (v?.isEmpty ?? true) ? 'Last Name is required.' : null,
            ),
          ] else ...[
            TextFormField(
              controller: _licenceController,
              decoration: const InputDecoration(labelText: 'Licence Number*'),
              validator: (v) => (v?.isEmpty ?? true) ? 'Licence Number is required.' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _dobController,
              readOnly: true,
              onTap: _selectDate,
              decoration: InputDecoration(
                labelText: 'Date of Birth*',
                suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary),
              ),
              validator: (v) => (v?.isEmpty ?? true) ? 'Date of Birth is required.' : null,
            ),
          ],
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
