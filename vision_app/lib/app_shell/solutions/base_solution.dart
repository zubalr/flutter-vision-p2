import 'package:flutter/material.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

/// Base interface for all AI solutions
abstract class BaseSolution {
  /// Unique identifier for the solution
  String get id;

  /// Display name for the solution
  String get name;

  /// Description of what the solution does
  String get description;

  /// Icon to display in the UI
  IconData get icon;

  /// Color theme for the solution
  Color get color;

  /// Whether this solution supports drawing interactions
  bool get supportsDrawing;

  /// Type of drawing interaction (line, polygon, etc.)
  DrawingType get drawingType;

  /// Process detections and update internal state
  void processDetections(List<DetectedObject> detections);

  /// Process keypoints (if applicable)
  void processKeypoints(List<DetectedKeypoint> keypoints);

  /// Handle drawing completion
  void handleDrawingComplete(List<Offset> points);

  /// Reset solution state
  void reset();

  /// Get overlay data for rendering
  SolutionOverlayData getOverlayData();

  /// Initialize solution with settings
  void initialize(Map<String, dynamic> settings);

  /// Get current solution metrics
  Map<String, dynamic> getMetrics();
}

/// Types of drawing interactions
enum DrawingType { none, line, polygon, rectangle, point, tap }

/// Data for rendering solution overlays
abstract class SolutionOverlayData {
  /// Objects to render
  List<DetectedObject> get objects;

  /// Keypoints to render (if applicable)
  List<DetectedKeypoint> get keypoints;

  /// Additional rendering data specific to the solution
  Map<String, dynamic> get customData;
}

/// Factory for creating solution instances
class SolutionFactory {
  static final Map<String, BaseSolution Function()> _creators = {};

  /// Register a solution creator
  static void register(String id, BaseSolution Function() creator) {
    _creators[id] = creator;
  }

  /// Create a solution instance by ID
  static BaseSolution? create(String id) {
    final creator = _creators[id];
    return creator?.call();
  }

  /// Get all available solution IDs
  static List<String> getAvailableSolutions() {
    return _creators.keys.toList();
  }

  /// Check if a solution is available
  static bool isAvailable(String id) {
    return _creators.containsKey(id);
  }
}
