import 'package:flutter/material.dart';
import 'package:vision_app/app_shell/solutions/base_solution.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';
import 'package:vision_app/solution_distance_calculation/distance_calculation_service.dart';

class DistanceCalculationSolution implements BaseSolution {
  final DistanceCalculationService _service = DistanceCalculationService();

  @override
  String get id => 'distance_calculation';

  @override
  String get name => 'Distance Calculation';

  @override
  String get description => 'Measure distances between objects';

  @override
  IconData get icon => Icons.straighten;

  @override
  Color get color => Colors.orange;

  @override
  bool get supportsDrawing => true;

  @override
  DrawingType get drawingType => DrawingType.tap;

  @override
  void processDetections(List<DetectedObject> detections) {
    _service.processDetections(detections);
  }

  @override
  void processKeypoints(List<DetectedKeypoint> keypoints) {
    // Distance calculation doesn't use keypoints
  }

  @override
  void handleDrawingComplete(List<Offset> points) {
    // Handle tap interactions for object selection
    if (points.isNotEmpty) {
      _service.selectObjectAt(points.first);
    }
  }

  @override
  void reset() {
    _service.clearSelections();
  }

  @override
  SolutionOverlayData getOverlayData() {
    return DistanceCalculationOverlayData(
      objects: _service.getDetectedObjects(),
      keypoints: [],
      customData: {
        'distances': _service.getDistances(),
        'selectedObjects': _service.getSelectedObjects(),
        'connectionLines': _service.getConnectionLines(),
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
      'detectedObjects': _service.getDetectedObjects().length,
      'calculatedDistances': _service.getDistances().length,
    };
  }
}

class DistanceCalculationOverlayData extends SolutionOverlayData {
  @override
  final List<DetectedObject> objects;

  @override
  final List<DetectedKeypoint> keypoints;

  @override
  final Map<String, dynamic> customData;

  DistanceCalculationOverlayData({
    required this.objects,
    required this.keypoints,
    required this.customData,
  });
}
