import 'package:flutter/material.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

class OverlayPainter extends CustomPainter {
  final List<DetectedObject> detectedObjects;
  final List<Offset> countingLine;
  final int objectCount;
  final List<DetectedKeypoint> detectedKeypoints;
  final int repCount;
  final List<List<Offset>> zones;
  final bool alarmTriggered;
  final Map<String, double> distances;

  // Constructor for object counting
  OverlayPainter({
    required this.detectedObjects,
    required this.countingLine,
    required this.objectCount,
    this.detectedKeypoints = const [],
    this.repCount = 0,
    this.zones = const [],
    this.alarmTriggered = false,
    this.distances = const {},
  });

  // Named constructor for workouts monitoring
  OverlayPainter.forWorkouts({
    required this.detectedKeypoints,
    required this.repCount,
    this.detectedObjects = const [],
    this.countingLine = const [],
    this.objectCount = 0,
    this.zones = const [],
    this.alarmTriggered = false,
    this.distances = const {},
  });

  // Named constructor for security alarm
  OverlayPainter.forSecurityAlarm({
    required this.detectedObjects,
    required this.zones,
    required this.alarmTriggered,
    this.detectedKeypoints = const [],
    this.repCount = 0,
    this.countingLine = const [],
    this.objectCount = 0,
    this.distances = const {},
  });

  // Named constructor for distance calculation
  OverlayPainter.forDistanceCalculation({
    required this.detectedObjects,
    required this.distances,
    this.detectedKeypoints = const [],
    this.repCount = 0,
    this.countingLine = const [],
    this.objectCount = 0,
    this.zones = const [],
    this.alarmTriggered = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Drawing logic for object counting
    if (detectedObjects.isNotEmpty || countingLine.isNotEmpty) {
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (var obj in detectedObjects) {
        canvas.drawRect(obj.boundingBox, paint);
        TextPainter tp = TextPainter(
          text: TextSpan(text: "${obj.label} (${(obj.confidence * 100).toStringAsFixed(0)}%)", style: TextStyle(color: Colors.white, fontSize: 12)),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(obj.boundingBox.left, obj.boundingBox.top - 15));
      }

      if (countingLine.length == 2) {
        final linePaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawLine(countingLine[0], countingLine[1], linePaint);

        TextPainter countTp = TextPainter(
          text: TextSpan(text: "Count: $objectCount", style: TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold)),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        countTp.layout();
        countTp.paint(canvas, Offset(10, 10));
      }
    }

    // Drawing logic for workouts monitoring
    if (detectedKeypoints.isNotEmpty) {
      final keypointPaint = Paint()
        ..color = Colors.yellow
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.0;

      for (var keypoint in detectedKeypoints) {
        canvas.drawCircle(keypoint.point, 5, keypointPaint);
        TextPainter tp = TextPainter(
          text: TextSpan(text: keypoint.label, style: TextStyle(color: Colors.white, fontSize: 10)),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(keypoint.point.dx + 5, keypoint.point.dy + 5));
      }

      TextPainter repCountTp = TextPainter(
        text: TextSpan(text: "Reps: $repCount", style: TextStyle(color: Colors.yellow, fontSize: 20, fontWeight: FontWeight.bold)),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      repCountTp.layout();
      repCountTp.paint(canvas, Offset(10, 40)); // Position below object count
    }

    // Drawing logic for security alarm
    if (zones.isNotEmpty) {
      final zonePaint = Paint()
        ..color = alarmTriggered ? Colors.red.withValues(alpha: 0.5) : Colors.green.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;

      for (var zone in zones) {
        if (zone.length > 1) {
          Path path = Path();
          path.moveTo(zone[0].dx, zone[0].dy);
          for (int i = 1; i < zone.length; i++) {
            path.lineTo(zone[i].dx, zone[i].dy);
          }
          path.close();
          canvas.drawPath(path, zonePaint);
        }
      }

      // Draw detected objects for security alarm
      final objectPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      for (var obj in detectedObjects) {
        canvas.drawRect(obj.boundingBox, objectPaint);
      }

      if (alarmTriggered) {
        TextPainter alarmTp = TextPainter(
          text: TextSpan(text: "ALARM!", style: TextStyle(color: Colors.red, fontSize: 30, fontWeight: FontWeight.bold)),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        alarmTp.layout();
        alarmTp.paint(canvas, Offset(size.width / 2 - alarmTp.width / 2, size.height / 2 - alarmTp.height / 2));
      }
    }

    // Drawing logic for distance calculation
    if (distances.isNotEmpty) {
      final distancePaint = Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final textPaint = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      int i = 0;
      for (var entry in distances.entries) {
        final distanceLabel = entry.key;
        final distanceValue = entry.value;

        // Assuming the distanceLabel contains info to draw the line between objects
        // This needs to be refined based on how you want to represent the distances
        // For now, just displaying the text
        textPaint.text = TextSpan(text: "$distanceLabel: ${distanceValue.toStringAsFixed(2)}", style: TextStyle(color: Colors.purple, fontSize: 14));
        textPaint.layout();
        textPaint.paint(canvas, Offset(10, 70 + (i * 20))); // Position below rep count
        i++;
      }

      // Draw lines between detected objects for distance calculation
      if (detectedObjects.length >= 2) {
        for (int i = 0; i < detectedObjects.length; i++) {
          for (int j = i + 1; j < detectedObjects.length; j++) {
            final obj1 = detectedObjects[i];
            final obj2 = detectedObjects[j];
            canvas.drawLine(obj1.boundingBox.center, obj2.boundingBox.center, distancePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.detectedObjects != detectedObjects ||
        oldDelegate.countingLine != countingLine ||
        oldDelegate.objectCount != objectCount ||
        oldDelegate.detectedKeypoints != detectedKeypoints ||
        oldDelegate.repCount != repCount ||
        oldDelegate.zones != zones ||
        oldDelegate.alarmTriggered != alarmTriggered ||
        oldDelegate.distances != distances;
  }
}