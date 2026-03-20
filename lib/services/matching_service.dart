import '../services/safety_service.dart';

// Matching states
enum MatchingState {
  idle,
  searching,
  connecting,
  found,
  failed,
  retrying,
}

// Placeholder for matching logic
class MatchingService {
  final SafetyService _safetyService;

  MatchingState _currentState = MatchingState.idle;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  MatchingService(this._safetyService);

  MatchingState get currentState => _currentState;

  // Find a match with retry logic
  Future<String?> findMatch({String? currentUserId, bool isRetry = false}) async {
    if (!isRetry) {
      _retryCount = 0;
    }

    _currentState = MatchingState.searching;

    try {
      // Check if user can skip (rate limiting)
      final canSkip = await _safetyService.canSkip();
      if (!canSkip) {
        _currentState = MatchingState.failed;
        throw Exception('Too many skips. Please wait before trying again.');
      }

      _currentState = MatchingState.connecting;

      // TODO: Implement matching logic with Firebase
      // For now, simulate finding a match with possible failure
      await Future.delayed(const Duration(seconds: 2));

      // Simulate occasional failure (20% chance)
      if (DateTime.now().millisecondsSinceEpoch % 5 == 0) {
        throw Exception('Connection failed. Retrying...');
      }

      // Generate a mock user ID (in real app, this would come from Firebase)
      final mockUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Check if this user is blocked
      if (currentUserId != null) {
        final isBlocked = await _safetyService.isUserBlocked(mockUserId);
        if (isBlocked) {
          // Try to find another match
          return await findMatch(currentUserId: currentUserId, isRetry: true);
        }
      }

      _currentState = MatchingState.found;
      return mockUserId;

    } catch (e) {
      _currentState = MatchingState.failed;

      if (_retryCount < _maxRetries) {
        _retryCount++;
        _currentState = MatchingState.retrying;

        // Exponential backoff: 2s, 4s, 8s
        final delay = _baseRetryDelay * (1 << (_retryCount - 1));
        await Future.delayed(delay);

        // Retry recursively
        return await findMatch(currentUserId: currentUserId, isRetry: true);
      } else {
        // Max retries reached
        rethrow;
      }
    }
  }

  // Skip current match
  Future<bool> skipMatch() async {
    final canSkip = await _safetyService.canSkip();
    if (!canSkip) {
      return false;
    }

    // Cancel current matching if in progress
    if (_currentState == MatchingState.searching || _currentState == MatchingState.connecting) {
      cancelMatch();
    }

    // Notify Firebase backend about the skip when Firestore integration is added
    return true;
  }

  // Cancel match
  void cancelMatch() {
    _currentState = MatchingState.idle;
    _retryCount = 0;
  }

  // Reset matching state
  void reset() {
    _currentState = MatchingState.idle;
    _retryCount = 0;
  }

  // Report and block user
  Future<void> reportAndBlockUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String description,
    required String chatSessionId,
  }) async {
    await _safetyService.reportUser(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      reason: reason,
      description: description,
      chatSessionId: chatSessionId,
    );

    await _safetyService.blockUser(
      blockerId: reporterId,
      blockedUserId: reportedUserId,
      reason: reason,
    );
  }
}