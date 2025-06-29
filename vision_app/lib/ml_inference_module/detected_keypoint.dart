
import 'package:flutter/material.dart';

class DetectedKeypoint {
  final Offset point;
  final String label;
  final double score;

  DetectedKeypoint({
    required this.point,
    required this.label,
    required this.score,
  });
}
