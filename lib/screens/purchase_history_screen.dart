import 'package:flutter/material.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  final List<PurchaseItem> purchases;

  const PurchaseHistoryScreen({super.key, required this.purchases});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Purchase History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final item = purchases[index];
          final isRecent = index == 0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isRecent ? Colors.cyanAccent.withOpacity(0.15) : Colors.white10,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (isRecent)
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
              ],
              border: isRecent ? Border.all(color: Colors.cyanAccent, width: 2) : null,
            ),
            child: ListTile(
              leading: Icon(
                item.icon,
                color: Colors.cyanAccent,
                size: 32,
              ),
              title: Text(
                item.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                item.date,
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: Text(
                item.amount,
                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PurchaseItem {
  final String title;
  final String date;
  final String amount;
  final IconData icon;

  PurchaseItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.icon,
  });
}
