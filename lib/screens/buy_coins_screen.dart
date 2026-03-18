import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/monetization_service.dart';
import '../models/monetization_models.dart';

class BuyCoinsScreen extends StatefulWidget {
  final MonetizationService monetizationService;

  const BuyCoinsScreen({
    super.key,
    required this.monetizationService,
  });

  @override
  State<BuyCoinsScreen> createState() => _BuyCoinsScreenState();
}

class _BuyCoinsScreenState extends State<BuyCoinsScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Buy Coins',
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a coin package',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: widget.monetizationService.coinPackages.length,
                itemBuilder: (context, index) {
                  final coinPackage = widget.monetizationService.coinPackages[index];
                  return _buildCoinPackageCard(coinPackage);
                },
              ),
            ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: secondaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: secondaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinPackageCard(CoinPackage coinPackage) {
    final coinPerDollar = coinPackage.coinAmount / coinPackage.price;
    final isBestValue = coinPerDollar == widget.monetizationService.coinPackages
        .map((pkg) => pkg.coinAmount / pkg.price)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      color: coinPackage.isBundle ? accentColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: coinPackage.isBundle ? accentColor : (isBestValue ? accentColor : primaryColor.withOpacity(0.3)),
          width: coinPackage.isBundle ? 2 : (isBestValue ? 2 : 1),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  coinPackage.name,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (coinPackage.isBundle) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BUNDLE',
                      style: TextStyle(
                        color: backgroundColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (isBestValue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BEST VALUE',
                      style: TextStyle(
                        color: backgroundColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: accentColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${coinPackage.coinAmount} coins',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                if (coinPackage.bonusCoins != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '+ ${coinPackage.bonusCoins} bonus',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            if (coinPackage.bonusFeatures != null && coinPackage.bonusFeatures!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Includes: ${coinPackage.bonusFeatures!.join(", ")}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${coinPackage.currency} ${coinPackage.price}',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _purchasePackage(coinPackage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: coinPackage.isBundle ? accentColor : primaryColor,
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      )
                    : Text(
                        coinPackage.isBundle ? 'Get Bundle!' : 'Buy Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchasePackage(CoinPackage coinPackage) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isStoreAvailable = await widget.monetizationService.isStoreAvailable();
      if (!isStoreAvailable) {
        throw Exception('In-app purchases are not available on this device');
      }

      await widget.monetizationService.buyCoinPackage(coinPackage.id);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase initiated for ${coinPackage.name}'),
            backgroundColor: accentColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}