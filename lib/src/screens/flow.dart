import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../verification/verification.dart';
import 'package:provider/provider.dart';
import '../api/flow_maps.dart';

/// A widget that manages and displays the sequential steps of the verification flow.
class FlowScreen extends StatelessWidget {
  /// Creates a [FlowScreen].
  const FlowScreen({super.key});

  /// Displays a confirmation dialog to the user before exiting the verification flow.
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit'),
        content: const Text('Are you sure you want to leave the verification process? Your progress will not be saved.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Exit')),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  /// A callback for [WillPopScope] to intercept the system back button press.
  Future<bool> _onWillPop(BuildContext context) async {
    final get = context.read<Verification>();

    if (!get.flowState.isFirstStep) {
      get.previousScreen();
      return false;
    }

    return _showExitConfirmationDialog(context);
  }

  /// Helper method to calculate the range of step indexes to display in the progress bar.
  List<int> _visibleSteps({
    required int totalSteps,
    required int currentStepIndex,
    int maxVisible = 5,
  }) {
    if (totalSteps <= maxVisible) {
      return List.generate(totalSteps, (index) => index);
    }

    int halfWindow = maxVisible ~/ 2;
    int start = currentStepIndex - halfWindow;
    int end = currentStepIndex + halfWindow;

    if (start < 0) {
      start = 0;
      end = maxVisible - 1;
    }
    if (end >= totalSteps - 1) {
      end = totalSteps - 2;
      start = end - maxVisible + 1;
    }

    return List.generate(end - start + 1, (index) => start + index);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the Verification provider
    final get = context.watch<Verification>();
    final flowState = get.flowState;
    final int totalSteps = flowState.allSteps.length;
    final int currentStepIndex = flowState.currentStepIndex;
    final settings = get.designSettings?.settings;
    final logoUrl = get.designSettings?.logoUrl;

    // Resolve current step
    final String? currentStepKey = flowState.currentStepKey;
    final String displayName = apiPlanDisplayNames[currentStepKey] ?? 'Verification Step';
    final Widget? screenWidget = apiScreenMapping[currentStepKey];

    // --- Dynamic Theme Colors ---
    final Color primaryColor = settings?.primaryColor ?? Colors.white;
    final Color headerColor = settings?.primaryColor ?? Colors.grey.shade100;

    final Color activeColor = settings?.secondaryColor ?? Colors.blue;
    final Color pillTextColor = settings?.buttonTextColor ?? Colors.white;
    final Color contentTextColor = settings?.textColor ?? Colors.black;
    final Color inactiveColor = contentTextColor.withOpacity(0.2);

    // Button Labels
    final String continueText = flowState.isLastStep ? "Complete" : "Continue";

    // --- WHITELIST: Only these screens show the sticky footer ---
    const Set<String> screensWithStickyFooter = {
      'document_verification',
      'document_verification_v2',
      'aml',
      'biometrics_verification',
      'biometrics_registration',
      'philippines_driving_license',
    };

    final bool showStickyFooter = currentStepKey != null && screensWithStickyFooter.contains(currentStepKey);

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: logoUrl != null ? Image.network(logoUrl, height: 50, errorBuilder: (_, __, ___) => const _DefaultLogo()) : const _DefaultLogo(),
          centerTitle: true,
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: contentTextColor,
        ),
        floatingActionButton: kDebugMode
            ? FloatingActionButton(
                onPressed: () => get.nextScreen(context),
                tooltip: 'Next Step (Debug)',
                child: const Icon(Icons.skip_next),
              )
            : null,
        body: Column(
          children: [
            // --- 1. Progress Header ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: activeColor, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentStepIndex + 1}/$totalSteps',
                        style: TextStyle(
                          color: pillTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i in _visibleSteps(totalSteps: totalSteps, currentStepIndex: currentStepIndex)) ...[
                        if (i > 0 && i > (_visibleSteps(totalSteps: totalSteps, currentStepIndex: currentStepIndex).first))
                          Container(
                            width: 15,
                            height: 2,
                            color: i <= currentStepIndex ? activeColor : inactiveColor,
                          ),
                        _buildDot(
                          index: i,
                          currentIndex: currentStepIndex,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          textColor: pillTextColor,
                        ),
                      ],
                      if (totalSteps > 5 && currentStepIndex < totalSteps - 3) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: inactiveColor)),
                        ),
                        _buildDot(
                          index: totalSteps - 1,
                          currentIndex: currentStepIndex,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          textColor: pillTextColor,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(displayName, style: TextStyle(fontSize: 18, color: contentTextColor)),
                ],
              ),
            ),

            // --- 2. Screen Body ---
            Expanded(
              child: _buildBody(context, screenWidget, currentStepKey),
            ),

            // --- 3. Sticky Footer Buttons (Conditional) ---
            if (showStickyFooter)
              SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -2),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // --- Back Button (Hidden on first step) ---
                      if (!flowState.isFirstStep) ...[
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEBEBEB),
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: get.isLoading ? null : () => get.previousScreen(),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Back',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],

                      // --- Continue Button ---
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            foregroundColor: pillTextColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: activeColor.withOpacity(0.5),
                            disabledForegroundColor: pillTextColor.withOpacity(0.7),
                          ),
                          onPressed: get.isLoading || get.onContinuePressed == null ? null : () => get.onContinuePressed!(),
                          child: get.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      continueText,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    if (!flowState.isLastStep) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ]
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({
    required int index,
    required int currentIndex,
    required Color activeColor,
    required Color inactiveColor,
    required Color textColor,
  }) {
    final bool isActive = index == currentIndex;
    final bool isCompleted = index < currentIndex;

    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive || isCompleted ? activeColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive || isCompleted ? activeColor : inactiveColor,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, size: 16, color: textColor)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: isActive ? textColor : inactiveColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Widget? screenWidget, String? currentStepKey) {
    if (screenWidget == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
              const SizedBox(height: 20),
              const Text(
                'Workflow Step Not Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "The step '$currentStepKey' could not be loaded.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return screenWidget;
  }
}

class _DefaultLogo extends StatelessWidget {
  const _DefaultLogo();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/logo.png', package: 'idmeta_sdk_flutter', height: 37),
        const SizedBox(width: 12),
        const Text('IDMeta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
      ],
    );
  }
}
