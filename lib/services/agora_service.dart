import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static const String appId = '86e45b74f65d4e6190c86109212ab412';
  RtcEngine? _engine;
  bool _isInitialized = false;

  // Performance optimization settings
  static const int targetFrameRate = 30;
  static const int lowFrameRate = 24;
  static const VideoDimensions highResolution = VideoDimensions(width: 1280, height: 720);
  static const VideoDimensions lowResolution = VideoDimensions(width: 640, height: 360);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Create engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Configure for optimal performance
      await _configureEngine();

      // Set up event handlers
      _setupEventHandlers();

      _isInitialized = true;
      debugPrint('Agora engine initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Agora: $e');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus != PermissionStatus.granted ||
        microphoneStatus != PermissionStatus.granted) {
      throw Exception('Camera and microphone permissions are required');
    }
  }

  Future<void> _configureEngine() async {
    if (_engine == null) return;

    // Set video encoder configuration for optimal performance
    await _engine!.setVideoEncoderConfiguration(VideoEncoderConfiguration(
      dimensions: highResolution,
      frameRate: targetFrameRate,
      bitrate: 1500, // kbps - optimized for quality vs performance
      orientationMode: OrientationMode.orientationModeAdaptive,
      mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
    ));

    // Enable dual stream mode for better performance
    await _engine!.enableDualStreamMode(enabled: true);

    // Set low stream configuration
    // await _engine!.setBeautyEffectOptions(
    //   enabled: true,
    //   options: const BeautyOptions(
    //     lighteningLevel: 0.5,
    //     rednessLevel: 0.1,
    //     smoothnessLevel: 0.5,
    //   ),
    // );

    // Optimize for low latency
    await _engine!.setParameters('{"che.audio.enable.aec": true}');
    await _engine!.setParameters('{"che.audio.enable.agc": true}');
    await _engine!.setParameters('{"che.audio.enable.ns": true}');

    // Set preferred video codec to H.264 for better performance
    await _engine!.setParameters('{"engine.video.codec": "h264"}');
  }

  void _setupEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint('Successfully joined channel: ${connection.channelId}');
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        debugPrint('Remote user joined: $remoteUid');
      },
      onUserOffline: (connection, remoteUid, reason) {
        debugPrint('Remote user left: $remoteUid');
      },
      onVideoSizeChanged: (connection, sourceType, uid, width, height, rotation) {
        debugPrint('Video size changed: ${width}x$height for user $uid');
      },
      onRtcStats: (connection, stats) {
        // Monitor performance metrics
        _monitorPerformance(stats);
      },
    ));
  }

  void _monitorPerformance(RtcStats stats) {
    // Adjust quality based on network conditions
    /*
    if (stats.txVideoKBitrate < 500 && stats.rxVideoKBitrate < 500) {
      // Low bandwidth - reduce quality
      _adjustVideoQuality(lowResolution, lowFrameRate);
    } else if (stats.txVideoKBitrate > 1000 && stats.rxVideoKBitrate > 1000) {
      // Good bandwidth - increase quality
      _adjustVideoQuality(highResolution, targetFrameRate);
    }
    */
  }

  Future<void> _adjustVideoQuality(VideoDimensions dimensions, int frameRate) async {
    if (_engine == null) return;

    await _engine!.setVideoEncoderConfiguration(VideoEncoderConfiguration(
      dimensions: dimensions,
      frameRate: frameRate,
      bitrate: frameRate == targetFrameRate ? 1500 : 800,
      orientationMode: OrientationMode.orientationModeAdaptive,
    ));
  }

  Future<void> joinChannel(String channelName, String token, int uid) async {
    if (_engine == null || !_isInitialized) {
      throw Exception('Agora engine not initialized');
    }

    try {
      // Enable video
      await _engine!.enableVideo();
      await _engine!.startPreview();

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      debugPrint('Joined channel: $channelName');
    } catch (e) {
      debugPrint('Failed to join channel: $e');
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;

    try {
      await _engine!.leaveChannel();
      await _engine!.stopPreview();
      debugPrint('Left channel');
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
  }

  Future<void> toggleVideo(bool enabled) async {
    if (_engine == null) return;

    if (enabled) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.disableVideo();
      await _engine!.stopPreview();
    }
  }

  Future<void> toggleAudio(bool enabled) async {
    if (_engine == null) return;

    if (enabled) {
      await _engine!.enableAudio();
    } else {
      await _engine!.disableAudio();
    }
  }

  Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
  }

  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _engine?.release();
    _engine = null;
    _isInitialized = false;
  }
}