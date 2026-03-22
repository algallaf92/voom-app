import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/coin_balance_widget.dart';
import '../main.dart';
import 'matching_screen.dart';
import 'buy_coins_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final monetizationService = MonetizationProvider.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.person, color: textColor),
          onPressed: () {
            // Profile
          },
        ),
        title: CoinBalanceWidget(monetizationService: monetizationService),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: accentColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BuyCoinsScreen(monetizationService: monetizationService),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: textColor),
            onPressed: () {
              // Settings
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const MatchingScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                  ),
                );
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}