import 'package:camera/camera.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';
import 'package:flutter/foundation.dart';

// Conditional imports
import 'package:vision_app/ml_inference_module/ml_service_native.dart'
    if (dart.library.js) 'package:vision_app/ml_inference_module/ml_service_native_stub.dart';
import 'package:vision_app/ml_inference_module/ml_service_web.dart';

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

  List<DetectedObject> runObjectDetection(CameraImage? cameraImage) {
    return _platformService.runObjectDetection(cameraImage);
  }

  List<DetectedKeypoint> runKeypointDetection(CameraImage? cameraImage) {
    return _platformService.runKeypointDetection(cameraImage);
  }

  // Method for getting mock detections - ONLY FOR WEB DEMO
  List<DetectedObject> getMockObjectDetections() {
    if (kIsWeb) {
      // Web platform uses mock detections for demo
      return _platformService.runObjectDetection(null);
    } else {
      // Native platforms require real TensorFlow Lite models
      print('WARNING: Mock detections not available on native platforms');
      print('Please download real YOLO11 model: ./scripts/setup_yolo11.sh');
      return [];
    }
  }

  List<DetectedKeypoint> getMockKeypointDetections() {
    if (kIsWeb) {
      // Web platform uses mock detections for demo
      return _platformService.runKeypointDetection(null);
    } else {
      // Native platforms require real pose estimation models
      print('WARNING: Mock keypoints not available on native platforms');
      print('Please download YOLO11-pose model for keypoint detection');
      return [];
    }
  }

  void setCanRunInference(bool canRun) {
    _platformService.setCanRunInference(canRun);
  }

  void dispose() {
    _platformService.dispose();
  }
}
