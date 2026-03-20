import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/monetization_models.dart';

class MonetizationService {
  static const String _coinBalanceKey = 'coin_balance';
  static const String _premiumFeaturesKey = 'premium_features';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // In-memory caches to avoid repeated SharedPreferences I/O
  CoinBalance? _cachedCoinBalance;
  List<PremiumFeature>? _cachedPremiumFeatures;

  // Coin packages available for purchase
  final List<CoinPackage> coinPackages = [
    CoinPackage(
      id: 'small_pack',
      name: 'Small Pack',
      coinAmount: 100,
      price: 0.99,
      currency: 'USD',
      productId: 'voom_coins_100',
    ),
    CoinPackage(
      id: 'medium_pack',
      name: 'Medium Pack',
      coinAmount: 500,
      price: 4.99,
      currency: 'USD',
      productId: 'voom_coins_500',
    ),
    CoinPackage(
      id: 'large_pack',
      name: 'Large Pack',
      coinAmount: 1200,
      price: 9.99,
      currency: 'USD',
      productId: 'voom_coins_1200',
    ),
    CoinPackage(
      id: 'mega_pack',
      name: 'Mega Pack',
      coinAmount: 2500,
      price: 19.99,
      currency: 'USD',
      productId: 'voom_coins_2500',
      bonusCoins: 500, // Bonus 500 coins
      bonusFeatures: ['premium_filters_unlock'], // Bonus premium filters unlock
    ),
  ];

  // Premium features
  final List<PremiumFeature> premiumFeatures = [
    PremiumFeature(
      id: 'gender_filter',
      name: 'Gender Filter',
      description: 'Filter matches by gender preference (5 min)',
      coinCost: 15,
      isUnlocked: false,
      type: FeatureType.timeBased,
      durationMinutes: 5,
    ),
    PremiumFeature(
      id: 'region_filter',
      name: 'Region Filter',
      description: 'Filter matches by region (3 matches)',
      coinCost: 10,
      isUnlocked: false,
      type: FeatureType.usageBased,
      maxUses: 3,
    ),
    PremiumFeature(
      id: 'reconnect',
      name: 'Reconnect',
      description: 'Reconnect with previous matches',
      coinCost: 10,
      isUnlocked: false,
      type: FeatureType.perUse,
    ),
    PremiumFeature(
      id: 'premium_filters',
      name: 'Premium Filters',
      description: 'Access to exclusive filter effects',
      coinCost: 5,
      isUnlocked: false,
      type: FeatureType.perUse,
    ),
    PremiumFeature(
      id: 'priority_matching',
      name: 'Priority Matching',
      description: 'Get matched faster with priority',
      coinCost: 30,
      isUnlocked: false,
      type: FeatureType.timeBased,
      durationMinutes: 10,
    ),
    PremiumFeature(
      id: 'no_ads',
      name: 'No Ads',
      description: 'Remove all advertisements',
      coinCost: 100,
      isUnlocked: false,
      type: FeatureType.permanent,
    ),
  ];

  // Stream controllers for reactive updates
  final StreamController<CoinBalance> _coinBalanceController = StreamController<CoinBalance>.broadcast();
  final StreamController<List<PremiumFeature>> _premiumFeaturesController = StreamController<List<PremiumFeature>>.broadcast();

  Stream<CoinBalance> get coinBalanceStream => _coinBalanceController.stream;
  Stream<List<PremiumFeature>> get premiumFeaturesStream => _premiumFeaturesController.stream;

  MonetizationService() {
    _initialize();
  }

  void _initialize() {
    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Handle successful purchase
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle purchase error
        debugPrint('Purchase error: ${purchaseDetails.error}');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    // Find the coin package that was purchased
    final coinPackage = coinPackages.firstWhere(
      (pkg) => pkg.productId == purchaseDetails.productID,
      orElse: () => throw Exception('Unknown product ID: ${purchaseDetails.productID}'),
    );

    // Add coins to balance (including bonus)
    addCoins(coinPackage.totalCoins);

    // Unlock bonus features if any
    if (coinPackage.bonusFeatures != null) {
      for (final featureId in coinPackage.bonusFeatures!) {
        unlockPremiumFeature(featureId);
      }
    }
  }

  // Coin balance management
  Future<CoinBalance> getCoinBalance() async {
    // Return cached value if available to avoid repeated I/O
    if (_cachedCoinBalance != null) return _cachedCoinBalance!;

    final prefs = await SharedPreferences.getInstance();
    final balanceJson = prefs.getString(_coinBalanceKey);

    if (balanceJson != null) {
      _cachedCoinBalance = CoinBalance.fromJson(json.decode(balanceJson));
      return _cachedCoinBalance!;
    } else {
      // Initialize with 50 free coins for new users
      final initialBalance = CoinBalance(balance: 50, lastUpdated: DateTime.now());
      await _saveCoinBalance(initialBalance);
      return initialBalance;
    }
  }

  Future<void> _saveCoinBalance(CoinBalance balance) async {
    _cachedCoinBalance = balance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coinBalanceKey, json.encode(balance.toJson()));
    _coinBalanceController.add(balance);
  }

  Future<void> addCoins(int amount) async {
    final currentBalance = await getCoinBalance();
    final newBalance = currentBalance.copyWith(
      balance: currentBalance.balance + amount,
      lastUpdated: DateTime.now(),
    );
    await _saveCoinBalance(newBalance);
  }

  Future<bool> deductCoins(int amount) async {
    final currentBalance = await getCoinBalance();
    if (currentBalance.balance >= amount) {
      final newBalance = currentBalance.copyWith(
        balance: currentBalance.balance - amount,
        lastUpdated: DateTime.now(),
      );
      await _saveCoinBalance(newBalance);
      return true;
    }
    return false;
  }

  // Premium features management
  Future<List<PremiumFeature>> getPremiumFeatures() async {
    // Return cached value if available to avoid repeated I/O
    if (_cachedPremiumFeatures != null) return _cachedPremiumFeatures!;

    final prefs = await SharedPreferences.getInstance();
    final featuresJson = prefs.getString(_premiumFeaturesKey);

    if (featuresJson != null) {
      final featuresList = json.decode(featuresJson) as List;
      _cachedPremiumFeatures =
          featuresList.map((f) => PremiumFeature.fromJson(f)).toList();
      return _cachedPremiumFeatures!;
    } else {
      // Return default features and cache them
      await _savePremiumFeatures(premiumFeatures);
      return premiumFeatures;
    }
  }

  Future<void> _savePremiumFeatures(List<PremiumFeature> features) async {
    _cachedPremiumFeatures = features;
    final prefs = await SharedPreferences.getInstance();
    final featuresJson = json.encode(features.map((f) => f.toJson()).toList());
    await prefs.setString(_premiumFeaturesKey, featuresJson);
    _premiumFeaturesController.add(features);
  }

  Future<bool> unlockPremiumFeature(String featureId) async {
    final features = await getPremiumFeatures();
    final featureIndex = features.indexWhere((f) => f.id == featureId);

    if (featureIndex != -1) {
      final feature = features[featureIndex];

      // Check if user has enough coins
      final hasEnoughCoins = await deductCoins(feature.coinCost);
      if (hasEnoughCoins) {
        // Update feature based on type
        switch (feature.type) {
          case FeatureType.permanent:
            features[featureIndex] = feature.copyWith(isUnlocked: true);
            break;
          case FeatureType.timeBased:
            features[featureIndex] = feature.copyWith(
              isUnlocked: true,
              activatedAt: DateTime.now(),
            );
            break;
          case FeatureType.usageBased:
            features[featureIndex] = feature.copyWith(
              isUnlocked: true,
              usesRemaining: feature.maxUses,
            );
            break;
          case FeatureType.perUse:
            // For per-use features, just mark as unlocked (available for purchase)
            features[featureIndex] = feature.copyWith(isUnlocked: true);
            break;
        }

        await _savePremiumFeatures(features);
        return true;
      }
    }
    return false;
  }

  Future<bool> usePremiumFeature(String featureId) async {
    final features = await getPremiumFeatures();
    final featureIndex = features.indexWhere((f) => f.id == featureId);

    if (featureIndex != -1) {
      final feature = features[featureIndex];

      if (!feature.isActive) return false;

      switch (feature.type) {
        case FeatureType.perUse:
          // Deduct coins for per-use features
          final hasEnoughCoins = await deductCoins(feature.coinCost);
          if (!hasEnoughCoins) return false;
          break;
        case FeatureType.usageBased:
          if ((feature.usesRemaining ?? 0) > 0) {
            features[featureIndex] = feature.copyWith(
              usesRemaining: (feature.usesRemaining ?? 0) - 1,
            );
            await _savePremiumFeatures(features);
          } else {
            return false;
          }
          break;
        default:
          // Other types don't need per-use actions
          break;
      }

      return true;
    }
    return false;
  }

  Future<bool> isFeatureUnlocked(String featureId) async {
    final features = await getPremiumFeatures();
    final feature = features.firstWhere(
      (f) => f.id == featureId,
      orElse: () => PremiumFeature(
        id: featureId,
        name: '',
        description: '',
        coinCost: 0,
        isUnlocked: false,
        type: FeatureType.permanent,
      ),
    );
    return feature.isUnlocked;
  }

  Future<bool> isFeatureActive(String featureId) async {
    final features = await getPremiumFeatures();
    final feature = features.firstWhere(
      (f) => f.id == featureId,
      orElse: () => PremiumFeature(
        id: featureId,
        name: '',
        description: '',
        coinCost: 0,
        isUnlocked: false,
        type: FeatureType.permanent,
      ),
    );
    return feature.isActive;
  }

  Future<String?> getFeatureTimeRemaining(String featureId) async {
    final features = await getPremiumFeatures();
    final feature = features.firstWhere(
      (f) => f.id == featureId,
      orElse: () => PremiumFeature(
        id: featureId,
        name: '',
        description: '',
        coinCost: 0,
        isUnlocked: false,
        type: FeatureType.permanent,
      ),
    );

    final timeRemaining = feature.timeRemaining;
    if (timeRemaining == null) return null;

    if (timeRemaining.inMinutes > 0) {
      return '${timeRemaining.inMinutes}m ${timeRemaining.inSeconds % 60}s';
    } else {
      return '${timeRemaining.inSeconds}s';
    }
  }

  Future<int?> getFeatureUsesRemaining(String featureId) async {
    final features = await getPremiumFeatures();
    final feature = features.firstWhere(
      (f) => f.id == featureId,
      orElse: () => PremiumFeature(
        id: featureId,
        name: '',
        description: '',
        coinCost: 0,
        isUnlocked: false,
        type: FeatureType.permanent,
      ),
    );
    return feature.usesRemaining;
  }

  // In-app purchase methods
  Future<bool> isStoreAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  Future<List<ProductDetails>> getProductDetails() async {
    final Set<String> productIds = coinPackages.map((pkg) => pkg.productId).toSet();
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

    if (response.error != null) {
      throw Exception('Error querying products: ${response.error}');
    }

    return response.productDetails;
  }

  Future<void> buyCoinPackage(String packageId) async {
    final coinPackage = coinPackages.firstWhere(
      (pkg) => pkg.id == packageId,
      orElse: () => throw Exception('Coin package not found: $packageId'),
    );

    final products = await getProductDetails();
    final product = products.firstWhere(
      (p) => p.id == coinPackage.productId,
      orElse: () => throw Exception('Product not found: ${coinPackage.productId}'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  void dispose() {
    _subscription.cancel();
    _coinBalanceController.close();
    _premiumFeaturesController.close();
    _cachedCoinBalance = null;
    _cachedPremiumFeatures = null;
  }
}