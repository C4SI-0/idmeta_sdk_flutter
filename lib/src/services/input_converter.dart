import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Converts a [CameraImage] from the `camera` package to an [InputImage]
/// format suitable for Google ML Kit vision APIs.
///
/// This function is crucial for bridging the gap between the camera's raw
/// image stream and the format required by ML Kit for processing. It handles
/// platform-specific image formats and rotation calculations to ensure the
/// ML model receives correctly oriented images.
///
/// Parameters:
///   - [image]: The [CameraImage] object provided by the camera's image stream.
///   - [controller]: The active [CameraController] instance, used to get device orientation.
///   - [camera]: The [CameraDescription] of the currently active camera, used for sensor
///     orientation and lens direction.
///
/// Returns an [InputImage] if the conversion is successful, otherwise returns `null`.
/// The function may return `null` if the image format is unsupported, rotation cannot be
/// determined, or the image plane data is invalid.
InputImage? inputImageFromCameraImage(CameraImage image, CameraController controller, CameraDescription camera) {
  // A map to convert device orientation values to rotation degrees.
  // This is used for Android rotation compensation.
  final orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImageRotation? rotation;
  if (Platform.isIOS) {
    // On iOS, the sensor orientation is directly used to determine the rotation.
    rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  } else if (Platform.isAndroid) {
    // On Android, rotation is a combination of sensor orientation and the current
    // device orientation.
    var rotationCompensation = orientations[controller.value.deviceOrientation];
    if (rotationCompensation == null) return null; // Exit if orientation is unknown.

    if (camera.lensDirection == CameraLensDirection.front) {
      // For front-facing cameras, the logic is to add the sensor orientation
      // to the device's rotation compensation.
      rotationCompensation = (camera.sensorOrientation + rotationCompensation) % 360;
    } else {
      // back-facing camera
      // For back-facing cameras, the compensation is subtracted from the sensor orientation.
      rotationCompensation = (camera.sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
  }

  // If rotation could not be determined, we cannot proceed.
  if (rotation == null) return null;

  // Get the image format from the raw value of the CameraImage's format.
  final format = InputImageFormatValue.fromRawValue(image.format.raw);

  // Validate the image format. ML Kit on Android typically works best with NV21,
  // and on iOS with BGRA8888. If the format is null or not the expected one
  // for the platform, we cannot process the image.
  if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21) || (Platform.isIOS && format != InputImageFormat.bgra8888)) {
    return null;
  }

  // ML Kit's fromBytes constructor for NV21 and BGRA8888 formats expects
  // the data to be in a single plane.
  if (image.planes.length != 1) return null;
  final plane = image.planes.first;

  // If all checks pass, construct and return the InputImage.
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}
