import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';
import 'dart:io';
import 'dart:math' as math;

class MLServiceNative {
  late Interpreter _interpreter;
  bool _isModelLoaded = false;
  bool _canRunInference = true;

  // YOLO11 model specifications
  static const int inputSize = 640; // YOLO11 standard input size
  static const double confidenceThreshold = 0.25;
  static const double iouThreshold = 0.45;
  static const int maxDetections = 300;
  
  // COCO dataset class names (80 classes)
  static const List<String> classNames = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat',
    'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench', 'bird', 'cat',
    'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'backpack',
    'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball',
    'kite', 'baseball bat', 'baseball glove', 'skateboard', 'surfboard', 'tennis racket',
    'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple',
    'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake',
    'chair', 'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop',
    'mouse', 'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
    'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush'
  ];

  Future<bool> loadModel({bool useGpu = false}) async {
    try {
      print('Initializing YOLO11 TensorFlow Lite model...');
      
      // Create interpreter options with iOS-specific optimizations
      final interpreterOptions = InterpreterOptions();
      
      // Configure platform-specific delegates
      if (Platform.isIOS) {
        print('Configuring for iOS platform...');
        
        if (useGpu) {
          try {
            // Use Metal delegate for iOS GPU acceleration
            interpreterOptions.addDelegate(GpuDelegate());
            print('iOS Metal GPU delegate configured');
          } catch (e) {
            print('GPU delegate failed, using CPU: $e');
          }
        }
        
        // iOS-specific optimizations
        interpreterOptions.threads = 2; // Optimal for mobile devices
        
      } else if (Platform.isAndroid) {
        print('Configuring for Android platform...');
        
        if (useGpu) {
          try {
            interpreterOptions.addDelegate(GpuDelegateV2());
            print('Android GPU delegate configured');
          } catch (e) {
            print('GPU delegate failed, using CPU: $e');
          }
        }
      }
      
      // Load the YOLO11 model from assets
      print('Loading model from assets/yolov11.tflite...');
      _interpreter = await Interpreter.fromAsset(
        'yolov11.tflite',
        options: interpreterOptions,
      );
      
      // Verify model loaded correctly
      if (_interpreter == null) {
        throw Exception('Interpreter is null after loading');
      }
      
      // Validate model structure
      final inputTensors = _interpreter.getInputTensors();
      final outputTensors = _interpreter.getOutputTensors();
      
      if (inputTensors.isEmpty) {
        throw Exception('Model has no input tensors');
      }
      
      if (outputTensors.isEmpty) {
        throw Exception('Model has no output tensors');
      }
      
      final inputShape = inputTensors[0].shape;
      final outputShape = outputTensors[0].shape;
      
      // Validate YOLO11 input format [1, 640, 640, 3] or [1, 3, 640, 640]
      bool validInput = false;
      if (inputShape.length == 4) {
        // NHWC format: [1, 640, 640, 3]
        if (inputShape[0] == 1 && inputShape[1] == inputSize && 
            inputShape[2] == inputSize && inputShape[3] == 3) {
          validInput = true;
          print('Model uses NHWC format (Height-Width-Channels)');
        }
        // NCHW format: [1, 3, 640, 640]
        else if (inputShape[0] == 1 && inputShape[1] == 3 && 
                 inputShape[2] == inputSize && inputShape[3] == inputSize) {
          validInput = true;
          print('Model uses NCHW format (Channels-Height-Width)');
        }
      }
      
      if (!validInput) {
        print('WARNING: Unexpected input shape $inputShape');
        print('Expected: [1, $inputSize, $inputSize, 3] or [1, 3, $inputSize, $inputSize]');
        print('Proceeding anyway - model might still work...');
      }
      
      print('SUCCESS: YOLO11 model loaded on ${Platform.operatingSystem}');
      print('Model input shape: $inputShape');
      print('Model output shape: $outputShape');
      print('GPU acceleration: ${useGpu ? "enabled" : "disabled"}');
      print('Threads: ${Platform.isIOS ? "2" : "default"}');
      
      _isModelLoaded = true;
      return true;
      
    } catch (e) {
      print('CRITICAL ERROR: Failed to load YOLO11 model');
      print('Error details: $e');
      print('');
      print('TROUBLESHOOTING STEPS:');
      print('1. Check if assets/yolov11.tflite exists');
      print('2. Verify file size is > 5MB (not a placeholder)');
      print('3. Ensure model is in TensorFlow Lite format');
      print('4. Try: flutter clean && flutter pub get');
      print('5. For iOS: check Xcode build settings');
      print('');
      print('TO DOWNLOAD REAL YOLO11 MODEL:');
      print('Run: ./scripts/setup_yolo11.sh');
      print('Or: python scripts/download_yolo11_model.py');
      print('');
      print('IMPORTANT: This app requires a real TensorFlow Lite model!');
      print('Mock detections are disabled for production use.');
      
      _isModelLoaded = false;
      return false;
    }
  }

  bool get isModelLoaded => _isModelLoaded;

  // YOLO11 image preprocessing
  Float32List _preprocessImage(CameraImage image) {
    // Convert camera image to RGB and resize to model input size
    final rgbBytes = _convertYUV420ToRGB(image);
    final resizedBytes = _resizeImage(rgbBytes, image.width, image.height, inputSize, inputSize);
    
    // Normalize to [0, 1] range as expected by YOLO11
    final normalizedBytes = Float32List(inputSize * inputSize * 3);
    for (int i = 0; i < normalizedBytes.length; i++) {
      normalizedBytes[i] = resizedBytes[i] / 255.0;
    }
    
    return normalizedBytes;
  }

  // Convert YUV420 camera image to RGB
  Uint8List _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    
    final Uint8List yPlane = image.planes[0].bytes;
    final Uint8List uPlane = image.planes[1].bytes;
    final Uint8List vPlane = image.planes[2].bytes;
    
    final Uint8List rgbBytes = Uint8List(width * height * 3);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        
        final int yValue = yPlane[yIndex];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];
        
        // YUV to RGB conversion
        final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
        final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);
        
        final int rgbIndex = yIndex * 3;
        rgbBytes[rgbIndex] = r;
        rgbBytes[rgbIndex + 1] = g;
        rgbBytes[rgbIndex + 2] = b;
      }
    }
    
    return rgbBytes;
  }

  // Resize image using bilinear interpolation
  Uint8List _resizeImage(Uint8List imageBytes, int originalWidth, int originalHeight, int targetWidth, int targetHeight) {
    final Uint8List resizedBytes = Uint8List(targetWidth * targetHeight * 3);
    
    final double scaleX = originalWidth / targetWidth;
    final double scaleY = originalHeight / targetHeight;
    
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final double srcX = x * scaleX;
        final double srcY = y * scaleY;
        
        final int x1 = srcX.floor();
        final int y1 = srcY.floor();
        final int x2 = math.min(x1 + 1, originalWidth - 1);
        final int y2 = math.min(y1 + 1, originalHeight - 1);
        
        final double dx = srcX - x1;
        final double dy = srcY - y1;
        
        for (int c = 0; c < 3; c++) {
          final int idx1 = (y1 * originalWidth + x1) * 3 + c;
          final int idx2 = (y1 * originalWidth + x2) * 3 + c;
          final int idx3 = (y2 * originalWidth + x1) * 3 + c;
          final int idx4 = (y2 * originalWidth + x2) * 3 + c;
          
          final double val1 = imageBytes[idx1] * (1 - dx) + imageBytes[idx2] * dx;
          final double val2 = imageBytes[idx3] * (1 - dx) + imageBytes[idx4] * dx;
          final double finalVal = val1 * (1 - dy) + val2 * dy;
          
          resizedBytes[(y * targetWidth + x) * 3 + c] = finalVal.round();
        }
      }
    }
    
    return resizedBytes;
  }

  // YOLO11 object detection - REQUIRES REAL MODEL
  List<DetectedObject> runObjectDetection(CameraImage? cameraImage) {
    if (!_canRunInference || cameraImage == null) {
      return [];
    }
    
    if (!_isModelLoaded) {
      // REFUSE to run without real model - no mock detections
      print('ERROR: Cannot run object detection without a real YOLO11 model!');
      print('Please download the model using: ./scripts/setup_yolo11.sh');
      return [];
    }

    try {
      // Preprocess image
      final preprocessedImage = _preprocessImage(cameraImage);
      
      // Prepare input tensor [1, 640, 640, 3] for YOLO11 (NHWC format for TensorFlow Lite)
      final input = List.generate(1, (_) => 
        List.generate(inputSize, (_) => 
          List.generate(inputSize, (_) => 
            List.filled(3, 0.0))));
      
      // Fill input tensor with preprocessed image data
      int pixelIndex = 0;
      for (int h = 0; h < inputSize; h++) {
        for (int w = 0; w < inputSize; w++) {
          for (int c = 0; c < 3; c++) {
            input[0][h][w][c] = preprocessedImage[pixelIndex++];
          }
        }
      }
      
      // Prepare output tensor - YOLO11 typically outputs [1, 84, 8400] for 80 classes
      // 84 = 4 (bbox) + 80 (classes), 8400 = number of anchor points
      final output = List.generate(1, (_) => List.generate(84, (_) => List.filled(8400, 0.0)));

      // Run inference
      _interpreter.run(input, output);
      
      // Post-process results
      final detections = _postProcessYOLO11Output(output[0], cameraImage.width, cameraImage.height);
      
      print('Object Detection Inference successful - Found ${detections.length} objects');
      return detections;
      
    } catch (e) {
      print('CRITICAL ERROR during YOLO11 inference: $e');
      print('Model may be corrupted or incompatible');
      print('Try re-downloading: ./scripts/setup_yolo11.sh');
      return [];
    }
  }

  // Post-process YOLO11 output
  List<DetectedObject> _postProcessYOLO11Output(List<List<double>> output, int imageWidth, int imageHeight) {
    final List<DetectedObject> detections = [];
    final List<_Detection> rawDetections = [];
    
    // Extract detections from output
    for (int i = 0; i < output[0].length; i++) {
      // Get bounding box coordinates (center_x, center_y, width, height)
      final double centerX = output[0][i];
      final double centerY = output[1][i];
      final double width = output[2][i];
      final double height = output[3][i];
      
      // Find the class with highest confidence
      double maxConfidence = 0.0;
      int maxClassIndex = 0;
      
      for (int classIndex = 0; classIndex < classNames.length; classIndex++) {
        final double confidence = output[4 + classIndex][i];
        if (confidence > maxConfidence) {
          maxConfidence = confidence;
          maxClassIndex = classIndex;
        }
      }
      
      // Filter by confidence threshold
      if (maxConfidence > confidenceThreshold) {
        rawDetections.add(_Detection(
          centerX: centerX,
          centerY: centerY,
          width: width,
          height: height,
          confidence: maxConfidence,
          classIndex: maxClassIndex,
        ));
      }
    }
    
    // Apply Non-Maximum Suppression (NMS)
    final nmsDetections = _applyNMS(rawDetections);
    
    // Convert to DetectedObject format
    for (final detection in nmsDetections) {
      // Convert from normalized coordinates to image coordinates
      final double scaleX = imageWidth / inputSize;
      final double scaleY = imageHeight / inputSize;
      
      final double left = (detection.centerX - detection.width / 2) * scaleX;
      final double top = (detection.centerY - detection.height / 2) * scaleY;
      final double right = (detection.centerX + detection.width / 2) * scaleX;
      final double bottom = (detection.centerY + detection.height / 2) * scaleY;
      
      detections.add(DetectedObject(
        boundingBox: Rect.fromLTRB(
          left.clamp(0, imageWidth.toDouble()),
          top.clamp(0, imageHeight.toDouble()),
          right.clamp(0, imageWidth.toDouble()),
          bottom.clamp(0, imageHeight.toDouble()),
        ),
        label: classNames[detection.classIndex],
        confidence: detection.confidence,
      ));
    }
    
    return detections;
  }

  // Apply Non-Maximum Suppression
  List<_Detection> _applyNMS(List<_Detection> detections) {
    if (detections.isEmpty) return [];
    
    // Sort by confidence (descending)
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    final List<_Detection> nmsDetections = [];
    final List<bool> suppressed = List.filled(detections.length, false);
    
    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      
      nmsDetections.add(detections[i]);
      
      // Suppress overlapping detections
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        
        final double iou = _calculateIoU(detections[i], detections[j]);
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
      
      // Limit number of detections
      if (nmsDetections.length >= maxDetections) break;
    }
    
    return nmsDetections;
  }

  // Calculate Intersection over Union (IoU)
  double _calculateIoU(_Detection det1, _Detection det2) {
    final double left1 = det1.centerX - det1.width / 2;
    final double top1 = det1.centerY - det1.height / 2;
    final double right1 = det1.centerX + det1.width / 2;
    final double bottom1 = det1.centerY + det1.height / 2;
    
    final double left2 = det2.centerX - det2.width / 2;
    final double top2 = det2.centerY - det2.height / 2;
    final double right2 = det2.centerX + det2.width / 2;
    final double bottom2 = det2.centerY + det2.height / 2;
    
    final double intersectionLeft = math.max(left1, left2);
    final double intersectionTop = math.max(top1, top2);
    final double intersectionRight = math.min(right1, right2);
    final double intersectionBottom = math.min(bottom1, bottom2);
    
    if (intersectionLeft >= intersectionRight || intersectionTop >= intersectionBottom) {
      return 0.0;
    }
    
    final double intersectionArea = (intersectionRight - intersectionLeft) * (intersectionBottom - intersectionTop);
    final double area1 = det1.width * det1.height;
    final double area2 = det2.width * det2.height;
    final double unionArea = area1 + area2 - intersectionArea;
    
    return intersectionArea / unionArea;
  }

  // Keypoint detection - REQUIRES SPECIALIZED POSE MODEL
  List<DetectedKeypoint> runKeypointDetection(CameraImage? cameraImage) {
    if (!_canRunInference || cameraImage == null) {
      return [];
    }
    
    if (!_isModelLoaded) {
      print('ERROR: Cannot run keypoint detection without a real pose estimation model!');
      print('Current YOLO11 model is for object detection only');
      return [];
    }

    // Note: YOLO11 object detection model doesn't support keypoint detection
    // You would need a specialized YOLO11-pose model for this functionality
    print('WARNING: Keypoint detection requires YOLO11-pose model');
    print('Current model only supports object detection');
    print('To add pose estimation, download YOLO11-pose model');
    return [];
  }

  void setCanRunInference(bool canRun) {
    _canRunInference = canRun;
  }

  // Mock detection methods for demo mode
  List<DetectedObject> getMockObjectDetections() {
    return [
      DetectedObject(
        boundingBox: const Rect.fromLTWH(100, 100, 200, 200),
        label: 'person',
        confidence: 0.9,
      ),
      DetectedObject(
        boundingBox: const Rect.fromLTWH(300, 150, 150, 180),
        label: 'chair',
        confidence: 0.7,
      ),
      DetectedObject(
        boundingBox: const Rect.fromLTWH(50, 300, 100, 120),
        label: 'bottle',
        confidence: 0.8,
      ),
    ];
  }

  List<DetectedKeypoint> getMockKeypointDetections() {
    return [
      DetectedKeypoint(
        point: const Offset(150, 120),
        label: 'nose',
        score: 0.95,
      ),
      DetectedKeypoint(
        point: const Offset(140, 140),
        label: 'left_eye',
        score: 0.88,
      ),
      DetectedKeypoint(
        point: const Offset(160, 140),
        label: 'right_eye',
        score: 0.92,
      ),
    ];
  }

  void dispose() {
    if (_isModelLoaded) {
      _interpreter.close();
    }
  }
}

// Helper class for raw detections during post-processing
class _Detection {
  final double centerX;
  final double centerY;
  final double width;
  final double height;
  final double confidence;
  final int classIndex;

  _Detection({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.confidence,
    required this.classIndex,
  });
}
