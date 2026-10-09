import 'package:flutter/material.dart';

import '../theme.dart';

class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = 140, this.wink = false});

  final double size;
  final bool wink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Островок, ваш турагент',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _MascotPainter(wink)),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter(this.wink);
  final bool wink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.width * .46,
      Paint()..color = AppColors.mint,
    );

    final island = Rect.fromCenter(
      center: Offset(center.dx, size.height * .65),
      width: size.width * .68,
      height: size.height * .23,
    );
    canvas.drawOval(island, Paint()..color = AppColors.leaf);

    final trunk = Paint()
      ..color = const Color(0xFF9E6B38)
      ..strokeWidth = size.width * .045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .49, size.height * .56),
      Offset(size.width * .46, size.height * .29),
      trunk,
    );

    final leaf = Paint()
      ..color = AppColors.forest
      ..strokeWidth = size.width * .065
      ..strokeCap = StrokeCap.round;
    final crown = Offset(size.width * .46, size.height * .28);
    for (final direction in const [
      Offset(-.18, -.04),
      Offset(-.13, -.13),
      Offset(.02, -.16),
      Offset(.16, -.09),
      Offset(.18, .03),
    ]) {
      canvas.drawLine(
        crown,
        Offset(
          crown.dx + direction.dx * size.width,
          crown.dy + direction.dy * size.height,
        ),
        leaf,
      );
    }

    final eyePaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = size.width * .025
      ..strokeCap = StrokeCap.round;
    final eyeY = size.height * .62;
    if (wink) {
      canvas.drawLine(
        Offset(size.width * .38, eyeY),
        Offset(size.width * .44, eyeY),
        eyePaint,
      );
    } else {
      canvas.drawCircle(
        Offset(size.width * .41, eyeY),
        size.width * .025,
        eyePaint,
      );
    }
    canvas.drawCircle(
      Offset(size.width * .58, eyeY),
      size.width * .025,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .67),
        width: size.width * .18,
        height: size.height * .1,
      ),
      0,
      3.14,
      false,
      eyePaint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.wink != wink;
}
