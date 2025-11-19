import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'coordinates.dart';

/// A [CustomPainter] for rendering face detection results on a Flutter canvas.
///
/// This painter is designed to be used as an overlay on top of a camera preview.
/// It takes a list of detected [Face] objects and draws their bounding boxes,
/// contours (e.g., outlines of eyes, nose), and landmarks (e.g., corners of the mouth)
/// onto the canvas.
///
/// It relies on the [translateX] and [translateY] utility functions to correctly
/// convert coordinates from the camera's image space to the UI's canvas space,
/// accounting for rotation, scaling, and mirroring.
class FaceDetectorPainter extends CustomPainter {
  /// Creates a painter for the detected faces.
  FaceDetectorPainter(
    this.faces,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  /// The list of [Face] objects detected by the ML Kit face detector.
  final List<Face> faces;

  /// The absolute size of the image that was processed by the face detector.
  final Size imageSize;

  /// The rotation of the input image, needed for coordinate translation.
  final InputImageRotation rotation;

  /// The lens direction of the camera used, needed to handle mirroring correctly.
  final CameraLensDirection cameraLensDirection;

  /// The core painting method called by the Flutter framework.
  ///
  /// This method iterates through each detected [Face] and draws its features on the canvas.
  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the bounding box and contours (red strokes).
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.red;
    // Paint for the landmarks (green filled circles).
    final Paint paint2 = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = Colors.green;

    // Iterate through each face found in the image.
    for (final Face face in faces) {
      // Translate the coordinates of the bounding box from the image's coordinate
      // system to the canvas's coordinate system.
      final left = translateX(
        face.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      // Draw the bounding box rectangle on the canvas.
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint1,
      );

      /// A local helper function to paint a specific facial contour.
      void paintContour(FaceContourType type) {
        final contour = face.contours[type];
        if (contour?.points != null) {
          // For each point in the contour, translate its coordinates and draw a small circle.
          for (final Point point in contour!.points) {
            canvas.drawCircle(
                Offset(
                  translateX(
                    point.x.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                  translateY(
                    point.y.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                ),
                1, // Radius of the circle.
                paint1);
          }
        }
      }

      /// A local helper function to paint a specific facial landmark.
      void paintLandmark(FaceLandmarkType type) {
        final landmark = face.landmarks[type];
        if (landmark?.position != null) {
          // Translate the landmark's coordinates and draw a slightly larger circle.
          canvas.drawCircle(
              Offset(
                translateX(
                  landmark!.position.x.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  landmark.position.y.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              2, // Radius of the circle.
              paint2);
        }
      }

      // Iterate through all possible contour types and paint them.
      for (final type in FaceContourType.values) {
        paintContour(type);
      }

      // Iterate through all possible landmark types and paint them.
      for (final type in FaceLandmarkType.values) {
        paintLandmark(type);
      }
    }
  }

  /// Determines whether the painter should repaint the canvas.
  ///
  /// This is an important optimization. The painter should only repaint if the
  /// input data (the image size or the detected faces) has changed since the
  /// last paint call.
  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
  }
}
