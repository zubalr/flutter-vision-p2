#!/usr/bin/env python3
"""
Simple YOLOv11 Download and Export Script
Downloads YOLOv11n model and exports to various formats for web use
"""

import os
import subprocess
import sys
import json
import shutil

def install_ultralytics():
    """Install ultralytics if not available"""
    try:
        import ultralytics
        print("✅ Ultralytics already installed")
        return True
    except ImportError:
        print("Installing ultralytics...")
        try:
            subprocess.run([sys.executable, "-m", "pip", "install", "ultralytics"], 
                         check=True, capture_output=True)
            print("✅ Ultralytics installed successfully")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to install ultralytics: {e}")
            return False

def download_and_export_yolo11():
    """Download YOLOv11n and export to web-compatible formats"""
    try:
        from ultralytics import YOLO
        print("Downloading YOLOv11n model...")
        
        # Download YOLOv11n model
        model = YOLO("yolo11n.pt")
        print("YOLOv11n downloaded successfully!")
        
        # Create output directories
        os.makedirs("web/tfjs_model", exist_ok=True)
        os.makedirs("assets", exist_ok=True)
        
        # Try different export formats for compatibility
        export_results = {}
        
        # 1. Export to ONNX format (best for web)
        try:
            print("Exporting to ONNX format...")
            onnx_path = model.export(format="onnx", imgsz=640, simplify=True)
            export_results["onnx"] = onnx_path
            print(f"ONNX export successful: {onnx_path}")
            
            # Copy ONNX file to web directory
            if os.path.exists(onnx_path):
                shutil.copy2(onnx_path, "web/tfjs_model/model.onnx")
                print("ONNX model copied to web/tfjs_model/")
        except Exception as e:
            print(f"ONNX export failed: {e}")
        
        # 2. Export to TensorFlow.js format
        try:
            print("Exporting to TensorFlow.js format...")
            tfjs_path = model.export(format="tfjs", imgsz=640)
            export_results["tfjs"] = tfjs_path
            print(f"TensorFlow.js export successful: {tfjs_path}")
            
            # Copy TF.js files to web directory
            if os.path.exists(tfjs_path):
                if os.path.isdir(tfjs_path):
                    # Copy model.json and .bin files
                    for file in os.listdir(tfjs_path):
                        if file.endswith(('.json', '.bin')):
                            src = os.path.join(tfjs_path, file)
                            dst = os.path.join("web/tfjs_model", file)
                            shutil.copy2(src, dst)
                    print("TensorFlow.js model files copied to web/tfjs_model/")
        except Exception as e:
            print(f"TensorFlow.js export failed: {e}")
        
        # 3. Export to TensorFlow Lite for mobile
        try:
            print("Exporting to TensorFlow Lite format...")
            tflite_path = model.export(format="tflite", imgsz=640, int8=False)
            export_results["tflite"] = tflite_path
            print(f"TensorFlow Lite export successful: {tflite_path}")
            
            # Copy TFLite file to assets directory
            if os.path.exists(tflite_path):
                shutil.copy2(tflite_path, "assets/yolov11.tflite")
                print("TensorFlow Lite model copied to assets/")
        except Exception as e:
            print(f"TensorFlow Lite export failed: {e}")
        
        # 4. Create model info file
        model_info = {
            "model_name": "yolo11n",
            "input_size": [640, 640],
            "num_classes": 80,
            "output_shape": [1, 84, 8400],
            "exports": export_results,
            "classes": [
                "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck",
                "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
                "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra",
                "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
                "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
                "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup",
                "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange",
                "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch",
                "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse",
                "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
                "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier",
                "toothbrush"
            ]
        }
        
        with open("web/tfjs_model/model_info.json", "w") as f:
            json.dump(model_info, f, indent=2)
        
        print("Model info saved to web/tfjs_model/model_info.json")
        
        # List what we have
        print("\nFiles created:")
        if os.path.exists("web/tfjs_model"):
            for file in os.listdir("web/tfjs_model"):
                file_path = os.path.join("web/tfjs_model", file)
                if os.path.isfile(file_path):
                    size = os.path.getsize(file_path) / (1024 * 1024)
                    print(f"  web/tfjs_model/{file} ({size:.1f} MB)")
        
        if os.path.exists("assets"):
            for file in os.listdir("assets"):
                if file.endswith('.tflite'):
                    file_path = os.path.join("assets", file)
                    size = os.path.getsize(file_path) / (1024 * 1024)
                    print(f"  assets/{file} ({size:.1f} MB)")
        
        return True
        
    except Exception as e:
        print(f"Failed to download/export YOLOv11: {e}")
        return False

def main():
    print("YOLOv11 Download and Export for Flutter Vision App")
    print("=" * 60)
    
    # Change to script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    os.chdir(project_dir)
    print(f"Working directory: {os.getcwd()}")
    
    # Install ultralytics
    if not install_ultralytics():
        print("Cannot proceed without ultralytics")
        return False
    
    # Download and export model
    if download_and_export_yolo11():
        print("\nSUCCESS! YOLOv11n model is ready for use")
        print("\nNext steps:")
        print("1. Run: flutter clean && flutter pub get")
        print("2. For web: flutter run -d chrome")
        print("3. For iOS: ./scripts/fix_ios_complete.sh")
        print("4. For iOS run: flutter run")
        return True
    else:
        print("\nFailed to prepare YOLOv11 model")
        print("Check the error messages above")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
