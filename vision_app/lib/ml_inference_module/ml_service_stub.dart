import 'package:camera/camera.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

abstract class MLService {
  Future<bool> loadModel({bool useGpu = false});
  bool get isModelLoaded;
  List<DetectedObject> runObjectDetection(CameraImage? cameraImage);
  List<DetectedKeypoint> runKeypointDetection(CameraImage? cameraImage);
  void setCanRunInference(bool canRun);
  void dispose();
}

MLService getMLService() => throw UnimplementedError('getMLService() has not been implemented.');
