import 'package:flutter/material.dart';
import 'package:vision_app/app_shell/views/camera_view.dart';
import 'package:vision_app/app_shell/views/settings_view.dart';
import 'package:vision_app/app_shell/views/solutions_view.dart';
import 'package:vision_app/app_shell/views/benchmarking_view.dart';
import 'package:vision_app/camera_module/camera_manager.dart';
import 'package:vision_app/ml_inference_module/ml_service.dart';
import 'package:vision_app/solution_object_counting/object_counting_service.dart';
import 'package:vision_app/solution_workouts_monitoring/workouts_monitoring_service.dart';
import 'package:vision_app/solution_security_alarm/security_alarm_service.dart';
import 'package:vision_app/solution_distance_calculation/distance_calculation_service.dart';

enum SolutionMode {
  objectCounting,
  workoutsMonitoring,
  securityAlarm,
  distanceCalculation,
}

class AppShell extends StatefulWidget {
  final CameraManager cameraManager;
  final MLService mlService;
  final ObjectCountingService objectCountingService;
  final WorkoutsMonitoringService workoutsMonitoringService;
  final SecurityAlarmService securityAlarmService;
  final DistanceCalculationService distanceCalculationService;

  const AppShell({
    super.key,
    required this.cameraManager,
    required this.mlService,
    required this.objectCountingService,
    required this.workoutsMonitoringService,
    required this.securityAlarmService,
    required this.distanceCalculationService,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  SolutionMode _currentMode = SolutionMode.objectCounting;

  @override
  Widget build(BuildContext context) {
    final pages = [
      CameraView(
        cameraManager: widget.cameraManager,
        mlService: widget.mlService,
        objectCountingService: widget.objectCountingService,
        workoutsMonitoringService: widget.workoutsMonitoringService,
        securityAlarmService: widget.securityAlarmService,
        distanceCalculationService: widget.distanceCalculationService,
        currentMode: _currentMode,
        onModeChanged: (mode) => setState(() => _currentMode = mode),
      ),
      SolutionsView(
        currentMode: _currentMode,
        onModeChanged: (mode) => setState(() => _currentMode = mode),
      ),
      const SettingsView(),
      const BenchmarkingView(),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Solutions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Benchmark'),
        ],
      ),
    );
  }
}
