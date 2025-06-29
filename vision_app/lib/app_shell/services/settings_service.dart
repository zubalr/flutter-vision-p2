import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _cameraResolutionKey = 'camera_resolution';
  static const String _overlayOpacityKey = 'overlay_opacity';
  static const String _showConfidenceScoresKey = 'show_confidence_scores';
  static const String _enableModelOptimizationKey = 'enable_model_optimization';
  static const String _confidenceThresholdKey = 'confidence_threshold';
  static const String _enableGPUAccelerationKey = 'enable_gpu_acceleration';

  // Default values
  String _cameraResolution = 'High';
  double _overlayOpacity = 0.7;
  bool _showConfidenceScores = true;
  bool _enableModelOptimization = true;
  double _confidenceThreshold = 0.5;
  bool _enableGPUAcceleration = true;

  bool _isInitialized = false;

  // Getters
  String get cameraResolution => _cameraResolution;
  double get overlayOpacity => _overlayOpacity;
  bool get showConfidenceScores => _showConfidenceScores;
  bool get enableModelOptimization => _enableModelOptimization;
  double get confidenceThreshold => _confidenceThreshold;
  bool get enableGPUAcceleration => _enableGPUAcceleration;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();

    _cameraResolution =
        prefs.getString(_cameraResolutionKey) ?? _cameraResolution;
    _overlayOpacity = prefs.getDouble(_overlayOpacityKey) ?? _overlayOpacity;
    _showConfidenceScores =
        prefs.getBool(_showConfidenceScoresKey) ?? _showConfidenceScores;
    _enableModelOptimization =
        prefs.getBool(_enableModelOptimizationKey) ?? _enableModelOptimization;
    _confidenceThreshold =
        prefs.getDouble(_confidenceThresholdKey) ?? _confidenceThreshold;
    _enableGPUAcceleration =
        prefs.getBool(_enableGPUAccelerationKey) ?? _enableGPUAcceleration;

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setCameraResolution(String resolution) async {
    _cameraResolution = resolution;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cameraResolutionKey, resolution);
    notifyListeners();
  }

  Future<void> setOverlayOpacity(double opacity) async {
    _overlayOpacity = opacity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_overlayOpacityKey, opacity);
    notifyListeners();
  }

  Future<void> setShowConfidenceScores(bool show) async {
    _showConfidenceScores = show;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showConfidenceScoresKey, show);
    notifyListeners();
  }

  Future<void> setEnableModelOptimization(bool enable) async {
    _enableModelOptimization = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableModelOptimizationKey, enable);
    notifyListeners();
  }

  Future<void> setConfidenceThreshold(double threshold) async {
    _confidenceThreshold = threshold;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_confidenceThresholdKey, threshold);
    notifyListeners();
  }

  Future<void> setEnableGPUAcceleration(bool enable) async {
    _enableGPUAcceleration = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableGPUAccelerationKey, enable);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove all settings keys
    await prefs.remove(_cameraResolutionKey);
    await prefs.remove(_overlayOpacityKey);
    await prefs.remove(_showConfidenceScoresKey);
    await prefs.remove(_enableModelOptimizationKey);
    await prefs.remove(_confidenceThresholdKey);
    await prefs.remove(_enableGPUAccelerationKey);

    // Reset to defaults
    _cameraResolution = 'High';
    _overlayOpacity = 0.7;
    _showConfidenceScores = true;
    _enableModelOptimization = true;
    _confidenceThreshold = 0.5;
    _enableGPUAcceleration = true;

    notifyListeners();
  }
}
