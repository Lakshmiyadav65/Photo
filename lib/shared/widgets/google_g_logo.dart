// The official four-colour Google "G", reproduced exactly from the prototype's
// inline SVG (Downloads/gang-roll-prototype.html, the "Continue with Google"
// button). Drawn with a CustomPainter so it scales crisply at any size and
// needs no asset / flutter_svg dependency.
//
// The path data is the canonical 24×24 Google logo; each of the four arcs is a
// separate fill. It always paints centred in a square [size]×[size] box, so it
// aligns perfectly next to button text.

import 'package:flutter/material.dart';

class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  // Brand colours, matching the prototype SVG fills.
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    // Path data is authored in the SVG's 24×24 viewBox; scale to fit.
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    canvas.drawPath(_bluePath(), paint..color = _blue);
    canvas.drawPath(_greenPath(), paint..color = _green);
    canvas.drawPath(_yellowPath(), paint..color = _yellow);
    canvas.drawPath(_redPath(), paint..color = _red);

    canvas.restore();
  }

  Path _bluePath() => Path()
    ..moveTo(22.56, 12.25)
    ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
    ..lineTo(12.0, 10.0)
    ..lineTo(12.0, 14.26)
    ..lineTo(17.92, 14.26)
    ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
    ..lineTo(15.71, 20.34)
    ..lineTo(19.28, 20.34)
    ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
    ..close();

  Path _greenPath() => Path()
    ..moveTo(12.0, 23.0)
    ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
    ..lineTo(15.71, 17.57)
    ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
    ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
    ..lineTo(2.18, 14.1)
    ..lineTo(2.18, 16.94)
    ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
    ..close();

  Path _yellowPath() => Path()
    ..moveTo(5.84, 14.09)
    ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
    ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
    ..lineTo(5.84, 7.07)
    ..lineTo(2.18, 7.07)
    ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
    ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93)
    ..lineTo(5.03, 14.71)
    ..lineTo(5.84, 14.09)
    ..close();

  Path _redPath() => Path()
    ..moveTo(12.0, 5.38)
    ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
    ..lineTo(19.36, 3.87)
    ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
    ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.07)
    ..lineTo(5.84, 9.91)
    ..cubicTo(6.71, 7.31, 9.14, 5.38, 12.0, 5.38)
    ..close();

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
