import 'package:flutter/material.dart';
import 'selection_screen.dart';
import 'pcn_screen.dart';
import 'qr_scanner_screen.dart';
import 'manual_form_screen.dart';

// An enum to define the steps in this specific sub-flow.
enum PhilSysStep { selection, pcn, qrScanner, manualForm }

class PhilSysScreen extends StatefulWidget {
  const PhilSysScreen({super.key});
  @override
  State<PhilSysScreen> createState() => _PhilSysScreenState();
}

class _PhilSysScreenState extends State<PhilSysScreen> {
  PhilSysStep _currentStep = PhilSysStep.selection;

  void _navigateTo(PhilSysStep step) => setState(() => _currentStep = step);
  void _navigateBack() => setState(() => _currentStep = PhilSysStep.selection);

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    switch (_currentStep) {
      case PhilSysStep.pcn:
        currentScreen = PcnScreen(onBack: _navigateBack);
        break;
      case PhilSysStep.qrScanner:
        currentScreen = QrScannerScreen(onBack: _navigateBack);
        break;
      case PhilSysStep.manualForm:
        currentScreen = ManualFormScreen(onBack: _navigateBack);
        break;
      case PhilSysStep.selection:
      default:
        currentScreen = SelectionScreen(
          onPcnSelected: () => _navigateTo(PhilSysStep.pcn),
          onQrSelected: () => _navigateTo(PhilSysStep.qrScanner),
          onManualFormSelected: () => _navigateTo(PhilSysStep.manualForm),
        );
    }

    // Use AnimatedSwitcher for smooth transitions between sub-screens
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: SizedBox(
        // Use a key to ensure the AnimatedSwitcher correctly identifies child changes
        key: ValueKey<PhilSysStep>(_currentStep),
        child: currentScreen,
      ),
    );
  }
}
