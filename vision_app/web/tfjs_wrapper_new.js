// TensorFlow.js wrapper for Flutter web - YOLO implementation
class TFJSWrapper {
  constructor() {
    this.model = null;
    this.isLoaded = false;
    this.inputSize = 640;
    this.classes = [
      'person',
      'bicycle',
      'car',
      'motorcycle',
      'airplane',
      'bus',
      'train',
      'truck',
      'boat',
      'traffic light',
      'fire hydrant',
      'stop sign',
      'parking meter',
      'bench',
      'bird',
      'cat',
      'dog',
      'horse',
      'sheep',
      'cow',
      'elephant',
      'bear',
      'zebra',
      'giraffe',
      'backpack',
      'umbrella',
      'handbag',
      'tie',
      'suitcase',
      'frisbee',
      'skis',
      'snowboard',
      'sports ball',
      'kite',
      'baseball bat',
      'baseball glove',
      'skateboard',
      'surfboard',
      'tennis racket',
      'bottle',
      'wine glass',
      'cup',
      'fork',
      'knife',
      'spoon',
      'bowl',
      'banana',
      'apple',
      'sandwich',
      'orange',
      'broccoli',
      'carrot',
      'hot dog',
      'pizza',
      'donut',
      'cake',
      'chair',
      'couch',
      'potted plant',
      'bed',
      'dining table',
      'toilet',
      'tv',
      'laptop',
      'mouse',
      'remote',
      'keyboard',
      'cell phone',
      'microwave',
      'oven',
      'toaster',
      'sink',
      'refrigerator',
      'book',
      'clock',
      'vase',
      'scissors',
      'teddy bear',
      'hair drier',
      'toothbrush',
    ];
  }

  async loadModel(modelUrl, useGpu = false) {
    try {
      console.log('Loading YOLO model from:', modelUrl);

      // Set backend
      if (useGpu) {
        await tf.setBackend('webgl');
      } else {
        await tf.setBackend('cpu');
      }

      // Load the YOLO model
      this.model = await tf.loadGraphModel(modelUrl);
      this.isLoaded = true;

      console.log('YOLO model loaded successfully');
      console.log('Model input shape:', this.model.inputs[0].shape);
      console.log('Model output shape:', this.model.outputs[0].shape);

      return true;
    } catch (error) {
      console.error('Error loading YOLO model:', error);
      this.isLoaded = false;
      return false;
    }
  }

  preprocessImage(imageElement) {
    return tf.tidy(() => {
      // Convert image to tensor
      let tensor = tf.browser.fromPixels(imageElement);

      // Resize to model input size (640x640)
      tensor = tf.image.resizeBilinear(tensor, [
        this.inputSize,
        this.inputSize,
      ]);

      // Normalize to [0, 1]
      tensor = tensor.div(255.0);

      // Add batch dimension
      tensor = tensor.expandDims(0);

      return tensor;
    });
  }

  async runObjectDetection(imageElement) {
    if (!this.isLoaded || !this.model) {
      console.warn('YOLO model not loaded');
      return [];
    }

    try {
      return tf.tidy(() => {
        // Preprocess image
        const inputTensor = this.preprocessImage(imageElement);

        // Run inference
        const predictions = this.model.predict(inputTensor);

        // Get prediction data
        const predData = predictions.dataSync();

        // Post-process YOLO predictions
        const detections = this.postProcessYOLO(
          predData,
          imageElement.width,
          imageElement.height
        );

        return detections;
      });
    } catch (error) {
      console.error('Error during YOLO inference:', error);
      return [];
    }
  }

  postProcessYOLO(
    predictions,
    originalWidth,
    originalHeight,
    confidenceThreshold = 0.5,
    iouThreshold = 0.4
  ) {
    const detections = [];

    // YOLO output format: [batch, 25200, 85] where 85 = 4 (bbox) + 1 (conf) + 80 (classes)
    const numDetections = 25200; // For 640x640 input
    const numClasses = 80;

    for (let i = 0; i < numDetections; i++) {
      const offset = i * (4 + 1 + numClasses);

      // Extract bbox coordinates (center format)
      const x_center = predictions[offset];
      const y_center = predictions[offset + 1];
      const width = predictions[offset + 2];
      const height = predictions[offset + 3];
      const confidence = predictions[offset + 4];

      if (confidence > confidenceThreshold) {
        // Find the class with highest probability
        let maxClassIndex = 0;
        let maxClassScore = 0;

        for (let j = 0; j < numClasses; j++) {
          const classScore = predictions[offset + 5 + j] * confidence;
          if (classScore > maxClassScore) {
            maxClassScore = classScore;
            maxClassIndex = j;
          }
        }

        if (maxClassScore > confidenceThreshold) {
          // Convert from center format to corner format
          const x1 = (x_center - width / 2) / this.inputSize;
          const y1 = (y_center - height / 2) / this.inputSize;
          const x2 = (x_center + width / 2) / this.inputSize;
          const y2 = (y_center + height / 2) / this.inputSize;

          // Scale to original image size
          const scaledX1 = x1 * originalWidth;
          const scaledY1 = y1 * originalHeight;
          const scaledWidth = (x2 - x1) * originalWidth;
          const scaledHeight = (y2 - y1) * originalHeight;

          detections.push({
            boundingBox: {
              left: scaledX1,
              top: scaledY1,
              width: scaledWidth,
              height: scaledHeight,
            },
            confidence: maxClassScore,
            classIndex: maxClassIndex,
            className: this.classes[maxClassIndex] || 'unknown',
          });
        }
      }
    }

    // Apply Non-Maximum Suppression
    return this.applyNMS(detections, iouThreshold);
  }

  applyNMS(detections, iouThreshold) {
    // Sort by confidence (descending)
    detections.sort((a, b) => b.confidence - a.confidence);

    const keep = [];
    const suppressed = new Set();

    for (let i = 0; i < detections.length; i++) {
      if (suppressed.has(i)) continue;

      keep.push(detections[i]);

      for (let j = i + 1; j < detections.length; j++) {
        if (suppressed.has(j)) continue;

        const iou = this.calculateIoU(
          detections[i].boundingBox,
          detections[j].boundingBox
        );
        if (iou > iouThreshold) {
          suppressed.add(j);
        }
      }
    }

    return keep;
  }

  calculateIoU(box1, box2) {
    const x1 = Math.max(box1.left, box2.left);
    const y1 = Math.max(box1.top, box2.top);
    const x2 = Math.min(box1.left + box1.width, box2.left + box2.width);
    const y2 = Math.min(box1.top + box1.height, box2.top + box2.height);

    if (x2 <= x1 || y2 <= y1) return 0;

    const intersection = (x2 - x1) * (y2 - y1);
    const area1 = box1.width * box1.height;
    const area2 = box2.width * box2.height;
    const union = area1 + area2 - intersection;

    return intersection / union;
  }

  dispose() {
    if (this.model) {
      this.model.dispose();
      this.model = null;
    }
    this.isLoaded = false;
  }
}

// Make it globally available
window.TFJSWrapper = TFJSWrapper;
