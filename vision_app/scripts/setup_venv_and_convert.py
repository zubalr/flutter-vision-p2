#!/usr/bin/env python3
"""
Setup virtual environment and convert YOLOv11 to TensorFlow.js format
This script creates a virtual environment, installs dependencies, and performs the conversion
"""

import os
import sys
import subprocess
import json
import shutil
from pathlib import Path

def create_virtual_environment():
    """Create and setup virtual environment"""
    venv_path = "yolo_conversion_env"
    
    print("Creating virtual environment...")
    
    # Remove existing venv if it exists
    if os.path.exists(venv_path):
        print(f"Removing existing virtual environment: {venv_path}")
        shutil.rmtree(venv_path)
    
    # Create new virtual environment
    result = subprocess.run([sys.executable, "-m", "venv", venv_path], 
                          capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Failed to create virtual environment: {result.stderr}")
        return None
    
    print(f"✅ Virtual environment created: {venv_path}")
    return venv_path

def get_venv_python(venv_path):
    """Get the path to Python executable in virtual environment"""
    if sys.platform == "win32":
        return os.path.join(venv_path, "Scripts", "python.exe")
    else:
        return os.path.join(venv_path, "bin", "python")

def get_venv_pip(venv_path):
    """Get the path to pip executable in virtual environment"""
    if sys.platform == "win32":
        return os.path.join(venv_path, "Scripts", "pip")
    else:
        return os.path.join(venv_path, "bin", "pip")

def install_dependencies(venv_path):
    """Install required dependencies in virtual environment"""
    pip_path = get_venv_pip(venv_path)
    
    # List of packages to install
    packages = [
        "ultralytics",
        "onnx",
        "onnx2tf",
        "tensorflowjs",
        "tensorflow",
        "numpy",
        "opencv-python",
        "torch",
        "torchvision",
        "Pillow"
    ]
    
    print("Installing dependencies in virtual environment...")
    print("This may take a few minutes...")
    
    for package in packages:
        print(f"Installing {package}...")
        result = subprocess.run([pip_path, "install", package], 
                              capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Warning: Failed to install {package}: {result.stderr}")
            # Continue with other packages
        else:
            print(f"✅ {package} installed successfully")
    
    print("✅ All dependencies installation completed")

def download_yolo_model(venv_python):
    """Download YOLO model using ultralytics in virtual environment"""
    try:
        print("Downloading YOLO model...")
        
        # Create models directory
        os.makedirs("models", exist_ok=True)
        
        # Python code to download and export model
        python_code = '''
import os
import sys
from ultralytics import YOLO

def download_and_export():
    try:
        # Download YOLOv11n only
        print("Downloading YOLOv11n...")
        model = YOLO("yolo11n.pt")
        print("✅ YOLOv11n downloaded successfully")
        return model, "yolo11n"
    except Exception as e:
        print(f"YOLOv11n download failed: {e}")
        print("Please ensure you have internet connection and ultralytics is properly installed.")
        return None, None

def export_to_tfjs(model, model_name):
    try:
        print(f"Exporting {model_name} to TensorFlow.js...")
        
        # Try direct TensorFlow.js export first
        try:
            print("Attempting direct TF.js export...")
            tfjs_path = model.export(format="tfjs", imgsz=640)
            print(f"✅ Direct TF.js export successful: {tfjs_path}")
            return tfjs_path, "tfjs"
        except Exception as e:
            print(f"Direct TF.js export failed: {e}")
            
            # Fallback to SavedModel format
            try:
                print("Attempting SavedModel export...")
                saved_model_path = model.export(format="saved_model", imgsz=640)
                print(f"✅ SavedModel export successful: {saved_model_path}")
                return saved_model_path, "saved_model"
            except Exception as e2:
                print(f"SavedModel export failed: {e2}")
                
                # Fallback to ONNX format
                try:
                    print("Attempting ONNX export...")
                    onnx_path = model.export(format="onnx", imgsz=640)
                    print(f"✅ ONNX export successful: {onnx_path}")
                    return onnx_path, "onnx"
                except Exception as e3:
                    print(f"All export formats failed: {e3}")
                    return None, None
    except Exception as e:
        print(f"Export failed: {e}")
        return None, None

if __name__ == "__main__":
    model, model_name = download_and_export()
    if model:
        export_path, export_format = export_to_tfjs(model, model_name)
        if export_path:
            print(f"SUCCESS:{export_path}:{export_format}:{model_name}")
        else:
            print("EXPORT_FAILED")
    else:
        print("DOWNLOAD_FAILED")
'''
        
        # Write the Python code to a temporary file
        with open("temp_download.py", "w") as f:
            f.write(python_code)
        
        # Run the download script in virtual environment
        result = subprocess.run([venv_python, "temp_download.py"], 
                              capture_output=True, text=True)
        
        # Clean up temporary file
        if os.path.exists("temp_download.py"):
            os.remove("temp_download.py")
        
        if result.returncode != 0:
            print(f"Download script failed: {result.stderr}")
            return None, None, None
        
        # Parse the output
        lines = result.stdout.strip().split('\n')
        for line in lines:
            if line.startswith("SUCCESS:"):
                parts = line.split(":")
                if len(parts) >= 4:
                    return parts[1], parts[2], parts[3]  # path, format, model_name
        
        print("No success message found in output")
        return None, None, None
        
    except Exception as e:
        print(f"Error downloading model: {e}")
        return None, None, None

def convert_to_tfjs(export_path, export_format, model_name, venv_python):
    """Convert exported model to TensorFlow.js format"""
    try:
        output_dir = "../web/tfjs_model"
        os.makedirs(output_dir, exist_ok=True)
        
        if export_format == "tfjs":
            # Already in TF.js format, just move it
            print("Model already in TF.js format, copying...")
            if os.path.exists(output_dir):
                shutil.rmtree(output_dir)
            shutil.move(export_path, output_dir)
            return True
            
        elif export_format == "saved_model":
            # Convert SavedModel to TF.js
            print("Converting SavedModel to TF.js...")
            
            # Use tensorflowjs_converter
            python_code = f'''
import subprocess
import os

try:
    cmd = [
        "tensorflowjs_converter",
        "--input_format=tf_saved_model",
        "--output_format=tfjs_graph_model",
        "{export_path}",
        "{output_dir}"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print("CONVERSION_SUCCESS")
    else:
        print(f"CONVERSION_FAILED: {{result.stderr}}")
        
except Exception as e:
    print(f"CONVERSION_ERROR: {{e}}")
'''
            
            with open("temp_convert.py", "w") as f:
                f.write(python_code)
            
            result = subprocess.run([venv_python, "temp_convert.py"], 
                                  capture_output=True, text=True)
            
            if os.path.exists("temp_convert.py"):
                os.remove("temp_convert.py")
            
            return "CONVERSION_SUCCESS" in result.stdout
            
        elif export_format == "onnx":
            # Convert ONNX to TF.js (more complex)
            print("Converting ONNX to TF.js...")
            # For now, we'll skip this complex conversion and suggest using SavedModel
            print("ONNX conversion is complex. Please use SavedModel format instead.")
            return False
            
        return False
        
    except Exception as e:
        print(f"Error converting model: {e}")
        return False

def create_model_info(model_name):
    """Create model information file"""
    try:
        model_info = {
            "model_name": model_name,
            "description": f"{model_name} model for object detection",
            "input_size": [640, 640],
            "input_format": "RGB",
            "output_format": "YOLO format with 8400 detections",
            "classes": 80,
            "class_names": [
                "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat",
                "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat",
                "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack",
                "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball",
                "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
                "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
                "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake",
                "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop",
                "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
                "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
            ],
            "preprocessing": {
                "resize": [640, 640],
                "normalize": [0, 255],
                "format": "NCHW"
            }
        }
        
        with open("../web/tfjs_model/model_info.json", "w") as f:
            json.dump(model_info, f, indent=2)
        
        print("✅ Created model_info.json")
        return True
        
    except Exception as e:
        print(f"Error creating model info: {e}")
        return False

def main():
    """Main function"""
    print("🚀 YOLO to TensorFlow.js Converter with Virtual Environment")
    print("=" * 60)
    
    try:
        # Step 1: Create virtual environment
        venv_path = create_virtual_environment()
        if not venv_path:
            print("❌ Failed to create virtual environment")
            return 1
        
        # Step 2: Install dependencies
        install_dependencies(venv_path)
        
        # Get paths to executables in virtual environment
        venv_python = get_venv_python(venv_path)
        
        # Step 3: Download and export model
        export_path, export_format, model_name = download_yolo_model(venv_python)
        
        if not export_path:
            print("❌ Failed to download and export model")
            return 1
        
        print(f"✅ Model exported: {export_path} (format: {export_format})")
        
        # Step 4: Convert to TensorFlow.js if needed
        if export_format != "tfjs":
            success = convert_to_tfjs(export_path, export_format, model_name, venv_python)
            if not success:
                print("❌ Failed to convert to TensorFlow.js")
                return 1
        
        # Step 5: Create model info
        create_model_info(model_name)
        
        # Step 6: List output files
        output_dir = "../web/tfjs_model"
        if os.path.exists(output_dir):
            print(f"\n📁 Files in {output_dir}:")
            for file in os.listdir(output_dir):
                file_path = os.path.join(output_dir, file)
                size = os.path.getsize(file_path) if os.path.isfile(file_path) else 0
                print(f"  - {file} ({size:,} bytes)")
        
        print("\n🎉 SUCCESS! Model conversion completed!")
        print("🚀 Ready for web inference!")
        print(f"\n💡 Virtual environment created at: {venv_path}")
        print("💡 You can reuse this environment for future conversions")
        
        return 0
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1
    
    except KeyboardInterrupt:
        print("\n⚠️  Operation cancelled by user")
        return 1

if __name__ == "__main__":
    sys.exit(main())
