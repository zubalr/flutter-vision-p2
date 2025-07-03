
import 'package:flutter/material.dart';

class BoundingBox extends StatelessWidget {
  final Rect rect;
  final Color color;
  final String label;

  const BoundingBox({
    super.key,
    required this.rect,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            color: color,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
