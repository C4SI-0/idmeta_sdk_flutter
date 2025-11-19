import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// A utility function to translate a horizontal (X) coordinate from the coordinate system
/// of an ML Kit [InputImage] to the coordinate system of a Flutter UI canvas.
///
/// This is essential for accurately drawing overlays (like bounding boxes around faces)
/// on top of a `CameraPreview` widget. It accounts for differences in resolution,

/// rotation, and mirroring between the raw camera image and the displayed preview.
///
/// - [x]: The horizontal coordinate from the image analysis result (e.g., from a face bounding box).
/// - [canvasSize]: The `Size` of the canvas (e.g., the `CameraPreview` widget) on which you are drawing.
/// - [imageSize]: The `Size` of the raw `InputImage` that was processed by ML Kit.
/// - [rotation]: The rotation of the `InputImage`, which determines how the coordinate system is oriented.
/// - [cameraLensDirection]: The direction of the camera lens (front or back), which is used to handle mirroring for front cameras.
///
/// Returns the translated X coordinate scaled and adjusted for the UI canvas.
double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    // When the image is rotated 90 or 270 degrees, the image's width and height are swapped
    // relative to the canvas.
    case InputImageRotation.rotation90deg:
      // The image's height on Android or width on iOS corresponds to the canvas's width.
      return x * canvasSize.width / (Platform.isIOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation270deg:
      // The coordinate is inverted because the image is rotated in the opposite direction.
      return canvasSize.width - x * canvasSize.width / (Platform.isIOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      // When the image is not rotated sideways, the logic depends on the camera lens.
      switch (cameraLensDirection) {
        case CameraLensDirection.back:
          // For back cameras, the coordinate scales directly.
          return x * canvasSize.width / imageSize.width;
        default: // front camera
          // For front cameras, the image is mirrored, so the X coordinate is inverted.
          return canvasSize.width - x * canvasSize.width / imageSize.width;
      }
  }
}

/// A utility function to translate a vertical (Y) coordinate from the coordinate system
/// of an ML Kit [InputImage] to the coordinate system of a Flutter UI canvas.
///
/// This works in conjunction with [translateX] to correctly position overlays on a camera preview.
///
/// - [y]: The vertical coordinate from the image analysis result.
/// - [canvasSize]: The `Size` of the canvas on which you are drawing.
/// - [imageSize]: The `Size` of the raw `InputImage` that was processed.
/// - [rotation]: The rotation of the `InputImage`.
/// - [cameraLensDirection]: The direction of the camera lens (though it has less impact on the Y-axis).
///
/// Returns the translated Y coordinate scaled for the UI canvas.
double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    // When the image is rotated sideways, the image's height (or width on iOS) corresponds to the canvas's height.
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y * canvasSize.height / (Platform.isIOS ? imageSize.height : imageSize.width);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      // When not rotated sideways, the Y coordinate scales directly with the image and canvas heights.
      // Mirroring for front cameras does not affect the vertical axis.
      return y * canvasSize.height / imageSize.height;
  }
}
