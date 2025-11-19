import 'package:flutter/material.dart';

/// A utility function to parse a hexadecimal color string into a [Color] object.
///
/// It handles hex strings with or without a leading '#' and supports both
/// 6-digit (RGB) and 8-digit (ARGB) formats. If the input string is 6 digits,
/// it assumes full opacity (ff).
///
/// - [hexString]: The string containing the hex color code (e.g., "#RRGGBB" or "AARRGGBB").
/// - [fallback]: The [Color] to return if the [hexString] is null, empty, or invalid.
///
/// Returns the parsed [Color] or the [fallback] color on failure.
Color parseHexColor(String? hexString, {required Color fallback}) {
  // Return fallback immediately if the input is invalid.
  if (hexString == null || hexString.isEmpty) return fallback;
  try {
    final buffer = StringBuffer();

    // Prepend 'ff' for full opacity if the hex string is in RGB format.
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    // Append the hex value, removing the '#' if it exists.
    buffer.write(hexString.replaceFirst('#', ''));
    // Parse the resulting 8-digit hex string.
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    // Log the error and return the fallback color if parsing fails.
    debugPrint('Could not parse color: $hexString. Error: $e');
    return fallback;
  }
}

/// A safe utility function to parse a date string into a [DateTime] object.
///
/// Uses `DateTime.tryParse`, which returns `null` instead of throwing an
/// exception if the date string is in an invalid format.
///
/// - [dateString]: The string to be parsed.
///
/// Returns the parsed [DateTime] or `null` if the string is null, empty, or invalid.
DateTime? tryParseDateTime(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  return DateTime.tryParse(dateString);
}

/// A data model representing the overall design configuration for the SDK UI.
///
/// This class holds information fetched from the API, such as the logo URL and
/// a nested [Settings] object containing specific theme properties.
class DesignSettings {
  /// The unique identifier for the design setting record.
  final int? id;

  /// The ID of the verification template these settings are associated with.
  final int? templateId;

  /// The URL for the company's logo to be displayed in the UI.
  final String? logoUrl;

  /// A nested object containing detailed UI theme settings like colors and fonts.
  final Settings? settings;

  /// A flag indicating if this design setting is currently active (e.g., 1 for true, 0 for false).
  final int? isActive;

  /// The original file name of the uploaded logo, if applicable.
  final String? fileName;

  /// The creation timestamp of this design setting record.
  final DateTime? createdAt;

  /// The last update timestamp of this design setting record.
  final DateTime? updatedAt;

  /// Creates a [DesignSettings] instance.
  const DesignSettings({
    this.id,
    this.templateId,
    this.logoUrl,
    this.settings,
    this.isActive,
    this.fileName,
    this.createdAt,
    this.updatedAt,
  });

  /// A factory constructor to create a [DesignSettings] instance from a JSON map.
  ///
  /// This is typically used when decoding a response from an API. It performs
  /// type checking and safe parsing for all fields.
  factory DesignSettings.fromJson(Map<String, dynamic> json) {
    final templateDesignJson = json['templateDesign'] as Map<String, dynamic>;

    return DesignSettings(
      id: templateDesignJson['id'],
      templateId: templateDesignJson['template_id'],
      logoUrl: (templateDesignJson['logo'] is String && templateDesignJson['logo'].isNotEmpty) ? templateDesignJson['logo'] : null,
      settings: templateDesignJson['settings'] is Map<String, dynamic> ? Settings.fromJson(templateDesignJson['settings']) : null,
      isActive: templateDesignJson['is_active'],
      fileName: templateDesignJson['file_name'],
      createdAt: tryParseDateTime(templateDesignJson['created_at']),
      updatedAt: tryParseDateTime(templateDesignJson['updated_at']),
    );
  }
}

/// A data model for specific UI theme settings.
///
/// This class holds raw string values for theme properties like colors and fonts,
/// and provides convenient getters to parse them into usable types ([Color], [double])
/// with sensible fallback values.
class Settings {
  /// The font size as a string (e.g., "14px", "16").
  final String? fontSize;

  /// The font family name (e.g., "Roboto", "Arial").
  final String? fontFamily;

  /// A custom description or consent text to display on the home screen.
  final String? description;

  /// The primary color of the UI as a hex string (e.g., "#FFFFFF").
  final String? primaryColorHex;

  /// The main text color as a hex string.
  final String? textFontColorHex;

  /// The secondary/accent color as a hex string.
  final String? secondaryColorHex;

  /// The text color for buttons as a hex string.
  final String? buttonFontColorHex;

  /// Creates a [Settings] instance.
  const Settings({
    this.fontSize,
    this.fontFamily,
    this.description,
    this.primaryColorHex,
    this.textFontColorHex,
    this.secondaryColorHex,
    this.buttonFontColorHex,
  });

  /// Parses [primaryColorHex] into a [Color], with a blue fallback.
  Color get primaryColor => parseHexColor(primaryColorHex, fallback: Colors.blue);

  /// Parses [textFontColorHex] into a [Color], with a black fallback.
  Color get textColor => parseHexColor(textFontColorHex, fallback: Colors.black);

  /// Parses [secondaryColorHex] into a [Color], with a blue accent fallback.
  Color get secondaryColor => parseHexColor(secondaryColorHex, fallback: Colors.blueAccent);

  /// Parses [buttonFontColorHex] into a [Color], with a white fallback.
  Color get buttonTextColor => parseHexColor(buttonFontColorHex, fallback: Colors.white);

  /// A getter that safely parses the [fontSize] string into a [double].
  ///
  /// It removes non-numeric characters and returns a default value of 14.0 if
  /// parsing fails or the string is null.
  double get parsedFontSize {
    final size = fontSize?.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(size ?? '14.0') ?? 14.0;
  }

  /// A getter that returns the [fontFamily] or a default value ('Arial').
  String get effectiveFontFamily => (fontFamily?.isNotEmpty ?? false) ? fontFamily! : 'Arial';

  /// A getter that returns the custom [description] or a default legal consent text.
  String get effectiveDescription {
    return description ??
        "By clicking 'Start' I consent to Company and its service provider, IDMeta, obtaining and disclosing a scan of my face geometry and barcode of my ID for the purpose of verifying my identity...";
  }

  /// A factory constructor to create a [Settings] instance from a JSON map.
  ///
  /// Ensures all incoming values are converted to strings for consistent handling.
  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      fontSize: json['fontSize']?.toString(),
      fontFamily: json['fontFamily']?.toString(),
      description: json['description']?.toString(),
      primaryColorHex: json['primaryColor']?.toString(),
      textFontColorHex: json['textFontColor']?.toString(),
      secondaryColorHex: json['secondaryColor']?.toString(),
      buttonFontColorHex: json['buttonFontColor']?.toString(),
    );
  }
}
