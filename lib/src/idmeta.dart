import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'verification/verification.dart';
import 'screens/flow.dart';
import 'screens/home.dart';
import 'screens/success.dart';

/// The root widget for the Idmeta SDK's user interface.
///
/// This widget acts as a router, determining which screen to display based on the
/// current state of the verification process. It listens to the [Verification]
/// provider and rebuilds whenever the state changes.
///
/// It also wraps the entire UI in a dynamic [Theme] that can be customized
/// remotely via the design settings provided by the [Verification] provider.
class IdMeta extends StatelessWidget {
  /// Creates the root widget for the Idmeta UI.
  const IdMeta({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the Verification provider for state changes.
    // The widget will rebuild when any property of 'Verification' notifies its listeners.
    final get = context.watch<Verification>();

    // A placeholder for the screen that will be displayed.
    final Widget currentScreen;

    // Determine the current screen based on the verification flow state.
    if (get.isFlowCompleted) {
      // If the verification flow is marked as complete, show the success screen.
      currentScreen = const CompleteVerif();
    } else if (get.flowState.allSteps.isNotEmpty) {
      // If the verification flow has been initialized and steps are available, show the main flow screen.
      currentScreen = const FlowScreen();
    } else {
      // Otherwise, show the initial home/welcome screen.
      currentScreen = const HomePage();
    }

    // Apply a dynamically generated theme to the currently active screen.
    return Theme(
      data: _buildDynamicTheme(context, get),
      child: currentScreen,
    );
  }

  /// A private helper method to build a [ThemeData] object based on the
  /// design settings from the [Verification] provider.
  ///
  /// This allows for remote customization of the SDK's UI, including colors,
  /// fonts, and text sizes. It provides sensible default values if custom
  /// settings are not specified.
  ///
  /// The [context] is the build context.
  /// The [provider] is the instance of the [Verification] provider containing the design settings.
  ThemeData _buildDynamicTheme(BuildContext context, Verification provider) {
    // Safely access the design settings.
    final settings = provider.designSettings?.settings;

    // Determine colors and font properties, using default values if null.
    final primary = settings?.primaryColor ?? Colors.white;
    final secondary = settings?.secondaryColor ?? Colors.blue;
    final buttonFontColor = settings?.buttonTextColor ?? Colors.white;
    final textFontColor = settings?.textColor ?? Colors.black;
    final fontSize = settings?.parsedFontSize ?? 14.0;
    final fontFamily = settings?.effectiveFontFamily; // Uses system default if null

    // Construct and return the ThemeData object.
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: primary,
      fontFamily: fontFamily,
      textTheme: TextTheme(
        // Default text style for the body of the app.
        bodyMedium: TextStyle(
          fontSize: fontSize,
          color: textFontColor,
          fontFamily: fontFamily,
        ),
      ),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      // Define the color scheme for the application.
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: primary,
        background: primary,
        error: Colors.red,
        onPrimary: buttonFontColor, // Text/icon color on primary color
        onSecondary: buttonFontColor, // Text/icon color on secondary color
      ),
      // Define the default style for ElevatedButton widgets.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: buttonFontColor,
          textStyle: TextStyle(
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Define the default style for TextButton widgets.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: buttonFontColor,
          textStyle: TextStyle(
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Define the default style for OutlinedButton widgets.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: buttonFontColor,
          side: BorderSide.none, // No border for a filled look
          textStyle: TextStyle(
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Define the default style for Card widgets.
      cardTheme: CardTheme(
        color: primary,
        surfaceTintColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      // Define the default decoration for input fields (e.g., TextField).
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          color: textFontColor.withOpacity(0.7),
          fontSize: fontSize,
          fontFamily: fontFamily,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: secondary, width: 2.0),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        hintStyle: TextStyle(
          color: textFontColor.withOpacity(0.5),
          fontSize: fontSize,
          fontFamily: fontFamily,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
