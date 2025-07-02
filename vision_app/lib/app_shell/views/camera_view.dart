import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:vision_app/app_shell/app_shell.dart';
import 'package:vision_app/camera_module/camera_manager.dart';
import 'package:vision_app/ml_inference_module/ml_service.dart';
import 'package:vision_app/ui_overlay_module/overlay_painter.dart';
import 'package:vision_app/solution_object_counting/object_counting_service.dart';
// Removed unused solutions
import 'package:vision_app/solution_distance_calculation/distance_calculation_service.dart';
import 'package:vision_app/ui_overlay_module/drawing_painter.dart';

class CameraView extends StatefulWidget {
  final CameraManager cameraManager;
  final MLService mlService;
  final ObjectCountingService objectCountingService;
  final DistanceCalculationService distanceCalculationService;
  final SolutionMode currentMode;
  final Function(SolutionMode) onModeChanged;

  const CameraView({
    super.key,
    required this.cameraManager,
    required this.mlService,
    required this.objectCountingService,
    required this.distanceCalculationService,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  List<Offset> _points = [];
  bool _isCameraInitialized = false;
  bool _isModelLoaded = false;
  String? _errorMessage;
  Timer? _inferenceTimer;

  @override
  void initState() {
    super.initState();
    _initializeCameraAndML();
  }

  Future<void> _initializeCameraAndML() async {
    try {
      _isCameraInitialized = await widget.cameraManager.initialize();
      if (_isCameraInitialized) {
        _isModelLoaded = await widget.mlService.loadModel(useGpu: true);
        if (_isModelLoaded) {
          // Check if image streaming is supported
          if (widget.cameraManager.supportsImageStreaming) {
            widget.cameraManager.startImageStream((image) {
              if (widget.mlService.isModelLoaded) {
                _processFrame(image);
                setState(() {}); // Trigger rebuild to update overlay
              }
            });
          } else {
            // For web, use timer-based inference
            print('Using timer-based inference for web platform');
            _startWebInference();
          }
        } else {
          _errorMessage = 'Failed to load ML model';
        }
      } else {
        _errorMessage =
            'Failed to initialize camera. Please check permissions.';
      }
    } catch (e) {
      _errorMessage = 'Error during initialization: $e';
    }
    setState(() {}); // Update UI after initialization attempt
  }

  void _startWebInference() {
    if (kIsWeb) {
      _inferenceTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (widget.mlService.isModelLoaded) {
          _processWebFrame();
          setState(() {}); // Trigger rebuild to update overlay
        }
      });
    }
  }

  void _processFrame(CameraImage image) {
    switch (widget.currentMode) {
      case SolutionMode.objectCounting:
        final detections = widget.mlService.runObjectDetection(image);
        widget.objectCountingService.processDetections(detections);
        break;
      case SolutionMode.distanceCalculation:
        final detections = widget.mlService.runObjectDetection(image);
        widget.distanceCalculationService.processDetections(detections);
        break;
    }
  }

  void _processWebFrame() {
    switch (widget.currentMode) {
      case SolutionMode.objectCounting:
        final detections = widget.mlService.runObjectDetection(null);
        widget.objectCountingService.processDetections(detections);
        break;
      case SolutionMode.distanceCalculation:
        final detections = widget.mlService.runObjectDetection(null);
        widget.distanceCalculationService.processDetections(detections);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || !_isModelLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _errorMessage ??
                    (_isCameraInitialized
                        ? 'Loading ML model...'
                        : 'Initializing camera...'),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isCameraInitialized = false;
                      _isModelLoaded = false;
                    });
                    _initializeCameraAndML();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getSolutionTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: () async {
              await widget.cameraManager.switchCamera();
              setState(() {});
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Handle tap for distance calculation
          if (widget.currentMode == SolutionMode.distanceCalculation) {
            _handleTapForDistanceCalculation();
          }
        },
        onTapDown: (details) {
          // Store tap position for distance calculation
          if (widget.currentMode == SolutionMode.distanceCalculation) {
            setState(() {
              _points = [details.localPosition];
            });
          }
        },
        onSecondaryTap: () {
          // Right-click to clear selections in distance calculation
          if (widget.currentMode == SolutionMode.distanceCalculation) {
            widget.distanceCalculationService.clearSelections();
            setState(() {});
          }
        },
        onPanStart: (details) {
          if (widget.currentMode != SolutionMode.distanceCalculation) {
            setState(() {
              _points = [details.localPosition];
            });
          }
        },
        onPanUpdate: (details) {
          if (widget.currentMode != SolutionMode.distanceCalculation) {
            setState(() {
              _points.add(details.localPosition);
            });
          }
        },
        onPanEnd: (details) {
          if (widget.currentMode != SolutionMode.distanceCalculation) {
            _handleDrawingComplete();
            setState(() {
              _points = []; // Clear points after drawing
            });
          }
        },
        child: Stack(
          children: [
            CameraPreview(widget.cameraManager.controller!),
            _buildOverlay(),
            _buildDrawingLayer(),
          ],
        ),
      ),
    );
  }

  void _handleDrawingComplete() {
    switch (widget.currentMode) {
      case SolutionMode.objectCounting:
        if (_points.length >= 2) {
          widget.objectCountingService.setCountingLine([
            _points.first,
            _points.last,
          ]);
        }
        break;
      default:
        break;
    }
  }

  void _handleTapForDistanceCalculation() {
    if (_points.isNotEmpty) {
      widget.distanceCalculationService.selectObjectAt(_points.first);
      setState(() {
        _points = []; // Clear the tap position
      });
    }
  }

  Widget _buildOverlay() {
    switch (widget.currentMode) {
      case SolutionMode.objectCounting:
        return CustomPaint(
          painter: OverlayPainter(
            detectedObjects: widget.objectCountingService.getDetectedObjects(),
            countingLine: widget.objectCountingService.getCountingLine(),
            objectCount: widget.objectCountingService.getObjectCount(),
          ),
          child: Container(),
        );
      case SolutionMode.distanceCalculation:
        return CustomPaint(
          painter: DistanceCalculationOverlayPainter(
            detectedObjects: widget.distanceCalculationService.getDetectedObjects(),
            selectedObjects: widget.distanceCalculationService.getSelectedObjects(),
            distances: widget.distanceCalculationService.getDistances(),
            connectionLines: widget.distanceCalculationService.getConnectionLines(),
          ),
          child: Container(),
        );
    }
  }

  Widget _buildDrawingLayer() {
    return CustomPaint(
      painter: DrawingPainter(
        points: _points,
        isDrawing: _points.isNotEmpty,
        isPolygon: false, // Only object counting uses lines, not polygons
      ),
      child: Container(),
    );
  }

  String _getSolutionTitle() {
    switch (widget.currentMode) {
      case SolutionMode.objectCounting:
        return 'Object Counting';
      case SolutionMode.distanceCalculation:
        return 'Distance Calculation';
    }
  }

  @override
  void didUpdateWidget(CameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to mode changes
    if (oldWidget.currentMode != widget.currentMode) {
      // Mode changed, no need to restart everything, just update processing
      print('Solution mode changed to: ${widget.currentMode}');
    }
  }

  @override
  void dispose() {
    widget.cameraManager.stopImageStream();
    _inferenceTimer?.cancel();
    super.dispose();
  }
}
