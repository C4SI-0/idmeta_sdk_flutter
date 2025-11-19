import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/service.dart';
import '../verification/verification.dart';

/// A sophisticated camera widget for biometric verification.
///
/// This widget provides a live camera feed, integrates with [FaceCameraService]
/// for real-time face detection, and guides the user to position their face
/// correctly. It features an automatic capture mechanism that triggers when the
/// user's face is stable and properly framed.
class BiometricCameraView extends StatefulWidget {
  /// A callback function that is invoked when a picture is successfully captured.
  /// It provides the captured image as an [XFile].
  final Function(XFile image) onPictureCaptured;

  /// An optional callback that is invoked if the picture capture process fails.
  final VoidCallback? onCaptureFailed;

  /// An optional fixed height for the camera view widget.
  final double? height;

  /// Creates a [BiometricCameraView] widget.
  const BiometricCameraView({
    super.key,
    required this.onPictureCaptured,
    this.onCaptureFailed,
    this.height,
  });

  @override
  BiometricCameraViewState createState() => BiometricCameraViewState();
}

/// The state management class for the [BiometricCameraView].
///
/// It handles the camera lifecycle, state updates from the [FaceCameraService],
/// and user interactions. It also observes the application's lifecycle to
/// pause and resume the camera appropriately.
class BiometricCameraViewState extends State<BiometricCameraView> with WidgetsBindingObserver {
  /// The core service that manages camera operations and face detection.
  final _cameraService = FaceCameraService();

  /// A list to hold stream subscriptions, allowing them to be easily cancelled on dispose.
  List<StreamSubscription>? _subscriptions;

  // --- UI State Flags ---
  /// `true` when the camera has been successfully initialized and is ready to preview.
  bool _isCameraInitialized = false;

  /// `true` during the auto-capture process to prevent further interactions.
  bool _isCapturing = false;

  /// `true` while the camera is switching between front and back lenses.
  bool _isSwitchingCamera = false;

  // --- UI Data ---
  /// The instructional text displayed to the user (e.g., "Move closer").
  String _instructionText = '';

  /// An error message to be displayed if camera initialization fails.
  String? _errorText;

  /// A custom painter for drawing overlays on the camera preview (e.g., a box around the face).
  CustomPaint? _customPaint;

  /// Holds the current properties of the camera, such as zoom and exposure ranges.
  CameraPropertiesState? _cameraProps;

  /// A computed property to determine if user interaction should be disabled.
  bool get _isInteractionDisabled => _isCapturing || _isSwitchingCamera || context.read<Verification>().isLoading;

  @override
  void initState() {
    super.initState();
    // Listen to app lifecycle events (e.g., pause, resume).
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    // Clean up resources to prevent memory leaks.
    WidgetsBinding.instance.removeObserver(this);
    _subscriptions?.forEach((s) => s.cancel());
    _cameraService.dispose();
    super.dispose();
  }

  /// Handles app lifecycle changes to pause or resume the camera stream.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _cameraService.isDisposed) return;
    if (state == AppLifecycleState.resumed) {
      // Resume the camera's image stream when the app comes back to the foreground.
      _cameraService.resume();
    } else {
      // Pause the camera's image stream when the app is in the background.
      _cameraService.pause();
    }
  }

  /// Public method to resume the camera feed after a capture or failure.
  Future<void> resumeCamera() async {
    if (mounted) {
      setState(() => _isCapturing = false);
      await _cameraService.resume();
    }
  }

  /// Initializes the camera service and sets up stream listeners.
  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        _errorText = null;
      });
    }
    // Set up listeners for the various streams from the camera service.
    _subscriptions ??= [
      _cameraService.faceDetectionStream.listen(_onFaceDetectionStateChanged),
      _cameraService.propertiesStream.listen((props) => setState(() => _cameraProps = props)),
      _cameraService.errorStream.listen((error) => setState(() => _errorText = error)),
      _cameraService.isSwitchingStream.listen((isSwitching) {
        if (mounted) setState(() => _isSwitchingCamera = isSwitching);
      }),
    ];
    // Start the camera service, preferring the front camera.
    await _cameraService.initialize(CameraLensDirection.front);
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  /// Callback for the face detection stream. Updates UI based on detection status.
  void _onFaceDetectionStateChanged(FaceDetectionState state) {
    if (!mounted || _isInteractionDisabled) return;
    setState(() {
      _customPaint = state.customPaint;
      switch (state.status) {
        case FaceDetectionStatus.noFaceDetected:
          _instructionText = 'Align your face in the frame';
          break;
        case FaceDetectionStatus.faceTooSmall:
          _instructionText = 'Move closer';
          break;
        case FaceDetectionStatus.holdStill:
          _instructionText = 'Hold still...';
          break;
        case FaceDetectionStatus.captureReady:
          _instructionText = 'Perfect!';
          _autoCapture(); // Trigger capture when the face is ready.
          break;
      }
    });
  }

  /// Handles the automatic picture-taking process.
  Future<void> _autoCapture() async {
    if (_isCapturing) return; // Prevent multiple captures.
    setState(() => _isCapturing = true);

    final image = await _cameraService.takePicture();

    if (image != null && mounted) {
      setState(() => _isCapturing = false);
      widget.onPictureCaptured(image);
    } else if (mounted) {
      widget.onCaptureFailed?.call();
      await resumeCamera(); // Resume camera on failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Error State ---
    if (_errorText != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Error: $_errorText', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _initialize, child: const Text('Try Again')),
        ]),
      );
    }
    // --- Loading State ---
    if (!_isCameraInitialized || _isSwitchingCamera) {
      return const Center(child: CircularProgressIndicator());
    }
    // --- Camera View State ---
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          // Layer 1: The live camera preview.
          CameraPreview(_cameraService.cameraController!),
          // Layer 2: The face detection overlay (e.g., bounding box).
          if (_customPaint != null) _customPaint!,
          // Layer 3: The user interface overlay (instructions, buttons).
          _buildUIOverlay(),
          // Layer 4: A loading indicator shown during capture.
          if (_isCapturing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ]),
      ),
    );
  }

  /// Builds the UI controls and informational text that are layered on top of the camera preview.
  Widget _buildUIOverlay() {
    return Stack(
      children: [
        // Top-center instruction text.
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: Text(_instructionText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        // Camera switch button (top-left), only shown if multiple cameras are available.
        if (_cameraService.canSwitchCameras)
          Positioned(
            top: 10,
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
              onPressed: _isInteractionDisabled ? null : _cameraService.switchCamera,
            ),
          ),
        // Zoom slider (bottom-center), only shown after camera properties are loaded.
        if (_cameraProps != null)
          Positioned(
            bottom: 0,
            left: 20,
            right: 20,
            child: Slider(
              value: _cameraProps!.currentZoom,
              min: _cameraProps!.minZoom,
              max: _cameraProps!.maxZoom,
              activeColor: Colors.white,
              inactiveColor: Colors.white30,
              onChanged: _isInteractionDisabled ? null : _cameraService.setZoomLevel,
            ),
          ),
      ],
    );
  }
}
