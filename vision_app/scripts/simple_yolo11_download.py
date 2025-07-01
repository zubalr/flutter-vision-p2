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
        print("🚀 Downloading YOLOv11n model...")
        
        # Download YOLOv11n model
        model = YOLO("yolo11n.pt")
        print("✅ YOLOv11n downloaded successfully!")
        
        # Create output directories
        os.makedirs("web/tfjs_model", exist_ok=True)
        
        # Try different export formats for web compatibility
        export_results = {}
        
        # 1. Try ONNX export (most compatible)
        try:
            print("📦 Exporting to ONNX format...")
            onnx_path = model.export(format="onnx", imgsz=640)
            export_results["onnx"] = onnx_path
            print(f"✅ ONNX export successful: {onnx_path}")
            
            # Copy ONNX file to web directory
            if os.path.exists(onnx_path):
                shutil.copy2(onnx_path, "web/tfjs_model/model.onnx")
                print("✅ ONNX model copied to web/tfjs_model/")
        except Exception as e:
            print(f"⚠️  ONNX export failed: {e}")
        
        # 2. Try TensorFlow.js export
        try:
            print("🌐 Exporting to TensorFlow.js format...")
            tfjs_path = model.export(format="tfjs", imgsz=640)
            export_results["tfjs"] = tfjs_path
            print(f"✅ TensorFlow.js export successful: {tfjs_path}")
            
            # Copy TF.js files to web directory
            if os.path.exists(tfjs_path):
                if os.path.isdir(tfjs_path):
                    # Copy entire directory
                    dest_dir = "web/tfjs_model"
                    if os.path.exists(dest_dir):
                        shutil.rmtree(dest_dir)
                    shutil.copytree(tfjs_path, dest_dir)
                    print("✅ TensorFlow.js model copied to web/tfjs_model/")
        except Exception as e:
            print(f"⚠️  TensorFlow.js export failed: {e}")
        
        # 3. Create model info file
        model_info = {
            "model_name": "yolo11n",
            "input_size": [640, 640],
            "num_classes": 80,
            "exports": export_results,
            "created_at": str(subprocess.run(["date"], capture_output=True, text=True).stdout.strip())
        }
        
        with open("web/tfjs_model/model_info.json", "w") as f:
            json.dump(model_info, f, indent=2)
        
        print("✅ Model info saved to web/tfjs_model/model_info.json")
        
        # List what we have
        print("\n📁 Files in web/tfjs_model/:")
        if os.path.exists("web/tfjs_model"):
            for file in os.listdir("web/tfjs_model"):
                file_path = os.path.join("web/tfjs_model", file)
                if os.path.isfile(file_path):
                    size = os.path.getsize(file_path)
                    print(f"  {file} ({size} bytes)")
                else:
                    print(f"  {file}/ (directory)")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to download/export YOLOv11: {e}")
        return False

def main():
    print("🎯 Simple YOLOv11 Download and Export")
    print("=" * 50)
    
    # Change to script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    os.chdir(project_dir)
    print(f"Working directory: {os.getcwd()}")
    
    # Install ultralytics
    if not install_ultralytics():
        print("❌ Cannot proceed without ultralytics")
        return False
    
    # Download and export model
    if download_and_export_yolo11():
        print("\n🎉 Success! YOLOv11n model is ready for web use")
        print("Files are available in web/tfjs_model/")
        return True
    else:
        print("\n❌ Failed to prepare YOLOv11 model")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
