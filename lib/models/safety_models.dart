class UserReport {
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String description;
  final DateTime timestamp;
  final String chatSessionId;

  UserReport({
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    required this.timestamp,
    required this.chatSessionId,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      reporterId: json['reporterId'],
      reportedUserId: json['reportedUserId'],
      reason: json['reason'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      chatSessionId: json['chatSessionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'chatSessionId': chatSessionId,
    };
  }
}

class BlockedUser {
  final String blockerId;
  final String blockedUserId;
  final DateTime blockedAt;
  final String reason;

  BlockedUser({
    required this.blockerId,
    required this.blockedUserId,
    required this.blockedAt,
    required this.reason,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      blockerId: json['blockerId'],
      blockedUserId: json['blockedUserId'],
      blockedAt: DateTime.parse(json['blockedAt']),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'blockedAt': blockedAt.toIso8601String(),
      'reason': reason,
    };
  }
}

class ModerationResult {
  final bool isSafe;
  final String riskLevel; // 'low', 'medium', 'high'
  final List<String> flags;
  final String aiAnalysis;

  ModerationResult({
    required this.isSafe,
    required this.riskLevel,
    required this.flags,
    required this.aiAnalysis,
  });

  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    return ModerationResult(
      isSafe: json['isSafe'] ?? true,
      riskLevel: json['riskLevel'] ?? 'low',
      flags: List<String>.from(json['flags'] ?? []),
      aiAnalysis: json['aiAnalysis'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSafe': isSafe,
      'riskLevel': riskLevel,
      'flags': flags,
      'aiAnalysis': aiAnalysis,
    };
  }
}

class SafetySettings {
  final bool autoSkipCameraOff;
  final bool enableModeration;
  final int maxSkipsPerMinute;
  final bool requireCamera;

  SafetySettings({
    required this.autoSkipCameraOff,
    required this.enableModeration,
    required this.maxSkipsPerMinute,
    required this.requireCamera,
  });

  factory SafetySettings.fromJson(Map<String, dynamic> json) {
    return SafetySettings(
      autoSkipCameraOff: json['autoSkipCameraOff'] ?? true,
      enableModeration: json['enableModeration'] ?? true,
      maxSkipsPerMinute: json['maxSkipsPerMinute'] ?? 5,
      requireCamera: json['requireCamera'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSkipCameraOff': autoSkipCameraOff,
      'enableModeration': enableModeration,
      'maxSkipsPerMinute': maxSkipsPerMinute,
      'requireCamera': requireCamera,
    };
  }

  SafetySettings copyWith({
    bool? autoSkipCameraOff,
    bool? enableModeration,
    int? maxSkipsPerMinute,
    bool? requireCamera,
  }) {
    return SafetySettings(
      autoSkipCameraOff: autoSkipCameraOff ?? this.autoSkipCameraOff,
      enableModeration: enableModeration ?? this.enableModeration,
      maxSkipsPerMinute: maxSkipsPerMinute ?? this.maxSkipsPerMinute,
      requireCamera: requireCamera ?? this.requireCamera,
    );
  }
}