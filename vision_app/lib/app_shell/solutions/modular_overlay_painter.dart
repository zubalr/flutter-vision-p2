import 'package:flutter/material.dart';
import 'package:vision_app/app_shell/solutions/base_solution.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

/// Modular painter that can render overlays for any solution
class ModularOverlayPainter extends CustomPainter {
  final SolutionOverlayData overlayData;
  final String solutionId;

  ModularOverlayPainter({required this.overlayData, required this.solutionId});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw detected objects
    _drawObjects(canvas, size, overlayData.objects);

    // Draw keypoints if available
    _drawKeypoints(canvas, size, overlayData.keypoints);

    // Draw solution-specific overlays
    _drawCustomOverlays(canvas, size, overlayData.customData);
  }

  void _drawObjects(Canvas canvas, Size size, List<DetectedObject> objects) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final object in objects) {
      // Draw bounding box
      canvas.drawRect(object.boundingBox, paint);

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${object.label} (${(object.confidence * 100).toInt()}%)',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(object.boundingBox.left, object.boundingBox.top - 20),
      );
    }
  }

  void _drawKeypoints(
    Canvas canvas,
    Size size,
    List<DetectedKeypoint> keypoints,
  ) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (final keypoint in keypoints) {
      canvas.drawCircle(keypoint.point, 4.0, paint);
    }
  }

  void _drawCustomOverlays(
    Canvas canvas,
    Size size,
    Map<String, dynamic> customData,
  ) {
    switch (solutionId) {
      case 'object_counting':
        _drawObjectCountingOverlay(canvas, size, customData);
        break;
      case 'workouts_monitoring':
        _drawWorkoutsMonitoringOverlay(canvas, size, customData);
        break;
      case 'security_alarm':
        _drawSecurityAlarmOverlay(canvas, size, customData);
        break;
      case 'distance_calculation':
        _drawDistanceCalculationOverlay(canvas, size, customData);
        break;
    }
  }

  void _drawObjectCountingOverlay(
    Canvas canvas,
    Size size,
    Map<String, dynamic> data,
  ) {
    final countingLine = data['countingLine'] as List<Offset>?;
    final objectCount = data['objectCount'] as int? ?? 0;

    if (countingLine != null && countingLine.length >= 2) {
      final paint = Paint()
        ..color = Colors.red
        ..strokeWidth = 3.0;

      canvas.drawLine(countingLine.first, countingLine.last, paint);
    }

    // Draw count
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Count: $objectCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  void _drawWorkoutsMonitoringOverlay(
    Canvas canvas,
    Size size,
    Map<String, dynamic> data,
  ) {
    final repCount = data['repCount'] as int? ?? 0;

    // Draw rep count
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Reps: $repCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.green,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  void _drawSecurityAlarmOverlay(
    Canvas canvas,
    Size size,
    Map<String, dynamic> data,
  ) {
    final zones = data['zones'] as List<List<Offset>>? ?? [];
    final alarmTriggered = data['alarmTriggered'] as bool? ?? false;

    final paint = Paint()
      ..color = alarmTriggered
          ? Colors.red.withValues(alpha: 0.3)
          : Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = alarmTriggered ? Colors.red : Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final zone in zones) {
      if (zone.length >= 3) {
        final path = Path();
        path.moveTo(zone.first.dx, zone.first.dy);
        for (int i = 1; i < zone.length; i++) {
          path.lineTo(zone[i].dx, zone[i].dy);
        }
        path.close();

        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
      }
    }

    // Draw alarm status
    if (alarmTriggered) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '🚨 ALARM TRIGGERED! 🚨',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 - textPainter.width / 2, 10),
      );
    }
  }

  void _drawDistanceCalculationOverlay(
    Canvas canvas,
    Size size,
    Map<String, dynamic> data,
  ) {
    final distances = data['distances'] as Map<String, double>? ?? {};
    final selectedObjects = data['selectedObjects'] as List<DetectedObject>? ?? [];
    final connectionLines = data['connectionLines'] as List<Offset>? ?? [];

    // Draw connection lines between selected objects
    if (connectionLines.length >= 2) {
      final linePaint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < connectionLines.length - 1; i += 2) {
        canvas.drawLine(connectionLines[i], connectionLines[i + 1], linePaint);
        
        // Draw distance text at the midpoint of the line
        final midPoint = Offset(
          (connectionLines[i].dx + connectionLines[i + 1].dx) / 2,
          (connectionLines[i].dy + connectionLines[i + 1].dy) / 2,
        );
        
        // Find the corresponding distance
        String distanceText = '';
        for (final entry in distances.entries) {
          if (!entry.key.endsWith('_pixels')) {
            distanceText = '${(entry.value * 1000).toStringAsFixed(0)}mm';
            break;
          }
        }
        
        if (distanceText.isNotEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: distanceText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.orange,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          
          // Draw background for better readability
          final textRect = Rect.fromLTWH(
            midPoint.dx - textPainter.width / 2 - 4,
            midPoint.dy - textPainter.height / 2 - 2,
            textPainter.width + 8,
            textPainter.height + 4,
          );
          canvas.drawRect(textRect, Paint()..color = Colors.orange);
          
          textPainter.paint(
            canvas,
            Offset(midPoint.dx - textPainter.width / 2, midPoint.dy - textPainter.height / 2),
          );
        }
      }
    }

    // Highlight selected objects
    final selectedPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    for (final obj in selectedObjects) {
      canvas.drawRect(obj.boundingBox, selectedPaint);
      
      // Draw selection indicator
      final center = obj.boundingBox.center;
      canvas.drawCircle(center, 8.0, Paint()..color = Colors.orange);
      canvas.drawCircle(center, 6.0, Paint()..color = Colors.white);
    }

    // Draw instructions
    String instructionText = '';
    if (selectedObjects.isEmpty) {
      instructionText = 'Tap on objects to measure distance';
    } else if (selectedObjects.length == 1) {
      instructionText = 'Tap on another object to measure distance';
    } else {
      instructionText = 'Right-click to clear selection';
    }

    final instructionPainter = TextPainter(
      text: TextSpan(
        text: instructionText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    instructionPainter.layout();
    instructionPainter.paint(canvas, Offset(10, size.height - 30));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
