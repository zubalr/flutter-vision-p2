import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

/// Web-compatible ML Service that provides mock inference for demonstration
/// In a real implementation, this would use TensorFlow.js or WebAssembly
class MLServiceWeb {
  bool _isModelLoaded = false;
  bool _canRunInference = true;
  final Random _random = Random();

  // Mock model parameters
  static const int inputSize = 416;
  static const double confidenceThreshold = 0.5;

  Future<bool> loadModel({bool useGpu = false}) async {
    // Simulate model loading delay
    await Future.delayed(const Duration(milliseconds: 500));
    _isModelLoaded = true;
    print('Mock model loaded successfully for web');
    return true;
  }

  bool get isModelLoaded => _isModelLoaded;

  /// Mock object detection that returns dummy results for web demo
  List<DetectedObject> runObjectDetection(CameraImage? cameraImage) {
    if (!_isModelLoaded || !_canRunInference) {
      print('Model not loaded or inference paused.');
      return [];
    }

    print('Running mock object detection for web');

    // Return mock detected objects for demonstration with some randomness
    List<DetectedObject> detectedObjects = [];

    // Add some variety to make it more realistic
    final objectTypes = [
      'person',
      'chair',
      'table',
      'laptop',
      'bottle',
      'book',
    ];
    final numObjects = _random.nextInt(3) + 1; // 1-3 objects

    for (int i = 0; i < numObjects; i++) {
      final x = _random.nextDouble() * 300 + 50; // Random x between 50-350
      final y = _random.nextDouble() * 200 + 50; // Random y between 50-250
      final width =
          _random.nextDouble() * 100 + 80; // Random width between 80-180
      final height =
          _random.nextDouble() * 120 + 100; // Random height between 100-220
      final confidence =
          _random.nextDouble() * 0.4 + 0.6; // Confidence between 0.6-1.0
      final label = objectTypes[_random.nextInt(objectTypes.length)];

      detectedObjects.add(
        DetectedObject(
          boundingBox: Rect.fromLTWH(x, y, width, height),
          label: label,
          confidence: confidence,
        ),
      );
    }

    return detectedObjects;
  }

  /// Mock keypoint detection that returns dummy results for web demo
  List<DetectedKeypoint> runKeypointDetection(CameraImage? cameraImage) {
    if (!_isModelLoaded || !_canRunInference) {
      print('Model not loaded or inference paused.');
      return [];
    }

    print('Running mock keypoint detection for web');

    // Return mock keypoints for demonstration with some randomness
    List<DetectedKeypoint> detectedKeypoints = [];

    // Create mock human pose keypoints with slight variations
    final baseX = 175 + (_random.nextDouble() * 20 - 10); // Add some jitter
    final baseY = 120 + (_random.nextDouble() * 20 - 10);

    final keypointLabels = [
      'nose',
      'left_eye',
      'right_eye',
      'neck',
      'left_shoulder',
      'right_shoulder',
    ];
    final positions = [
      Offset(baseX, baseY), // nose
      Offset(baseX - 10, baseY + 10), // left_eye
      Offset(baseX + 10, baseY + 10), // right_eye
      Offset(baseX, baseY + 40), // neck
      Offset(baseX - 25, baseY + 60), // left_shoulder
      Offset(baseX + 25, baseY + 60), // right_shoulder
    ];

    for (int i = 0; i < keypointLabels.length; i++) {
      detectedKeypoints.add(
        DetectedKeypoint(
          point: positions[i],
          label: keypointLabels[i],
          score: 0.85 + _random.nextDouble() * 0.15, // Score between 0.85-1.0
        ),
      );
    }

    return detectedKeypoints;
  }

  void setCanRunInference(bool canRun) {
    _canRunInference = canRun;
  }

  void dispose() {
    // Nothing to dispose for web mock implementation
  }
}
