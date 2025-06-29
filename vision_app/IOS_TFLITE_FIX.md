# iOS TensorFlow Lite dylib Fix Guide

## Problem
The app crashes on iOS with the error:
```
Library not loaded: @rpath/Runner.debug.dylib
Referenced from: Runner.app/Runner
Reason: tried: '/usr/lib/system/introspection/Runner.debug.dylib' (no such file)
```

This is a common issue with TensorFlow Lite on iOS related to dynamic library loading and framework embedding.

## Root Cause
1. **TensorFlow Lite C++ dependencies** not properly linked
2. **Framework search paths** not configured correctly
3. **Bitcode enabled** (incompatible with TensorFlow Lite)
4. **Missing runtime search paths** for dynamic libraries
5. **Incorrect build settings** for iOS deployment

## Solution Applied

### 1. Updated Podfile Configuration
- **Disabled Bitcode**: `ENABLE_BITCODE = 'NO'`
- **Added C++ linking**: `-lc++` flag
- **Configured runtime paths**: `@executable_path/Frameworks`, `@loader_path/Frameworks`
- **Embedded Swift libraries**: `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = 'YES'`
- **Optimized TensorFlow Lite targets**: Specific build settings for TF Lite

### 2. Enhanced ML Service Implementation
- **Robust model loading** with iOS-specific optimizations
- **Metal GPU delegate** for iOS acceleration
- **Comprehensive error handling** with detailed troubleshooting
- **No mock detections** - requires real YOLO11 model
- **Input validation** for YOLO11 format compliance

### 3. Build Configuration
- **iOS deployment target**: 13.0+
- **Architecture support**: arm64, x86_64 (no i386)
- **Debug information**: Preserved for TensorFlow Lite
- **Dead code stripping**: Disabled to prevent library issues

## Quick Fix Commands

### Option 1: Automated Fix
```bash
# Run the comprehensive iOS fix script
./scripts/fix_ios_dylib.sh
```

### Option 2: Manual Steps
```bash
# 1. Clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/build

# 2. Get dependencies
flutter pub get

# 3. Reinstall pods
cd ios
pod deintegrate
pod install --repo-update
cd ..

# 4. Build
flutter build ios --debug --no-codesign
```

## Required Model Setup

**CRITICAL**: The app now requires a real YOLO11 model and will NOT run with mock detections.

```bash
# Download real YOLO11 model
./scripts/setup_yolo11.sh

# Or manually
pip install ultralytics
python scripts/download_yolo11_model.py
```

## Verification Steps

1. **Check model file**:
   ```bash
   ls -la assets/yolov11.tflite
   # Should be > 5MB, not 18 bytes
   ```

2. **Verify iOS build**:
   ```bash
   flutter build ios --debug --no-codesign
   # Should complete without errors
   ```

3. **Test on device/simulator**:
   ```bash
   flutter run
   # Should load model and run real inference
   ```

## Expected Console Output

### Successful Model Loading
```
Initializing YOLO11 TensorFlow Lite model...
Configuring for iOS platform...
iOS Metal GPU delegate configured
Loading model from assets/yolov11.tflite...
Model uses NHWC format (Height-Width-Channels)
SUCCESS: YOLO11 model loaded on iOS
Model input shape: [1, 640, 640, 3]
Model output shape: [1, 84, 8400]
GPU acceleration: enabled
```

### Model Loading Failure
```
CRITICAL ERROR: Failed to load YOLO11 model
Error details: Unable to load asset: "yolov11.tflite"
TROUBLESHOOTING STEPS:
1. Check if assets/yolov11.tflite exists
2. Verify file size is > 5MB (not a placeholder)
...
```

## Troubleshooting

### If Build Still Fails

1. **Update Xcode** to latest version (14+)
2. **Check iOS deployment target** in Xcode project settings
3. **Clear derived data**: Xcode > Preferences > Locations > Derived Data > Delete
4. **Try different simulator** or real device
5. **Update CocoaPods**: `sudo gem install cocoapods`

### If Model Loading Fails

1. **Download real model**: `./scripts/setup_yolo11.sh`
2. **Check file size**: `ls -la assets/yolov11.tflite`
3. **Verify format**: Should be TensorFlow Lite (.tflite)
4. **Check console logs** for detailed error messages

### If App Crashes on Launch

1. **Check iOS version**: Requires iOS 13.0+
2. **Verify camera permissions** in iOS Settings
3. **Try without GPU**: Disable GPU acceleration in settings
4. **Check memory usage**: YOLO11 requires ~14MB RAM

## Performance Optimization

### iOS-Specific Settings
- **Metal GPU acceleration**: Enabled by default
- **Thread count**: Optimized to 2 for mobile
- **Precision loss**: Allowed for better performance
- **Memory management**: Automatic cleanup

### Expected Performance
- **Model size**: ~6MB (YOLO11 nano)
- **Inference time**: 30-100ms on modern devices
- **Memory usage**: ~14MB peak
- **FPS**: 10-30 depending on device

## Key Changes Made

### 1. Podfile Updates
- Added comprehensive TensorFlow Lite build settings
- Fixed framework embedding and runtime paths
- Disabled problematic build optimizations

### 2. ML Service Enhancements
- iOS-specific Metal GPU delegate configuration
- Robust error handling and validation
- Removed dependency on mock detections

### 3. Build Configuration
- Optimized for TensorFlow Lite compatibility
- Enhanced debugging and error reporting
- Proper architecture and deployment settings

## Next Steps

1. **Run the fix script**: `./scripts/fix_ios_dylib.sh`
2. **Download YOLO11 model**: `./scripts/setup_yolo11.sh`
3. **Test on iOS device**: `flutter run`
4. **Verify real-time detection** works properly

The app will now use real TensorFlow Lite inference on iOS without dylib loading issues!