import 'package:flutter/material.dart';
import 'package:vision_app/app_shell/solutions/base_solution.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';
import 'package:vision_app/solution_workouts_monitoring/workouts_monitoring_service.dart';

class WorkoutsMonitoringSolution implements BaseSolution {
  final WorkoutsMonitoringService _service = WorkoutsMonitoringService();

  @override
  String get id => 'workouts_monitoring';

  @override
  String get name => 'Workouts Monitoring';

  @override
  String get description => 'Track exercise repetitions and form';

  @override
  IconData get icon => Icons.fitness_center;

  @override
  Color get color => Colors.green;

  @override
  bool get supportsDrawing => false;

  @override
  DrawingType get drawingType => DrawingType.none;

  @override
  void processDetections(List<DetectedObject> detections) {
    // Workouts monitoring uses keypoints, not object detections
  }

  @override
  void processKeypoints(List<DetectedKeypoint> keypoints) {
    _service.processKeypoints(keypoints);
  }

  @override
  void handleDrawingComplete(List<Offset> points) {
    // No drawing interaction needed
  }

  @override
  void reset() {
    // Reset workout state if needed
  }

  @override
  SolutionOverlayData getOverlayData() {
    return WorkoutsMonitoringOverlayData(
      objects: [],
      keypoints: _service.getDetectedKeypoints(),
      customData: {'repCount': _service.getRepCount()},
    );
  }

  @override
  void initialize(Map<String, dynamic> settings) {
    // Initialize with settings if needed
  }

  @override
  Map<String, dynamic> getMetrics() {
    return {
      'repCount': _service.getRepCount(),
      'detectedKeypoints': _service.getDetectedKeypoints().length,
    };
  }
}

class WorkoutsMonitoringOverlayData extends SolutionOverlayData {
  @override
  final List<DetectedObject> objects;

  @override
  final List<DetectedKeypoint> keypoints;

  @override
  final Map<String, dynamic> customData;

  WorkoutsMonitoringOverlayData({
    required this.objects,
    required this.keypoints,
    required this.customData,
  });
}
