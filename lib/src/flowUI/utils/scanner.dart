import 'package:flutter/material.dart';

/// A [CustomPainter] that draws a static scanner overlay with corner brackets.
///
/// This painter is designed to be used as a visual guide in a user interface,
/// such as for QR code scanning or document capture. It creates a frame-like
/// appearance by drawing short lines at the four corners of its bounding box.
///
/// Since the overlay is static and does not change, `shouldRepaint` is
/// hardcoded to return `false` for performance optimization.
class ScannerOverlayPainter extends CustomPainter {
  /// The main painting method that draws the corner brackets onto the canvas.
  ///
  /// - [canvas]: The canvas on which to draw.
  /// - [size]: The size of the area the canvas covers. The painter will use this
  ///   to position the corners at the edges of the available space.
  @override
  void paint(Canvas canvas, Size size) {
    // Define the appearance of the lines (white, 4 pixels thick, stroke).
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    /// The length of each line segment that forms the corner brackets.
    const double cornerLength = 30;

    // --- Draw Top-Left Corner ---
    // Horizontal line
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    // Vertical line
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // --- Draw Top-Right Corner ---
    // Horizontal line (from right edge inwards)
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    // Vertical line (from top edge downwards)
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // --- Draw Bottom-Left Corner ---
    // Horizontal line (from left edge inwards)
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    // Vertical line (from bottom edge upwards)
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // --- Draw Bottom-Right Corner ---
    // Horizontal line (from right edge inwards)
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    // Vertical line (from bottom edge upwards)
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  /// Determines whether the painter should repaint.
  ///
  /// This is set to `false` because the scanner overlay is a static graphic.
  /// Its appearance does not depend on any external state or animation,
  /// so it never needs to be redrawn. This is an important performance optimization.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
