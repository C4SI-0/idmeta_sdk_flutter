import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../verification/verification.dart';

class PhDrivingLicenseScreen extends StatefulWidget {
  const PhDrivingLicenseScreen({super.key});

  @override
  State<PhDrivingLicenseScreen> createState() => _PhDrivingLicenseScreenState();
}

class _PhDrivingLicenseScreenState extends State<PhDrivingLicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _expiryController = TextEditingController();
  final _serialController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();
      final prefilledData = get.flowState.collectedData;

      _licenseController.text = prefilledData['docNumber'] ?? '';
      _expiryController.text = prefilledData['doe'] ?? '';
    });
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _expiryController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    DateTime initial;
    try {
      initial = _expiryController.text.isNotEmpty ? DateFormat('yyyy-MM-dd').parse(_expiryController.text) : now;
    } catch (_) {
      initial = now;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365 * 10)),
      lastDate: now.add(const Duration(days: 365 * 20)),
    );
    if (picked != null) {
      setState(() {
        _expiryController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final get = context.read<Verification>();
    final success = await get.submitPhDrivingLicenseData(
      context,
      licenseNumber: _licenseController.text,
      expiryDate: _expiryController.text,
      serialNumber: _serialController.text,
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
            controller: _licenseController,
            decoration: const InputDecoration(labelText: 'License Number*'),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter the license number.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _serialController,
            decoration: const InputDecoration(labelText: 'Serial Number (Optional)'),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _expiryController,
            readOnly: true,
            onTap: _selectDate,
            decoration: InputDecoration(
              labelText: 'Expiration Date*',
              hintText: 'YYYY-MM-DD',
              suffixIcon: Icon(Icons.calendar_today, color: theme.colorScheme.secondary),
            ),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please select the expiration date.' : null,
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
