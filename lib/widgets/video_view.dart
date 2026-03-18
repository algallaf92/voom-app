import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:deepar_flutter/deepar_flutter.dart';
import '../services/agora_service.dart';
import '../services/filter_service.dart';

class VideoView extends StatefulWidget {
  final AgoraService? agoraService;
  final FilterService? filterService;
  final bool isLocal;

  const VideoView({
    super.key,
    this.agoraService,
    this.filterService,
    this.isLocal = true,
  });

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> with WidgetsBindingObserver {
  Timer? _performanceTimer;
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();

  // Performance monitoring
  double _currentFps = 0.0;
  bool _isLowPerformance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start performance monitoring
    _startPerformanceMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pauseVideoProcessing();
        break;
      case AppLifecycleState.resumed:
        _resumeVideoProcessing();
        break;
      default:
        break;
    }
  }

  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final timeDiff = now.difference(_lastFrameTime).inMilliseconds / 1000.0;

      if (timeDiff > 0) {
        _currentFps = _frameCount / timeDiff;
      }

      // Check performance thresholds
      if (_currentFps < 24.0 && !_isLowPerformance) {
        _isLowPerformance = true;
        _optimizeForLowPerformance();
      } else if (_currentFps >= 28.0 && _isLowPerformance) {
        _isLowPerformance = false;
        _restoreOptimalPerformance();
      }

      _frameCount = 0;
      _lastFrameTime = now;

      debugPrint('Current FPS: ${_currentFps.toStringAsFixed(1)}');
    });
  }

  void _optimizeForLowPerformance() {
    debugPrint('Optimizing for low performance');

    // Reduce frame rate
    widget.agoraService?.engine?.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 24,
        bitrate: 800,
      ),
    );

    // Reduce filter processing
    // widget.filterService?.deepArController?.setFrameRate(24);
  }

  void _restoreOptimalPerformance() {
    debugPrint('Restoring optimal performance');

    // Restore high frame rate
    widget.agoraService?.engine?.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 1280, height: 720),
        frameRate: 30,
        bitrate: 1500,
      ),
    );

    // Restore filter processing
    // widget.filterService?.deepArController?.setFrameRate(30);
  }

  void _pauseVideoProcessing() {
    widget.agoraService?.engine?.muteLocalVideoStream(true);
    widget.filterService?.stopCameraStream();
  }

  void _resumeVideoProcessing() {
    widget.agoraService?.engine?.muteLocalVideoStream(false);
    widget.filterService?.startCameraStream();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Main video content
            _buildVideoContent(),

            // Performance indicator (debug mode only)
            if (kDebugMode) _buildPerformanceIndicator(),

            // Filter overlay
            if (widget.filterService?.deepArController != null)
              Positioned.fill(
                child: DeepArPreview(
                  widget.filterService!.deepArController!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (widget.agoraService?.engine == null) {
      return const Center(
        child: Text(
          'Video Stream',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: widget.agoraService!.engine!,
        canvas: const VideoCanvas(
          uid: 0, // Local user
          renderMode: RenderModeType.renderModeHidden,
        ),
      ),
      onAgoraVideoViewCreated: (viewId) {
        debugPrint('Video view created: $viewId');
      },
    );
  }

  Widget _buildPerformanceIndicator() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _currentFps >= 24 ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${_currentFps.toStringAsFixed(1)} FPS',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _performanceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}