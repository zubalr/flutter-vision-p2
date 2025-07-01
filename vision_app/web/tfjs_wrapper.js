// YOLO Model Wrapper for Flutter web - Supports ONNX and TensorFlow.js
class TFJSWrapper {
  constructor() {
    this.model = null;
    this.isLoaded = false;
    this.inputSize = 640;
    this.session = null;
    this.backend = null; // 'onnx' or 'tfjs'
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

  async loadModel(modelUrl = null, useGpu = false) {
    try {
      console.log('Loading YOLO model...');
      
      // Check if required libraries are available
      if (typeof ort === 'undefined' && typeof tf === 'undefined') {
        console.error('Neither ONNX Runtime nor TensorFlow.js is available');
        return false;
      }

      // Try ONNX first (more efficient for web)
      if (typeof ort !== 'undefined' && await this.loadONNXModel()) {
        return true;
      }

      // Fallback to TensorFlow.js
      if (typeof tf !== 'undefined' && await this.loadTensorFlowJSModel(modelUrl, useGpu)) {
        return true;
      }

      console.error('Failed to load any model format');
      return false;
    } catch (error) {
      console.error('Error in loadModel:', error);
      return false;
    }
  }

  async loadONNXModel() {
    try {
      // Check if ONNX.js is available
      if (typeof ort === 'undefined') {
        console.log('ONNX Runtime Web not available');
        return false;
      }
      
      // Wait a bit for ONNX Runtime to fully initialize
      await new Promise(resolve => setTimeout(resolve, 100));

      console.log('Attempting to load ONNX model...');
      const modelUrl = './tfjs_model/model.onnx';
      console.log('ONNX Model URL:', modelUrl);

      const response = await fetch(modelUrl);
      if (!response.ok) {
        console.log(
          `ONNX model not found at ${modelUrl} (status: ${response.status}), falling back to TensorFlow.js`
        );
        return false;
      }

      console.log('ONNX model file found, loading...');
      const arrayBuffer = await response.arrayBuffer();

      // Configure ONNX session options with better providers
      const sessionOptions = {
        executionProviders: ['webgl', 'wasm', 'cpu'],
        logSeverityLevel: 2, // Reduce logging
        logVerbosityLevel: 0,
        graphOptimizationLevel: 'all',
      };

      this.session = await ort.InferenceSession.create(
        arrayBuffer,
        sessionOptions
      );
      this.backend = 'onnx';
      this.isLoaded = true;

      console.log('ONNX model loaded successfully');
      console.log('Model inputs:', this.session.inputNames);
      console.log('Model outputs:', this.session.outputNames);
      
      // Safely access metadata
      try {
        if (this.session.inputNames.length > 0) {
          const inputName = this.session.inputNames[0];
          console.log('Input shape:', this.session.inputMetadata[inputName]?.dims || 'unknown');
        }
        if (this.session.outputNames.length > 0) {
          const outputName = this.session.outputNames[0];
          console.log('Output shape:', this.session.outputMetadata[outputName]?.dims || 'unknown');
        }
      } catch (metaError) {
        console.log('Could not access metadata, but model loaded successfully');
      }

      // Test inference with dummy data to ensure model works
      try {
        console.log('Testing ONNX model with dummy input...');
        const dummyInput = new Float32Array(1 * 3 * 640 * 640).fill(0.5);
        const dummyTensor = new ort.Tensor('float32', dummyInput, [1, 3, 640, 640]);
        const feeds = {};
        feeds[this.session.inputNames[0]] = dummyTensor;
        
        const testResults = await this.session.run(feeds);
        console.log('ONNX model test successful, output shape:', testResults[this.session.outputNames[0]].dims);
      } catch (testError) {
        console.warn('ONNX model test failed:', testError);
        // Continue anyway, might work with real data
      }

      return true;
    } catch (error) {
      console.log('ONNX loading failed:', error);
      return false;
    }
  }

  async loadONNXRuntime() {
    try {
      // Load ONNX Runtime Web from CDN
      const script = document.createElement('script');
      script.src =
        'https://cdn.jsdelivr.net/npm/onnxruntime-web/dist/ort.min.js';
      document.head.appendChild(script);

      // Wait for script to load
      await new Promise((resolve, reject) => {
        script.onload = resolve;
        script.onerror = reject;
      });

      console.log('ONNX Runtime Web loaded successfully');
    } catch (error) {
      console.error('Failed to load ONNX Runtime:', error);
      throw error;
    }
  }

  async loadTensorFlowJSModel(modelUrl = null, useGpu = false) {
    try {
      console.log('Attempting to load TensorFlow.js model...');
      const url = modelUrl || './tfjs_model/model.json';
      console.log('Model URL:', url);

      // Check if model.json exists
      const response = await fetch(url);
      if (!response.ok) {
        console.log(`TensorFlow.js model not found at ${url} (status: ${response.status})`);
        return false;
      }

      console.log('TensorFlow.js model file found, loading...');

      // Set backend with better error handling
      if (useGpu) {
        try {
          await tf.setBackend('webgl');
          await tf.ready();
          console.log('Using WebGL backend for GPU acceleration');
        } catch (e) {
          console.log('WebGL not available, trying WASM backend');
          try {
            await tf.setBackend('wasm');
            await tf.ready();
            console.log('Using WASM backend');
          } catch (wasmError) {
            console.log('WASM not available, falling back to CPU');
            await tf.setBackend('cpu');
            await tf.ready();
            console.log('Using CPU backend');
          }
        }
      } else {
        try {
          await tf.setBackend('wasm');
          await tf.ready();
          console.log('Using WASM backend');
        } catch (wasmError) {
          await tf.setBackend('cpu');
          await tf.ready();
          console.log('Using CPU backend');
        }
      }

      // Load the YOLO model
      try {
        this.model = await tf.loadGraphModel(url);
        this.backend = 'tfjs';
        this.isLoaded = true;

        console.log('TensorFlow.js model loaded successfully');
        console.log('Model input shape:', this.model.inputs[0].shape);
        console.log('Model output shape:', this.model.outputs[0].shape);
        console.log('Backend:', tf.getBackend());

        // Test the model with dummy data
        try {
          console.log('Testing TensorFlow.js model...');
          const dummyInput = tf.zeros([1, 640, 640, 3]);
          const testOutput = this.model.predict(dummyInput);
          console.log('TensorFlow.js model test successful, output shape:', testOutput.shape);
          dummyInput.dispose();
          testOutput.dispose();
        } catch (testError) {
          console.warn('TensorFlow.js model test failed:', testError);
        }

        return true;
      } catch (loadError) {
        console.error('Error loading TensorFlow.js model:', loadError);
        console.log('Model URL:', url);
        
        // Try to get more details about the error
        if (loadError.message) {
          console.log('Error message:', loadError.message);
        }
        
        return false;
      }
    } catch (error) {
      console.log('TensorFlow.js setup failed:', error);
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
    if (!this.isLoaded) {
      console.warn('YOLO model not loaded');
      return [];
    }

    if (!imageElement) {
      console.warn('No image element provided for inference');
      return [];
    }

    try {
      console.log('Running inference with backend:', this.backend);

      if (this.backend === 'onnx') {
        return await this.runONNXInference(imageElement);
      } else if (this.backend === 'tfjs') {
        return await this.runTensorFlowJSInference(imageElement);
      } else {
        console.error('Unknown backend:', this.backend);
        return [];
      }
    } catch (error) {
      console.error('Error during YOLO inference:', error);
      return [];
    }
  }

  async runONNXInference(imageElement) {
    try {
      console.log('Starting ONNX inference...');
      
      if (!imageElement) {
        console.error('No image element provided');
        return [];
      }
      
      console.log('Image element:', imageElement.width, 'x', imageElement.height);
      
      if (!this.session) {
        console.error('ONNX session not initialized');
        return [];
      }
      
      console.log('Session input names:', this.session.inputNames);
      console.log('Session output names:', this.session.outputNames);
      
      // Preprocess image for ONNX
      const inputTensor = this.preprocessImageForONNX(imageElement);
      if (!inputTensor) {
        console.error('Failed to create input tensor');
        return [];
      }
      
      console.log('Input tensor shape:', inputTensor.dims);
      console.log('Input tensor type:', inputTensor.type);
      
      // Create feeds object
      const feeds = {};
      const inputName = this.session.inputNames[0];
      feeds[inputName] = inputTensor;
      
      console.log('Running ONNX session with input:', inputName);
      
      // Run inference
      const results = await this.session.run(feeds);
      
      if (!results) {
        console.error('ONNX inference returned no results');
        return [];
      }
      
      const outputName = this.session.outputNames[0];
      const predictions = results[outputName];
      
      if (!predictions) {
        console.error('No predictions in results for output:', outputName);
        return [];
      }

      console.log('ONNX prediction shape:', predictions.dims);
      console.log('ONNX prediction data length:', predictions.data.length);
      console.log('First few prediction values:', Array.from(predictions.data.slice(0, 10)));

      // Post-process YOLO predictions
      const detections = this.postProcessYOLO(
        predictions.data,
        imageElement.width,
        imageElement.height
      );

      console.log('Post-processed detections:', detections.length);
      return detections;
    } catch (error) {
      console.error('ONNX inference error:', error);
      console.error('Error stack:', error.stack);
      return [];
    }
  }

  preprocessImageForONNX(imageElement) {
    try {
      console.log('Preprocessing image for ONNX...');
      
      if (!imageElement) {
        console.error('No image element for preprocessing');
        return null;
      }
      
      // Create a canvas for image processing
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      canvas.width = this.inputSize;
      canvas.height = this.inputSize;

      console.log('Canvas created:', canvas.width, 'x', canvas.height);
      
      // Draw and resize image
      ctx.drawImage(imageElement, 0, 0, this.inputSize, this.inputSize);
      const imageData = ctx.getImageData(0, 0, this.inputSize, this.inputSize);
      
      console.log('Image data extracted, length:', imageData.data.length);

      // Convert to Float32Array and normalize
      const input = new Float32Array(3 * this.inputSize * this.inputSize);
      for (let i = 0; i < imageData.data.length; i += 4) {
        const pixel = i / 4;
        const y = Math.floor(pixel / this.inputSize);
        const x = pixel % this.inputSize;

        // RGB values, normalized to [0, 1]
        input[0 * this.inputSize * this.inputSize + y * this.inputSize + x] =
          imageData.data[i] / 255.0; // R
        input[1 * this.inputSize * this.inputSize + y * this.inputSize + x] =
          imageData.data[i + 1] / 255.0; // G
        input[2 * this.inputSize * this.inputSize + y * this.inputSize + x] =
          imageData.data[i + 2] / 255.0; // B
      }

      console.log('Input array created, length:', input.length);
      console.log('First few input values:', Array.from(input.slice(0, 10)));

      // Create ONNX tensor
      const tensor = new ort.Tensor('float32', input, [
        1,
        3,
        this.inputSize,
        this.inputSize,
      ]);
      console.log('ONNX tensor created:', tensor.dims);
      
      return tensor;
    } catch (error) {
      console.error('Error in preprocessImageForONNX:', error);
      return null;
    }
  }

  async runTensorFlowJSInference(imageElement) {
    return tf.tidy(() => {
      // Preprocess image
      const inputTensor = this.preprocessImage(imageElement);

      // Run inference
      const predictions = this.model.predict(inputTensor);

      // Get prediction data
      const predData = predictions.dataSync();

      console.log('Prediction shape:', predictions.shape);
      console.log('Prediction data length:', predData.length);

      // Post-process YOLO predictions
      const detections = this.postProcessYOLO(
        predData,
        imageElement.width,
        imageElement.height
      );

      return detections;
    });
  }

  postProcessYOLO(
    predictions,
    originalWidth,
    originalHeight,
    confidenceThreshold = 0.3,
    iouThreshold = 0.4
  ) {
    const detections = [];

    // YOLO11 output format: [batch, 84, 8400] where 84 = 4 (bbox) + 80 (classes)
    const numDetections = 8400; // For 640x640 input with YOLO11
    const numClasses = 80;

    for (let i = 0; i < numDetections; i++) {
      // YOLO11 format: [batch, 84, 8400] - transposed format
      // Extract bbox coordinates (center format)
      const x_center = predictions[i]; // predictions[0 * 8400 + i]
      const y_center = predictions[numDetections + i]; // predictions[1 * 8400 + i]
      const width = predictions[2 * numDetections + i]; // predictions[2 * 8400 + i]
      const height = predictions[3 * numDetections + i]; // predictions[3 * 8400 + i]

      // Find the class with highest probability
      let maxClassIndex = 0;
      let maxClassScore = 0;

      for (let j = 0; j < numClasses; j++) {
        const classScore = predictions[(4 + j) * numDetections + i];
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
