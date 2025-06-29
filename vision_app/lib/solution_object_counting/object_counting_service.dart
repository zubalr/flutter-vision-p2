import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vision_app/ml_inference_module/detected_object.dart';

class ObjectCountingService {
  List<DetectedObject> _detectedObjects = [];
  List<Offset> _countingLine = [];
  int _objectCount = 0;

  void processDetections(List<DetectedObject> detections) {
    _detectedObjects = detections;
    _objectCount = _countObjectsCrossingLine();
  }

  void setCountingLine(List<Offset> line) {
    _countingLine = line;
  }

  int getObjectCount() {
    return _objectCount;
  }

  List<DetectedObject> getDetectedObjects() {
    return _detectedObjects;
  }

  List<Offset> getCountingLine() {
    return _countingLine;
  }

  int _countObjectsCrossingLine() {
    if (_countingLine.length < 2) return 0;

    int count = 0;
    final p1 = _countingLine[0];
    final p2 = _countingLine[1];

    for (var obj in _detectedObjects) {
      // Check if the line intersects with the bounding box
      // This is a simplified check, a more robust solution would involve line-segment intersection
      if (_doLineSegmentsIntersect(p1, p2, obj.boundingBox.topLeft, obj.boundingBox.topRight) ||
          _doLineSegmentsIntersect(p1, p2, obj.boundingBox.topRight, obj.boundingBox.bottomRight) ||
          _doLineSegmentsIntersect(p1, p2, obj.boundingBox.bottomRight, obj.boundingBox.bottomLeft) ||
          _doLineSegmentsIntersect(p1, p2, obj.boundingBox.bottomLeft, obj.boundingBox.topLeft)) {
        count++;
      }
    }
    return count;
  }

  // Helper function to check if two line segments intersect
  bool _doLineSegmentsIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
    int o1 = _orientation(p1, q1, p2);
    int o2 = _orientation(p1, q1, q2);
    int o3 = _orientation(p2, q2, p1);
    int o4 = _orientation(p2, q2, q1);

    // General case
    if (o1 != 0 && o2 != 0 && o3 != 0 && o4 != 0) return true;

    // Special Cases
    // p1, q1 and p2 are collinear and p2 lies on segment p1q1
    if (o1 == 0 && _onSegment(p1, p2, q1)) return true;

    // p1, q1 and q2 are collinear and q2 lies on segment p1q1
    if (o2 == 0 && _onSegment(p1, q2, q1)) return true;

    // p2, q2 and p1 are collinear and p1 lies on segment p2q2
    if (o3 == 0 && _onSegment(p2, p1, q2)) return true;

    // p2, q2 and q1 are collinear and q1 lies on segment p2q2
    if (o4 == 0 && _onSegment(p2, q1, q2)) return true;

    return false; // Doesn't fall in any of the above cases
  }

  // To find orientation of ordered triplet (p, q, r).
  // The function returns following values
  // 0 --> p, q and r are collinear
  // 1 --> Clockwise
  // 2 --> Counterclockwise
  int _orientation(Offset p, Offset q, Offset r) {
    double val = (q.dy - p.dy) * (r.dx - q.dx) -
        (q.dx - p.dx) * (r.dy - q.dy);

    if (val == 0) return 0; // collinear
    return (val > 0) ? 1 : 2; // clock or counterclock wise
  }

  // Given three collinear points p, q, r, the function checks if
  // point q lies on segment 'pr'
  bool _onSegment(Offset p, Offset q, Offset r) {
    return (q.dx <= max(p.dx, r.dx) && q.dx >= min(p.dx, r.dx) &&
        q.dy <= max(p.dy, r.dy) && q.dy >= min(p.dy, r.dy));
  }
}