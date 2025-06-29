
import 'package:flutter/material.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';

class SecurityAlarmService {
  List<List<Offset>> _zones = [];
  bool _alarmTriggered = false;
  List<DetectedObject> _detectedObjects = [];

  void setZones(List<List<Offset>> zones) {
    _zones = zones;
  }

  List<List<Offset>> getZones() {
    return _zones;
  }

  bool isAlarmTriggered() {
    return _alarmTriggered;
  }

  List<DetectedObject> getDetectedObjects() {
    return _detectedObjects;
  }

  void processDetections(List<DetectedObject> detections) {
    _detectedObjects = detections;
    _alarmTriggered = false; // Reset alarm
    for (var zone in _zones) {
      for (var obj in detections) {
        if (_isPointInPolygon(obj.boundingBox.center, zone)) {
          _alarmTriggered = true;
          print('Alarm! Object detected in zone.');
          break; // Only need one object to trigger alarm
        }
      }
      if (_alarmTriggered) break; // Alarm triggered, no need to check other zones
    }
  }

  // Ray-casting algorithm to check if a point is inside a polygon
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false; // A polygon must have at least 3 vertices

    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy)) &&
          (point.dx < (polygon[j].dx - polygon[i].dx) * (point.dy - polygon[i].dy) /
                  (polygon[j].dy - polygon[i].dy) + polygon[i].dx)) {
        inside = !inside;
      }
    }
    return inside;
  }
}
