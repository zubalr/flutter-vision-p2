# YOLO11 Object Detection Setup Guide

This Flutter app implements real-time object detection using YOLO11 (You Only Look Once version 11) with TensorFlow Lite.

## 🚀 Quick Start

### Option 1: Automatic Setup (Recommended)

1. **Install Python dependencies:**
   ```bash
   pip install ultralytics
   ```

2. **Run the download script:**
   ```bash
   python scripts/download_yolo11_model.py
   ```

3. **Clean and rebuild your Flutter app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Option 2: Manual Setup

1. **Install Ultralytics:**
   ```bash
   pip install ultralytics
   ```

2. **Download and convert YOLO11 model:**
   ```python
   from ultralytics import YOLO
   
   # Load YOLO11 nano model
   model = YOLO('yolo11n.pt')
   
   # Export to TensorFlow Lite
   model.export(format='tflite', imgsz=640)
   ```

3. **Copy the generated `.tflite` file to `assets/yolov11.tflite`**

4. **Run your Flutter app:**
   ```bash
   flutter run
   ```

## 📱 Features

- **Real-time object detection** with 80 COCO classes
- **Optimized for mobile** with YOLO11 nano model
- **GPU acceleration** support (Metal on iOS, GPU delegate on Android)
- **Bounding box visualization** with confidence scores
- **Multiple solution modes:**
  - Object counting
  - Security alarm
  - Distance calculation
  - Workout monitoring

## 🎯 Supported Objects

The YOLO11 model can detect 80 different object classes from the COCO dataset:

**People & Animals:**
- person, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe

**Vehicles:**
- bicycle, car, motorcycle, airplane, bus, train, truck, boat

**Everyday Objects:**
- bottle, cup, fork, knife, spoon, bowl, chair, couch, bed, toilet, tv, laptop, cell phone

**And many more!** See the complete list in `lib/ml_inference_module/ml_service_native.dart`

## ⚙️ Configuration

### Model Parameters
- **Input size:** 640x640 pixels
- **Confidence threshold:** 0.25
- **IoU threshold:** 0.45
- **Max detections:** 300

### Performance Optimization
- **GPU acceleration** automatically enabled when available
- **Efficient image preprocessing** with YUV to RGB conversion
- **Non-Maximum Suppression (NMS)** for duplicate removal
- **Bilinear interpolation** for image resizing

## 🔧 Troubleshooting

### Model Loading Issues

If you see "Failed to load model" errors:

1. **Check model file size:**
   ```bash
   ls -la assets/yolov11.tflite
   ```
   The file should be several MB in size, not just a few bytes.

2. **Re-download the model:**
   ```bash
   python scripts/download_yolo11_model.py
   ```

3. **Verify model format:**
   Make sure you're using the TensorFlow Lite (.tflite) format, not PyTorch (.pt)

### Performance Issues

1. **Enable GPU acceleration:**
   - The app automatically tries to use GPU when available
   - On iOS: Uses Metal Performance Shaders
   - On Android: Uses GPU Delegate V2

2. **Reduce model complexity:**
   - Switch to YOLO11n (nano) for fastest performance
   - Consider YOLO11s (small) for better accuracy
   - Avoid YOLO11m/l/x on mobile devices

3. **Optimize camera settings:**
   - Lower camera resolution if needed
   - Reduce inference frequency in settings

### Memory Issues

1. **Monitor memory usage** in the benchmarking view
2. **Close other apps** when running object detection
3. **Restart the app** if memory usage gets too high

## 📊 Model Variants

| Model | Size | Speed | Accuracy | Recommended Use |
|-------|------|-------|----------|-----------------|
| YOLO11n | ~6MB | Fastest | Good | Mobile apps, real-time |
| YOLO11s | ~22MB | Fast | Better | Balanced performance |
| YOLO11m | ~50MB | Medium | High | High-end devices |
| YOLO11l | ~87MB | Slow | Higher | Desktop/server |
| YOLO11x | ~136MB | Slowest | Highest | Research/analysis |

For mobile apps, **YOLO11n** is recommended for the best balance of speed and accuracy.

## 🛠️ Development

### Adding New Object Classes

To detect custom objects:

1. Train a custom YOLO11 model with your dataset
2. Export to TensorFlow Lite format
3. Update the `classNames` list in `ml_service_native.dart`
4. Replace the model file in `assets/`

### Modifying Detection Parameters

Edit these constants in `lib/ml_inference_module/ml_service_native.dart`:

```dart
static const double confidenceThreshold = 0.25;  // Lower = more detections
static const double iouThreshold = 0.45;         // Lower = less overlap filtering
static const int maxDetections = 300;            // Maximum objects per frame
```

## 📚 Additional Resources

- [Ultralytics YOLO11 Documentation](https://docs.ultralytics.com/)
- [TensorFlow Lite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [COCO Dataset Classes](https://cocodataset.org/#explore)
- [Flutter Camera Plugin](https://pub.dev/packages/camera)

## 🤝 Contributing

Feel free to contribute improvements:
- Better image preprocessing algorithms
- Additional post-processing features
- Performance optimizations
- New solution modes

## 📄 License

This project uses YOLO11 which is licensed under AGPL-3.0. Please ensure compliance with the license terms for your use case.