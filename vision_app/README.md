# Vision App - YOLO11 Object Detection

A Flutter application for real-time object detection using YOLO11 (You Only Look Once version 11) with TensorFlow Lite.

## Quick Start

### 1. Setup YOLO11 Model

**Option A: Automatic Setup (Recommended)**
```bash
# Run the setup script
./scripts/setup_yolo11.sh
```

**Option B: Manual Setup**
```bash
# Install Python dependencies
pip install ultralytics

# Download and convert model
python scripts/download_yolo11_model.py
```

### 2. Run the App

```bash
flutter clean
flutter pub get
flutter run
```

## Features

- **Real-time object detection** with 80 COCO classes
- **Multiple solution modes:**
  - Object counting with custom counting lines
  - Security alarm with zone detection
  - Distance calculation between objects
  - Workout monitoring with pose detection
- **GPU acceleration** (Metal on iOS, GPU delegate on Android)
- **Performance benchmarking** and monitoring
- **Optimized for mobile** with efficient preprocessing

## Supported Objects

The app can detect 80 different object classes including:
- **People & Animals:** person, cat, dog, horse, bird, etc.
- **Vehicles:** car, bicycle, motorcycle, bus, truck, etc.
- **Everyday Objects:** bottle, chair, laptop, cell phone, etc.

See complete list in [YOLO11_SETUP.md](YOLO11_SETUP.md)

## Configuration

### Model Parameters
- **Input size:** 640x640 pixels
- **Confidence threshold:** 0.25
- **IoU threshold:** 0.45
- **Max detections:** 300

### Performance Settings
- **GPU acceleration:** Automatically enabled
- **Inference frequency:** Configurable in settings
- **Memory monitoring:** Built-in performance tracking

## Documentation

- [YOLO11 Setup Guide](YOLO11_SETUP.md) - Detailed setup instructions
- [Model Configuration](lib/ml_inference_module/ml_service_native.dart) - Technical details
- [Solution Modes](lib/app_shell/solutions/) - Different detection modes

## Development

### Project Structure
```
lib/
├── ml_inference_module/     # YOLO11 inference engine
├── camera_module/           # Camera management
├── ui_overlay_module/       # Detection visualization
├── app_shell/              # Main app structure
└── solution_*/             # Different detection modes
```

### Key Components
- **MLService:** Handles YOLO11 model loading and inference
- **CameraManager:** Manages camera stream and permissions
- **OverlayPainter:** Draws bounding boxes and labels
- **SolutionManager:** Coordinates different detection modes

## Troubleshooting

### Model Loading Issues
- Ensure `assets/yolov11.tflite` exists and is > 1MB
- Run the setup script to download a proper model
- Check console for detailed error messages

### Performance Issues
- Enable GPU acceleration in settings
- Reduce camera resolution if needed
- Monitor memory usage in benchmarking view

### Camera Issues
- Grant camera permissions
- Check device compatibility
- Restart app if camera fails to initialize

## Performance

The app is optimized for mobile devices:
- **YOLO11 Nano:** ~6MB model, 30+ FPS on modern devices
- **Efficient preprocessing:** YUV to RGB conversion with bilinear interpolation
- **Smart inference:** Configurable frequency to balance accuracy and performance
- **Memory management:** Automatic cleanup and monitoring

## Contributing

Contributions welcome! Areas for improvement:
- Additional object classes
- Better preprocessing algorithms
- New solution modes
- Performance optimizations

## License

This project uses YOLO11 which is licensed under AGPL-3.0. Please ensure compliance with license terms for your use case.

---

## Getting Started with Flutter

If this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)