# Modular Architecture Documentation

## Overview

The Vision App is built with a modular architecture that allows for easy addition of new AI solutions. This document outlines the architecture and provides guidelines for adding new solutions.

## Architecture Components

### 1. Base Solution Interface (`BaseSolution`)

All AI solutions must implement the `BaseSolution` interface, which defines:

- **Metadata**: ID, name, description, icon, and color
- **Capabilities**: Drawing support and interaction type
- **Processing**: Methods for handling detections and keypoints
- **State Management**: Reset, initialization, and metrics
- **Rendering**: Overlay data for UI rendering

### 2. Solution Manager (`SolutionManager`)

The `SolutionManager` is a centralized service that:

- Manages all available solutions
- Handles solution switching
- Provides a unified interface for the UI
- Supports dynamic solution loading

### 3. Modular Overlay Painter (`ModularOverlayPainter`)

A flexible painter that can render overlays for any solution:

- Handles common rendering (objects, keypoints)
- Delegates solution-specific rendering
- Supports extensibility for new solution types

### 4. Solution Factory (`SolutionFactory`)

A factory pattern implementation for:

- Dynamic solution creation
- Solution registration
- Plugin-style architecture support

## Adding a New Solution

To add a new AI solution, follow these steps:

### Step 1: Create Solution Implementation

Create a new file: `lib/app_shell/solutions/implementations/your_solution.dart`

```dart
import 'package:flutter/material.dart';
import 'package:vision_app/app_shell/solutions/base_solution.dart';
import 'package:vision_app/ml_inference_module/detected_object.dart';
import 'package:vision_app/ml_inference_module/detected_keypoint.dart';

class YourSolution implements BaseSolution {
  @override
  String get id => 'your_solution';

  @override
  String get name => 'Your Solution Name';

  @override
  String get description => 'Description of what your solution does';

  @override
  IconData get icon => Icons.your_icon;

  @override
  Color get color => Colors.yourColor;

  @override
  bool get supportsDrawing => true; // or false

  @override
  DrawingType get drawingType => DrawingType.line; // or appropriate type

  @override
  void processDetections(List<DetectedObject> detections) {
    // Your detection processing logic
  }

  @override
  void processKeypoints(List<DetectedKeypoint> keypoints) {
    // Your keypoint processing logic (if needed)
  }

  @override
  void handleDrawingComplete(List<Offset> points) {
    // Handle user drawing interactions (if needed)
  }

  @override
  void reset() {
    // Reset solution state
  }

  @override
  SolutionOverlayData getOverlayData() {
    return YourSolutionOverlayData(
      objects: [], // Your detected objects
      keypoints: [], // Your keypoints
      customData: {
        // Your custom overlay data
      },
    );
  }

  @override
  void initialize(Map<String, dynamic> settings) {
    // Initialize with settings
  }

  @override
  Map<String, dynamic> getMetrics() {
    return {
      // Your solution metrics
    };
  }
}

class YourSolutionOverlayData extends SolutionOverlayData {
  @override
  final List<DetectedObject> objects;

  @override
  final List<DetectedKeypoint> keypoints;

  @override
  final Map<String, dynamic> customData;

  YourSolutionOverlayData({
    required this.objects,
    required this.keypoints,
    required this.customData,
  });
}
```

### Step 2: Register the Solution

In `solution_manager.dart`, add your solution to the registration:

```dart
void _registerBuiltInSolutions() {
  // Existing registrations...
  SolutionFactory.register('your_solution', () => YourSolution());

  // Create instance
  _solutions['your_solution'] = YourSolution();
}
```

### Step 3: Add Custom Overlay Rendering (Optional)

If your solution needs custom overlay rendering, add a case in `modular_overlay_painter.dart`:

```dart
void _drawCustomOverlays(Canvas canvas, Size size, Map<String, dynamic> customData) {
  switch (solutionId) {
    // Existing cases...
    case 'your_solution':
      _drawYourSolutionOverlay(canvas, size, customData);
      break;
  }
}

void _drawYourSolutionOverlay(Canvas canvas, Size size, Map<String, dynamic> data) {
  // Your custom rendering logic
}
```

### Step 4: Update Imports (if needed)

Add the import for your solution in `solution_manager.dart`:

```dart
import 'package:vision_app/app_shell/solutions/implementations/your_solution.dart';
```

## Best Practices

### 1. Solution Independence

- Solutions should be self-contained
- Avoid dependencies between solutions
- Use the base interface for all interactions

### 2. State Management

- Keep solution state isolated
- Implement proper reset functionality
- Use metrics for debugging and monitoring

### 3. Performance

- Optimize processing methods for real-time use
- Avoid heavy computations in overlay rendering
- Use efficient data structures

### 4. Error Handling

- Implement proper error handling in processing methods
- Gracefully handle missing or invalid data
- Provide meaningful error messages

### 5. Testing

- Write unit tests for solution logic
- Test with various input scenarios
- Verify overlay rendering correctness

## Solution Types

### Detection-Based Solutions

Use object detections from YOLO model:

- Object counting
- Distance calculation
- Security monitoring

### Keypoint-Based Solutions

Use pose estimation keypoints:

- Workout monitoring
- Gesture recognition
- Activity tracking

### Hybrid Solutions

Combine both detections and keypoints:

- Advanced fitness tracking
- Behavioral analysis
- Multi-modal interactions

## Extension Points

The architecture supports several extension points:

1. **Custom ML Models**: Add support for different model types
2. **New Drawing Types**: Extend `DrawingType` enum for new interactions
3. **Custom Overlays**: Add new overlay rendering capabilities
4. **Plugin System**: Dynamic loading of external solutions
5. **Settings Integration**: Solution-specific configuration options

## Future Enhancements

- Dynamic solution loading from plugins
- Solution marketplace integration
- Real-time solution switching
- Advanced metrics and analytics
- Cloud-based solution management
