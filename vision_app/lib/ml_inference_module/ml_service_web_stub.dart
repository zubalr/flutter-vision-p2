import 'package:camera/camera.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

/// Stub implementation for native builds
class MLServiceWeb {
  final bool _isModelLoaded = false;

  Future<bool> loadModel({bool useGpu = false}) async {
    throw UnsupportedError(
      'Web ML service is not supported on native platforms',
    );
  }

  bool get isModelLoaded => _isModelLoaded;

  List<DetectedObject> runObjectDetection(CameraImage? cameraImage) {
    throw UnsupportedError(
      'Web ML service is not supported on native platforms',
    );
  }

  List<DetectedKeypoint> runKeypointDetection(CameraImage? cameraImage) {
    throw UnsupportedError(
      'Web ML service is not supported on native platforms',
    );
  }

  void dispose() {
    throw UnsupportedError(
      'Web ML service is not supported on native platforms',
    );
  }

  void processImage(CameraImage image) {
    throw UnsupportedError(
      'Web ML service is not supported on native platforms',
    );
  }

  bool get canRunInference => false;
}
