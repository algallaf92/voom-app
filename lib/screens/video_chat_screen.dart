import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/safety_service.dart';
import '../widgets/buttons.dart';
import '../widgets/video_view.dart';
import '../widgets/coin_balance_widget.dart';
import '../services/agora_service.dart';
import '../services/filter_service.dart';
import '../constants.dart';

class VideoChatScreen extends StatefulWidget {
  const VideoChatScreen({super.key});

  @override
  _VideoChatScreenState createState() => _VideoChatScreenState();
}

class _VideoChatScreenState extends State<VideoChatScreen> with WidgetsBindingObserver {
  final AgoraService _agoraService = AgoraService();
  final FilterService _filterService = FilterService();

  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isInitialized = false;
  bool _premiumFiltersUnlocked = false;
  final bool _remoteCameraOn = true; // Track remote user's camera status
  final String _remoteUserId = '';
  final String _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

  String _currentFilter = 'None';
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _checkPremiumFeatures();
    _startSafetyMonitoring();
  }

  Future<void> _checkPremiumFeatures() async {
    final monetizationService = MonetizationProvider.of(context);
    final premiumFiltersUnlocked = await monetizationService.isFeatureUnlocked('premium_filters');
    setState(() {
      _premiumFiltersUnlocked = premiumFiltersUnlocked;
    });
  }

  void _startSafetyMonitoring() {
    // Monitor for auto-skip conditions every 5 seconds
    _safetyTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final safetyService = SafetyProvider.of(context);
      await safetyService.checkCameraStatus(_remoteCameraOn, _remoteUserId);

      // Auto-skip if camera is off and setting is enabled
      final settings = await safetyService.getSafetySettings();
      if (settings.autoSkipCameraOff && !_remoteCameraOn && _isInitialized) {
        _showAutoSkipDialog();
      }
    });
  }

  void _showAutoSkipDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Safety Alert',
          style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'The other user has their camera off. For your safety, this call will end in 10 seconds.',
          style: const TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endCall();
            },
            child: const Text(
              'End Call Now',
              style: TextStyle(color: secondaryColor),
            ),
          ),
        ],
      ),
    );

    // Auto-end call after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        _endCall();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pauseServices();
        break;
      case AppLifecycleState.resumed:
        _resumeServices();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize Agora and filters in parallel for faster startup
      await Future.wait([
        _agoraService.initialize(),
        _filterService.initialize(),
      ]);

      // Start camera stream for filters
      await _filterService.startCameraStream();

      // Join a test channel (replace with actual channel logic)
      await _agoraService.joinChannel(
        'test_channel_${DateTime.now().millisecondsSinceEpoch}',
        '', // Token - use your token generation logic
        0,  // UID
      );

      setState(() {
        _isInitialized = true;
      });

      debugPrint('Services initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize services: $e');
      // Show error dialog
      if (mounted) {
        _showErrorDialog('Failed to initialize video chat: $e');
      }
    }
  }

  void _pauseServices() {
    _agoraService.toggleVideo(false);
    _filterService.stopCameraStream();
  }

  void _resumeServices() {
    if (_isInitialized && !_isVideoOff) {
      _agoraService.toggleVideo(true);
      _filterService.startCameraStream();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monetizationService = MonetizationProvider.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Video View with performance optimization
          VideoView(
            agoraService: _agoraService,
            filterService: _filterService,
            isLocal: true,
          ),

          // Coin Balance
          Positioned(
            top: 20,
            right: 20,
            child: CoinBalanceWidget(monetizationService: monetizationService),
          ),

          // Filter Selector
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildFilterButtons(),
              ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Premium controls row
                FutureBuilder<bool>(
                  future: monetizationService.isFeatureUnlocked('reconnect'),
                  builder: (context, snapshot) {
                    final reconnectUnlocked = snapshot.data ?? false;
                    if (reconnectUnlocked) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: buildControlButton(
                          icon: Icons.refresh,
                          color: accentColor,
                          onPressed: _reconnect,
                          label: 'Reconnect (20 coins)',
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Main controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? secondaryColor : accentColor,
                      onPressed: _toggleMute,
                    ),
                    buildControlButton(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      color: _isVideoOff ? secondaryColor : accentColor,
                      onPressed: _toggleVideo,
                    ),
                    buildControlButton(
                      icon: Icons.call_end,
                      color: Colors.red,
                      onPressed: _endCall,
                    ),
                    buildControlButton(
                      icon: Icons.camera_alt,
                      color: accentColor,
                      onPressed: _takeSnapshot,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Safety controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildControlButton(
                      icon: Icons.report,
                      color: secondaryColor,
                      onPressed: _reportUser,
                      label: 'Report',
                    ),
                    buildControlButton(
                      icon: Icons.block,
                      color: secondaryColor,
                      onPressed: _blockUser,
                      label: 'Block',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Loading indicator
          if (!_isInitialized)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterButtons() {
    final allFilters = _filterService.getFilters();
    final basicFilters = ['None', 'Beauty', 'Smooth'];
    final premiumFilters = allFilters.where((filter) => !basicFilters.contains(filter)).toList();

    final availableFilters = _premiumFiltersUnlocked ? allFilters : basicFilters;

    return availableFilters.map((filter) {
      final isSelected = filter == _currentFilter;
      final isPremium = premiumFilters.contains(filter) && !_premiumFiltersUnlocked;

      return GestureDetector(
        onTap: () => _applyFilter(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : (isPremium ? secondaryColor.withValues(alpha: 0.3) : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
            border: isPremium ? Border.all(color: secondaryColor.withValues(alpha: 0.5)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filter,
                style: TextStyle(
                  color: isPremium ? secondaryColor : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.monetization_on,
                  color: accentColor,
                  size: 14,
                ),
                Text(
                  '5',
                  style: const TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  void _applyFilter(String filter) async {
    final monetizationService = MonetizationProvider.of(context);
    final basicFilters = ['None', 'Beauty', 'Smooth'];
    final isPremium = !basicFilters.contains(filter);

    if (isPremium) {
      // Check if premium filters are unlocked for per-use
      final canUse = await monetizationService.usePremiumFeature('premium_filters');
      if (!canUse) {
        _showPremiumFilterDialog();
        return;
      }
    }

    setState(() {
      _currentFilter = filter;
    });

    try {
      await _filterService.applyFilter(filter);
    } catch (e) {
      debugPrint('Failed to apply filter: $e');
    }
  }

  void _showPremiumFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Premium Filters',
          style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Unlock premium filters for 5 coins per use?',
          style: const TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final monetizationService = MonetizationProvider.of(context);
              final unlocked = await monetizationService.unlockPremiumFeature('premium_filters');
              if (unlocked) {
                setState(() {
                  _premiumFiltersUnlocked = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Premium filters unlocked!'),
                    backgroundColor: accentColor,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Not enough coins!'),
                    backgroundColor: secondaryColor,
                  ),
                );
              }
            },
            child: const Text(
              'Unlock (5 coins)',
              style: TextStyle(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMute() async {
    final newMuted = !_isMuted;
    setState(() {
      _isMuted = newMuted;
    });

    try {
      await _agoraService.toggleAudio(!newMuted);
    } catch (e) {
      debugPrint('Failed to toggle audio: $e');
      // Revert state on failure
      if (mounted) {
        setState(() {
          _isMuted = !newMuted;
        });
      }
    }
  }

  void _toggleVideo() async {
    final newVideoOff = !_isVideoOff;
    setState(() {
      _isVideoOff = newVideoOff;
    });

    try {
      await _agoraService.toggleVideo(!newVideoOff);
    } catch (e) {
      debugPrint('Failed to toggle video: $e');
      // Revert state on failure
      if (mounted) {
        setState(() {
          _isVideoOff = !newVideoOff;
        });
      }
    }
  }

  void _reconnect() async {
    final monetizationService = MonetizationProvider.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Reconnect',
          style: const TextStyle(color: textColor),
        ),
        content: Text(
          'Spend 20 coins to find a new match?',
          style: const TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reconnect',
              style: TextStyle(color: accentColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await monetizationService.unlockPremiumFeature('reconnect');
      if (success) {
        // End current call and start new matching
        await _endCall();
        // Navigate back to matching screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/matching');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough coins!'),
            backgroundColor: secondaryColor,
          ),
        );
      }
    }
  }

  void _reportUser() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return; // Require authentication

    final safetyService = SafetyProvider.of(context);

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => ReportDialog(
        reasons: SafetyService.reportReasons,
      ),
    );

    if (reason != null && mounted) {
      final description = await showDialog<String>(
        context: context,
        builder: (context) => ReportDescriptionDialog(reason: reason),
      );

      if (description != null && mounted) {
        try {
          await safetyService.reportUser(
            reporterId: currentUid,
            reportedUserId: _remoteUserId,
            reason: reason,
            description: description,
            chatSessionId: _sessionId,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted successfully'),
              backgroundColor: accentColor,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit report: $e'),
              backgroundColor: secondaryColor,
            ),
          );
        }
      }
    }
  }

  void _blockUser() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return; // Require authentication

    final safetyService = SafetyProvider.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Block User',
          style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to block this user? You won\'t be matched with them again.',
          style: const TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Block',
              style: TextStyle(color: secondaryColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await safetyService.blockUser(
          blockerId: currentUid,
          blockedUserId: _remoteUserId,
          reason: 'User blocked during chat',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User blocked successfully'),
            backgroundColor: accentColor,
          ),
        );

        // End the call after blocking
        _endCall();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: $e'),
            backgroundColor: secondaryColor,
          ),
        );
      }
    }
  }

  void _takeSnapshot() {
    _filterService.takeSnapshot();
  }

  Future<void> _endCall() async {
    try {
      await _agoraService.leaveChannel();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _safetyTimer?.cancel();
    _filterService.dispose();
    _agoraService.dispose();
    super.dispose();
  }
}

class ReportDialog extends StatefulWidget {
  final List<String> reasons;

  const ReportDialog({
    super.key,
    required this.reasons,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      title: Text(
        'Report User',
        style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.reasons.map((reason) {
          return RadioListTile<String>(
            title: Text(
              reason,
              style: const TextStyle(color: textColor),
            ),
            value: reason,
            groupValue: _selectedReason,
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
              });
            },
            activeColor: secondaryColor,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
        ),
        TextButton(
          onPressed: _selectedReason != null
              ? () => Navigator.of(context).pop(_selectedReason)
              : null,
          child: Text(
            'Next',
            style: TextStyle(
              color: _selectedReason != null ? secondaryColor : textColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class ReportDescriptionDialog extends StatefulWidget {
  final String reason;

  const ReportDescriptionDialog({
    super.key,
    required this.reason,
  });

  @override
  State<ReportDescriptionDialog> createState() => _ReportDescriptionDialogState();
}

class _ReportDescriptionDialogState extends State<ReportDescriptionDialog> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      title: Text(
        'Report Details',
        style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason: ${widget.reason}',
            style: const TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Please provide additional details (optional)',
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: primaryColor),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_descriptionController.text.trim()),
          child: const Text(
            'Submit Report',
            style: TextStyle(color: secondaryColor),
          ),
        ),
      ],
    );
  }
}