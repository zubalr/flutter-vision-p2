
import 'dart:math';

List<Map<String, dynamic>> applyNMS(List<Map<String, dynamic>> detections, double iouThreshold) {
  if (detections.isEmpty) return [];
  
  // Sort by confidence (highest first)
  detections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
  
  final List<Map<String, dynamic>> keep = [];
  final List<bool> suppressed = List.filled(detections.length, false);
  
  for (int i = 0; i < detections.length; i++) {
    if (suppressed[i]) continue;
    
    keep.add(detections[i]);
    final List<double> boxA = List<double>.from(detections[i]['box']);
    
    for (int j = i + 1; j < detections.length; j++) {
      if (suppressed[j]) continue;
      
      final List<double> boxB = List<double>.from(detections[j]['box']);
      final double iou = _calculateIoU(boxA, boxB);
      
      if (iou > iouThreshold) {
        suppressed[j] = true;
      }
    }
  }
  
  return keep;
}

double _calculateIoU(List<double> boxA, List<double> boxB) {
  // boxA and boxB are in format [x1, y1, x2, y2]
  final double xA = max(boxA[0], boxB[0]);
  final double yA = max(boxA[1], boxB[1]);
  final double xB = min(boxA[2], boxB[2]);
  final double yB = min(boxA[3], boxB[3]);

  final double intersectionArea = max(0, xB - xA) * max(0, yB - yA);
  final double boxAArea = (boxA[2] - boxA[0]) * (boxA[3] - boxA[1]);
  final double boxBArea = (boxB[2] - boxB[0]) * (boxB[3] - boxB[1]);

  return intersectionArea / (boxAArea + boxBArea - intersectionArea);
}
