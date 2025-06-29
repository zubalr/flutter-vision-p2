import 'package:flutter/material.dart';
import 'package:vision_app/app_shell/solutions/base_solution.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';
import 'package:vision_app/solution_security_alarm/security_alarm_service.dart';

class SecurityAlarmSolution implements BaseSolution {
  final SecurityAlarmService _service = SecurityAlarmService();

  @override
  String get id => 'security_alarm';

  @override
  String get name => 'Security Alarm';

  @override
  String get description => 'Monitor restricted zones and trigger alerts';

  @override
  IconData get icon => Icons.security;

  @override
  Color get color => Colors.red;

  @override
  bool get supportsDrawing => true;

  @override
  DrawingType get drawingType => DrawingType.polygon;

  @override
  void processDetections(List<DetectedObject> detections) {
    _service.processDetections(detections);
  }

  @override
  void processKeypoints(List<DetectedKeypoint> keypoints) {
    // Security alarm doesn't use keypoints
  }

  @override
  void handleDrawingComplete(List<Offset> points) {
    if (points.length >= 3) {
      _service.setZones([points]);
    }
  }

  @override
  void reset() {
    // Reset alarm state if needed
  }

  @override
  SolutionOverlayData getOverlayData() {
    return SecurityAlarmOverlayData(
      objects: [],
      keypoints: [],
      customData: {
        'zones': _service.getZones(),
        'alarmTriggered': _service.isAlarmTriggered(),
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
      'zonesCount': _service.getZones().length,
      'alarmTriggered': _service.isAlarmTriggered(),
    };
  }
}

class SecurityAlarmOverlayData extends SolutionOverlayData {
  @override
  final List<DetectedObject> objects;

  @override
  final List<DetectedKeypoint> keypoints;

  @override
  final Map<String, dynamic> customData;

  SecurityAlarmOverlayData({
    required this.objects,
    required this.keypoints,
    required this.customData,
  });
}
