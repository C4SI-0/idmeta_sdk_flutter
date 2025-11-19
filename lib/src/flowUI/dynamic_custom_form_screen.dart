import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DynamicCustomFormScreen extends StatefulWidget {
  const DynamicCustomFormScreen({super.key});
  @override
  State<DynamicCustomFormScreen> createState() => _DynamicCustomFormScreenState();
}

class _DynamicCustomFormScreenState extends State<DynamicCustomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<Map<String, dynamic>> _formFields;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, File?> _fileData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeForm());
  }

  void _initializeForm() {
    final provider = context.read<Verification>();
    final config = provider.flowState.toolSettings['custom_form'];
    if (config == null || config['fields'] is! List) {
      setState(() {
        _formFields = [];
        _isLoading = false;
      });
      return;
    }
    final fields = (config['fields'] as List).whereType<Map<String, dynamic>>().toList();
    _formFields = fields.where((f) => f['name'] != null && f['slug'] != null).toList();
    for (var field in _formFields) {
      final slug = field['slug'] as String;
      if (field['type'] == 'file') {
        _fileData[slug] = null;
      } else {
        _controllers[slug] = TextEditingController();
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final formData = <String, dynamic>{};
    for (var field in _formFields) {
      final slug = field['slug'] as String;
      if (field['type'] == 'file') {
        formData[slug] = _fileData[slug];
      } else {
        formData[slug] = _controllers[slug]!.text;
      }
    }

    final provider = context.read<Verification>();
    final success = await provider.submitCustomForm(context, formData: formData);
    if (!mounted) return;
    if (success) {
      provider.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Submission failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_formFields.isEmpty) return const Center(child: Text("No form fields configured for this step."));

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          ..._formFields.map((field) => _buildFormField(field)),
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

  Widget _buildFormField(Map<String, dynamic> field) {
    final type = field['type'] as String;
    final name = field['name'] as String;
    final slug = field['slug'] as String;
    final isRequired = field['required'] as bool? ?? false;

    Widget formField;
    switch (type) {
      case 'string':
        formField = _buildTextField(slug, name, isRequired);
        break;
      case 'number':
        formField = _buildNumberField(slug, name, isRequired);
        break;
      case 'date':
        formField = _buildDateField(slug, name, isRequired);
        break;
      case 'datetime':
        formField = _buildDateTimeField(slug, name, isRequired);
        break;
      case 'file':
        formField = _buildFileField(slug, name, isRequired);
        break;
      default:
        formField = Text('Unsupported field type: $type');
    }
    return Padding(padding: const EdgeInsets.only(bottom: 24.0), child: formField);
  }

  // --- Field Builder Widgets ---
  TextFormField _buildTextField(String slug, String name, bool isRequired) {
    return TextFormField(
      controller: _controllers[slug],
      decoration: InputDecoration(hintText: 'Enter $name'),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $name';
              }
              return null;
            }
          : null,
    );
  }

  TextFormField _buildNumberField(String slug, String name, bool isRequired) {
    return TextFormField(
      controller: _controllers[slug],
      decoration: InputDecoration(hintText: 'Enter $name'),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $name';
              }
              return null;
            }
          : null,
    );
  }

  TextFormField _buildDateField(String slug, String name, bool isRequired) {
    return TextFormField(
      controller: _controllers[slug],
      readOnly: true,
      decoration: const InputDecoration(
        hintText: 'Select a date',
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          _controllers[slug]!.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      },
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a date for $name';
              }
              return null;
            }
          : null,
    );
  }

  TextFormField _buildDateTimeField(String slug, String name, bool isRequired) {
    return TextFormField(
      controller: _controllers[slug],
      readOnly: true,
      decoration: const InputDecoration(
        hintText: 'Select a date and time',
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null && mounted) {
          final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(DateTime.now()),
          );
          if (pickedTime != null) {
            final fullDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            _controllers[slug]!.text = DateFormat("yyyy-MM-dd HH:mm").format(fullDateTime);
          }
        }
      },
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a date and time for $name';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildFileField(String slug, String name, bool isRequired) {
    return FormField<File>(
      validator: (v) => (isRequired && _fileData[slug] == null) ? 'Please upload a file for $name' : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(text: name, children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))])),
          const SizedBox(height: 8),
          _fileData[slug] != null
              ? ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(_fileData[slug]!.path.split('/').last, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _fileData[slug] = null)),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                )
              : OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose File'),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result != null) setState(() => _fileData[slug] = File(result.files.single.path!));
                  },
                ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
