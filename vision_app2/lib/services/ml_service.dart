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
      print('Number of labels: ${_labels.length}');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('Input type: ${_interpreter!.getInputTensor(0).type}');
      print('Output type: ${_interpreter!.getOutputTensor(0).type}');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> predict(CameraImage image) async {
    if (_interpreter == null) {
      print('Error: Interpreter not loaded');
      return [];
    }
    
    try {
      // Check image format and dimensions
      if (image.planes.isEmpty) {
        print('Error: Image has no planes');
        return [];
      }
      
      print('Image info: ${image.width}x${image.height}, planes: ${image.planes.length}, format: ${image.format.group}');
      
      // Preprocess the image
      final input = _preprocessImage(image);
      
      // Get the actual output shape from the model
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('Expected output shape: $outputShape');
      
      // Prepare output tensor based on actual model output shape
      List<List<double>> output;
      if (outputShape.length == 2) {
        // Shape: [1, features] or [batch, features]
        output = [List.filled(outputShape[1], 0.0)];
      } else if (outputShape.length == 3) {
        // Shape: [1, boxes, features]
        output = [List.filled(outputShape[1] * outputShape[2], 0.0)];
      } else {
        // Fallback to original assumption
        output = [List.filled(numBoxes * (4 + numClasses), 0.0)];
      }
      
      // Run inference
      _interpreter!.run(input, output);
      
      // Post-process results
      return _postprocessOutput(output[0], image.width, image.height);
    } catch (e) {
      print('Error during prediction: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  List<List<List<List<double>>>> _preprocessImage(CameraImage image) {
    try {
      // Convert camera image to RGB bytes
      final rgbBytes = _convertCameraImageToRGB(image);
      final resized = _resizeImage(rgbBytes, image.width, image.height, inputSize, inputSize);
      
      // Get actual input shape from the model
      final inputShape = _interpreter!.getInputTensor(0).shape;
      print('Model input shape: $inputShape');
      
      // Handle different input shapes
      if (inputShape.length == 4) {
        if (inputShape[1] == 3) {
          // Shape: [1, 3, 640, 640] - channel first
          final input = List.generate(1, (batch) =>
              List.generate(3, (channel) =>
                  List.generate(inputSize, (y) =>
                      List.generate(inputSize, (x) {
                        final pixelIndex = (y * inputSize + x) * 3;
                        return resized[pixelIndex + channel] / 255.0;
                      }))));
          return input;
        } else if (inputShape[3] == 3) {
          // Shape: [1, 640, 640, 3] - channel last
          final input = List.generate(1, (batch) =>
              List.generate(inputSize, (y) =>
                  List.generate(inputSize, (x) =>
                      List.generate(3, (channel) {
                        final pixelIndex = (y * inputSize + x) * 3;
                        return resized[pixelIndex + channel] / 255.0;
                      }))));
          return input;
        }
      }
      
      // Default: assume [1, 3, 640, 640] format
      final input = List.generate(1, (batch) =>
          List.generate(3, (channel) =>
              List.generate(inputSize, (y) =>
                  List.generate(inputSize, (x) {
                    final pixelIndex = (y * inputSize + x) * 3;
                    return resized[pixelIndex + channel] / 255.0;
                  }))));
      
      return input;
    } catch (e) {
      print('Error in preprocessing: $e');
      rethrow;
    }
  }

  Uint8List _convertCameraImageToRGB(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToRGB(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToRGB(image);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        return _convertNV21ToRGB(image);
      } else {
        // Fallback: treat as grayscale or single plane
        print('Unknown image format: ${image.format.group}, using fallback conversion');
        return _convertSinglePlaneToRGB(image);
      }
    } catch (e) {
      print('Error converting image format: $e');
      return _convertSinglePlaneToRGB(image);
    }
  }

  Uint8List _convertSinglePlaneToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final Uint8List rgbBytes = Uint8List(width * height * 3);
    
    if (image.planes.isEmpty) return rgbBytes;
    
    final plane = image.planes[0];
    final bytes = plane.bytes;
    
    for (int i = 0; i < width * height && i < bytes.length; i++) {
      final int value = bytes[i];
      rgbBytes[i * 3] = value;     // R
      rgbBytes[i * 3 + 1] = value; // G
      rgbBytes[i * 3 + 2] = value; // B
    }
    
    return rgbBytes;
  }

  Uint8List _convertBGRA8888ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final Uint8List rgbBytes = Uint8List(width * height * 3);
    final plane = image.planes[0];
    final bytes = plane.bytes;
    
    for (int i = 0; i < width * height; i++) {
      final int bgIndex = i * 4;
      if (bgIndex + 3 < bytes.length) {
        final int b = bytes[bgIndex];
        final int g = bytes[bgIndex + 1];
        final int r = bytes[bgIndex + 2];
        // Alpha channel is at bgIndex + 3, but we ignore it
        
        final int rgbIndex = i * 3;
        rgbBytes[rgbIndex] = r;
        rgbBytes[rgbIndex + 1] = g;
        rgbBytes[rgbIndex + 2] = b;
      }
    }
    
    return rgbBytes;
  }

  Uint8List _convertNV21ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final Uint8List rgbBytes = Uint8List(width * height * 3);
    
    if (image.planes.length < 2) {
      return _convertSinglePlaneToRGB(image);
    }
    
    final yPlane = image.planes[0];
    final uvPlane = image.planes[1];
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);
        
        if (yIndex >= yPlane.bytes.length) continue;
        
        final int yValue = yPlane.bytes[yIndex];
        int uValue = 128;
        int vValue = 128;
        
        if (uvIndex * 2 + 1 < uvPlane.bytes.length) {
          vValue = uvPlane.bytes[uvIndex * 2];
          uValue = uvPlane.bytes[uvIndex * 2 + 1];
        }
        
        // YUV to RGB conversion
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        final int rgbIndex = yIndex * 3;
        if (rgbIndex + 2 < rgbBytes.length) {
          rgbBytes[rgbIndex] = r;
          rgbBytes[rgbIndex + 1] = g;
          rgbBytes[rgbIndex + 2] = b;
        }
      }
    }
    
    return rgbBytes;
  }

  Uint8List _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final Uint8List rgbBytes = Uint8List(width * height * 3);

    // Check if we have enough planes for YUV420
    if (image.planes.length < 3) {
      print('Warning: Image has only ${image.planes.length} planes, expected 3 for YUV420');
      // Use fallback conversion for single plane
      return _convertSinglePlaneToRGB(image);
    }

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        
        // Bounds checking for Y plane
        if (yIndex >= image.planes[0].bytes.length) continue;
        
        final int yValue = image.planes[0].bytes[yIndex];
        
        // Bounds checking for UV planes
        int uValue = 128; // Default neutral value
        int vValue = 128; // Default neutral value
        
        if (uvIndex < image.planes[1].bytes.length) {
          uValue = image.planes[1].bytes[uvIndex];
        }
        
        if (image.planes.length > 2 && uvIndex < image.planes[2].bytes.length) {
          vValue = image.planes[2].bytes[uvIndex];
        }

        // YUV to RGB conversion
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        final int rgbIndex = yIndex * 3;
        if (rgbIndex + 2 < rgbBytes.length) {
          rgbBytes[rgbIndex] = r;
          rgbBytes[rgbIndex + 1] = g;
          rgbBytes[rgbIndex + 2] = b;
        }
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