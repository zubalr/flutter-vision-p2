
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraManager {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isInitialized = false;
  int _cameraIndex = 0;
  ResolutionPreset _resolutionPreset = ResolutionPreset.medium;

  Future<bool> initialize({ResolutionPreset resolution = ResolutionPreset.medium}) async {
    _resolutionPreset = resolution;
    // Request camera permission
    var status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        _cameras = await availableCameras();
        if (_cameras.isNotEmpty) {
          await _selectCamera(0);
          _isInitialized = true;
          return true;
        } else {
          print('No cameras found.');
          return false;
        }
      } on CameraException catch (e) {
        print('Camera initialization error: ${e.description}');
        return false;
      }
    } else if (status.isDenied) {
      print('Camera permission denied. Please enable it in settings.');
      return false;
    } else if (status.isPermanentlyDenied) {
      print('Camera permission permanently denied. Please enable it in settings.');
      openAppSettings(); // Opens app settings for the user to enable permission
      return false;
    }
    return false;
  }

  Future<void> _selectCamera(int index) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    _cameraIndex = index;
    _controller = CameraController(
      _cameras[_cameraIndex],
      _resolutionPreset,
      enableAudio: false,
    );
    await _controller!.initialize();
  }

  Future<void> switchCamera() async {
    if (_cameras.length > 1) {
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      await _selectCamera(_cameraIndex);
    }
  }

  void startImageStream(Function(CameraImage) onFrame) {
    if (_controller != null && !_controller!.value.isStreamingImages) {
      _controller!.startImageStream(onFrame);
    }
  }

  void stopImageStream() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
  }

  CameraController? get controller => _controller;

  bool get isInitialized => _isInitialized;

  void dispose() {
    _controller?.dispose();
  }
}
