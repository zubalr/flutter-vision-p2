import 'dart:typed_data';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vision_app2/utils/nms.dart';

class MLService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  
  // Model input/output dimensions for YOLOv11
  static const int inputSize = 640;
  static const int numClasses = 80; // COCO dataset classes
  static const int numBoxes = 8400; // Typical for YOLOv11n

  Future<void> loadModel() async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset('assets/yolov11.tflite');
      
      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((line) => line.isNotEmpty).toList();
      
      print('Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> predict(CameraImage image) async {
    if (_interpreter == null) return [];
    
    try {
      // Preprocess the image
      final input = _preprocessImage(image);
      
      // Prepare output tensor - adjust shape based on actual model output
      final output = [List.filled(numBoxes * (4 + numClasses), 0.0)];
      
      // Run inference
      _interpreter!.run(input, output);
      
      // Post-process results
      return _postprocessOutput(output[0], image.width, image.height);
    } catch (e) {
      print('Error during prediction: $e');
      return [];
    }
  }

  List<List<List<List<double>>>> _preprocessImage(CameraImage image) {
    // Convert YUV420 to RGB and resize to model input size
    final rgbBytes = _convertYUV420ToRGB(image);
    final resized = _resizeImage(rgbBytes, image.width, image.height, inputSize, inputSize);
    
    // Normalize to [0, 1] and reshape for model input [1, 3, 640, 640] format
    final input = List.generate(1, (batch) =>
        List.generate(3, (channel) =>
            List.generate(inputSize, (y) =>
                List.generate(inputSize, (x) {
                  final pixelIndex = (y * inputSize + x) * 3;
                  return resized[pixelIndex + channel] / 255.0;
                }))));
    
    return input;
  }

  Uint8List _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    final Uint8List rgbBytes = Uint8List(width * height * 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        
        final int yValue = image.planes[0].bytes[yIndex];
        final int uValue = image.planes[1].bytes[uvIndex];
        final int vValue = image.planes[2].bytes[uvIndex];

        // YUV to RGB conversion
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        final int rgbIndex = yIndex * 3;
        rgbBytes[rgbIndex] = r;
        rgbBytes[rgbIndex + 1] = g;
        rgbBytes[rgbIndex + 2] = b;
      }
    }
    return rgbBytes;
  }

  Uint8List _resizeImage(Uint8List bytes, int originalWidth, int originalHeight, int targetWidth, int targetHeight) {
    final Uint8List resized = Uint8List(targetWidth * targetHeight * 3);
    
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final int srcX = (x * originalWidth / targetWidth).floor();
        final int srcY = (y * originalHeight / targetHeight).floor();
        
        final int srcIndex = (srcY * originalWidth + srcX) * 3;
        final int dstIndex = (y * targetWidth + x) * 3;
        
        resized[dstIndex] = bytes[srcIndex];
        resized[dstIndex + 1] = bytes[srcIndex + 1];
        resized[dstIndex + 2] = bytes[srcIndex + 2];
      }
    }
    
    return resized;
  }

  List<Map<String, dynamic>> _postprocessOutput(List<double> output, int imageWidth, int imageHeight) {
    List<Map<String, dynamic>> detections = [];
    
    // Reshape output to [numBoxes, 4 + numClasses]
    for (int i = 0; i < numBoxes; i++) {
      final int baseIndex = i * (4 + numClasses);
      
      // Extract box coordinates (center_x, center_y, width, height)
      final double centerX = output[baseIndex];
      final double centerY = output[baseIndex + 1];
      final double width = output[baseIndex + 2];
      final double height = output[baseIndex + 3];
      
      // Find the class with highest confidence
      double maxConf = 0.0;
      int maxClassIndex = 0;
      for (int j = 4; j < 4 + numClasses; j++) {
        final double conf = output[baseIndex + j];
        if (conf > maxConf) {
          maxConf = conf;
          maxClassIndex = j - 4;
        }
      }
      
      // Filter by confidence threshold
      if (maxConf > 0.5) {
        // Convert to corner coordinates and scale to image size
        final double scaleX = imageWidth / inputSize;
        final double scaleY = imageHeight / inputSize;
        
        final double x1 = (centerX - width / 2) * scaleX;
        final double y1 = (centerY - height / 2) * scaleY;
        final double x2 = (centerX + width / 2) * scaleX;
        final double y2 = (centerY + height / 2) * scaleY;
        
        detections.add({
          'box': [x1, y1, x2, y2],
          'tag': maxClassIndex < _labels.length ? _labels[maxClassIndex] : 'unknown',
          'confidence': maxConf,
        });
      }
    }
    
    // Apply Non-Maximum Suppression
    return applyNMS(detections, 0.5);
  }

  void dispose() {
    _interpreter?.close();
  }
}