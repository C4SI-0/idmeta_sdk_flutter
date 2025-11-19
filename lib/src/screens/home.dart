import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../verification/verification.dart';

/// The initial screen of the verification flow.
///
/// This widget serves as the landing page for the SDK. It displays branding (logo),
/// introductory information, a description of the process, and a "Start" button
/// to begin the verification. It handles the initial loading state while fetching
/// the verification flow configuration from the server.
class HomePage extends StatefulWidget {
  /// Creates the [HomePage] widget.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// The state class for the [HomePage] widget.
class _HomePageState extends State<HomePage> {
  /// A scroll controller for the description text box to ensure the scrollbar is manageable.
  final ScrollController scrollController = ScrollController();

  /// Displays a confirmation dialog to the user before exiting the verification flow.
  ///
  /// This is triggered by the system back button via [WillPopScope].
  ///
  /// Returns `true` if the user confirms they want to exit, otherwise `false`.
  Future<bool> _showExitConfirmationDialog() async {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit'),
        content: const Text('Are you sure you want to leave the verification process?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Exit'),
          ),
        ],
      ),
    );
    // Default to false if the dialog is dismissed without a choice.
    return shouldPop ?? false;
  }

  /// Initiates the verification flow by calling the provider.
  ///
  /// This method is called when the user taps the "Start" button.
  /// It handles the API call and displays an error message via a [SnackBar]
  /// if the flow fails to start.
  Future<void> _startFlow() async {
    // Use `context.read` as we are calling a method, not listening for changes.
    final get = context.read<Verification>();
    final success = await get.startVerificationFlow();
    // Check if the widget is still in the tree before updating the UI.
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Failed to start verification flow.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the Verification provider to rebuild when state updates.
    final get = context.watch<Verification>();
    final settings = get.designSettings?.settings;
    final isStartingFlow = get.isStartingFlow;
    final String paragraph = settings?.effectiveDescription ?? "Loading description...";
    final logoUrl = get.designSettings?.logoUrl;
    final theme = Theme.of(context);

    // Define the button style based on dynamic settings or theme defaults.
    final buttonStyle = TextButton.styleFrom(
      backgroundColor: settings?.secondaryColor ?? theme.colorScheme.secondary,
      foregroundColor: settings?.buttonTextColor ?? theme.colorScheme.onSecondary,
      textStyle: TextStyle(
        fontFamily: settings?.effectiveFontFamily,
        fontSize: settings?.parsedFontSize ?? 14,
        fontWeight: FontWeight.bold,
      ),
      minimumSize: const Size.fromHeight(50),
    );

    // Intercept back button presses to show a confirmation dialog.
    return WillPopScope(
      onWillPop: _showExitConfirmationDialog,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: true,
            // Display a shimmer effect while loading the logo and settings.
            title: get.isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(height: 50, width: 120, color: Colors.white),
                  )
                : logoUrl != null
                    // Attempt to load the logo from the network.
                    ? Image.network(logoUrl, height: 50, errorBuilder: (_, __, ___) => const _DefaultLogo())
                    // Show a default logo if the URL is null or fails to load.
                    : const _DefaultLogo(),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informational rows explaining the process.
            const _InfoRow(
              icon: Icons.assignment,
              text: 'Submit the required details and upload any necessary documents or images.',
            ),
            const _InfoRow(
              icon: Icons.cloud_upload,
              text: 'Please fill in the required details and provide any necessary documents or photos.',
            ),
            // A container for the descriptive text about the verification process.
            SizedBox(
              height: 200,
              child: Container(
                margin: const EdgeInsets.all(15.0),
                padding: const EdgeInsets.all(3.0),
                // Show a shimmer effect while the description is loading.
                child: get.isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                              8,
                              (i) => Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    height: 16,
                                    width: i % 3 == 2 ? 150 : double.infinity,
                                    color: Colors.white,
                                  )),
                        ),
                      )
                    // Once loaded, display the scrollable description text.
                    : Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(8.0),
                          child: Text(paragraph),
                        ),
                      ),
              ),
            ),
            // The main action button to start the verification flow.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                style: buttonStyle,
                // Disable the button while the flow is being initiated.
                onPressed: isStartingFlow ? null : _startFlow,
                // Show a loading indicator inside the button when starting the flow.
                child: isStartingFlow
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(
                        'Start',
                        style: TextStyle(fontSize: settings?.parsedFontSize ?? 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A private widget to display a default logo.
///
/// This is used as a fallback if the remote logo URL from the design settings
/// is not provided or fails to load.
class _DefaultLogo extends StatelessWidget {
  /// Creates the default logo widget.
  const _DefaultLogo();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Assumes a logo asset is included in the package.
        Image.asset('assets/logo.png', package: 'idmeta_sdk_flutter', height: 37),
        const SizedBox(width: 12),
        const Text('IDMeta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
      ],
    );
  }
}

/// A private reusable widget for displaying a row with an icon and text.
///
/// Used on the [HomePage] to provide users with key information about the process.
class _InfoRow extends StatelessWidget {
  /// The icon to display on the left.
  final IconData icon;

  /// The text to display on the right.
  final String text;

  /// Creates an information row.
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
