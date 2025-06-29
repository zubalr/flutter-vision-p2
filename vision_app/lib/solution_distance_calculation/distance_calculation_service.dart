import 'package:flutter/material.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'dart:math';

class DistanceCalculationService {
  List<DetectedObject> _detectedObjects = [];
  final Map<String, double> _distances = {};

  void processDetections(List<DetectedObject> detections) {
    _detectedObjects = detections;
    _calculateDistances();
  }

  Map<String, double> getDistances() {
    return _distances;
  }

  List<DetectedObject> getDetectedObjects() {
    return _detectedObjects;
  }

  void _calculateDistances() {
    _distances.clear();
    if (_detectedObjects.length < 2) return;

    for (int i = 0; i < _detectedObjects.length; i++) {
      for (int j = i + 1; j < _detectedObjects.length; j++) {
        final obj1 = _detectedObjects[i];
        final obj2 = _detectedObjects[j];

        final center1 = obj1.boundingBox.center;
        final center2 = obj2.boundingBox.center;

        final distance = _euclideanDistance(center1, center2);
        _distances['${obj1.label}_${i}_to_${obj2.label}_$j'] = distance;
      }
    }
  }

  double _euclideanDistance(Offset p1, Offset p2) {
    return sqrt(pow(p1.dx - p2.dx, 2) + pow(p1.dy - p2.dy, 2));
  }
}
