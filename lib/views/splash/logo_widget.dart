import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LogoWidget({super.key, this.size = 120, this.color});

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [logoColor, logoColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(size * 0.16),
        boxShadow: [
          BoxShadow(
            color: logoColor.withOpacity(0.3),
            blurRadius: size * 0.16,
            spreadRadius: size * 0.04,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background pattern
          CustomPaint(
            size: Size(size, size),
            painter: _LogoPatternPainter(color: Colors.white.withOpacity(0.1)),
          ),
          // Main icon
          Icon(Icons.eco, size: size * 0.5, color: Colors.white),
          // Environmental elements
          Positioned(
            top: size * 0.15,
            right: size * 0.15,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.2,
            left: size * 0.2,
            child: Container(
              width: size * 0.06,
              height: size * 0.06,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPatternPainter extends CustomPainter {
  final Color color;

  _LogoPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Create a subtle wave pattern
    final waveHeight = size.height * 0.05;
    final waveCount = 3;

    for (int i = 0; i < waveCount; i++) {
      final y = size.height * 0.3 + (i * size.height * 0.15);
      path.moveTo(size.width * 0.2, y);

      for (
        double x = size.width * 0.2;
        x <= size.width * 0.8;
        x += size.width * 0.1
      ) {
        final waveY =
            y +
            waveHeight *
                0.5 *
                (1 + (i % 2 == 0 ? 1 : -1) * (0.5 + 0.5 * (x / size.width)));
        path.lineTo(x, waveY);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
