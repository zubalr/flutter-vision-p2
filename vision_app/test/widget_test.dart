// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:vision_app/app_shell/services/settings_service.dart';
import 'package:vision_app/app_shell/solutions/solution_manager.dart';
import 'package:vision_app/camera_module/camera_manager.dart';
import 'package:vision_app/ml_inference_module/ml_service.dart';
import 'package:vision_app/solution_object_counting/object_counting_service.dart';
import 'package:vision_app/solution_workouts_monitoring/workouts_monitoring_service.dart';
import 'package:vision_app/solution_security_alarm/security_alarm_service.dart';
import 'package:vision_app/solution_distance_calculation/distance_calculation_service.dart';

import 'package:vision_app/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Create mock services
    final settingsService = SettingsService();
    final solutionManager = SolutionManager();
    final cameraManager = CameraManager();
    final mlService = MLService();
    final objectCountingService = ObjectCountingService();
    final workoutsMonitoringService = WorkoutsMonitoringService();
    final securityAlarmService = SecurityAlarmService();
    final distanceCalculationService = DistanceCalculationService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      settingsService: settingsService,
      solutionManager: solutionManager,
      cameraManager: cameraManager,
      mlService: mlService,
      objectCountingService: objectCountingService,
      workoutsMonitoringService: workoutsMonitoringService,
      securityAlarmService: securityAlarmService,
      distanceCalculationService: distanceCalculationService,
    ));

    // Verify that the app loads
    expect(find.text('Vision App'), findsOneWidget);
  });
}
