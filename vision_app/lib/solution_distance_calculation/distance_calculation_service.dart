import 'package:flutter/material.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'dart:math';

class DistanceCalculationService {
  List<DetectedObject> _detectedObjects = [];
  final List<DetectedObject> _selectedObjects = [];
  final Map<String, double> _distances = {};
  final List<Offset> _connectionLines = [];

  // Calibration factor for converting pixels to real-world units
  // This should be calibrated based on camera setup and known object sizes
  static const double _pixelsToMetersFactor = 0.001; // Default: 1 pixel = 1mm

  void processDetections(List<DetectedObject> detections) {
    _detectedObjects = detections;
    _updateDistanceCalculations();
  }

  /// Handle user tap on an object for distance calculation
  void selectObjectAt(Offset tapPosition) {
    // Find the object that was tapped
    DetectedObject? tappedObject;
    for (final obj in _detectedObjects) {
      if (obj.boundingBox.contains(tapPosition)) {
        tappedObject = obj;
        break;
      }
    }

    if (tappedObject != null) {
      if (_selectedObjects.length < 2) {
        if (!_selectedObjects.contains(tappedObject)) {
          _selectedObjects.add(tappedObject);
          print('Selected object: ${tappedObject.label}');
        }
      } else {
        // Reset selection and start over
        _selectedObjects.clear();
        _selectedObjects.add(tappedObject);
        print('Reset selection. Selected object: ${tappedObject.label}');
      }
      _updateDistanceCalculations();
    }
  }

  /// Clear all selections (right-click functionality)
  void clearSelections() {
    _selectedObjects.clear();
    _distances.clear();
    _connectionLines.clear();
    print('Cleared all selections');
  }

  Map<String, double> getDistances() {
    return _distances;
  }

  List<DetectedObject> getDetectedObjects() {
    return _detectedObjects;
  }

  List<DetectedObject> getSelectedObjects() {
    return _selectedObjects;
  }

  List<Offset> getConnectionLines() {
    return _connectionLines;
  }

  void _updateDistanceCalculations() {
    _distances.clear();
    _connectionLines.clear();

    if (_selectedObjects.length == 2) {
      final obj1 = _selectedObjects[0];
      final obj2 = _selectedObjects[1];

      final center1 = obj1.boundingBox.center;
      final center2 = obj2.boundingBox.center;

      // Calculate pixel distance
      final pixelDistance = _euclideanDistance(center1, center2);
      
      // Convert to estimated real-world distance
      final realWorldDistance = pixelDistance * _pixelsToMetersFactor;

      _distances['${obj1.label}_to_${obj2.label}'] = realWorldDistance;
      _distances['${obj1.label}_to_${obj2.label}_pixels'] = pixelDistance;

      // Store connection line for drawing
      _connectionLines.addAll([center1, center2]);

      print('Distance calculated: ${realWorldDistance.toStringAsFixed(3)}m (${pixelDistance.toStringAsFixed(1)}px)');
    }
  }

  double _euclideanDistance(Offset p1, Offset p2) {
    return sqrt(pow(p1.dx - p2.dx, 2) + pow(p1.dy - p2.dy, 2));
  }

  /// Set calibration factor for pixel-to-real-world conversion
  void setCalibrationFactor(double factor) {
    // This would be called with a calibrated value based on known object sizes
    // For now, we use a default estimation
  }
}
