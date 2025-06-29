import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class CameraManager {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isInitialized = false;
  int _cameraIndex = 0;
  ResolutionPreset _resolutionPreset = ResolutionPreset.medium;
  bool _isImageStreamActive = false;

  Future<bool> initialize({
    ResolutionPreset resolution = ResolutionPreset.medium,
  }) async {
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
      print(
        'Camera permission permanently denied. Please enable it in settings.',
      );
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
    if (_controller != null && _controller!.value.isInitialized) {
      // Check if image streaming is supported (not available on web)
      if (kIsWeb) {
        print('Image streaming not supported on web platform');
        return;
      }

      try {
        if (!_controller!.value.isStreamingImages) {
          _controller!.startImageStream(onFrame);
          _isImageStreamActive = true;
        }
      } catch (e) {
        print('Error starting image stream: $e');
      }
    }
  }

  void stopImageStream() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        _controller!.stopImageStream();
        _isImageStreamActive = false;
      } catch (e) {
        print('Error stopping image stream: $e');
      }
    }
  }

  CameraController? get controller => _controller;

  bool get isInitialized => _isInitialized;

  bool get supportsImageStreaming => !kIsWeb;

  bool get isImageStreamActive => _isImageStreamActive;

  void dispose() {
    _controller?.dispose();
  }
}
