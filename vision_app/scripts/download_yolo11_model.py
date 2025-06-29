#!/usr/bin/env python3
"""
Script to download and convert YOLO11 model to TensorFlow Lite format.
This script requires ultralytics package to be installed.

Usage:
    pip install ultralytics
    python scripts/download_yolo11_model.py
"""

import os
import sys
from pathlib import Path

def download_and_convert_yolo11():
    try:
        from ultralytics import YOLO
        
        print("Downloading YOLO11 nano model...")
        
        # Load YOLO11 nano model (smallest and fastest)
        model = YOLO('yolo11n.pt')
        
        print("Converting to TensorFlow Lite format...")
        
        # Export to TensorFlow Lite
        model.export(
            format='tflite',
            imgsz=640,
            int8=False,  # Use float32 for better accuracy
            dynamic=False,
            simplify=True
        )
        
        # Move the generated file to assets directory
        assets_dir = Path(__file__).parent.parent / 'assets'
        assets_dir.mkdir(exist_ok=True)
        
        # Find the generated .tflite file
        tflite_files = list(Path('.').glob('yolo11n*.tflite'))
        if tflite_files:
            source_file = tflite_files[0]
            target_file = assets_dir / 'yolov11.tflite'
            
            # Remove existing file if it exists
            if target_file.exists():
                target_file.unlink()
            
            # Move the file
            source_file.rename(target_file)
            
            print(f"✅ YOLO11 model successfully saved to: {target_file}")
            print(f"📊 Model size: {target_file.stat().st_size / (1024*1024):.1f} MB")
            
            # Verify the file
            if target_file.stat().st_size > 1024:  # Should be larger than 1KB
                print("✅ Model file appears to be valid")
                return True
            else:
                print("❌ Model file seems too small, might be corrupted")
                return False
        else:
            print("❌ No .tflite file found after export")
            return False
            
    except ImportError:
        print("❌ ultralytics package not found!")
        print("Please install it using: pip install ultralytics")
        return False
    except Exception as e:
        print(f"❌ Error during model download/conversion: {e}")
        return False

def main():
    print("🚀 YOLO11 Model Download and Conversion Script")
    print("=" * 50)
    
    if download_and_convert_yolo11():
        print("\n🎉 Success! Your Flutter app is now ready to use YOLO11 object detection.")
        print("\nNext steps:")
        print("1. Run 'flutter clean' and 'flutter pub get'")
        print("2. Build and run your app")
        print("3. The app will now use the real YOLO11 model instead of mock detections")
    else:
        print("\n❌ Failed to download/convert YOLO11 model.")
        print("The app will continue to work with mock detections.")

if __name__ == "__main__":
    main()