import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/monetization_service.dart';

class CoinBalanceWidget extends StatefulWidget {
  final MonetizationService monetizationService;
  final bool showLowBalanceWarning;

  const CoinBalanceWidget({
    super.key,
    required this.monetizationService,
    this.showLowBalanceWarning = true,
  });

  @override
  State<CoinBalanceWidget> createState() => _CoinBalanceWidgetState();
}

class _CoinBalanceWidgetState extends State<CoinBalanceWidget> {
  int _coinBalance = 0;
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    _loadCoinBalance();
    widget.monetizationService.coinBalanceStream.listen((balance) {
      setState(() {
        _coinBalance = balance.balance;
        _showWarning = widget.showLowBalanceWarning && _coinBalance < 20;
      });
    });
  }

  Future<void> _loadCoinBalance() async {
    final balance = await widget.monetizationService.getCoinBalance();
    setState(() {
      _coinBalance = balance.balance;
      _showWarning = widget.showLowBalanceWarning && _coinBalance < 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _showWarning ? secondaryColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _showWarning ? secondaryColor.withOpacity(0.5) : primaryColor.withOpacity(0.3),
          width: _showWarning ? 2 : 1,
        ),
        boxShadow: _showWarning ? [
          BoxShadow(
            color: secondaryColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            color: _showWarning ? secondaryColor : accentColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$_coinBalance',
            style: TextStyle(
              color: _showWarning ? secondaryColor : textColor,
              fontSize: 16,
              fontWeight: _showWarning ? FontWeight.bold : FontWeight.bold,
            ),
          ),
          if (_showWarning) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.warning,
              color: secondaryColor,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }
}