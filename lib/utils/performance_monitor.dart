import 'dart:async';
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static const int targetFps = 30;
  static const int minFps = 24;

  Timer? _fpsTimer;
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  double _currentFps = 0.0;

  final VoidCallback? onLowPerformance;
  final VoidCallback? onPerformanceRestored;

  bool _isLowPerformance = false;

  PerformanceMonitor({
    this.onLowPerformance,
    this.onPerformanceRestored,
  });

  void startMonitoring() {
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final timeDiff = now.difference(_lastFrameTime).inMilliseconds / 1000.0;

      if (timeDiff > 0) {
        _currentFps = _frameCount / timeDiff;
      }

      // Check performance thresholds
      if (_currentFps < minFps && !_isLowPerformance) {
        _isLowPerformance = true;
        onLowPerformance?.call();
        debugPrint('⚠️ Low performance detected: ${_currentFps.toStringAsFixed(1)} FPS');
      } else if (_currentFps >= targetFps && _isLowPerformance) {
        _isLowPerformance = false;
        onPerformanceRestored?.call();
        debugPrint('✅ Performance restored: ${_currentFps.toStringAsFixed(1)} FPS');
      }

      _frameCount = 0;
      _lastFrameTime = now;
    });
  }

  void recordFrame() {
    _frameCount++;
  }

  void stopMonitoring() {
    _fpsTimer?.cancel();
    _fpsTimer = null;
  }

  double get currentFps => _currentFps;
  bool get isLowPerformance => _isLowPerformance;

  // Memory optimization utilities
  static void optimizeMemory() {
    // Force garbage collection hint
    // Note: This is a hint, not guaranteed to run
  }

  // CPU optimization utilities
  static void optimizeCpu() {
    // Reduce background processing
    // Lower frame rates
    // Use more efficient algorithms
  }
}