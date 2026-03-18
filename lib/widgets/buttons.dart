import 'package:flutter/material.dart';
import '../constants.dart';

class LogoWidget extends StatelessWidget {
  final double size;

  const LogoWidget({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Abstract camera/chat bubble shape
          CustomPaint(
            size: Size(size * 0.6, size * 0.6),
            painter: LogoPainter(),
          ),
          // Glow effect
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = textColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Abstract camera shape
    final Path path = Path();
    // Lens
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.4), radius: size.width * 0.15));
    // Body
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.6), width: size.width * 0.4, height: size.height * 0.3),
      Radius.circular(size.width * 0.1),
    ));

    canvas.drawPath(path, paint);

    // Chat bubble tail
    final Path bubblePath = Path();
    bubblePath.moveTo(size.width * 0.3, size.height * 0.7);
    bubblePath.lineTo(size.width * 0.2, size.height * 0.8);
    bubblePath.lineTo(size.width * 0.3, size.height * 0.9);
    canvas.drawPath(bubblePath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Widget buildControlButton({
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
  double size = 60,
  bool glow = false,
  String? label,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
      if (label != null) ...[
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ],
  );
}