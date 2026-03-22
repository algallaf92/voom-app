import 'package:flutter/material.dart';
import 'dart:async';
import 'video_chat_screen.dart';
import '../constants.dart';
import '../services/monetization_service.dart';
import '../services/matching_service.dart';
import '../main.dart';

class _PremiumButtonData {
  final bool isActive;
  final String? timeRemaining;
  final int? usesRemaining;

  const _PremiumButtonData({
    required this.isActive,
    this.timeRemaining,
    this.usesRemaining,
  });
}

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  _MatchingScreenState createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> with TickerProviderStateMixin {
  // Fields
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _retryController;
  late Animation<double> _retryAnimation;

  Timer? _statusTimer;
  Timer? _timeoutTimer;
  int _elapsedSeconds = 0;
  bool _genderFilterEnabled = false;
  bool _regionFilterEnabled = false;
  bool _priorityMatchingEnabled = false;
  bool _canSkip = true;
  bool _showRetryButton = false;
  String? _matchedUserId;
  // Default preferences — updated when the user picks a specific value.
  String? _selectedGender;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _retryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _retryAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _retryController, curve: Curves.elasticOut),
    );

    _startMatching();
  }

  void _startMatching() async {
    final safetyService = SafetyProvider.of(context);
    final matchingService = MatchingProvider.of(context);

    _canSkip = await safetyService.canSkip();

    if (!_canSkip) {
      _showRateLimitDialog();
      return;
    }

    // Reset state
    setState(() {
      _elapsedSeconds = 0;
      _matchedUserId = null;
      _showRetryButton = false;
    });

    // Cancel any existing timers
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();

    // Start status timer
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });

    // Start 10-second timeout timer
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _matchedUserId == null) {
        setState(() {
          _showRetryButton = true;
        });
        // Auto-retry after showing the button for 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _showRetryButton) {
            _retryMatching();
          }
        });
      }
    });

    try {
      // Start real Firestore matchmaking.
      final result = await matchingService.findMatch(
        genderPreference: _genderFilterEnabled ? _selectedGender : null,
        regionPreference: _regionFilterEnabled ? _selectedRegion : null,
        isPriority: _priorityMatchingEnabled,
      );

      if (result != null && mounted) {
        // Cancel timeout timer since we found a match
        _timeoutTimer?.cancel();

        setState(() {
          _matchedUserId = result.matchedUserId;
        });

        // Navigate to video chat after a brief success animation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VideoChatScreen(
                  channelName: result.channelName,
                  remoteUserId: result.matchedUserId,
                  matchId: result.matchId,
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _timeoutTimer?.cancel();
        _showMatchFailedDialog(e.toString());
      }
    } finally {
      _statusTimer?.cancel();
    }
  }

  void _retryMatching() {
    if (mounted) {
      _startMatching();
    }
  }

  void _showRateLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Too Many Skips',
            style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You\'ve skipped too many matches recently. Please wait a minute before trying again.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to home
              },
              child: const Text(
                'OK',
                style: TextStyle(color: accentColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMatchFailedDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Match Failed',
            style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Unable to find a match. $error',
            style: const TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startMatching(); // Retry
              },
              child: const Text(
                'Try Again',
                style: TextStyle(color: accentColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to home
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _retryController.dispose();
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchingService = MatchingProvider.of(context);
    final monetizationService = MonetizationProvider.of(context);
    final state = matchingService.currentState;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            matchingService.cancelMatch();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Finding a Match',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            _buildAnimatedIcon(state),
            const SizedBox(height: 32),
            _buildStatusText(state),
            const SizedBox(height: 12),
            _buildTimerText(state),
            const Spacer(),
            _buildPremiumFeatures(monetizationService),
            const SizedBox(height: 32),
            _buildActionButton(state),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(MatchingState state) {
    IconData icon;
    Color color;
    bool shouldPulse = false;

    if (_showRetryButton) {
      icon = Icons.access_time;
      color = secondaryColor;
      shouldPulse = true;
    } else {
      switch (state) {
        case MatchingState.searching:
          icon = Icons.search;
          color = accentColor;
          shouldPulse = true;
          break;
        case MatchingState.connecting:
          icon = Icons.wifi;
          color = primaryColor;
          shouldPulse = true;
          break;
        case MatchingState.found:
          icon = Icons.check_circle;
          color = Colors.green;
          shouldPulse = false;
          break;
        case MatchingState.failed:
          icon = Icons.error;
          color = secondaryColor;
          shouldPulse = false;
          break;
        case MatchingState.retrying:
          icon = Icons.refresh;
          color = Colors.orange;
          shouldPulse = false;
          // Trigger retry animation
          _retryController.forward(from: 0.0);
          break;
        default:
          icon = Icons.video_call;
          color = primaryColor;
          shouldPulse = true;
      }
    }

    return AnimatedBuilder(
      animation: shouldPulse ? _pulseAnimation : (state == MatchingState.retrying ? _retryAnimation : AlwaysStoppedAnimation(1.0)),
      builder: (context, child) {
        return Transform.scale(
          scale: shouldPulse ? _pulseAnimation.value : (state == MatchingState.retrying ? _retryAnimation.value : 1.0),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 80,
              color: textColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText(MatchingState state) {
    if (_showRetryButton) {
      return const Text(
        'No match found yet...',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: secondaryColor,
        ),
      );
    }

    String text;
    Color color;

    switch (state) {
      case MatchingState.searching:
        text = 'Finding a match...';
        color = textColor;
        break;
      case MatchingState.connecting:
        text = 'Connecting...';
        color = primaryColor;
        break;
      case MatchingState.found:
        text = 'Match found!';
        color = Colors.green;
        break;
      case MatchingState.failed:
        text = 'Connection failed';
        color = secondaryColor;
        break;
      case MatchingState.retrying:
        text = 'Retrying...';
        color = Colors.orange;
        break;
      default:
        text = 'Preparing...';
        color = textColor;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildTimerText(MatchingState state) {
    if (_showRetryButton) {
      return const Text(
        'Retrying automatically...',
        style: TextStyle(
          fontSize: 18,
          color: accentColor,
        ),
      );
    }

    if (state == MatchingState.found) {
      return const Text(
        'Starting chat...',
        style: TextStyle(
          fontSize: 18,
          color: Colors.green,
        ),
      );
    }

    return Text(
      '$_elapsedSeconds seconds',
      style: TextStyle(
        fontSize: 18,
        color: textColor.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildActionButton(MatchingState state) {
    if (state == MatchingState.found) {
      return const SizedBox.shrink(); // No button when match is found
    }

    if (_showRetryButton) {
      return ElevatedButton.icon(
        onPressed: _retryMatching,
        icon: const Icon(
          Icons.refresh,
          color: textColor,
        ),
        label: const Text(
          'Retry',
          style: TextStyle(color: textColor),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      );
    }

    final isLoading = state == MatchingState.searching ||
                     state == MatchingState.connecting ||
                     state == MatchingState.retrying;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : _skipMatch,
      icon: Icon(
        isLoading ? Icons.hourglass_empty : Icons.skip_next,
        color: textColor,
      ),
      label: Text(
        isLoading ? 'Please wait...' : (_canSkip ? 'Skip' : 'Rate Limited'),
        style: const TextStyle(color: textColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isLoading
            ? secondaryColor.withValues(alpha: 0.5)
            : (_canSkip ? secondaryColor : secondaryColor.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  Widget _buildPremiumFeatures(MonetizationService monetizationService) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPremiumButton(
              monetizationService,
              'gender_filter',
              'Gender Filter',
              Icons.people,
              10,
              _genderFilterEnabled,
              () => _toggleFeature('gender_filter'),
            ),
            const SizedBox(width: 16),
            _buildPremiumButton(
              monetizationService,
              'region_filter',
              'Region Filter',
              Icons.location_on,
              15,
              _regionFilterEnabled,
              () => _toggleFeature('region_filter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPremiumButton(
          monetizationService,
          'priority_matching',
          'Priority Matching',
          Icons.star,
          30,
          _priorityMatchingEnabled,
          () => _toggleFeature('priority_matching'),
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildPremiumButton(
    MonetizationService monetizationService,
    String featureId,
    String label,
    IconData icon,
    int coinCost,
    bool isEnabled,
    VoidCallback onTap, {
    bool isWide = false,
  }) {
    return FutureBuilder<_PremiumButtonData>(
      future: Future.wait([
        monetizationService.isFeatureActive(featureId),
        monetizationService.getFeatureTimeRemaining(featureId),
        monetizationService.getFeatureUsesRemaining(featureId),
      ]).then((results) => _PremiumButtonData(
            isActive: results[0] as bool,
            timeRemaining: results[1] as String?,
            usesRemaining: results[2] as int?,
          )),
      builder: (context, snapshot) {
        final isActive = snapshot.data?.isActive ?? false;
        final timeRemaining = snapshot.data?.timeRemaining;
        final usesRemaining = snapshot.data?.usesRemaining;

        return GestureDetector(
          onTap: isActive ? onTap : () => _unlockFeature(monetizationService, featureId, coinCost),
          child: Container(
            width: isWide ? 200 : 120,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isEnabled ? accentColor.withValues(alpha: 0.2) : (isActive ? primaryColor.withValues(alpha: 0.3) : primaryColor.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEnabled ? accentColor : (isActive ? primaryColor : secondaryColor),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isEnabled ? accentColor : (isActive ? primaryColor : secondaryColor),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? accentColor : (isActive ? textColor : secondaryColor),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isActive) ...[
                  const SizedBox(height: 2),
                  if (timeRemaining != null) ...[
                    Text(
                      timeRemaining,
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (usesRemaining != null) ...[
                    Text(
                      '$usesRemaining left',
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: accentColor,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$coinCost',
                        style: const TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleFeature(String featureId) {
    setState(() {
      switch (featureId) {
        case 'gender_filter':
          _genderFilterEnabled = !_genderFilterEnabled;
          break;
        case 'region_filter':
          _regionFilterEnabled = !_regionFilterEnabled;
          break;
        case 'priority_matching':
          _priorityMatchingEnabled = !_priorityMatchingEnabled;
          break;
      }
    });
  }

  void _skipMatch() async {
    final safetyService = SafetyProvider.of(context);
    final canSkip = await safetyService.canSkip();

    if (canSkip) {
      // Cancel current timers
      _statusTimer?.cancel();
      _timeoutTimer?.cancel();

      // Restart matching process
      _startMatching();
    } else {
      _showRateLimitDialog();
    }
  }

  void _unlockFeature(MonetizationService monetizationService, String featureId, int coinCost) async {
    final success = await monetizationService.unlockPremiumFeature(featureId);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough coins or purchase failed')),
        );
      }
    } else {
      if (mounted) {
        setState(() {});
      }
    }
  }
}