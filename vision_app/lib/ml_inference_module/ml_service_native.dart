import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

/// Real TensorFlow Lite ML Service for native platforms
class MLServiceNative {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  bool _canRunInference = true;

  // YOLO11 model specifications
  static const int inputSize = 640;
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
    'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair',
    'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
    'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
    'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush'
  ];

  Future<bool> loadModel({bool useGpu = false}) async {
    try {
      print('Loading YOLO11 TensorFlow Lite model...');
      
      // Configure interpreter options
      final options = InterpreterOptions();
      
      if (useGpu && Platform.isAndroid) {
        // GPU delegate only for Android
        options.addDelegate(GpuDelegate());
        print('Using GPU acceleration on Android');
      } else {
        // Use CPU with optimizations
        options.threads = 4;
        print('Using CPU with 4 threads');
      }

      // Load model from assets
      _interpreter = await Interpreter.fromAsset(
        'assets/yolov11.tflite',
        options: options,
      );

      print('Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      
      _isModelLoaded = true;
      return true;
    } catch (e) {
      print('Error loading TensorFlow Lite model: $e');
      _isModelLoaded = false;
      return false;
    }
  }

  bool get isModelLoaded => _isModelLoaded;

  List<DetectedObject> runObjectDetection(CameraImage? cameraImage) {
    if (!_isModelLoaded || !_canRunInference || cameraImage == null || _interpreter == null) {
      return [];
    }

    try {
      // Preprocess camera image
      final inputData = _preprocessCameraImage(cameraImage);
      if (inputData == null) {
        return [];
      }

      // Run inference
      final outputData = List.filled(1 * 84 * 8400, 0.0).reshape([1, 84, 8400]);
      _interpreter!.run(inputData, outputData);

      // Post-process results
      final detections = _postProcessYOLO(outputData, cameraImage.width, cameraImage.height);
      
      print('Detected ${detections.length} objects');
      return detections;
    } catch (e) {
      print('Error during object detection: $e');
      return [];
    }
  }

  Float32List? _preprocessCameraImage(CameraImage cameraImage) {
    try {
      // Convert YUV420 to RGB
      final rgbBytes = _convertYUV420ToRGB(cameraImage);
      if (rgbBytes == null) return null;

      // Create input tensor [1, 640, 640, 3]
      final input = Float32List(1 * inputSize * inputSize * 3);
      
      // Resize and normalize
      final originalWidth = cameraImage.width;
      final originalHeight = cameraImage.height;
      
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          // Calculate source coordinates
          final srcX = (x * originalWidth / inputSize).floor();
          final srcY = (y * originalHeight / inputSize).floor();
          final srcIndex = (srcY * originalWidth + srcX) * 3;
          
          if (srcIndex + 2 < rgbBytes.length) {
            final dstIndex = (y * inputSize + x) * 3;
            // Normalize to [0, 1]
            input[dstIndex] = rgbBytes[srcIndex] / 255.0;         // R
            input[dstIndex + 1] = rgbBytes[srcIndex + 1] / 255.0; // G
            input[dstIndex + 2] = rgbBytes[srcIndex + 2] / 255.0; // B
          }
        }
      }

      return input.reshape([1, inputSize, inputSize, 3]);
    } catch (e) {
      print('Error preprocessing camera image: $e');
      return null;
    }
  }

  Uint8List? _convertYUV420ToRGB(CameraImage cameraImage) {
    try {
      final int width = cameraImage.width;
      final int height = cameraImage.height;
      final int uvRowStride = cameraImage.planes[1].bytesPerRow;
      final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

      final Uint8List yPlane = cameraImage.planes[0].bytes;
      final Uint8List uPlane = cameraImage.planes[1].bytes;
      final Uint8List vPlane = cameraImage.planes[2].bytes;

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
    } catch (e) {
      print('Error converting YUV420 to RGB: $e');
      return null;
    }
  }

  List<DetectedObject> _postProcessYOLO(dynamic predictions, int originalWidth, int originalHeight) {
    final detections = <DetectedObject>[];
    
    try {
      // YOLO11 output format: [1, 84, 8400] where 84 = 4 (bbox) + 80 (classes)
      const int numDetections = 8400;
      const int numClasses = 80;
      
      // Access the predictions - TensorFlow Lite returns List<List<List<dynamic>>>
      final batch = predictions[0]; // First batch
      
      for (int i = 0; i < numDetections; i++) {
        // Extract bbox coordinates (center format)
        final double xCenter = (batch[0][i] as num).toDouble();
        final double yCenter = (batch[1][i] as num).toDouble();
        final double width = (batch[2][i] as num).toDouble();
        final double height = (batch[3][i] as num).toDouble();

        // Find the class with highest probability
        int maxClassIndex = 0;
        double maxClassScore = 0;

        for (int j = 0; j < numClasses; j++) {
          final double classScore = (batch[4 + j][i] as num).toDouble();
          if (classScore > maxClassScore) {
            maxClassScore = classScore;
            maxClassIndex = j;
          }
        }

        if (maxClassScore > confidenceThreshold) {
          // Convert from center format to corner format
          final double x1 = (xCenter - width / 2) / inputSize;
          final double y1 = (yCenter - height / 2) / inputSize;
          final double x2 = (xCenter + width / 2) / inputSize;
          final double y2 = (yCenter + height / 2) / inputSize;

          // Scale to original image size
          final double scaledX1 = x1 * originalWidth;
          final double scaledY1 = y1 * originalHeight;
          final double scaledWidth = (x2 - x1) * originalWidth;
          final double scaledHeight = (y2 - y1) * originalHeight;

          detections.add(DetectedObject(
            boundingBox: Rect.fromLTWH(scaledX1, scaledY1, scaledWidth, scaledHeight),
            label: classNames[maxClassIndex],
            confidence: maxClassScore,
          ));
        }
      }

      // Apply Non-Maximum Suppression
      return _applyNMS(detections);
    } catch (e) {
      print('Error in post-processing: $e');
      return [];
    }
  }

  List<DetectedObject> _applyNMS(List<DetectedObject> detections) {
    // Sort by confidence (descending)
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<DetectedObject> keep = [];
    final Set<int> suppressed = {};

    for (int i = 0; i < detections.length; i++) {
      if (suppressed.contains(i)) continue;

      keep.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed.contains(j)) continue;

        final double iou = _calculateIoU(detections[i].boundingBox, detections[j].boundingBox);
        if (iou > iouThreshold) {
          suppressed.add(j);
        }
      }
    }

    return keep;
  }

  double _calculateIoU(Rect box1, Rect box2) {
    final double x1 = math.max(box1.left, box2.left);
    final double y1 = math.max(box1.top, box2.top);
    final double x2 = math.min(box1.right, box2.right);
    final double y2 = math.min(box1.bottom, box2.bottom);

    if (x2 <= x1 || y2 <= y1) return 0.0;

    final double intersection = (x2 - x1) * (y2 - y1);
    final double area1 = box1.width * box1.height;
    final double area2 = box2.width * box2.height;
    final double union = area1 + area2 - intersection;

    return intersection / union;
  }

  List<DetectedKeypoint> runKeypointDetection(CameraImage? cameraImage) {
    if (!_isModelLoaded || !_canRunInference || cameraImage == null) {
      return [];
    }

    // YOLO11 doesn't do keypoint detection by default
    return [];
  }

  void setCanRunInference(bool canRun) {
    _canRunInference = canRun;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}