import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:deepar_flutter/deepar_flutter.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class FilterService {
  DeepArController? _deepArController;
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;

  // Performance optimization
  static const int targetFrameRate = 30;
  static const int processingFrameRate = 24; // Slightly lower for processing
  Isolate? _filterIsolate;
  SendPort? _filterSendPort;
  ReceivePort? _filterReceivePort;

  // Filter assets
  final List<String> _filterAssets = [
    'assets/filters/none',
    'assets/filters/beauty',
    'assets/filters/fun',
    'assets/filters/mask',
    'assets/filters/color',
  ];

  List<String> getFilters() {
    return ['None', 'Beauty', 'Fun', 'Mask', 'Color'];
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize DeepAR
      _deepArController = DeepArController();

      // Configure for optimal performance
      await _configureDeepAR();

      // Initialize camera
      await _initializeCamera();

      // Start background filter processing
      await _startFilterProcessing();

      _isInitialized = true;
      debugPrint('Filter service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize filter service: $e');
      rethrow;
    }
  }

  Future<void> _configureDeepAR() async {
    if (_deepArController == null) return;

    // Set license key (replace with your actual key)
    await _deepArController!.initialize(
      androidLicenseKey: '1ca2d9c26dfb4b521f4b3b602700cd8715289719731e4e1eaafc95510c2aac1e41072fa545045194',
      iosLicenseKey: 'YOUR_IOS_LICENSE_KEY',
    );

    // Configure for performance
    // await _deepArController!.setFaceDetectionSensitivity(0.7); // Balanced sensitivity
    // await _deepArController!.setFrameRate(targetFrameRate);

    // Enable hardware acceleration
    // await _deepArController!.setParameter('use_hw_acceleration', 'true');

    // Optimize memory usage
    // await _deepArController!.setParameter('max_faces', '1'); // Single face tracking
    // await _deepArController!.setParameter('face_tracking_sensitivity', '0.5');
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    _cameraController = CameraController(
      cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      ),
      ResolutionPreset.high, // 1280x720 for good quality
      enableAudio: false, // Audio handled by Agora
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888 // Required on iOS; yuv420 is not supported for streaming
          : ImageFormatGroup.yuv420, // Efficient format on Android
    );

    await _cameraController!.initialize();

    // Configure camera for optimal performance
    await _cameraController!.setFlashMode(FlashMode.off);
    await _cameraController!.setFocusMode(FocusMode.auto);
    await _cameraController!.setExposureMode(ExposureMode.auto);
  }

  Future<void> _startFilterProcessing() async {
    _filterReceivePort = ReceivePort();
    _filterIsolate = await Isolate.spawn(_filterProcessingIsolate, _filterReceivePort!.sendPort);

    _filterReceivePort!.listen((message) {
      if (message is SendPort) {
        _filterSendPort = message;
      } else if (message is Map<String, dynamic>) {
        _handleProcessedFrame(message);
      }
    });
  }

  static void _filterProcessingIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        // Process frame in isolate
        final processedFrame = await _processFrameInIsolate(message);
        sendPort.send(processedFrame);
      }
    });
  }

  static Future<Map<String, dynamic>> _processFrameInIsolate(Map<String, dynamic> frameData) async {
    // Perform CPU-intensive filter processing here
    // This runs in a separate isolate to avoid blocking UI

    final Uint8List frameBytes = frameData['bytes'];
    final int width = frameData['width'];
    final int height = frameData['height'];
    final String filter = frameData['filter'];

    // Apply filter processing (simplified example)
    // In real implementation, this would use DeepAR's processing

    // Simulate processing time (should be very fast)
    await Future.delayed(const Duration(milliseconds: 8)); // ~120 FPS processing

    return {
      'processedBytes': frameBytes,
      'width': width,
      'height': height,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  void _handleProcessedFrame(Map<String, dynamic> processedData) {
    // Handle the processed frame back on main thread
    // Update UI or send to video stream
    debugPrint('Frame processed at ${processedData['timestamp']}');
  }

  Future<void> applyFilter(String filterName) async {
    if (_deepArController == null || !_isInitialized) return;

    try {
      final filterIndex = getFilters().indexOf(filterName);
      if (filterIndex == -1) return;

      if (filterName == 'None') {
        await _deepArController!.switchEffect(''); // Clear all effects
      } else {
        // Load filter asset
        final filterPath = await _getFilterPath(filterIndex);
        await _deepArController!.switchEffect(filterPath);
      }

      debugPrint('Applied filter: $filterName');
    } catch (e) {
      debugPrint('Failed to apply filter: $e');
    }
  }

  Future<String> _getFilterPath(int index) async {
    final filterAsset = _filterAssets[index];
    final directory = await getApplicationDocumentsDirectory();
    final filterFile = File('${directory.path}/filters/${filterAsset.split('/').last}.deepar');

    // In real implementation, you would download or copy the filter file
    // For now, return the asset path
    return filterAsset;
  }

  Future<void> startCameraStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    await _cameraController!.startImageStream((CameraImage image) {
      if (_isProcessing) return; // Skip if still processing previous frame

      _isProcessing = true;

      // Send frame to filter processing isolate
      if (_filterSendPort != null) {
        _filterSendPort!.send({
          'bytes': image.planes[0].bytes,
          'width': image.width,
          'height': image.height,
          'filter': 'current_filter', // Replace with actual current filter
        });
      }

      _isProcessing = false;
    });
  }

  Future<void> stopCameraStream() async {
    await _cameraController?.stopImageStream();
  }

  Future<void> takeSnapshot() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final image = await _cameraController!.takePicture();
      // Process snapshot with current filter
      debugPrint('Snapshot taken: ${image.path}');
    } catch (e) {
      debugPrint('Failed to take snapshot: $e');
    }
  }

  DeepArController? get deepArController => _deepArController;
  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _filterIsolate?.kill();
    _filterReceivePort?.close();
    _cameraController?.dispose();
    _deepArController?.destroy();
    _isInitialized = false;
  }
}