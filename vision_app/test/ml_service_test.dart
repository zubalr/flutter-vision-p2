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

    test('Object detection returns empty list when no camera image', () async {
      final detections = mlService.runObjectDetection(null);
      expect(detections, isEmpty);
    });

    test('Object detection returns empty list when model not loaded', () async {
      final detections = mlService.runObjectDetection(null);
      expect(detections, isEmpty);
      expect(mlService.isModelLoaded, isFalse);
    });

    tearDown(() {
      mlService.dispose();
    });
  });
}
