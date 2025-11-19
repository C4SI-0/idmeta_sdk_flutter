import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../verification/verification.dart';
import 'package:provider/provider.dart';
import '../api/flow_maps.dart';

/// A widget that manages and displays the sequential steps of the verification flow.
///
/// This screen acts as a host for the individual verification step widgets.
/// It includes a dynamic `AppBar` that shows the current step's title and
/// provides navigation controls (back and exit). It also handles back navigation
/// logic, asking for user confirmation before exiting the entire flow.
class FlowScreen extends StatelessWidget {
  /// Creates a [FlowScreen].
  const FlowScreen({super.key});

  /// Displays a confirmation dialog to the user before exiting the verification flow.
  ///
  /// This prevents accidental loss of progress.
  ///
  /// Returns `true` if the user confirms they want to exit, otherwise `false`.
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    // `showDialog<bool>` returns the value passed to `Navigator.pop`.
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit'),
        content: const Text('Are you sure you want to leave the verification process? Your progress will not be saved.'),
        actions: <Widget>[
          // The "Cancel" button pops the dialog and returns `false`.
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          // The "Yes, Exit" button pops the dialog and returns `true`.
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Exit')),
        ],
      ),
    );
    // If the dialog is dismissed (e.g., by tapping outside), it returns null.
    // In that case, we default to `false` to prevent exiting.
    return shouldExit ?? false;
  }

  /// A callback for [WillPopScope] to intercept the back button press.
  ///
  /// This method controls navigation within the flow. If the user is not on the
  /// first step, it navigates to the previous screen. If they are on the first
  /// step, it prompts for exit confirmation.
  ///
  /// Returns a `Future<bool>` that determines whether to allow the pop gesture.
  /// `false` prevents the pop, `true` allows it.
  Future<bool> _onWillPop(BuildContext context) async {
    // Use `context.read` here because we only need to call a method,
    // not listen for changes.
    final get = context.read<Verification>();

    // If it's not the first step, go to the previous screen in the flow state.
    if (!get.flowState.isFirstStep) {
      get.previousScreen();
      // Return false to prevent the default back navigation from popping the route.
      return false;
    }

    // If it is the first step, show the confirmation dialog. The result of the
    // dialog will determine if the route should be popped.
    return _showExitConfirmationDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the Verification provider to rebuild the UI when the state updates.
    final get = context.watch<Verification>();
    final flowState = get.flowState;
    final settings = get.designSettings?.settings;

    // Get the key for the current step (e.g., 'selfie_step').
    final String? currentStepKey = flowState.currentStepKey;
    // Look up the human-readable display name for the current step.
    final String displayName = apiPlanDisplayNames[currentStepKey] ?? 'Verification Step';

    // Look up the corresponding widget for the current verification step.
    final Widget? screenWidget = apiScreenMapping[currentStepKey];

    // Create a localized theme based on the dynamic settings from the API.
    final theme = Theme.of(context).copyWith(
        primaryColor: settings?.primaryColor,
        appBarTheme: AppBarTheme(
          // Use dynamic text color for AppBar icons and text.
          foregroundColor: settings?.textColor ?? Colors.black,
        ),
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: settings?.effectiveFontFamily,
              bodyColor: settings?.textColor,
            ));

    // WillPopScope intercepts the system back button to implement custom logic.
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          // Show a back button only if it's not the first step.
          leading: !flowState.isFirstStep
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  // The onPressed handler reuses the onWillPop logic.
                  onPressed: () => _onWillPop(context),
                )
              : null, // No leading widget on the first step.
          title: Text(displayName, style: const TextStyle(fontSize: 18)),
          actions: [
            // Exit button to allow users to quit the flow at any time.
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryColor,
              ),
              child: const Text('Exit', style: TextStyle(fontSize: 14)),
              onPressed: () async {
                // Confirm exit before popping the main navigator route.
                if (await _showExitConfirmationDialog(context)) {
                  // Ensure the context is still valid before interacting with it.
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        ),
        // The body of the scaffold displays the appropriate screen for the current step.
        body: _buildBody(context, screenWidget, currentStepKey),
        // A FloatingActionButton for debugging purposes to easily skip steps.
        floatingActionButton: kDebugMode
            ? FloatingActionButton(
                onPressed: () => get.nextScreen(context),
                tooltip: 'Next Step (Debug)',
                child: const Icon(Icons.skip_next),
              )
            : null,
      ),
    );
  }

  /// A helper method to build the body of the scaffold.
  ///
  /// It returns the [screenWidget] if it's available. Otherwise, it displays
  /// a user-friendly error message indicating that the workflow step could
  /// not be loaded.
  Widget _buildBody(BuildContext context, Widget? screenWidget, String? currentStepKey) {
    if (screenWidget == null) {
      // Display an error screen if no widget is mapped to the current step key.
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
                "The step '$currentStepKey' could not be loaded. Please contact support.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Return the widget for the current step.
    return screenWidget;
  }
}
