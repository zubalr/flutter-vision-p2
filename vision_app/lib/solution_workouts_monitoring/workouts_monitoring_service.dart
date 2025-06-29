import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

class WorkoutsMonitoringService {
  List<DetectedKeypoint> _detectedKeypoints = [];
  int _repCount = 0;

  void processKeypoints(List<DetectedKeypoint> keypoints) {
    _detectedKeypoints = keypoints;
    // Implement rep counting logic here based on keypoints
    // For now, just a placeholder
    _repCount = 0; // Reset for now
  }

  List<DetectedKeypoint> getDetectedKeypoints() {
    return _detectedKeypoints;
  }

  int getRepCount() {
    return _repCount;
  }
}