import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:vision_app/app_shell/app_shell.dart';
import 'package:vision_app/camera_module/camera_manager.dart';
import 'package:vision_app/ml_inference_module/ml_service.dart';
import 'package:vision_app/ui_overlay_module/overlay_painter.dart';
import 'package:vision_app/solution_object_counting/object_counting_service.dart';
import 'package:vision_app/solution_workouts_monitoring/workouts_monitoring_service.dart';
import 'package:vision_app/solution_security_alarm/security_alarm_service.dart';
import 'package:vision_app/solution_distance_calculation/distance_calculation_service.dart';
import 'package:vision_app/ui_overlay_module/drawing_painter.dart';

class CameraView extends StatefulWidget {
  final CameraManager cameraManager;
  final MLService mlService;
  final ObjectCountingService objectCountingService;
  final WorkoutsMonitoringService workoutsMonitoringService;
  final SecurityAlarmService securityAlarmService;
  final DistanceCalculationService distanceCalculationService;
  final SolutionMode currentMode;
  final Function(SolutionMode) onModeChanged;

  const CameraView({
    super.key,
    required this.cameraManager,
    required this.mlService,
    required this.objectCountingService,
    required this.workoutsMonitoringService,
    required this.securityAlarmService,
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
  Timer? _mockDetectionTimer;

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
            // For web platform, start mock detection timer
            _startMockDetectionForWeb();
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

  void _startMockDetectionForWeb() {
    // For web platform, simulate detections periodically
    _mockDetectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (mounted && widget.mlService.isModelLoaded) {
        _processMockDetections();
        setState(() {}); // Trigger rebuild to update overlay
      }
    });
  }

  void _processMockDetections() {
    // For web platform, use the mock detection methods
    switch (widget.currentMode) {
      case SolutionMode.objectCounting:
        final mockDetections = widget.mlService.getMockObjectDetections();
        widget.objectCountingService.processDetections(mockDetections);
        break;
      case SolutionMode.workoutsMonitoring:
        final keypoints = widget.mlService.getMockKeypointDetections();
        widget.workoutsMonitoringService.processKeypoints(keypoints);
        break;
      case SolutionMode.securityAlarm:
        final mockDetections = widget.mlService.getMockObjectDetections();
        widget.securityAlarmService.processDetections(mockDetections);
        break;
      case SolutionMode.distanceCalculation:
        final mockDetections = widget.mlService.getMockObjectDetections();
        widget.distanceCalculationService.processDetections(mockDetections);
        break;
    }
  }

  void _processFrame(CameraImage image) {
    switch (widget.currentMode) {
      case SolutionMode.objectCounting:
        final detections = widget.mlService.runObjectDetection(image);
        widget.objectCountingService.processDetections(detections);
        break;
      case SolutionMode.workoutsMonitoring:
        final keypoints = widget.mlService.runKeypointDetection(image);
        widget.workoutsMonitoringService.processKeypoints(keypoints);
        break;
      case SolutionMode.securityAlarm:
        final detections = widget.mlService.runObjectDetection(image);
        widget.securityAlarmService.processDetections(detections);
        break;
      case SolutionMode.distanceCalculation:
        final detections = widget.mlService.runObjectDetection(image);
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
        onPanStart: (details) {
          setState(() {
            _points = [details.localPosition];
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _points.add(details.localPosition);
          });
        },
        onPanEnd: (details) {
          _handleDrawingComplete();
          setState(() {
            _points = []; // Clear points after drawing
          });
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
      case SolutionMode.securityAlarm:
        if (_points.length >= 3) {
          widget.securityAlarmService.setZones([_points]);
        }
        break;
      default:
        break;
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
      case SolutionMode.workoutsMonitoring:
        return CustomPaint(
          painter: OverlayPainter.forWorkouts(
            detectedKeypoints: widget.workoutsMonitoringService
                .getDetectedKeypoints(),
            repCount: widget.workoutsMonitoringService.getRepCount(),
          ),
          child: Container(),
        );
      case SolutionMode.securityAlarm:
        return CustomPaint(
          painter: OverlayPainter.forSecurityAlarm(
            detectedObjects: widget.securityAlarmService.getDetectedObjects(),
            zones: widget.securityAlarmService.getZones(),
            alarmTriggered: widget.securityAlarmService.isAlarmTriggered(),
          ),
          child: Container(),
        );
      case SolutionMode.distanceCalculation:
        return CustomPaint(
          painter: OverlayPainter.forDistanceCalculation(
            detectedObjects: widget.distanceCalculationService
                .getDetectedObjects(),
            distances: widget.distanceCalculationService.getDistances(),
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
        isPolygon: widget.currentMode == SolutionMode.securityAlarm,
      ),
      child: Container(),
    );
  }

  String _getSolutionTitle() {
    switch (widget.currentMode) {
      case SolutionMode.objectCounting:
        return 'Object Counting';
      case SolutionMode.workoutsMonitoring:
        return 'Workouts Monitoring';
      case SolutionMode.securityAlarm:
        return 'Security Alarm';
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
    _mockDetectionTimer?.cancel();
    widget.cameraManager.stopImageStream();
    super.dispose();
  }
}
