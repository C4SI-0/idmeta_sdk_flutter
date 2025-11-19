import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../verification/verification.dart';

class DukcapilVerificationScreen extends StatefulWidget {
  const DukcapilVerificationScreen({super.key});

  @override
  State<DukcapilVerificationScreen> createState() => _DukcapilVerificationScreenState();
}

class _DukcapilVerificationScreenState extends State<DukcapilVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nikController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();
      final prefilledData = get.flowState.collectedData;

      _nameController.text = prefilledData['fullName'] ?? prefilledData['firstName'] ?? '';
      _nikController.text = prefilledData['docNumber'] ?? '';
      _dobController.text = prefilledData['dob'] ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    DateTime initial;
    try {
      initial = _dobController.text.isNotEmpty ? DateFormat('yyyy-MM-dd').parse(_dobController.text) : now;
    } catch (_) {
      initial = now;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
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
    final success = await get.submitDukcapilData(
      context,
      name: _nameController.text,
      dob: _dobController.text,
      nik: _nikController.text,
    );

    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Dukcapil verification failed.'),
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
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name*'),
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter a name.' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nikController,
            decoration: const InputDecoration(labelText: 'NIK Number*'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value?.trim().isEmpty ?? true) return 'Please enter a NIK number.';
              if (value!.length != 16) return 'NIK must be 16 digits.';
              return null;
            },
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
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please select a date of birth.' : null,
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
