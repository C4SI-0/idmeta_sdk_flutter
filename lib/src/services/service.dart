import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../flowUI/utils/detector.dart';
import 'input_converter.dart';

/// Represents the real-time status of face detection from the camera stream.
enum FaceDetectionStatus {
  /// No face was detected in the camera frame.
  noFaceDetected,

  /// A face was detected, but it is too far from the camera.
  faceTooSmall,

  /// A face is in a good position, but the user needs to hold still.
  holdStill,

  /// The user's face is correctly positioned and stable, ready for capture.
  captureReady
}

/// A state object that holds the current face detection status and an optional painter for UI overlays.
class FaceDetectionState {
  /// The current status of the face detection process.
  final FaceDetectionStatus status;

  /// A [CustomPaint] widget that can be used to draw an overlay over the camera preview,
  /// for example, to draw an outline around the detected face.
  final CustomPaint? customPaint;

  /// Creates a new [FaceDetectionState].
  FaceDetectionState(this.status, {this.customPaint});
}

/// A state object that holds the current properties and capabilities of the camera.
class CameraPropertiesState {
  /// The current zoom level of the camera.
  final double currentZoom;

  /// The minimum supported zoom level.
  final double minZoom;

  /// The maximum supported zoom level.
  final double maxZoom;

  /// The current exposure offset of the camera.
  final double currentExposure;

  /// The minimum supported exposure offset.
  final double minExposure;

  /// The maximum supported exposure offset.
  final double maxExposure;

  /// Creates a new [CameraPropertiesState].
  CameraPropertiesState({
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.currentExposure,
    required this.minExposure,
    required this.maxExposure,
  });
}

/// A comprehensive service to manage the camera, perform face detection,
/// and stream state updates to the UI.
///
/// This service encapsulates the logic for:
/// - Initializing and controlling the device camera.
/// - Processing the live camera image stream.
/// - Using Google ML Kit to detect faces in real-time.
/// - Analyzing detected faces for stability, position, and size.
/// - Providing streams of data ([FaceDetectionState], [CameraPropertiesState], errors)
///   for the UI to listen to and react accordingly.
class FaceCameraService {
  /// The underlying controller for the camera hardware.
  CameraController? _controller;

  /// Public accessor for the camera controller.
  CameraController? get cameraController => _controller;

  /// A list of available cameras on the device.
  List<CameraDescription> _cameras = [];

  /// The index of the currently active camera in the [_cameras] list.
  int _cameraIndex = -1;

  /// The ML Kit face detector instance.
  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions(enableLandmarks: true));

  /// A flag to prevent processing multiple images simultaneously.
  bool _isProcessingImage = false;

  /// A flag to enable or disable the image processing stream.
  bool _canProcess = true;

  /// A flag to prevent multiple camera switch operations at the same time.
  bool _isSwitchingCamera = false;

  // Camera properties state
  double _currentZoom = 1.0;
  double _currentExposure = 0.0;

  // Face stability and size detection parameters
  Rect? _lastFaceRect;
  int _stableFrameCount = 0;
  final int _requiredStableFrames = 10; // Number of consecutive frames the face must be stable for.
  final double _allowedMovement = 15.0; // Max allowed pixel distance for the face center between frames.
  final double _minFaceArea = 15000.0; // Minimum required area (width * height) for the face bounding box.

  /// Controller for broadcasting [FaceDetectionState] updates.
  final StreamController<FaceDetectionState> _faceDetectionController = StreamController.broadcast();

  /// A stream of [FaceDetectionState] providing real-time updates on face detection.
  Stream<FaceDetectionState> get faceDetectionStream => _faceDetectionController.stream;

  /// Controller for broadcasting [CameraPropertiesState] updates.
  final StreamController<CameraPropertiesState> _propertiesController = StreamController.broadcast();

  /// A stream of [CameraPropertiesState] providing updates on camera zoom and exposure capabilities.
  Stream<CameraPropertiesState> get propertiesStream => _propertiesController.stream;

  /// Controller for broadcasting error messages.
  final StreamController<String> _errorController = StreamController.broadcast();

  /// A stream of error messages that occur during camera initialization or operation.
  Stream<String> get errorStream => _errorController.stream;

  /// Controller for broadcasting the camera switching state.
  final StreamController<bool> _isSwitchingController = StreamController.broadcast();

  /// A stream that emits `true` when the camera is in the process of switching, and `false` when it's done.
  Stream<bool> get isSwitchingStream => _isSwitchingController.stream;

  /// Returns `true` if the device has more than one camera (e.g., front and back).
  bool get canSwitchCameras => _cameras.length > 1;

  /// A flag indicating if the service has been disposed.
  bool _isDisposed = false;

  /// Public accessor for the disposed state.
  bool get isDisposed => _isDisposed;

  /// Initializes the camera service.
  ///
  /// Finds available cameras, selects the one matching the [initialDirection],
  /// and starts the live feed and face detection.
  Future<void> initialize(CameraLensDirection initialDirection) async {
    if (_isDisposed) return;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception("No cameras found on this device.");

      // Find the camera with the desired lens direction.
      _cameraIndex = _cameras.indexWhere((cam) => cam.lensDirection == initialDirection);
      // Default to the first camera if the desired one isn't found.
      if (_cameraIndex == -1) _cameraIndex = 0;

      await _startLiveFeed();
    } catch (e) {
      debugPrint("FaceCameraService Initialization Error: $e");
      if (!_errorController.isClosed) _errorController.add(e.toString());
    }
  }

  /// Sets up the [CameraController] and starts the image stream.
  Future<void> _startLiveFeed() async {
    if (_isDisposed || _cameraIndex == -1) return;

    // Dispose the old controller if it exists.
    final oldController = _controller;
    if (oldController != null) {
      await oldController.stopImageStream().catchError((_) {});
      await oldController.dispose();
    }

    final camera = _cameras[_cameraIndex];

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      debugPrint("Error initializing camera controller: $e");
      if (!_errorController.isClosed) _errorController.add("Failed to initialize camera.");
      return;
    }

    // Reset camera properties and stability checks.
    _currentZoom = 1.0;
    _currentExposure = 0.0;
    await _updateAndBroadcastProperties();

    _canProcess = true;
    _stableFrameCount = 0;
    _lastFaceRect = null;

    // Start streaming images from the camera to our processing function.
    await _controller!.startImageStream(_processCameraImage);
  }

  /// Processes each [CameraImage] from the stream.
  void _processCameraImage(CameraImage image) {
    if (_isDisposed || !_canProcess || _isProcessingImage) return;
    _isProcessingImage = true;

    final inputImage = inputImageFromCameraImage(image, _controller!, _cameras[_cameraIndex]);
    if (inputImage == null) {
      _isProcessingImage = false;
      return;
    }

    _faceDetector.processImage(inputImage).then((faces) {
      _handleFaceDetectionResult(faces, inputImage);
      _isProcessingImage = false;
    }).catchError((_) {
      _isProcessingImage = false;
    });
  }

  /// Analyzes the face detection results and updates the [faceDetectionStream].
  void _handleFaceDetectionResult(List<Face> faces, InputImage inputImage) {
    if (_isDisposed) return;

    FaceDetectionStatus currentStatus = FaceDetectionStatus.noFaceDetected;

    if (faces.isNotEmpty) {
      final face = faces.first;
      final currentRect = face.boundingBox;

      // Check for stability by comparing the face's position to the last frame.
      if (_lastFaceRect != null && (currentRect.center - _lastFaceRect!.center).distance < _allowedMovement) {
        _stableFrameCount++;
      } else {
        _stableFrameCount = 0; // Reset if movement is too large.
      }
      _lastFaceRect = currentRect;

      // Check if the face is large enough.
      if ((currentRect.width * currentRect.height) < _minFaceArea) {
        currentStatus = FaceDetectionStatus.faceTooSmall;
        _stableFrameCount = 0; // Reset stability if face is too small.
      } else if (_stableFrameCount < _requiredStableFrames) {
        currentStatus = FaceDetectionStatus.holdStill;
      } else {
        currentStatus = FaceDetectionStatus.captureReady;
      }
    } else {
      // If no face is detected, reset stability checks.
      _stableFrameCount = 0;
      _lastFaceRect = null;
    }

    // Create a painter to draw an overlay (e.g., a box around the face).
    final painter = FaceDetectorPainter(
      faces,
      inputImage.metadata!.size,
      inputImage.metadata!.rotation,
      _cameras[_cameraIndex].lensDirection,
    );

    if (!_faceDetectionController.isClosed) {
      _faceDetectionController.add(FaceDetectionState(currentStatus, customPaint: CustomPaint(painter: painter)));
    }
  }

  /// Fetches camera properties (zoom/exposure ranges) and broadcasts them.
  Future<void> _updateAndBroadcastProperties() async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;

    try {
      final props = await Future.wait([
        _controller!.getMinZoomLevel(),
        _controller!.getMaxZoomLevel(),
        _controller!.getMinExposureOffset(),
        _controller!.getMaxExposureOffset(),
      ]);

      if (!_propertiesController.isClosed) {
        _propertiesController.add(CameraPropertiesState(
          minZoom: props[0],
          maxZoom: props[1],
          minExposure: props[2],
          maxExposure: props[3],
          currentZoom: _currentZoom,
          currentExposure: _currentExposure,
        ));
      }
    } catch (e) {
      debugPrint("Could not update camera properties: $e");
    }
  }

  /// Captures a still image.
  ///
  /// Stops the image stream, pauses the preview, and takes a picture.
  /// Returns the captured image as an [XFile], or null if capture fails.
  Future<XFile?> takePicture() async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      return null;
    }
    _canProcess = false;
    await _controller!.pausePreview();
    await _controller!.stopImageStream();
    return await _controller!.takePicture();
  }

  /// Switches to the next available camera (e.g., from front to back).
  Future<void> switchCamera() async {
    if (_isDisposed || !canSwitchCameras || _isSwitchingCamera) return;

    _isSwitchingCamera = true;
    if (!_isSwitchingController.isClosed) _isSwitchingController.add(true);

    try {
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      await _startLiveFeed();
    } catch (e) {
      debugPrint("Error switching camera: $e");
      if (!_errorController.isClosed) _errorController.add(e.toString());
    } finally {
      _isSwitchingCamera = false;
      if (!_isSwitchingController.isClosed) _isSwitchingController.add(false);
    }
  }

  /// Sets the camera's zoom level.
  Future<void> setZoomLevel(double zoom) async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;
    _currentZoom = zoom;
    await _controller!.setZoomLevel(zoom);
    await _updateAndBroadcastProperties();
  }

  /// Sets the camera's exposure offset.
  Future<void> setExposureOffset(double exposure) async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;
    _currentExposure = exposure;
    await _controller!.setExposureOffset(exposure);
    await _updateAndBroadcastProperties();
  }

  /// Pauses the image stream processing. The camera preview remains active.
  Future<void> pause() async {
    if (_isDisposed || _controller == null || !_controller!.value.isStreamingImages) return;
    _canProcess = false;
    await _controller!.stopImageStream();
  }

  /// Resumes the image stream processing.
  Future<void> resume() async {
    if (_isDisposed || _controller == null || _controller!.value.isStreamingImages) return;
    _canProcess = true;
    await _controller!.startImageStream(_processCameraImage);
  }

  /// Disposes all resources used by the service.
  ///
  /// This should be called when the service is no longer needed to release
  /// the camera and close all stream controllers.
  void dispose() {
    _isDisposed = true;
    _canProcess = false;
    _controller?.dispose();
    _faceDetector.close();
    _faceDetectionController.close();
    _propertiesController.close();
    _errorController.close();
    _isSwitchingController.close();
  }
}
