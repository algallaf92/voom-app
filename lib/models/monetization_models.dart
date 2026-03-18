class CoinBalance {
  final int balance;
  final DateTime lastUpdated;

  CoinBalance({
    required this.balance,
    required this.lastUpdated,
  });

  factory CoinBalance.fromJson(Map<String, dynamic> json) {
    return CoinBalance(
      balance: json['balance'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  CoinBalance copyWith({
    int? balance,
    DateTime? lastUpdated,
  }) {
    return CoinBalance(
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }



}

class PremiumFeature {
  final String id;
  final String name;
  final String description;
  final int coinCost;
  final bool isUnlocked;
  final FeatureType type;
  final int? durationMinutes; // For time-based features
  final int? maxUses; // For usage-based features
  final DateTime? activatedAt;
  final int? usesRemaining;

  PremiumFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.coinCost,
    required this.isUnlocked,
    required this.type,
    this.durationMinutes,
    this.maxUses,
    this.activatedAt,
    this.usesRemaining,
  });

  factory PremiumFeature.fromJson(Map<String, dynamic> json) {
    return PremiumFeature(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      coinCost: json['coinCost'],
      isUnlocked: json['isUnlocked'] ?? false,
      type: FeatureType.values[json['type'] ?? 0],
      durationMinutes: json['durationMinutes'],
      maxUses: json['maxUses'],
      activatedAt: json['activatedAt'] != null ? DateTime.parse(json['activatedAt']) : null,
      usesRemaining: json['usesRemaining'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coinCost': coinCost,
      'isUnlocked': isUnlocked,
      'type': type.index,
      'durationMinutes': durationMinutes,
      'maxUses': maxUses,
      'activatedAt': activatedAt?.toIso8601String(),
      'usesRemaining': usesRemaining,
    };
  }

  PremiumFeature copyWith({
    String? id,
    String? name,
    String? description,
    int? coinCost,
    bool? isUnlocked,
    FeatureType? type,
    int? durationMinutes,
    int? maxUses,
    DateTime? activatedAt,
    int? usesRemaining,
  }) {
    return PremiumFeature(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coinCost: coinCost ?? this.coinCost,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxUses: maxUses ?? this.maxUses,
      activatedAt: activatedAt ?? this.activatedAt,
      usesRemaining: usesRemaining ?? this.usesRemaining,
    );
  }

  bool get isActive {
    if (!isUnlocked) return false;

    switch (type) {
      case FeatureType.permanent:
        return true;
      case FeatureType.timeBased:
        if (activatedAt == null || durationMinutes == null) return false;
        final expiryTime = activatedAt!.add(Duration(minutes: durationMinutes!));
        return DateTime.now().isBefore(expiryTime);
      case FeatureType.usageBased:
        return (usesRemaining ?? 0) > 0;
      case FeatureType.perUse:
        return true; // Always available, charged per use
    }
  }

  Duration? get timeRemaining {
    if (type != FeatureType.timeBased || activatedAt == null || durationMinutes == null) {
      return null;
    }
    final expiryTime = activatedAt!.add(Duration(minutes: durationMinutes!));
    final remaining = expiryTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

enum FeatureType {
  permanent,    // One-time unlock (like no ads)
  timeBased,    // Time-limited activation
  usageBased,   // Limited uses
  perUse,       // Pay per use
}

class CoinPackage {
  final String id;
  final String name;
  final int coinAmount;
  final double price;
  final String currency;
  final String productId;
  final int? bonusCoins; // Bonus coins for bundles
  final List<String>? bonusFeatures; // Bonus features included

  CoinPackage({
    required this.id,
    required this.name,
    required this.coinAmount,
    required this.price,
    required this.currency,
    required this.productId,
    this.bonusCoins,
    this.bonusFeatures,
  });

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    return CoinPackage(
      id: json['id'],
      name: json['name'],
      coinAmount: json['coinAmount'],
      price: json['price'],
      currency: json['currency'],
      productId: json['productId'],
      bonusCoins: json['bonusCoins'],
      bonusFeatures: json['bonusFeatures'] != null ? List<String>.from(json['bonusFeatures']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coinAmount': coinAmount,
      'price': price,
      'currency': currency,
      'productId': productId,
      'bonusCoins': bonusCoins,
      'bonusFeatures': bonusFeatures,
    };
  }

  int get totalCoins => coinAmount + (bonusCoins ?? 0);
  bool get isBundle => bonusCoins != null || (bonusFeatures?.isNotEmpty ?? false);
}
