
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  Future<void> initialize() async {
    if (_cameraController != null) return;
    
    final cameras = await availableCameras();
    
    // For iOS, try bgra8888 first as it's more reliable
    try {
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _cameraController!.initialize();
      print('Camera initialized with BGRA8888 format');
      return;
    } catch (e) {
      print('Failed to initialize with BGRA8888: $e');
      _cameraController?.dispose();
    }
    
    // Fallback to YUV420
    try {
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();
      print('Camera initialized with YUV420 format');
      return;
    } catch (e) {
      print('Failed to initialize with YUV420: $e');
      _cameraController?.dispose();
    }
    
    // Final fallback without specifying format
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    print('Camera initialized with default format');
  }

  void dispose() {
    _cameraController?.dispose();
  }
}
