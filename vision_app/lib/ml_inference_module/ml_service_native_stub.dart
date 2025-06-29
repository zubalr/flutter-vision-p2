import 'package:camera/camera.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

/// Stub implementation for web builds
class MLServiceNative {
  final bool _isModelLoaded = false;

  Future<bool> loadModel({bool useGpu = false}) async {
    throw UnsupportedError('Native ML service is not supported on web');
  }

  bool get isModelLoaded => _isModelLoaded;

  List<DetectedObject> runObjectDetection(CameraImage? cameraImage) {
    throw UnsupportedError('Native ML service is not supported on web');
  }

  List<DetectedKeypoint> runKeypointDetection(CameraImage? cameraImage) {
    throw UnsupportedError('Native ML service is not supported on web');
  }

  void setCanRunInference(bool canRun) {
    // No-op for stub
  }

  void dispose() {
    // No-op for stub
  }
}
