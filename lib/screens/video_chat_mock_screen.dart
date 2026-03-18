import 'package:flutter/material.dart';

class VideoChatMockScreen extends StatelessWidget {
  const VideoChatMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Video feed placeholder
          Container(
            color: const Color(0xFF1E1E1E),
            child: const Center(
              child: Icon(Icons.videocam, color: Colors.cyanAccent, size: 120),
            ),
          ),
          // Coin balance
          Positioned(
            top: 48,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.monetization_on, color: Colors.amberAccent, size: 24),
                  SizedBox(width: 4),
                  Text('1,200', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ),
          // Floating buttons
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton(Icons.refresh, Colors.cyanAccent, 'Reconnect'),
                _buildCircleButton(Icons.filter_alt, Colors.purpleAccent, 'Gender'),
                _buildCircleButton(Icons.language, Colors.pinkAccent, 'Region'),
                _buildCircleButton(Icons.mic_off, Colors.white, 'Mute'),
                _buildCircleButton(Icons.cameraswitch, Colors.amberAccent, 'Flip'),
                _buildCircleButton(Icons.call_end, Colors.redAccent, 'End'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}
