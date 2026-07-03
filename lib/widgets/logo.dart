import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SnapCleanMark extends StatelessWidget {
  final double size;
  const SnapCleanMark({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: SnapCleanMarkPainter()));
  }
}

class SnapCleanMarkPainter extends CustomPainter {
  const SnapCleanMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 66;
    canvas.save();
    canvas.scale(scale);

    final card = RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 7, 42, 52), const Radius.circular(11));
    canvas.drawRRect(
        card.shift(const Offset(0, 2)),
        Paint()
          ..color = const Color(0x220891B2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawRRect(card, Paint()..color = Colors.white);
    canvas.drawRRect(
      card,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      Path()
        ..moveTo(39, 7)
        ..lineTo(52, 20)
        ..lineTo(39, 20)
        ..close(),
      Paint()..color = const Color(0xFFBAE6FD),
    );

    final line = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(18, 31), const Offset(43, 31), line);
    canvas.drawLine(const Offset(18, 40), const Offset(36, 40), line);

    canvas.drawPath(
      Path()
        ..moveTo(52, 35)
        ..lineTo(55.5, 43.5)
        ..lineTo(64, 47)
        ..lineTo(55.5, 50.5)
        ..lineTo(52, 59)
        ..lineTo(48.5, 50.5)
        ..lineTo(40, 47)
        ..lineTo(48.5, 43.5)
        ..close(),
      Paint()..color = AppColors.brand,
    );
    canvas.drawCircle(
        const Offset(15, 16), 3.2, Paint()..color = AppColors.mint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrandHeader extends StatelessWidget {
  final String subtitle;
  const BrandHeader({this.subtitle = 'Screenshot cleanup', super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFA5F3FC)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x2238BDF8),
                  blurRadius: 22,
                  offset: Offset(0, 10))
            ],
          ),
          child: const SnapCleanMark(size: 66),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('SnapClean',
                    style: TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink)),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: AppText.label.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
