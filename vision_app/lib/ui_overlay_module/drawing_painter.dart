
import 'package:flutter/material.dart';

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final bool isDrawing;
  final bool isPolygon;

  DrawingPainter({required this.points, this.isDrawing = false, this.isPolygon = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    if (isPolygon) {
      if (points.isNotEmpty) {
        Path path = Path();
        path.moveTo(points[0].dx, points[0].dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        if (isDrawing) {
          // Draw a line from the last point to the current finger position
          // This is handled by the GestureDetector in main.dart
        } else {
          path.close();
        }
        canvas.drawPath(path, paint..style = PaintingStyle.stroke);

        // Draw circles at each point for better visibility
        for (var point in points) {
          canvas.drawCircle(point, 8, paint..style = PaintingStyle.fill);
        }
      }
    } else {
      // Draw lines for object counting
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.isDrawing != isDrawing || oldDelegate.isPolygon != isPolygon;
  }
}
