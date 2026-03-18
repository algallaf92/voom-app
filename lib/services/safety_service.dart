import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/safety_models.dart';

class SafetyService {
  static const String _reportsKey = 'user_reports';
  static const String _blockedUsersKey = 'blocked_users';
  static const String _safetySettingsKey = 'safety_settings';
  static const String _skipHistoryKey = 'skip_history';

  // Report reasons
  static const List<String> reportReasons = [
    'Inappropriate content',
    'Harassment',
    'Spam',
    'Underage',
    'Fake profile',
    'Technical issues',
    'Other',
  ];

  // Stream controllers for reactive updates
  final StreamController<List<BlockedUser>> _blockedUsersController = StreamController<List<BlockedUser>>.broadcast();
  final StreamController<SafetySettings> _safetySettingsController = StreamController<SafetySettings>.broadcast();

  Stream<List<BlockedUser>> get blockedUsersStream => _blockedUsersController.stream;
  Stream<SafetySettings> get safetySettingsStream => _safetySettingsController.stream;

  SafetyService() {
    _initializeDefaults();
  }

  void _initializeDefaults() async {
    final settings = await getSafetySettings();
    if (settings.maxSkipsPerMinute == 0) {
      // Initialize with default settings
      final defaultSettings = SafetySettings(
        autoSkipCameraOff: true,
        enableModeration: true,
        maxSkipsPerMinute: 5,
        requireCamera: true,
      );
      await _saveSafetySettings(defaultSettings);
    }
  }

  // Report management
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String description,
    required String chatSessionId,
  }) async {
    final report = UserReport(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      reason: reason,
      description: description,
      timestamp: DateTime.now(),
      chatSessionId: chatSessionId,
    );

    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getString(_reportsKey);
    List<UserReport> reports = [];

    if (reportsJson != null) {
      final reportsList = json.decode(reportsJson) as List;
      reports = reportsList.map((r) => UserReport.fromJson(r)).toList();
    }

    reports.add(report);
    await prefs.setString(_reportsKey, json.encode(reports.map((r) => r.toJson()).toList()));

    // TODO: Send report to backend for moderation review
    print('User reported: $reportedUserId for $reason');
  }

  Future<List<UserReport>> getUserReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getString(_reportsKey);

    if (reportsJson != null) {
      final reportsList = json.decode(reportsJson) as List;
      return reportsList.map((r) => UserReport.fromJson(r)).toList();
    }

    return [];
  }

  // Block user management
  Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
    required String reason,
  }) async {
    final blockedUser = BlockedUser(
      blockerId: blockerId,
      blockedUserId: blockedUserId,
      blockedAt: DateTime.now(),
      reason: reason,
    );

    final blockedUsers = await getBlockedUsers();
    blockedUsers.add(blockedUser);

    await _saveBlockedUsers(blockedUsers);
  }

  Future<void> unblockUser(String blockedUserId) async {
    final blockedUsers = await getBlockedUsers();
    blockedUsers.removeWhere((user) => user.blockedUserId == blockedUserId);
    await _saveBlockedUsers(blockedUsers);
  }

  Future<List<BlockedUser>> getBlockedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedJson = prefs.getString(_blockedUsersKey);

    if (blockedJson != null) {
      final blockedList = json.decode(blockedJson) as List;
      return blockedList.map((b) => BlockedUser.fromJson(b)).toList();
    }

    return [];
  }

  Future<bool> isUserBlocked(String userId) async {
    final blockedUsers = await getBlockedUsers();
    return blockedUsers.any((user) => user.blockedUserId == userId);
  }

  Future<void> _saveBlockedUsers(List<BlockedUser> blockedUsers) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedJson = json.encode(blockedUsers.map((b) => b.toJson()).toList());
    await prefs.setString(_blockedUsersKey, blockedJson);
    _blockedUsersController.add(blockedUsers);
  }

  // Safety settings management
  Future<SafetySettings> getSafetySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_safetySettingsKey);

    if (settingsJson != null) {
      return SafetySettings.fromJson(json.decode(settingsJson));
    } else {
      // Return default settings
      return SafetySettings(
        autoSkipCameraOff: true,
        enableModeration: true,
        maxSkipsPerMinute: 5,
        requireCamera: true,
      );
    }
  }

  Future<void> updateSafetySettings(SafetySettings settings) async {
    await _saveSafetySettings(settings);
  }

  Future<void> _saveSafetySettings(SafetySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_safetySettingsKey, json.encode(settings.toJson()));
    _safetySettingsController.add(settings);
  }

  // Skip rate limiting
  Future<bool> canSkip() async {
    final settings = await getSafetySettings();
    final prefs = await SharedPreferences.getInstance();
    final skipHistoryJson = prefs.getString(_skipHistoryKey);

    List<DateTime> skipHistory = [];
    if (skipHistoryJson != null) {
      final historyList = json.decode(skipHistoryJson) as List;
      skipHistory = historyList.map((t) => DateTime.parse(t)).toList();
    }

    // Remove skips older than 1 minute
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
    skipHistory = skipHistory.where((time) => time.isAfter(oneMinuteAgo)).toList();

    // Check if under limit
    if (skipHistory.length >= settings.maxSkipsPerMinute) {
      return false;
    }

    // Add current skip
    skipHistory.add(DateTime.now());
    await prefs.setString(_skipHistoryKey, json.encode(skipHistory.map((t) => t.toIso8601String()).toList()));

    return true;
  }

  // AI Moderation placeholder
  Future<ModerationResult> moderateContent(String content, {List<String>? imageUrls}) async {
    // TODO: Implement actual AI moderation API call
    // For now, return a placeholder result

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call

    // Basic placeholder logic - flag obvious inappropriate content
    final inappropriateWords = ['inappropriate', 'spam', 'test'];
    final hasInappropriateContent = inappropriateWords.any((word) =>
        content.toLowerCase().contains(word));

    return ModerationResult(
      isSafe: !hasInappropriateContent,
      riskLevel: hasInappropriateContent ? 'medium' : 'low',
      flags: hasInappropriateContent ? ['inappropriate_content'] : [],
      aiAnalysis: hasInappropriateContent
          ? 'Content flagged for review due to potentially inappropriate language.'
          : 'Content appears safe based on basic analysis.',
    );
  }

  // Camera monitoring for auto-skip
  Future<void> checkCameraStatus(bool isRemoteCameraOn, String remoteUserId) async {
    final settings = await getSafetySettings();

    if (settings.autoSkipCameraOff && !isRemoteCameraOn) {
      // TODO: Implement auto-skip logic
      // This would be called from the video chat screen when remote camera status changes
      print('Auto-skip triggered: Remote camera is off for user $remoteUserId');
    }
  }

  void dispose() {
    _blockedUsersController.close();
    _safetySettingsController.close();
  }
}