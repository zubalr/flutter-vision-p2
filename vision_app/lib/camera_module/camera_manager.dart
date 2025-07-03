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
    try {
      _resolutionPreset = resolution;

      // Add a small delay to ensure native initialization is complete
      await Future.delayed(const Duration(milliseconds: 200));

      // Request camera permission
      var status = await Permission.camera.request();
      if (status.isGranted) {
        try {
          // Use a try-catch specifically for availableCameras() which can crash
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
        } catch (e) {
          print('Unexpected camera error: $e');
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
    } catch (e) {
      print('Fatal camera initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> _selectCamera(int index) async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      if (index >= 0 && index < _cameras.length) {
        _cameraIndex = index;
        _controller = CameraController(
          _cameras[_cameraIndex],
          _resolutionPreset,
          enableAudio: false,
        );

        // Add timeout to prevent hanging
        await _controller!.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw CameraException('timeout', 'Camera initialization timed out');
          },
        );
      } else {
        throw CameraException('invalid_index', 'Invalid camera index: $index');
      }
    } catch (e) {
      print('Error selecting camera: $e');
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
      rethrow;
    }
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
