#!/usr/bin/env python3
"""
Simple script to download YOLOv8 model and export to ONNX format.
This avoids TensorFlowJS dependency issues.
"""

import os
import sys
from pathlib import Path
from ultralytics import YOLO


def main():
    # Get script directory and set up paths
    script_dir = Path(__file__).parent
    vision_app_dir = script_dir.parent
    web_dir = vision_app_dir / "web"
    tfjs_model_dir = web_dir / "tfjs_model"
    
    # Create directories
    tfjs_model_dir.mkdir(parents=True, exist_ok=True)
    
    print("Downloading YOLOv8n model...")
    try:
        # Load YOLOv8n model (will download if not present)
        model = YOLO('yolov8n.pt')
        print("✓ YOLOv8n model downloaded successfully")
        
        # Export to ONNX
        print("Exporting to ONNX format...")
        onnx_path = model.export(format='onnx', dynamic=True)
        print(f"✓ ONNX model exported to: {onnx_path}")
        
        # Copy ONNX model to web directory
        import shutil
        target_onnx = tfjs_model_dir / "yolov8n.onnx"
        shutil.copy2(onnx_path, target_onnx)
        print(f"✓ ONNX model copied to: {target_onnx}")
        
        # Create a simple model info file
        model_info = {
            "name": "yolov8n",
            "format": "onnx",
            "input_size": [640, 640],
            "classes": 80,
            "description": "YOLOv8 nano model in ONNX format"
        }
        
        import json
        with open(tfjs_model_dir / "model_info.json", 'w') as f:
            json.dump(model_info, f, indent=2)
        
        print("\n🎉 Model setup complete!")
        print(f"Model location: {target_onnx}")
        print("You can now use ONNX.js or convert to TensorFlow.js manually if needed.")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
