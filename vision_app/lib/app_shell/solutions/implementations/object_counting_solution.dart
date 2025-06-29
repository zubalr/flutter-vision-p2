import 'package:flutter/material.dart';
import 'package:vision_app/app_shell/solutions/base_solution.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';
import 'package:vision_app/solution_object_counting/object_counting_service.dart';

class ObjectCountingSolution implements BaseSolution {
  final ObjectCountingService _service = ObjectCountingService();

  @override
  String get id => 'object_counting';

  @override
  String get name => 'Object Counting';

  @override
  String get description => 'Count objects crossing a line in real-time';

  @override
  IconData get icon => Icons.trending_up;

  @override
  Color get color => Colors.blue;

  @override
  bool get supportsDrawing => true;

  @override
  DrawingType get drawingType => DrawingType.line;

  @override
  void processDetections(List<DetectedObject> detections) {
    _service.processDetections(detections);
  }

  @override
  void processKeypoints(List<DetectedKeypoint> keypoints) {
    // Object counting doesn't use keypoints
  }

  @override
  void handleDrawingComplete(List<Offset> points) {
    if (points.length >= 2) {
      _service.setCountingLine([points.first, points.last]);
    }
  }

  @override
  void reset() {
    // Reset counting state if needed
  }

  @override
  SolutionOverlayData getOverlayData() {
    return ObjectCountingOverlayData(
      objects: _service.getDetectedObjects(),
      keypoints: [],
      customData: {
        'countingLine': _service.getCountingLine(),
        'objectCount': _service.getObjectCount(),
      },
    );
  }

  @override
  void initialize(Map<String, dynamic> settings) {
    // Initialize with settings if needed
  }

  @override
  Map<String, dynamic> getMetrics() {
    return {
      'objectCount': _service.getObjectCount(),
      'detectedObjects': _service.getDetectedObjects().length,
    };
  }
}

class ObjectCountingOverlayData extends SolutionOverlayData {
  @override
  final List<DetectedObject> objects;

  @override
  final List<DetectedKeypoint> keypoints;

  @override
  final Map<String, dynamic> customData;

  ObjectCountingOverlayData({
    required this.objects,
    required this.keypoints,
    required this.customData,
  });
}
