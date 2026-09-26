import 'package:flutter/material.dart';

/// Zofir logo — crisp at any size, no asset needed.
/// Teal squircle + white split-Z + amber ÷ coin.
/// Matches assets/icon/zofir_logo.svg and app_icon.png.
class ZofirLogo extends StatelessWidget {
  final double size;
  final bool withShadow;
  const ZofirLogo({super.key, this.size = 48, this.withShadow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.235),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.35),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                ),
              ]
            : null,
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512;
    canvas.save();
    canvas.scale(s);

    // Background squircle with vertical teal gradient
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 8, 496, 496),
      const Radius.circular(120),
    );
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
      ).createShader(const Rect.fromLTWH(0, 0, 512, 512));
    canvas.drawRRect(bgRect, bgPaint);

    // Top gloss
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 8, 496, 260),
        const Radius.circular(120),
      ),
      Paint()..color = const Color(0x14FFFFFF),
    );

    // White Z
    final zPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 58
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(140, 162), const Offset(340, 162), zPaint);
    canvas.drawLine(const Offset(336, 168), const Offset(176, 340), zPaint);
    canvas.drawLine(const Offset(172, 350), const Offset(352, 350), zPaint);

    // Roommate dots on diagonal
    final dotPaint = Paint()..color = const Color(0xFF0F766E);
    canvas.drawCircle(const Offset(236, 262), 13, dotPaint);
    canvas.drawCircle(const Offset(278, 222), 13, dotPaint);

    // Amber coin
    final coinPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
      ).createShader(const Rect.fromLTWH(298, 298, 156, 156));
    canvas.drawCircle(const Offset(376, 376), 78, coinPaint);
    canvas.drawCircle(
      const Offset(376, 376),
      78,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke,
    );
    // ÷ symbol
    final w = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(376, 348), 11, w);
    canvas.drawCircle(const Offset(376, 404), 11, w);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(342, 370, 68, 12),
        const Radius.circular(6),
      ),
      w,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
