import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

/// Web-compatible ML Service that provides mock inference for demonstration
/// In a real implementation, this would use TensorFlow.js or WebAssembly
class MLServiceWeb {
  bool _isModelLoaded = false;
  bool _canRunInference = true;

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
  List<DetectedObject> runObjectDetection(CameraImage cameraImage) {
    if (!_isModelLoaded || !_canRunInference) {
      print('Model not loaded or inference paused.');
      return [];
    }

    print('Running mock object detection for web');
    
    // Return mock detected objects for demonstration
    List<DetectedObject> detectedObjects = [];
    
    // Create some mock objects at different positions
    detectedObjects.add(DetectedObject(
      boundingBox: const Rect.fromLTWH(100, 100, 150, 200), 
      label: 'person', 
      confidence: 0.85
    ));
    
    detectedObjects.add(DetectedObject(
      boundingBox: const Rect.fromLTWH(300, 150, 100, 120), 
      label: 'chair', 
      confidence: 0.72
    ));
    
    return detectedObjects;
  }

  /// Mock keypoint detection that returns dummy results for web demo
  List<DetectedKeypoint> runKeypointDetection(CameraImage cameraImage) {
    if (!_isModelLoaded || !_canRunInference) {
      print('Model not loaded or inference paused.');
      return [];
    }

    print('Running mock keypoint detection for web');
    
    // Return mock keypoints for demonstration
    List<DetectedKeypoint> detectedKeypoints = [];
    
    // Create mock human pose keypoints
    detectedKeypoints.add(DetectedKeypoint(point: const Offset(175, 120), label: 'nose', score: 0.95));
    detectedKeypoints.add(DetectedKeypoint(point: const Offset(165, 130), label: 'left_eye', score: 0.92));
    detectedKeypoints.add(DetectedKeypoint(point: const Offset(185, 130), label: 'right_eye', score: 0.90));
    detectedKeypoints.add(DetectedKeypoint(point: const Offset(175, 160), label: 'neck', score: 0.88));
    detectedKeypoints.add(DetectedKeypoint(point: const Offset(150, 180), label: 'left_shoulder', score: 0.85));
    detectedKeypoints.add(DetectedKeypoint(point: const Offset(200, 180), label: 'right_shoulder', score: 0.87));
    
    return detectedKeypoints;
  }

  void setCanRunInference(bool canRun) {
    _canRunInference = canRun;
  }

  void dispose() {
    // Nothing to dispose for web mock implementation
  }
}