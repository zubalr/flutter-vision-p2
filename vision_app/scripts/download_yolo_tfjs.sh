#!/bin/bash

# Download pre-trained YOLOv5s model converted to TensorFlow.js
echo "Downloading pre-trained YOLOv5s model for TensorFlow.js..."

# Create model directory
mkdir -p web/tfjs_model

# Download YOLOv5s model files (these are publicly available)
cd web/tfjs_model

# Download model.json
curl -L -o model.json "https://raw.githubusercontent.com/zldrobit/tfjs-yolov5-example/master/src/assets/yolov5s_web_model/model.json"

# Download weight files (these need to be downloaded separately)
echo "Downloading model weights..."
for i in {1..4}; do
    curl -L -o "group${i}-shard1of1.bin" "https://github.com/zldrobit/tfjs-yolov5-example/raw/master/src/assets/yolov5s_web_model/group${i}-shard1of1.bin"
done

echo "Model download completed!"
echo "Model files are now available in web/tfjs_model/"

# Create model info file
cat > model_info.json << EOF
{
  "name": "YOLOv5s",
  "input_size": [640, 640],
  "num_classes": 80,
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
EOF

cd ../..
echo "Setup completed!"
