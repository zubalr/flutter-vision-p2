import 'package:flutter/foundation.dart';
import 'package:vision_app/app_shell/solutions/base_solution.dart';
import 'package:vision_app/app_shell/solutions/implementations/object_counting_solution.dart';
import 'package:vision_app/app_shell/solutions/implementations/workouts_monitoring_solution.dart';
import 'package:vision_app/app_shell/solutions/implementations/security_alarm_solution.dart';
import 'package:vision_app/app_shell/solutions/implementations/distance_calculation_solution.dart';

/// Manages all AI solutions and provides a unified interface
class SolutionManager extends ChangeNotifier {
  final Map<String, BaseSolution> _solutions = {};
  String? _currentSolutionId;

  SolutionManager() {
    _registerBuiltInSolutions();
  }

  /// Register all built-in solutions
  void _registerBuiltInSolutions() {
    // Register solution factories
    SolutionFactory.register('object_counting', () => ObjectCountingSolution());
    SolutionFactory.register(
      'workouts_monitoring',
      () => WorkoutsMonitoringSolution(),
    );
    SolutionFactory.register('security_alarm', () => SecurityAlarmSolution());
    SolutionFactory.register(
      'distance_calculation',
      () => DistanceCalculationSolution(),
    );

    // Create instances
    _solutions['object_counting'] = ObjectCountingSolution();
    _solutions['workouts_monitoring'] = WorkoutsMonitoringSolution();
    _solutions['security_alarm'] = SecurityAlarmSolution();
    _solutions['distance_calculation'] = DistanceCalculationSolution();

    // Set default solution
    _currentSolutionId = 'object_counting';
  }

  /// Get current active solution
  BaseSolution? get currentSolution {
    return _currentSolutionId != null ? _solutions[_currentSolutionId] : null;
  }

  /// Get current solution ID
  String? get currentSolutionId => _currentSolutionId;

  /// Get all available solutions
  List<BaseSolution> get availableSolutions => _solutions.values.toList();

  /// Switch to a different solution
  void switchSolution(String solutionId) {
    if (_solutions.containsKey(solutionId)) {
      // Reset current solution state
      currentSolution?.reset();

      _currentSolutionId = solutionId;
      notifyListeners();
    }
  }

  /// Get solution by ID
  BaseSolution? getSolution(String id) {
    return _solutions[id];
  }

  /// Add a new solution (for dynamic loading)
  void addSolution(BaseSolution solution) {
    _solutions[solution.id] = solution;
    notifyListeners();
  }

  /// Remove a solution
  void removeSolution(String id) {
    if (_solutions.containsKey(id)) {
      _solutions.remove(id);

      // If current solution was removed, switch to first available
      if (_currentSolutionId == id && _solutions.isNotEmpty) {
        _currentSolutionId = _solutions.keys.first;
      }

      notifyListeners();
    }
  }

  /// Initialize all solutions with settings
  void initializeWithSettings(Map<String, dynamic> settings) {
    for (final solution in _solutions.values) {
      solution.initialize(settings);
    }
  }

  /// Get metrics from all solutions
  Map<String, Map<String, dynamic>> getAllMetrics() {
    final metrics = <String, Map<String, dynamic>>{};
    for (final entry in _solutions.entries) {
      metrics[entry.key] = entry.value.getMetrics();
    }
    return metrics;
  }

  /// Check if a solution exists
  bool hasSolution(String id) {
    return _solutions.containsKey(id);
  }

  /// Get the number of available solutions
  int get solutionCount => _solutions.length;
}
