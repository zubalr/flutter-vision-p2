import 'package:flutter_test/flutter_test.dart';
import 'package:vision_app/ml_inference_module/ml_service.dart';

void main() {
  group('MLService Tests', () {
    late MLService mlService;

    setUp(() {
      mlService = MLService();
    });

    test('MLService initializes correctly', () {
      expect(mlService, isNotNull);
      expect(mlService.isModelLoaded, isFalse);
    });

    test('Model loading handles missing file gracefully', () async {
      // This should return false since we don't have a real model file
      final result = await mlService.loadModel();
      
      // Should not crash and should return false for missing model
      expect(result, isFalse);
      expect(mlService.isModelLoaded, isFalse);
    });

    test('Mock detections work when model is not loaded', () {
      // Should return mock detections even without model
      final detections = mlService.getMockObjectDetections();
      
      expect(detections, isNotEmpty);
      expect(detections.first.label, isNotEmpty);
      expect(detections.first.confidence, greaterThan(0));
    });

    test('Object detection returns empty list when no camera image', () {
      final detections = mlService.runObjectDetection(null);
      expect(detections, isEmpty);
    });

    tearDown(() {
      mlService.dispose();
    });
  });
}