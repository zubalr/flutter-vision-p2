import 'package:vision_app/app_shell/services/performance_benchmarking_service.dart';
import 'package:vision_app/ml_inference_module/ml_service.dart';
import 'package:vision_app/camera_module/camera_manager.dart';

/// Predefined benchmark scenarios for comprehensive testing
class BenchmarkScenarios {
  final PerformanceBenchmarkingService _benchmarkingService;
  final MLService _mlService;
  final CameraManager _cameraManager;

  BenchmarkScenarios({
    required PerformanceBenchmarkingService benchmarkingService,
    required MLService mlService,
    required CameraManager cameraManager,
  }) : _benchmarkingService = benchmarkingService,
       _mlService = mlService,
       _cameraManager = cameraManager;

  /// Scenario 1: Object Detection Performance
  Future<void> runObjectDetectionBenchmark() async {
    _benchmarkingService.startMeasurement('object_detection_benchmark');

    // Simulate object detection on multiple frames
    for (int i = 0; i < 50; i++) {
      _benchmarkingService.startMeasurement('single_inference');

      // In a real implementation, this would process actual camera frames
      // For now, we simulate the processing time
      await Future.delayed(const Duration(milliseconds: 16)); // ~60 FPS target

      _benchmarkingService.stopMeasurement(
        'single_inference',
        metadata: {'frame_number': i, 'scenario': 'object_detection'},
      );
    }

    _benchmarkingService.stopMeasurement('object_detection_benchmark');
  }

  /// Scenario 2: Memory Stress Test
  Future<void> runMemoryStressTest() async {
    _benchmarkingService.startMeasurement('memory_stress_test');

    // Record memory usage at different intervals
    for (int i = 0; i < 10; i++) {
      final memoryInfo = await _benchmarkingService.getMemoryInfo();
      _benchmarkingService.recordMetric(
        'memory_usage_interval_$i',
        memoryInfo.usedMemoryMB,
        'MB',
        metadata: {
          'interval': i,
          'total_memory': memoryInfo.totalMemoryMB,
          'available_memory': memoryInfo.availableMemoryMB,
        },
      );

      // Simulate some processing
      await Future.delayed(const Duration(seconds: 1));
    }

    _benchmarkingService.stopMeasurement('memory_stress_test');
  }

  /// Scenario 3: CPU Intensive Operations
  Future<void> runCPUIntensiveBenchmark() async {
    _benchmarkingService.startMeasurement('cpu_intensive_benchmark');

    // Simulate CPU-intensive operations
    for (int i = 0; i < 100; i++) {
      _benchmarkingService.startMeasurement('cpu_operation');

      // Simulate matrix operations or image processing
      await _simulateCPUIntensiveTask();

      _benchmarkingService.stopMeasurement(
        'cpu_operation',
        metadata: {'operation_index': i},
      );

      // Record CPU usage
      final cpuUsage = await _benchmarkingService.getCPUUsage();
      _benchmarkingService.recordMetric('cpu_usage_$i', cpuUsage, '%');
    }

    _benchmarkingService.stopMeasurement('cpu_intensive_benchmark');
  }

  /// Scenario 4: Frame Rate Consistency Test
  Future<void> runFrameRateConsistencyTest() async {
    _benchmarkingService.startMeasurement('frame_rate_consistency_test');

    // Measure FPS over multiple intervals
    for (int i = 0; i < 10; i++) {
      final fps = await _benchmarkingService.measureFPS(
        const Duration(seconds: 2),
      );
      _benchmarkingService.recordMetric(
        'fps_interval_$i',
        fps,
        'fps',
        metadata: {'interval': i, 'test_duration': 2},
      );
    }

    _benchmarkingService.stopMeasurement('frame_rate_consistency_test');
  }

  /// Scenario 5: Battery Impact Test
  Future<void> runBatteryImpactTest() async {
    _benchmarkingService.startMeasurement('battery_impact_test');

    final initialBattery = await _benchmarkingService.getBatteryLevel();
    _benchmarkingService.recordMetric('initial_battery', initialBattery, '%');

    // Run intensive operations for a period
    await runObjectDetectionBenchmark();
    await runCPUIntensiveBenchmark();

    final finalBattery = await _benchmarkingService.getBatteryLevel();
    _benchmarkingService.recordMetric('final_battery', finalBattery, '%');

    final batteryDrain = initialBattery - finalBattery;
    _benchmarkingService.recordMetric(
      'battery_drain',
      batteryDrain,
      '%',
      metadata: {
        'test_duration_minutes': 5, // Approximate
      },
    );

    _benchmarkingService.stopMeasurement('battery_impact_test');
  }

  /// Run all benchmark scenarios
  Future<BenchmarkReport> runComprehensiveBenchmark() async {
    // Run individual scenarios
    await runObjectDetectionBenchmark();
    await runMemoryStressTest();
    await runCPUIntensiveBenchmark();
    await runFrameRateConsistencyTest();
    await runBatteryImpactTest();

    // Generate comprehensive report
    final report = await _benchmarkingService.runBenchmark();

    // Add custom metrics from scenarios
    final metrics = _benchmarkingService.getMetrics();
    report.customMetrics = _calculateCustomMetrics(metrics);

    return report;
  }

  /// Calculate custom metrics from collected data
  Map<String, double> _calculateCustomMetrics(List<PerformanceMetric> metrics) {
    final customMetrics = <String, double>{};

    // Calculate average inference time
    final inferenceMetrics = metrics
        .where((m) => m.name == 'single_inference')
        .toList();
    if (inferenceMetrics.isNotEmpty) {
      final avgInferenceTime =
          inferenceMetrics.map((m) => m.value).reduce((a, b) => a + b) /
          inferenceMetrics.length;
      customMetrics['avg_inference_time_ms'] = avgInferenceTime;
      customMetrics['inference_fps'] = 1000 / avgInferenceTime;
    }

    // Calculate FPS consistency (standard deviation)
    final fpsMetrics = metrics
        .where((m) => m.name.startsWith('fps_interval_'))
        .toList();
    if (fpsMetrics.isNotEmpty) {
      final fpsValues = fpsMetrics.map((m) => m.value).toList();
      final avgFps = fpsValues.reduce((a, b) => a + b) / fpsValues.length;
      final variance =
          fpsValues
              .map((fps) => (fps - avgFps) * (fps - avgFps))
              .reduce((a, b) => a + b) /
          fpsValues.length;
      customMetrics['fps_consistency_stddev'] = variance.sqrt();
    }

    // Calculate memory efficiency
    final memoryMetrics = metrics
        .where((m) => m.name.startsWith('memory_usage_interval_'))
        .toList();
    if (memoryMetrics.isNotEmpty) {
      final maxMemory = memoryMetrics
          .map((m) => m.value)
          .reduce((a, b) => a > b ? a : b);
      final minMemory = memoryMetrics
          .map((m) => m.value)
          .reduce((a, b) => a < b ? a : b);
      customMetrics['memory_efficiency'] =
          (maxMemory - minMemory) / maxMemory * 100;
    }

    return customMetrics;
  }

  /// Simulate CPU-intensive task
  Future<void> _simulateCPUIntensiveTask() async {
    // Simulate matrix multiplication or image processing
    final list = List.generate(1000, (i) => i.toDouble());
    double sum = 0;
    for (int i = 0; i < 1000; i++) {
      sum += list[i] * list[i];
    }

    // Add a small delay to prevent blocking the UI
    await Future.delayed(const Duration(microseconds: 100));
  }
}

/// Extensions for mathematical operations
extension MathUtils on double {
  double sqrt() {
    if (this < 0) return 0;
    double x = this;
    double prev = 0;
    while ((x - prev).abs() > 0.0001) {
      prev = x;
      x = (x + this / x) / 2;
    }
    return x;
  }
}
