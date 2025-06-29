import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Service for measuring and tracking app performance metrics
class PerformanceBenchmarkingService {
  static const MethodChannel _channel = MethodChannel('performance_monitoring');

  final List<PerformanceMetric> _metrics = [];
  final Map<String, Stopwatch> _activeStopwatches = {};

  /// Start measuring a performance metric
  void startMeasurement(String metricName) {
    final stopwatch = Stopwatch()..start();
    _activeStopwatches[metricName] = stopwatch;
  }

  /// Stop measuring and record the metric
  void stopMeasurement(String metricName, {Map<String, dynamic>? metadata}) {
    final stopwatch = _activeStopwatches.remove(metricName);
    if (stopwatch != null) {
      stopwatch.stop();
      _metrics.add(
        PerformanceMetric(
          name: metricName,
          value: stopwatch.elapsedMilliseconds.toDouble(),
          unit: 'ms',
          timestamp: DateTime.now(),
          metadata: metadata ?? {},
        ),
      );
    }
  }

  /// Record a single performance metric
  void recordMetric(
    String name,
    double value,
    String unit, {
    Map<String, dynamic>? metadata,
  }) {
    _metrics.add(
      PerformanceMetric(
        name: name,
        value: value,
        unit: unit,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      ),
    );
  }

  /// Measure frame rate over a period
  Future<double> measureFPS(Duration duration) async {
    final completer = Completer<double>();
    final stopwatch = Stopwatch()..start();
    int frameCount = 0;

    void frameCallback(Duration timestamp) {
      frameCount++;
      if (stopwatch.elapsed < duration) {
        WidgetsBinding.instance.scheduleFrameCallback(frameCallback);
      } else {
        final fps = frameCount / (stopwatch.elapsedMilliseconds / 1000);
        completer.complete(fps);
      }
    }

    WidgetsBinding.instance.scheduleFrameCallback(frameCallback);
    return completer.future;
  }

  /// Get memory usage information
  Future<MemoryInfo> getMemoryInfo() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('getMemoryInfo');
        return MemoryInfo.fromMap(result);
      } else if (Platform.isIOS) {
        final result = await _channel.invokeMethod('getMemoryInfo');
        return MemoryInfo.fromMap(result);
      }
    } catch (e) {
      // Silently handle missing plugin implementation
      // This is expected when native plugins are not implemented
    }

    // Fallback to basic info
    return MemoryInfo(usedMemoryMB: 0, totalMemoryMB: 0, availableMemoryMB: 0);
  }

  /// Get CPU usage information
  Future<double> getCPUUsage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod('getCPUUsage');
        return result?.toDouble() ?? 0.0;
      }
    } catch (e) {
      // Silently handle missing plugin implementation
      // This is expected when native plugins are not implemented
    }
    return 0.0;
  }

  /// Get battery level
  Future<double> getBatteryLevel() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod('getBatteryLevel');
        return result?.toDouble() ?? 100.0;
      }
    } catch (e) {
      debugPrint('Failed to get battery level: $e');
    }
    return 100.0;
  }

  /// Run a comprehensive benchmark
  Future<BenchmarkReport> runBenchmark({
    Duration fpsTestDuration = const Duration(seconds: 10),
    int inferenceIterations = 100,
  }) async {
    final report = BenchmarkReport();

    // Device info
    report.deviceInfo = await _getDeviceInfo();

    // FPS test
    startMeasurement('fps_test');
    final fps = await measureFPS(fpsTestDuration);
    stopMeasurement('fps_test');
    report.avgFPS = fps;

    // Memory usage
    final memoryInfo = await getMemoryInfo();
    report.memoryUsageMB = memoryInfo.usedMemoryMB;

    // CPU usage
    report.cpuUsage = await getCPUUsage();

    // Battery level
    report.batteryLevel = await getBatteryLevel();

    // Inference benchmarks would be added here
    // This would require integration with the ML service

    // Calculate performance scores
    report.performanceScore = _calculatePerformanceScore(report);

    return report;
  }

  /// Get all recorded metrics
  List<PerformanceMetric> getMetrics() {
    return List.unmodifiable(_metrics);
  }

  /// Get metrics by name
  List<PerformanceMetric> getMetricsByName(String name) {
    return _metrics.where((metric) => metric.name == name).toList();
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _activeStopwatches.clear();
  }

  /// Export metrics to CSV format
  String exportMetricsToCSV() {
    final buffer = StringBuffer();
    buffer.writeln('Name,Value,Unit,Timestamp,Metadata');

    for (final metric in _metrics) {
      buffer.writeln(
        '${metric.name},${metric.value},${metric.unit},${metric.timestamp.toIso8601String()},${metric.metadata.toString()}',
      );
    }

    return buffer.toString();
  }

  Future<DeviceInfo> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod('getDeviceInfo');
        return DeviceInfo.fromMap(result);
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
    }

    return DeviceInfo(
      platform: Platform.operatingSystem,
      model: 'Unknown',
      version: 'Unknown',
    );
  }

  double _calculatePerformanceScore(BenchmarkReport report) {
    // Simple scoring algorithm (can be enhanced)
    double score = 0;

    // FPS score (0-40 points)
    if (report.avgFPS >= 30) {
      score += 40;
    } else if (report.avgFPS >= 15) {
      score += 20 + (report.avgFPS - 15) * (20 / 15);
    } else {
      score += report.avgFPS * (20 / 15);
    }

    // Memory efficiency (0-30 points)
    if (report.memoryUsageMB <= 200) {
      score += 30;
    } else if (report.memoryUsageMB <= 500) {
      score += 30 - ((report.memoryUsageMB - 200) * 30 / 300);
    }

    // CPU efficiency (0-30 points)
    if (report.cpuUsage <= 50) {
      score += 30;
    } else if (report.cpuUsage <= 80) {
      score += 30 - ((report.cpuUsage - 50) * 30 / 30);
    }

    return score.clamp(0, 100);
  }
}

/// Represents a single performance metric
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Memory information
class MemoryInfo {
  final double usedMemoryMB;
  final double totalMemoryMB;
  final double availableMemoryMB;

  MemoryInfo({
    required this.usedMemoryMB,
    required this.totalMemoryMB,
    required this.availableMemoryMB,
  });

  factory MemoryInfo.fromMap(Map<String, dynamic> map) {
    return MemoryInfo(
      usedMemoryMB: map['usedMemoryMB']?.toDouble() ?? 0,
      totalMemoryMB: map['totalMemoryMB']?.toDouble() ?? 0,
      availableMemoryMB: map['availableMemoryMB']?.toDouble() ?? 0,
    );
  }
}

/// Device information
class DeviceInfo {
  final String platform;
  final String model;
  final String version;

  DeviceInfo({
    required this.platform,
    required this.model,
    required this.version,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      platform: map['platform'] ?? 'Unknown',
      model: map['model'] ?? 'Unknown',
      version: map['version'] ?? 'Unknown',
    );
  }
}

/// Comprehensive benchmark report
class BenchmarkReport {
  DeviceInfo? deviceInfo;
  double avgFPS = 0;
  double memoryUsageMB = 0;
  double cpuUsage = 0;
  double batteryLevel = 100;
  double performanceScore = 0;
  Map<String, double> customMetrics = {};

  Map<String, dynamic> toMap() {
    return {
      'deviceInfo': {
        'platform': deviceInfo?.platform,
        'model': deviceInfo?.model,
        'version': deviceInfo?.version,
      },
      'avgFPS': avgFPS,
      'memoryUsageMB': memoryUsageMB,
      'cpuUsage': cpuUsage,
      'batteryLevel': batteryLevel,
      'performanceScore': performanceScore,
      'customMetrics': customMetrics,
    };
  }

  String toReadableString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Performance Benchmark Report ===');
    buffer.writeln('Device: ${deviceInfo?.model} (${deviceInfo?.platform})');
    buffer.writeln('Average FPS: ${avgFPS.toStringAsFixed(1)}');
    buffer.writeln('Memory Usage: ${memoryUsageMB.toStringAsFixed(1)} MB');
    buffer.writeln('CPU Usage: ${cpuUsage.toStringAsFixed(1)}%');
    buffer.writeln('Battery Level: ${batteryLevel.toStringAsFixed(1)}%');
    buffer.writeln(
      'Performance Score: ${performanceScore.toStringAsFixed(1)}/100',
    );

    if (customMetrics.isNotEmpty) {
      buffer.writeln('\nCustom Metrics:');
      for (final entry in customMetrics.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value.toStringAsFixed(2)}');
      }
    }

    return buffer.toString();
  }
}
