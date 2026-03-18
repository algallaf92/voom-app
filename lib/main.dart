import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/buttons.dart';
import 'constants.dart';
import 'services/monetization_service.dart';
import 'services/safety_service.dart';
import 'services/matching_service.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/purchase_history_screen.dart';
import 'screens/coin_store_screen.dart';
import 'screens/video_chat_mock_screen.dart';

void main() {
  runApp(const VoomApp());
}

class VoomApp extends StatefulWidget {
  const VoomApp({super.key});

  @override
  State<VoomApp> createState() => _VoomAppState();
}

class _VoomAppState extends State<VoomApp> {
  late MonetizationService _monetizationService;
  late SafetyService _safetyService;
  late MatchingService _matchingService;

  @override
  void initState() {
    super.initState();
    _monetizationService = MonetizationService();
    _safetyService = SafetyService();
    _matchingService = MatchingService(_safetyService);
  }

  @override
  void dispose() {
    _monetizationService.dispose();
    _safetyService.dispose();
    _matchingService.cancelMatch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voom',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        primaryColor: primaryColor,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: textColor),
          headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 32),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/profile': (_) => ProfileScreen(
              username: 'VoomUser',
              profilePictureUrl: 'https://i.pravatar.cc/150?img=3',
              coins: 1200,
              gender: 'Female',
              region: 'USA',
              joinDate: '2024-01-01',
              onEditProfile: () => Navigator.pushNamed(context, '/edit_profile'),
              onSettings: () {},
              onPurchaseHistory: () => Navigator.pushNamed(context, '/purchase_history'),
              onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
              onCoinStore: () => Navigator.pushNamed(context, '/coin_store'),
              dailyStreak: 5,
            ),
        '/edit_profile': (_) => EditProfileScreen(
              username: 'VoomUser',
              gender: 'Female',
              region: 'USA',
              profilePictureUrl: 'https://i.pravatar.cc/150?img=3',
              onSave: (u, g, r, p) => Navigator.pop(context),
            ),
        '/purchase_history': (_) => PurchaseHistoryScreen(
              purchases: [
                PurchaseItem(title: '1000 Coins', date: '2026-03-15', amount: '+1000', icon: Icons.monetization_on),
                PurchaseItem(title: 'Reconnect', date: '2026-03-10', amount: '-50', icon: Icons.refresh),
                PurchaseItem(title: 'Gender Filter', date: '2026-03-08', amount: '-100', icon: Icons.filter_alt),
              ],
            ),
        '/coin_store': (_) => const CoinStoreScreen(),
        '/video_chat': (_) => const VideoChatMockScreen(),
      },
      home: MonetizationProvider(
        service: _monetizationService,
        child: SafetyProvider(
          service: _safetyService,
          child: MatchingProvider(
            service: _matchingService,
            child: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}

class MonetizationProvider extends InheritedWidget {
  final MonetizationService service;

  const MonetizationProvider({
    super.key,
    required this.service,
    required super.child,
  });

  static MonetizationService of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<MonetizationProvider>();
    assert(provider != null, 'No MonetizationProvider found in context');
    return provider!.service;
  }

  @override
  bool updateShouldNotify(MonetizationProvider oldWidget) {
    return service != oldWidget.service;
  }
}

class SafetyProvider extends InheritedWidget {
  final SafetyService service;

  const SafetyProvider({
    super.key,
    required this.service,
    required super.child,
  });

  static SafetyService of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<SafetyProvider>();
    assert(provider != null, 'No SafetyProvider found in context');
    return provider!.service;
  }

  @override
  bool updateShouldNotify(SafetyProvider oldWidget) {
    return service != oldWidget.service;
  }
}

class MatchingProvider extends InheritedWidget {
  final MatchingService service;

  const MatchingProvider({
    super.key,
    required this.service,
    required super.child,
  });

  static MatchingService of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<MatchingProvider>();
    assert(provider != null, 'No MatchingProvider found in context');
    return provider!.service;
  }

  @override
  bool updateShouldNotify(MatchingProvider oldWidget) {
    return service != oldWidget.service;
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_glowController);

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoWidget(size: 120),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(_glowAnimation.value * 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Voom',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Meet instantly',
              style: TextStyle(
                fontSize: 18,
                color: accentColor,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
