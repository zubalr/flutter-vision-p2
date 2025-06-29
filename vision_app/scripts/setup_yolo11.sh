#!/bin/bash

# YOLO11 Setup Script for Flutter Object Detection App
# This script downloads and sets up the YOLO11 model for the Flutter app

echo "🚀 Setting up YOLO11 for Flutter Object Detection"
echo "=================================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    echo "Please install Python 3 and try again."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required but not installed."
    echo "Please install pip3 and try again."
    exit 1
fi

echo "✅ Python 3 and pip3 found"

# Install ultralytics if not already installed
echo "📦 Installing/updating ultralytics..."
pip3 install ultralytics --upgrade

if [ $? -ne 0 ]; then
    echo "❌ Failed to install ultralytics"
    echo "Please check your internet connection and try again."
    exit 1
fi

echo "✅ ultralytics installed successfully"

# Run the Python script to download and convert the model
echo "⬬ Downloading and converting YOLO11 model..."
python3 scripts/download_yolo11_model.py

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 YOLO11 setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Run: flutter clean"
    echo "2. Run: flutter pub get"
    echo "3. Run: flutter run"
    echo ""
    echo "Your app will now use real YOLO11 object detection! 🚀"
else
    echo ""
    echo "❌ YOLO11 setup failed"
    echo "The app will still work with mock detections."
    echo "Check the error messages above for troubleshooting."
fi