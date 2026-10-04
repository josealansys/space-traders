import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/planet.dart';

/// Premium planet painter with multi-layered atmosphere, surface details,
/// rings, and ambient glow.
class PlanetPainter extends CustomPainter {
  final Planet planet;
  final double pulse; // 0.0-1.0 for ambient effects
  final double rotation; // for animated surface

  PlanetPainter({
    required this.planet,
    this.pulse = 0.0,
    this.rotation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) * 0.78;

    // Outer atmospheric glow (largest, faintest)
    _paintOuterGlow(canvas, center, radius);

    // Ring (if present) — paint behind planet
    if (planet.ringColor != null) {
      _paintRing(canvas, center, radius);
    }

    // Planet body with multi-stop radial gradient
    _paintBody(canvas, center, radius);

    // Surface details
    _paintSurfaceDetails(canvas, center, radius);

    // Cloud layer
    _paintClouds(canvas, center, radius);

    // Inner atmospheric rim
    _paintAtmosphere(canvas, center, radius);

    // Specular highlight (sun reflection)
    _paintSpecular(canvas, center, radius);
  }

  void _paintOuterGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          planet.color.withOpacity(0.4 + pulse * 0.2),
          planet.color.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius * 1.4, glowPaint);
  }

  void _paintRing(Canvas canvas, Offset center, double planetRadius) {
    // Ring back (behind planet)
    final ringBack = Paint()
      ..color = planet.ringColor!.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = planetRadius * 0.18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final ringRect = Rect.fromCenter(
      center: center,
      width: planetRadius * 2.6,
      height: planetRadius * 0.45,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.4);
    canvas.translate(-center.dx, -center.dy);
    // Back half of ring
    canvas.drawArc(ringRect, 0, pi, false, ringBack);
    canvas.restore();

    // Planet body (so ring back goes behind)
    _paintBodyOnly(canvas, center, planetRadius);

    // Ring front (in front of planet)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.4);
    canvas.translate(-center.dx, -center.dy);
    final ringFront = Paint()
      ..color = planet.ringColor!.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = planetRadius * 0.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    canvas.drawArc(ringRect, pi, pi, false, ringFront);

    // Ring inner detail line
    final ringInner = Paint()
      ..color = planet.ringColor!.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = planetRadius * 0.04;
    canvas.drawArc(ringRect, pi, pi, false, ringInner);
    canvas.restore();
  }

  void _paintBodyOnly(Canvas canvas, Offset center, double radius) {
    final bodyPaint = _bodyShader(center, radius);
    canvas.drawCircle(center, radius, bodyPaint);
  }

  Paint _bodyShader(Offset center, double radius) {
    return Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [
          _lighten(planet.color, 0.15),
          planet.color,
          _darken(planet.accentColor, 0.1),
          _darken(planet.accentColor, 0.4),
        ],
        stops: const [0.0, 0.4, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
  }

  void _paintBody(Canvas canvas, Offset center, double radius) {
    if (planet.ringColor == null) {
      _paintBodyOnly(canvas, center, radius);
    }
  }

  void _paintSurfaceDetails(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final detailPaint = Paint()
      ..color = _darken(planet.color, 0.2).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = _lighten(planet.color, 0.2).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final rng = Random(planet.id.hashCode);
    final angleBase = rotation * 2 * pi;

    switch (planet.governmentType) {
      case GovernmentType.agrarianRepublic:
        // Saturn-like bands
        for (int i = 0; i < 7; i++) {
          final y = -radius * 0.7 + (i * radius * 0.22);
          final bandPath = Path();
          final bandHeight = radius * (0.08 + rng.nextDouble() * 0.04);
          for (double x = -radius; x <= radius; x += 1) {
            final yWave = sin((x / radius) * pi * 3 + i) * radius * 0.02;
            if (x == -radius) {
              bandPath.moveTo(x, y + yWave);
            } else {
              bandPath.lineTo(x, y + yWave);
            }
          }
          bandPath.lineTo(radius, y + bandHeight);
          for (double x = radius; x >= -radius; x -= 1) {
            final yWave = sin((x / radius) * pi * 3 + i) * radius * 0.02;
            bandPath.lineTo(x, y + bandHeight + yWave);
          }
          bandPath.close();
          final clipped = Path()
            ..addOval(Rect.fromCircle(center: Offset(0, 0), radius: radius))
            ..addPath(bandPath, Offset.zero)
            ..fillType = PathFillType.evenOdd;
          canvas.drawPath(clipped, detailPaint);
        }
        break;

      case GovernmentType.miningConsortium:
        // Jupiter-like spots + bands
        for (int i = 0; i < 5; i++) {
          final y = -radius * 0.6 + (i * radius * 0.3);
          final bandPath = Path();
          for (double x = -radius; x <= radius; x += 1) {
            final yWave = sin((x / radius) * pi * 4) * radius * 0.015;
            if (x == -radius) {
              bandPath.moveTo(x, y + yWave);
            } else {
              bandPath.lineTo(x, y + yWave);
            }
          }
          for (double x = radius; x >= -radius; x -= 1) {
            final yWave = sin((x / radius) * pi * 4) * radius * 0.015;
            bandPath.lineTo(x, y + radius * 0.06 + yWave);
          }
          bandPath.close();
          canvas.save();
          canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(0, 0), radius: radius)));
          canvas.drawPath(bandPath, detailPaint);
          canvas.restore();
        }
        // Big red spot (Jupiter)
        final spotCenter = Offset(radius * 0.2, radius * 0.15);
        canvas.drawOval(
          Rect.fromCenter(center: spotCenter, width: radius * 0.25, height: radius * 0.15),
          Paint()..color = const Color(0xFFCC4422).withOpacity(0.7),
        );
        break;

      case GovernmentType.federalDemocracy:
        // Earth-like continents
        for (int i = 0; i < 5; i++) {
          final angle = (i * pi * 2 / 5) + angleBase;
          final dist = radius * 0.4;
          final cx = cos(angle) * dist;
          final cy = sin(angle) * dist * 0.6;
          // Continent shape (irregular blob)
          final path = Path();
          final size = radius * 0.25;
          for (int j = 0; j < 8; j++) {
            final a = j * pi / 4;
            final r = size * (0.6 + rng.nextDouble() * 0.5);
            final px = cx + cos(a) * r;
            final py = cy + sin(a) * r;
            if (j == 0) {
              path.moveTo(px, py);
            } else {
              path.lineTo(px, py);
            }
          }
          path.close();
          canvas.save();
          canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(0, 0), radius: radius)));
          canvas.drawPath(path, Paint()..color = const Color(0xFF2D6A4F).withOpacity(0.7));
          canvas.restore();
        }
        break;

      case GovernmentType.plutocraticCouncil:
        // Venus-like swirls
        for (int i = 0; i < 6; i++) {
          final swirl = Path();
          final startY = -radius * 0.5 + i * radius * 0.18;
          for (double x = -radius; x <= radius; x += 2) {
            final y = startY + sin((x / radius) * pi * 6 + i) * radius * 0.04;
            if (x == -radius) {
              swirl.moveTo(x, y);
            } else {
              swirl.lineTo(x, y);
            }
          }
          canvas.save();
          canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(0, 0), radius: radius)));
          canvas.drawPath(
            swirl,
            Paint()
              ..color = const Color(0xFFFFB347).withOpacity(0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = radius * 0.04,
          );
          canvas.restore();
        }
        break;

      case GovernmentType.researchDirectorate:
        // Neptune-like — gas giant with deep blue bands
        for (int i = 0; i < 6; i++) {
          final y = -radius * 0.7 + (i * radius * 0.25);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(0, y), width: radius * 1.8, height: radius * 0.08),
            Paint()..color = const Color(0xFF1A4A7A).withOpacity(0.6),
          );
        }
        break;

      case GovernmentType.miningCorporation:
        // Mercury-like — cratered
        for (int i = 0; i < 10; i++) {
          final angle = rng.nextDouble() * 2 * pi;
          final dist = rng.nextDouble() * radius * 0.6;
          final craterSize = radius * (0.04 + rng.nextDouble() * 0.05);
          final craterCenter = Offset(cos(angle) * dist, sin(angle) * dist * 0.8);
          // Save and clip to planet
          canvas.save();
          canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(0, 0), radius: radius)));
          // Crater shadow
          canvas.drawCircle(craterCenter, craterSize, detailPaint);
          // Crater highlight (top-left)
          canvas.drawCircle(
            craterCenter.translate(-craterSize * 0.3, -craterSize * 0.3),
            craterSize * 0.7,
            highlightPaint,
          );
          canvas.restore();
        }
        break;

      default:
        // Generic texture
        for (int i = 0; i < 8; i++) {
          final angle = rng.nextDouble() * 2 * pi;
          final dist = rng.nextDouble() * radius * 0.6;
          final size = radius * (0.05 + rng.nextDouble() * 0.04);
          final center2 = Offset(cos(angle) * dist, sin(angle) * dist);
          canvas.save();
          canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(0, 0), radius: radius)));
          canvas.drawCircle(center2, size, detailPaint);
          canvas.restore();
        }
    }

    canvas.restore();
  }

  void _paintClouds(Canvas canvas, Offset center, double radius) {
    if (planet.governmentType == GovernmentType.federalDemocracy ||
        planet.governmentType == GovernmentType.industrialCartel) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius * 0.98)));
      final rng = Random(planet.id.hashCode + 1);
      for (int i = 0; i < 4; i++) {
        final angle = rng.nextDouble() * 2 * pi;
        final dist = rng.nextDouble() * radius * 0.5;
        final cloudCenter = center + Offset(cos(angle) * dist, sin(angle) * dist);
        final cloudSize = radius * (0.2 + rng.nextDouble() * 0.15);
        canvas.drawOval(
          Rect.fromCenter(center: cloudCenter, width: cloudSize, height: cloudSize * 0.5),
          Paint()..color = Colors.white.withOpacity(0.12),
        );
      }
      canvas.restore();
    }
  }

  void _paintAtmosphere(Canvas canvas, Offset center, double radius) {
    // Bright rim
    final rimPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0),
        colors: [
          planet.color.withOpacity(0.0),
          planet.color.withOpacity(0.5),
          planet.color.withOpacity(0.0),
        ],
        stops: const [0.85, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.05))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius * 1.0, rimPaint);
  }

  void _paintSpecular(Canvas canvas, Offset center, double radius) {
    // Sun-like highlight in upper-left
    final specPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.5),
        radius: 0.5,
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, specPaint);
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(PlanetPainter oldDelegate) {
    return oldDelegate.planet.id != planet.id ||
        oldDelegate.pulse != pulse ||
        oldDelegate.rotation != rotation;
  }
}

/// Starfield painter for backgrounds.
class StarfieldPainter extends CustomPainter {
  final double density;
  final int seed;

  StarfieldPainter({this.density = 1.0, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final starCount = (80 * density).round();
    for (int i = 0; i < starCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final sizeFactor = rng.nextDouble();
      final starSize = sizeFactor < 0.7 ? 0.5 : (sizeFactor < 0.95 ? 1.0 : 1.5);
      final opacity = 0.3 + rng.nextDouble() * 0.5;
      // Slight color variation
      Color color = Colors.white;
      final colorRoll = rng.nextDouble();
      if (colorRoll < 0.1) color = const Color(0xFFAACCFF); // blue
      else if (colorRoll < 0.15) color = const Color(0xFFFFE5B4); // warm
      canvas.drawCircle(
        Offset(x, y),
        starSize,
        Paint()..color = color.withOpacity(opacity),
      );
      // Bright stars get a glow
      if (starSize > 1.0) {
        canvas.drawCircle(
          Offset(x, y),
          starSize * 2.5,
          Paint()
            ..color = color.withOpacity(opacity * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
        );
      }
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) =>
      oldDelegate.density != density || oldDelegate.seed != seed;
}
