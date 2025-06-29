import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vision_app/app_shell/services/performance_benchmarking_service.dart';

class BenchmarkingView extends StatefulWidget {
  const BenchmarkingView({super.key});

  @override
  State<BenchmarkingView> createState() => _BenchmarkingViewState();
}

class _BenchmarkingViewState extends State<BenchmarkingView> {
  final PerformanceBenchmarkingService _benchmarkingService =
      PerformanceBenchmarkingService();
  BenchmarkReport? _currentReport;
  bool _isRunning = false;
  List<PerformanceMetric> _realtimeMetrics = [];

  @override
  void initState() {
    super.initState();
    _startRealtimeMonitoring();
  }

  void _startRealtimeMonitoring() {
    // Start real-time FPS monitoring
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _updateRealtimeMetrics();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _updateRealtimeMetrics() async {
    try {
      // Measure FPS for a short duration
      final fps = await _benchmarkingService.measureFPS(
        const Duration(seconds: 1),
      );
      final memoryInfo = await _benchmarkingService.getMemoryInfo();
      final cpuUsage = await _benchmarkingService.getCPUUsage();

      setState(() {
        _realtimeMetrics = [
          PerformanceMetric(
            name: 'FPS',
            value: fps,
            unit: 'fps',
            timestamp: DateTime.now(),
            metadata: {},
          ),
          PerformanceMetric(
            name: 'Memory',
            value: memoryInfo.usedMemoryMB,
            unit: 'MB',
            timestamp: DateTime.now(),
            metadata: {},
          ),
          PerformanceMetric(
            name: 'CPU',
            value: cpuUsage,
            unit: '%',
            timestamp: DateTime.now(),
            metadata: {},
          ),
        ];
      });
    } catch (e) {
      debugPrint('Error updating real-time metrics: $e');
    }
  }

  Future<void> _runFullBenchmark() async {
    setState(() {
      _isRunning = true;
    });

    try {
      final report = await _benchmarkingService.runBenchmark(
        fpsTestDuration: const Duration(seconds: 10),
        inferenceIterations: 50,
      );

      setState(() {
        _currentReport = report;
      });

      // Show completion dialog
      if (mounted) {
        _showBenchmarkResults(report);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Benchmark failed: $e')));
      }
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _showBenchmarkResults(BenchmarkReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Benchmark Results'),
        content: SingleChildScrollView(child: Text(report.toReadableString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportResults(report);
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _exportResults(BenchmarkReport report) {
    // In a real app, this would save to device storage or share
    _benchmarkingService.exportMetricsToCSV();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results exported to device storage')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Benchmark')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRealtimeMetrics(),
            const SizedBox(height: 24),
            _buildBenchmarkSection(),
            if (_currentReport != null) ...[
              const SizedBox(height: 24),
              _buildResultsSection(),
            ],
            const SizedBox(height: 24),
            _buildTargetsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Real-time Metrics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_realtimeMetrics.isEmpty)
              const Text('Loading metrics...')
            else
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: _realtimeMetrics.map((metric) {
                  return Chip(
                    label: Text(
                      '${metric.name}: ${metric.value.toStringAsFixed(1)} ${metric.unit}',
                    ),
                    backgroundColor: _getMetricColor(metric),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Comprehensive Benchmark',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Run a comprehensive performance test to measure FPS, memory usage, CPU usage, and overall performance score.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runFullBenchmark,
                    icon: _isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isRunning ? 'Running...' : 'Start Benchmark'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final report = _currentReport!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Latest Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Performance Score',
              '${report.performanceScore.toStringAsFixed(1)}/100',
            ),
            _buildMetricRow(
              'Average FPS',
              '${report.avgFPS.toStringAsFixed(1)} fps',
            ),
            _buildMetricRow(
              'Memory Usage',
              '${report.memoryUsageMB.toStringAsFixed(1)} MB',
            ),
            _buildMetricRow(
              'CPU Usage',
              '${report.cpuUsage.toStringAsFixed(1)}%',
            ),
            _buildMetricRow(
              'Battery Level',
              '${report.batteryLevel.toStringAsFixed(1)}%',
            ),
            if (report.deviceInfo != null) ...[
              const Divider(),
              _buildMetricRow('Device', '${report.deviceInfo!.model}'),
              _buildMetricRow('Platform', '${report.deviceInfo!.platform}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Performance Targets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTargetRow('Mid-range Devices', '> 15 FPS', Colors.orange),
            _buildTargetRow('High-end Devices', '> 25 FPS', Colors.green),
            _buildTargetRow('Memory Usage', '< 500 MB', Colors.blue),
            _buildTargetRow('CPU Usage', '< 80%', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTargetRow(String label, String target, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              target,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMetricColor(PerformanceMetric metric) {
    switch (metric.name) {
      case 'FPS':
        if (metric.value >= 25) return Colors.green.withOpacity(0.2);
        if (metric.value >= 15) return Colors.orange.withOpacity(0.2);
        return Colors.red.withOpacity(0.2);
      case 'Memory':
        if (metric.value <= 200) return Colors.green.withOpacity(0.2);
        if (metric.value <= 500) return Colors.orange.withOpacity(0.2);
        return Colors.red.withOpacity(0.2);
      case 'CPU':
        if (metric.value <= 50) return Colors.green.withOpacity(0.2);
        if (metric.value <= 80) return Colors.orange.withOpacity(0.2);
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.blue.withOpacity(0.2);
    }
  }
}
