#!/usr/bin/env python3
"""
Convert YOLO11 TFLite model to TensorFlow.js format
"""

import os
import sys
import subprocess
import urllib.request
import json

def install_dependencies():
    """Install required dependencies for conversion"""
    try:
        print("Installing tensorflowjs...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "tensorflowjs", "--quiet"])
        print("Installing tensorflow...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "tensorflow", "--quiet"])
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error installing dependencies: {e}")
        return False

def download_onnx_yolo11():
    """Download a pre-trained YOLO11 model in ONNX format"""
    try:
        # Download YOLO11n (nano) model which is smaller and good for web
        model_url = "https://github.com/ultralytics/assets/releases/download/v8.3.0/yolo11n.onnx"
        output_path = "./yolo11n.onnx"
        
        if not os.path.exists(output_path):
            print("Downloading YOLO11n ONNX model...")
            urllib.request.urlretrieve(model_url, output_path)
            print(f"Downloaded model to: {output_path}")
        else:
            print(f"Model already exists: {output_path}")
        
        return output_path
    except Exception as e:
        print(f"Error downloading model: {e}")
        return None

def convert_onnx_to_tfjs():
    """Convert ONNX model to TensorFlow.js"""
    try:
        onnx_path = download_onnx_yolo11()
        if not onnx_path:
            return False
            
        # Install onnx2tf for conversion
        print("Installing onnx2tf...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "onnx2tf", "--quiet"])
        
        # Convert ONNX to TensorFlow SavedModel first
        print("Converting ONNX to TensorFlow SavedModel...")
        subprocess.check_call([
            "onnx2tf", 
            "-i", onnx_path,
            "-o", "./saved_model",
            "--verbosity", "error"
        ])
        
        # Convert SavedModel to TensorFlow.js
        print("Converting SavedModel to TensorFlow.js...")
        subprocess.check_call([
            "tensorflowjs_converter",
            "--input_format=tf_saved_model",
            "--output_format=tfjs_graph_model",
            "--quantize_float16",
            "./saved_model",
            "../web/tfjs_model"
        ])
        
        print("Conversion completed successfully!")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error during conversion: {e}")
        return False
    except Exception as e:
        print(f"Unexpected error: {e}")
        return False

def create_model_info():
    """Create model information file"""
    model_info = {
        "name": "YOLO11n",
        "input_size": [640, 640],
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
    
    with open("../web/tfjs_model/model_info.json", "w") as f:
        json.dump(model_info, f, indent=2)

if __name__ == "__main__":
    print("YOLO11 to TensorFlow.js Converter")
    print("=================================")
    
    # Install dependencies
    if not install_dependencies():
        print("Failed to install dependencies")
        sys.exit(1)
    
    # Convert model
    if convert_onnx_to_tfjs():
        create_model_info()
        print("\n✅ Conversion completed successfully!")
        print("📁 Model files are now available in ../web/tfjs_model/")
    else:
        print("\n❌ Conversion failed")
        sys.exit(1)
