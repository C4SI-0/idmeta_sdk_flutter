import 'package:flutter/material.dart';

class SelectionScreen extends StatelessWidget {
  final VoidCallback onPcnSelected;
  final VoidCallback onQrSelected;
  final VoidCallback onManualFormSelected;

  const SelectionScreen({
    super.key,
    required this.onPcnSelected,
    required this.onQrSelected,
    required this.onManualFormSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text('Verification Method', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Please select your preferred verification method', style: TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVerificationCard(
                  iconData: Icons.person_pin_outlined,
                  title: 'Use PCN',
                  subtitle: 'Enter your Personal Control Number',
                  onTap: onPcnSelected,
                  color: theme.colorScheme.secondary),
              _buildVerificationCard(
                  iconData: Icons.qr_code_scanner, title: 'QR Scanner', subtitle: 'Scan your QR code', onTap: onQrSelected, color: theme.colorScheme.secondary),
              _buildVerificationCard(
                  iconData: Icons.edit_note,
                  title: 'Manual Form',
                  subtitle: 'Fill in your details manually',
                  onTap: onManualFormSelected,
                  color: theme.colorScheme.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard({required IconData iconData, required String title, required String subtitle, required VoidCallback onTap, Color? color}) {
    return Expanded(
      child: SizedBox(
        height: 160,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconData, size: 40, color: color),
                  const SizedBox(height: 12),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
