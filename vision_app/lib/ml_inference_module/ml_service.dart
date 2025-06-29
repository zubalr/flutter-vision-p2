import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';
import 'package:flutter/foundation.dart';

// Conditional imports for different platforms
import 'ml_service_native.dart' if (dart.library.js) 'ml_service_web.dart';

class MLService {
  late dynamic _platformService;

  MLService() {
    if (kIsWeb) {
      _platformService = MLServiceWeb();
    } else {
      _platformService = MLServiceNative();
    }
  }

  Future<bool> loadModel({bool useGpu = false}) async {
    return await _platformService.loadModel(useGpu: useGpu);
  }

  bool get isModelLoaded => _platformService.isModelLoaded;

  List<DetectedObject> runObjectDetection(CameraImage cameraImage) {
    return _platformService.runObjectDetection(cameraImage);
  }

  List<DetectedKeypoint> runKeypointDetection(CameraImage cameraImage) {
    return _platformService.runKeypointDetection(cameraImage);
  }

  void setCanRunInference(bool canRun) {
    _platformService.setCanRunInference(canRun);
  }

  void dispose() {
    _platformService.dispose();
  }
}