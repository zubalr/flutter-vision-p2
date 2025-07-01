import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vision_app/app_shell/app_shell.dart';
import 'package:vision_app/app_shell/services/settings_service.dart';
import 'package:vision_app/app_shell/solutions/solution_manager.dart';
import 'package:vision_app/camera_module/camera_manager.dart';
import 'package:vision_app/ml_inference_module/ml_service.dart';
import 'package:vision_app/solution_object_counting/object_counting_service.dart';
// Removed unused solutions
import 'package:vision_app/solution_distance_calculation/distance_calculation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.initialize();

  final solutionManager = SolutionManager();

  final cameraManager = CameraManager();
  final mlService = MLService();
  final objectCountingService = ObjectCountingService();
  final distanceCalculationService = DistanceCalculationService();

  runApp(
    MyApp(
      settingsService: settingsService,
      solutionManager: solutionManager,
      cameraManager: cameraManager,
      mlService: mlService,
      objectCountingService: objectCountingService,
      distanceCalculationService: distanceCalculationService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;
  final SolutionManager solutionManager;
  final CameraManager cameraManager;
  final MLService mlService;
  final ObjectCountingService objectCountingService;
  final DistanceCalculationService distanceCalculationService;

  const MyApp({
    super.key,
    required this.settingsService,
    required this.solutionManager,
    required this.cameraManager,
    required this.mlService,
    required this.objectCountingService,
    required this.distanceCalculationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: solutionManager),
      ],
      child: MaterialApp(
        title: 'Vision App',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: AppShell(
          cameraManager: cameraManager,
          mlService: mlService,
          objectCountingService: objectCountingService,
          distanceCalculationService: distanceCalculationService,
        ),
      ),
    );
  }
}
