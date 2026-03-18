import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String username;
  final String profilePictureUrl;
  final int coins;
  final String gender;
  final String region;
  final String joinDate;
  final VoidCallback onEditProfile;
  final VoidCallback onSettings;
  final VoidCallback onPurchaseHistory;
  final VoidCallback onLogout;
  final VoidCallback onCoinStore;
  final int? dailyStreak;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.profilePictureUrl,
    required this.coins,
    required this.gender,
    required this.region,
    required this.joinDate,
    required this.onEditProfile,
    required this.onSettings,
    required this.onPurchaseHistory,
    required this.onLogout,
    required this.onCoinStore,
    this.dailyStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.7),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 56,
                        backgroundImage: NetworkImage(profilePictureUrl),
                        backgroundColor: Colors.grey.shade900,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.amberAccent, size: 24),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.cyanAccent, size: 28),
                      onPressed: onCoinStore,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Gender', gender),
                _buildInfoRow('Region', region),
                _buildInfoRow('Joined', joinDate),
                if (dailyStreak != null) ...[
                  const SizedBox(height: 8),
                  _buildStreakIndicator(dailyStreak!),
                ],
                const SizedBox(height: 32),
                _buildNeonButton('Edit Profile', onEditProfile),
                const SizedBox(height: 16),
                _buildNeonButton('Settings', onSettings),
                const SizedBox(height: 16),
                _buildNeonButton('Purchase History', onPurchaseHistory),
                const SizedBox(height: 16),
                _buildNeonButton('Logout', onLogout, color: Colors.redAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakIndicator(int streak) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 24),
        const SizedBox(width: 4),
        Text(
          'Streak: $streak days',
          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildNeonButton(String text, VoidCallback onTap, {Color color = Colors.cyanAccent}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Colors.cyanAccent,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
