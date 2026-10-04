import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/commodity.dart';

/// Premium cargo icon painter with gradients, glow, and detail.
class CargoIconPainter extends CustomPainter {
  final Commodity commodity;
  final double size;
  final bool highlighted;
  final double pulse;

  CargoIconPainter({
    required this.commodity,
    this.size = 32.0,
    this.highlighted = false,
    this.pulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;

    // Outer glow if highlighted
    if (highlighted) {
      canvas.drawCircle(
        Offset(s / 2, s / 2),
        s * 0.55,
        Paint()
          ..color = _getCategoryColor().withOpacity(0.4 + pulse * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Hexagon background (sci-fi feel)
    final hexPath = _hexPath(s);
    final bg = Paint()
      ..shader = RadialGradient(
        colors: [
          _getCategoryColor().withOpacity(0.4),
          _getCategoryColor().withOpacity(0.1),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawPath(hexPath, bg);

    // Border
    final borderColor = _getCategoryColor();
    final border = Paint()
      ..color = borderColor.withOpacity(highlighted ? 1.0 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 2.0 : 1.2;
    canvas.drawPath(hexPath, border);

    // Inner shape based on commodity
    _paintIcon(canvas, size, s);
  }

  Color _getCategoryColor() {
    switch (commodity.category) {
      case 'essential': return const Color(0xFF00E676);
      case 'industrial': return const Color(0xFFFF9500);
      case 'tech': return const Color(0xFF00D9FF);
      case 'luxury': return const Color(0xFFB388FF);
      case 'illegal': return const Color(0xFFFF3D57);
      default: return Colors.grey;
    }
  }

  Path _hexPath(double s) {
    final path = Path();
    final cx = s / 2;
    final cy = s / 2;
    final r = s * 0.45;
    for (int i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3;
      final x = cx + cos(a) * r;
      final y = cy + sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _paintIcon(Canvas canvas, Size size, double s) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final color = _getCategoryColor();
    final paint = Paint()..color = color;
    final lightPaint = Paint()..color = Colors.white.withOpacity(0.5);
    final darkPaint = Paint()..color = Colors.black.withOpacity(0.3);

    switch (commodity.icon) {
      case 'food':
        // Apple-like
        canvas.drawCircle(Offset(cx - s * 0.12, cy + s * 0.08), s * 0.18, paint);
        canvas.drawCircle(Offset(cx + s * 0.12, cy + s * 0.08), s * 0.18, paint);
        // Highlight
        canvas.drawCircle(Offset(cx - s * 0.06, cy), s * 0.06, lightPaint);
        // Stem
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy - s * 0.2), width: s * 0.04, height: s * 0.1),
          darkPaint,
        );
        break;

      case 'water':
        // Droplet
        final path = Path()
          ..moveTo(cx, cy - s * 0.25)
          ..quadraticBezierTo(cx + s * 0.22, cy, cx, cy + s * 0.25)
          ..quadraticBezierTo(cx - s * 0.22, cy, cx, cy - s * 0.25);
        canvas.drawPath(path, paint);
        // Highlight
        canvas.drawCircle(Offset(cx - s * 0.05, cy - s * 0.05), s * 0.04, lightPaint);
        break;

      case 'fuel':
        // Canister with details
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy + s * 0.02), width: s * 0.4, height: s * 0.5),
            Radius.circular(s * 0.05),
          ),
          paint,
        );
        // Nozzle
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy - s * 0.28), width: s * 0.18, height: s * 0.08),
          darkPaint,
        );
        // Label
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy + s * 0.05), width: s * 0.2, height: s * 0.1),
          lightPaint,
        );
        break;

      case 'ore':
        // Crystal cluster
        final p1 = Path()
          ..moveTo(cx, cy - s * 0.25)
          ..lineTo(cx + s * 0.15, cy)
          ..lineTo(cx, cy + s * 0.25)
          ..lineTo(cx - s * 0.15, cy)
          ..close();
        canvas.drawPath(p1, paint);
        // Side crystal
        final sideCrystal = Path()
          ..moveTo(cx - s * 0.08, cy - s * 0.05)
          ..lineTo(cx - s * 0.18, cy + s * 0.05)
          ..lineTo(cx - s * 0.1, cy + s * 0.1)
          ..close();
        canvas.drawPath(sideCrystal, Paint()..color = color.withOpacity(0.7));
        break;

      case 'electronics':
        // Microchip
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: s * 0.5, height: s * 0.5),
          paint,
        );
        // Pins (top + bottom)
        for (int i = 0; i < 3; i++) {
          final x = cx - s * 0.2 + i * s * 0.2;
          canvas.drawRect(
            Rect.fromCenter(center: Offset(x, cy - s * 0.3), width: s * 0.04, height: s * 0.1),
            lightPaint,
          );
          canvas.drawRect(
            Rect.fromCenter(center: Offset(x, cy + s * 0.3), width: s * 0.04, height: s * 0.1),
            lightPaint,
          );
        }
        // Center dot
        canvas.drawCircle(Offset(cx, cy), s * 0.05, darkPaint);
        break;

      case 'medicine':
        // Cross with shadow
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx + 1, cy + 1), width: s * 0.18, height: s * 0.45),
          darkPaint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: s * 0.18, height: s * 0.45),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx + 1, cy + 1), width: s * 0.45, height: s * 0.18),
          darkPaint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: s * 0.45, height: s * 0.18),
          paint,
        );
        break;

      case 'luxury':
        // Diamond
        final path = Path()
          ..moveTo(cx, cy - s * 0.25)
          ..lineTo(cx + s * 0.2, cy - s * 0.05)
          ..lineTo(cx + s * 0.08, cy + s * 0.1)
          ..lineTo(cx, cy + s * 0.25)
          ..lineTo(cx - s * 0.08, cy + s * 0.1)
          ..lineTo(cx - s * 0.2, cy - s * 0.05)
          ..close();
        canvas.drawPath(path, paint);
        // Inner facet
        final innerPath = Path()
          ..moveTo(cx, cy - s * 0.15)
          ..lineTo(cx + s * 0.1, cy)
          ..lineTo(cx, cy + s * 0.1)
          ..lineTo(cx - s * 0.1, cy)
          ..close();
        canvas.drawPath(innerPath, lightPaint);
        break;

      case 'tech':
        // Gear
        final center2 = Offset(cx, cy);
        final outerR = s * 0.22;
        final innerR = s * 0.16;
        final teeth = 8;
        final path = Path();
        for (int i = 0; i < teeth * 2; i++) {
          final a = i * pi / teeth;
          final r = i.isEven ? outerR : innerR;
          final x = center2.dx + cos(a) * r;
          final y = center2.dy + sin(a) * r;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawCircle(center2, s * 0.08, darkPaint);
        break;

      case 'contraband':
        // Warning triangle
        final path = Path()
          ..moveTo(cx, cy - s * 0.25)
          ..lineTo(cx + s * 0.25, cy + s * 0.18)
          ..lineTo(cx - s * 0.25, cy + s * 0.18)
          ..close();
        canvas.drawPath(path, paint);
        // Exclamation
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy + s * 0.02), width: s * 0.05, height: s * 0.12),
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(Offset(cx, cy + s * 0.13), s * 0.025, Paint()..color = Colors.white);
        break;
    }
  }

  @override
  bool shouldRepaint(CargoIconPainter oldDelegate) {
    return oldDelegate.commodity.id != commodity.id ||
        oldDelegate.highlighted != highlighted ||
        oldDelegate.pulse != pulse;
  }
}
