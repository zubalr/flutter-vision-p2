import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

/// Web-compatible ML Service using TensorFlow.js
class MLServiceWeb {
  bool _isModelLoaded = false;
  bool _canRunInference = true;
  late web.HTMLCanvasElement _canvas;

  MLServiceWeb() {
    _initializeCanvas();
  }

  void _initializeCanvas() {
    _canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    _canvas.width = 640;
    _canvas.height = 640;
    print(
      'Canvas initialized for image processing: ${_canvas.width}x${_canvas.height}',
    );
  }

  Future<bool> loadModel({bool useGpu = false}) async {
    try {
      print('Loading YOLO model for web...');

      // Initialize TensorFlow.js and load model using direct JS calls
      final result = await _loadYOLOModel(useGpu);

      if (result) {
        _isModelLoaded = true;
        print('YOLO model loaded successfully for web inference');
        return true;
      } else {
        _isModelLoaded = false;
        print('Failed to load YOLO model');
        return false;
      }
    } catch (error) {
      print('Error loading YOLO model: $error');
      _isModelLoaded = false;
      return false;
    }
  }

  Future<bool> _loadYOLOModel(bool useGpu) async {
    // Use direct JavaScript evaluation to load the model
    try {
      final jsCode =
          '''
        (function() {
          try {
            // Initialize YOLO wrapper
            if (typeof window.yoloWrapper === 'undefined') {
              window.yoloWrapper = new TFJSWrapper();
            }
            
            // Load the model asynchronously (will auto-detect ONNX or TensorFlow.js)
            window.yoloWrapper.loadModel(null, $useGpu).then(function(success) {
              window.modelLoadResult = success;
              if (success) {
                console.log('YOLO model loaded successfully via', window.yoloWrapper.backend);
              }
            }).catch(function(error) {
              console.error('Model load error:', error);
              window.modelLoadResult = false;
            });
            
            return true; // Indicates JS execution started
          } catch (error) {
            console.error('Error in model loading:', error);
            return false;
          }
        })()
      ''';

      evalJS(jsCode);

      // Wait for model loading to complete
      for (int i = 0; i < 100; i++) {
        // Wait up to 10 seconds for model loading
        await Future.delayed(Duration(milliseconds: 100));
        final checkCode = 'window.modelLoadResult';
        final result = evalJS(checkCode);
        final resultStr = result.toString();
        if (resultStr != 'undefined' && resultStr != 'null') {
          return resultStr == 'true';
        }
      }

      return false;
    } catch (error) {
      print('Error in _loadYOLOModel: $error');
      return false;
    }
  }

  bool get isModelLoaded => _isModelLoaded;

  /// Object detection using real YOLO inference
  List<DetectedObject> runObjectDetection(CameraImage? cameraImage) {
    if (!_isModelLoaded || !_canRunInference) {
      return [];
    }

    try {
      print('Running YOLO inference on web...');

      // For web, capture from video element instead of camera image
      _captureVideoFrame();

      // Run inference using JavaScript
      final detections = _runYOLOInference();

      return detections;
    } catch (error) {
      print('Error during YOLO object detection: $error');
      return [];
    }
  }

  void _captureVideoFrame() {
    // Capture current frame from video element to canvas for inference
    try {
      final jsCode = '''
        (function() {
          try {
            // Find the video element from camera preview
            const video = document.querySelector('video');
            if (!video) {
              console.warn('No video element found for capture');
              return false;
            }
            
            // Get or create canvas for inference
            let canvas = document.getElementById('inference-canvas');
            if (!canvas) {
              canvas = document.createElement('canvas');
              canvas.id = 'inference-canvas';
              canvas.style.display = 'none'; // Hidden canvas for processing
              document.body.appendChild(canvas);
            }
            
            const ctx = canvas.getContext('2d');
            
            // Set canvas size to match model input (640x640)
            canvas.width = 640;
            canvas.height = 640;
            
            // Draw video frame to canvas, scaling to fit
            ctx.drawImage(video, 0, 0, 640, 640);
            
            return true;
          } catch (error) {
            console.error('Error capturing video frame:', error);
            return false;
          }
        })()
      ''';

      evalJS(jsCode);
    } catch (error) {
      print('Error in _captureVideoFrame: $error');
    }
  }

  List<DetectedObject> _runYOLOInference() {
    try {
      // Use JavaScript to run inference and get results
      final jsCode = '''
        (function() {
          try {
            if (window.yoloWrapper && window.yoloWrapper.isLoaded) {
              const canvas = document.getElementById('inference-canvas');
              if (canvas) {
                const detections = window.yoloWrapper.runObjectDetection(canvas);
                return JSON.stringify(detections || []);
              }
            }
            return '[]';
          } catch (error) {
            console.error('Error in inference:', error);
            return '[]';
          }
        })()
      ''';

      final resultJson = evalJS(jsCode) as String? ?? '[]';
      return _parseDetectionsFromJson(resultJson);
    } catch (error) {
      print('Error in _runYOLOInference: $error');
      return [];
    }
  }

  List<DetectedObject> _parseDetectionsFromJson(String json) {
    try {
      print('Parsing detections JSON: $json');
      
      final detections = <DetectedObject>[];

      // Parse real YOLO detections
      if (json != '[]' && json.isNotEmpty && json != '{}') {
        try {
          // Use JavaScript to safely parse and convert the detections
          final parseCode = '''
            (function() {
              try {
                const detections = JSON.parse('$json');
                const converted = [];
                
                if (Array.isArray(detections)) {
                  for (const detection of detections) {
                    if (detection.boundingBox && detection.confidence > 0.3) {
                      converted.push({
                        left: Math.round(detection.boundingBox.left || 0),
                        top: Math.round(detection.boundingBox.top || 0),
                        width: Math.round(detection.boundingBox.width || 0),
                        height: Math.round(detection.boundingBox.height || 0),
                        confidence: detection.confidence || 0.0,
                        label: detection.className || 'object'
                      });
                    }
                  }
                }
                
                return JSON.stringify(converted);
              } catch (error) {
                console.error('Error parsing detections:', error);
                return '[]';
              }
            })()
          ''';
          
          final convertedJson = evalJS(parseCode) as String? ?? '[]';
          print('Converted detections: $convertedJson');
          
          // Parse the converted detections using Dart
          if (convertedJson != '[]') {
            // Simple manual JSON parsing for the converted format
            final cleanJson = convertedJson.replaceAll(RegExp(r'[\[\]{}]'), '');
            if (cleanJson.isNotEmpty) {
              final parts = cleanJson.split('},{');
              for (String part in parts) {
                try {
                  final values = <String, dynamic>{};
                  final pairs = part.split(',');
                  for (String pair in pairs) {
                    final keyValue = pair.split(':');
                    if (keyValue.length == 2) {
                      final key = keyValue[0].replaceAll('"', '').trim();
                      final value = keyValue[1].replaceAll('"', '').trim();
                      if (key == 'label') {
                        values[key] = value;
                      } else {
                        values[key] = double.tryParse(value) ?? 0.0;
                      }
                    }
                  }
                  
                  if (values.containsKey('left') && values.containsKey('top') && 
                      values.containsKey('width') && values.containsKey('height')) {
                    detections.add(
                      DetectedObject(
                        boundingBox: Rect.fromLTWH(
                          values['left']?.toDouble() ?? 0.0,
                          values['top']?.toDouble() ?? 0.0,
                          values['width']?.toDouble() ?? 0.0,
                          values['height']?.toDouble() ?? 0.0,
                        ),
                        label: values['label']?.toString() ?? 'object',
                        confidence: values['confidence']?.toDouble() ?? 0.0,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error parsing detection part: $e');
                }
              }
            }
          }
        } catch (e) {
          print('Error in detection parsing: $e');
        }
      }

      print('Parsed ${detections.length} real detections');
      return detections;
    } catch (error) {
      print('Error parsing detections: $error');
      return [];
    }
  }

  /// Keypoint detection (not implemented for YOLO)
  List<DetectedKeypoint> runKeypointDetection(CameraImage? cameraImage) {
    if (!_isModelLoaded || !_canRunInference) {
      return [];
    }

    if (cameraImage == null) {
      return [];
    }

    // YOLO models typically don't do keypoint detection
    print('Keypoint detection not implemented for YOLO model');
    return [];
  }

  void setCanRunInference(bool canRun) {
    _canRunInference = canRun;
  }

  void dispose() {
    try {
      // Clean up resources
      final jsCode = '''
        if (window.yoloWrapper) {
          window.yoloWrapper.dispose();
          window.yoloWrapper = null;
        }
      ''';
      evalJS(jsCode);
    } catch (error) {
      print('Error disposing YOLO wrapper: $error');
    }

    _isModelLoaded = false;
  }
}

/// Helper function to evaluate JavaScript code
@JS('eval')
external JSAny evalJS(String code);
