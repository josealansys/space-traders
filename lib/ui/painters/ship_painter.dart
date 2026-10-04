import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/ship.dart';

/// Premium ship painter — detailed, multi-layered designs per ship class.
class ShipPainter extends CustomPainter {
  final Ship ship;
  final bool damaged;
  final double thrust; // 0.0-1.0
  final bool selected;

  ShipPainter({
    required this.ship,
    this.damaged = false,
    this.thrust = 0.5,
    this.selected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.shortestSide / 120;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Selection glow
    if (selected) {
      canvas.drawCircle(
        Offset.zero,
        size.shortestSide * 0.45,
        Paint()
          ..color = AppThemeColors.primary.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Engine thrust (always behind ship)
    _paintThrust(canvas, scale);

    // Ship body based on type
    switch (ship.typeId) {
      case 'scout':
        _paintScout(canvas, scale);
        break;
      case 'freighter':
        _paintFreighter(canvas, scale);
        break;
      case 'cruiser':
        _paintCruiser(canvas, scale);
        break;
      case 'dreadnought':
        _paintDreadnought(canvas, scale);
        break;
      default:
        _paintScout(canvas, scale);
    }

    // Damage overlay
    if (damaged) {
      _paintDamage(canvas, scale);
    }

    canvas.restore();
  }

  // === THRUST GLOW ===
  void _paintThrust(Canvas canvas, double scale) {
    final colors = thrustColors(ship.typeId);
    final center = Offset(0, 32 * scale);
    for (int i = 0; i < 4; i++) {
      final radius = (8 + i * 6) * scale;
      final opacity = (0.8 - i * 0.18) * thrust;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = colors[i % colors.length].withOpacity(opacity.clamp(0, 1).toDouble())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + i * 2.0),
      );
    }
    // Hot core
    canvas.drawCircle(
      center,
      4 * scale,
      Paint()..color = Colors.white.withOpacity(0.7 * thrust),
    );
  }

  List<Color> thrustColors(String typeId) {
    switch (typeId) {
      case 'scout': return [const Color(0xFF00D9FF), const Color(0xFF4FC3F7), const Color(0xFF80DEEA), const Color(0xFFB2EBF2)];
      case 'freighter': return [const Color(0xFFFF6B35), const Color(0xFFFFA726), const Color(0xFFFFCC80), const Color(0xFFFFE0B2)];
      case 'cruiser': return [const Color(0xFFFFB627), const Color(0xFFFFD54F), const Color(0xFFFFE082), const Color(0xFFFFF8E1)];
      case 'dreadnought': return [const Color(0xFFFF3D57), const Color(0xFFE57373), const Color(0xFFEF9A9A), const Color(0xFFFFCDD2)];
      default: return [const Color(0xFF00D9FF), const Color(0xFF4FC3F7), const Color(0xFF80DEEA), const Color(0xFFB2EBF2)];
    }
  }

  // === SCOUT: Sleek arrow / delta fighter ===
  void _paintScout(Canvas canvas, double scale) {
    // Main delta body
    final body = Paint()..color = const Color(0xFF6B85A8);
    final dark = Paint()..color = const Color(0xFF3D4F6B);
    final accent = Paint()..color = const Color(0xFF00D9FF);
    final accentGlow = Paint()..color = const Color(0xFF00D9FF);
    final highlight = Paint()..color = const Color(0xFFA8BCD4);

    // Underside shadow
    final underShadow = Path()
      ..moveTo(0, -36 * scale)
      ..lineTo(14 * scale, -8 * scale)
      ..lineTo(20 * scale, 8 * scale)
      ..lineTo(24 * scale, 24 * scale)
      ..lineTo(-24 * scale, 24 * scale)
      ..lineTo(-20 * scale, 8 * scale)
      ..lineTo(-14 * scale, -8 * scale);
    canvas.drawPath(underShadow, dark);

    // Top body
    final bodyPath = Path()
      ..moveTo(0, -36 * scale)
      ..lineTo(12 * scale, -10 * scale)
      ..lineTo(18 * scale, 6 * scale)
      ..lineTo(22 * scale, 20 * scale)
      ..lineTo(-22 * scale, 20 * scale)
      ..lineTo(-18 * scale, 6 * scale)
      ..lineTo(-12 * scale, -10 * scale)
      ..close();
    canvas.drawPath(bodyPath, body);

    // Top edge highlight (3D effect)
    final topHighlight = Path()
      ..moveTo(0, -36 * scale)
      ..lineTo(10 * scale, -8 * scale)
      ..lineTo(-10 * scale, -8 * scale)
      ..close();
    canvas.drawPath(topHighlight, highlight);

    // Cockpit dome
    final cockpit = Path()
      ..moveTo(0, -22 * scale)
      ..quadraticBezierTo(7 * scale, -14 * scale, 0, -6 * scale)
      ..quadraticBezierTo(-7 * scale, -14 * scale, 0, -22 * scale)
      ..close();
    canvas.drawPath(cockpit, dark);
    // Cockpit glow
    final cockpitGlow = Path()
      ..moveTo(0, -20 * scale)
      ..quadraticBezierTo(5 * scale, -14 * scale, 0, -8 * scale)
      ..quadraticBezierTo(-5 * scale, -14 * scale, 0, -20 * scale)
      ..close();
    canvas.drawPath(cockpitGlow, accent);

    // Wings
    final wingL = Path()
      ..moveTo(-12 * scale, 0)
      ..lineTo(-34 * scale, 18 * scale)
      ..lineTo(-30 * scale, 22 * scale)
      ..lineTo(-12 * scale, 8 * scale)
      ..close();
    canvas.drawPath(wingL, dark);
    final wingR = Path()
      ..moveTo(12 * scale, 0)
      ..lineTo(34 * scale, 18 * scale)
      ..lineTo(30 * scale, 22 * scale)
      ..lineTo(12 * scale, 8 * scale)
      ..close();
    canvas.drawPath(wingR, dark);

    // Wing accent lines
    canvas.drawLine(
      Offset(-20 * scale, 12 * scale),
      Offset(-28 * scale, 18 * scale),
      Paint()..color = accent.color..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(20 * scale, 12 * scale),
      Offset(28 * scale, 18 * scale),
      Paint()..color = accent.color..strokeWidth = 1.5,
    );

    // Engine ports (twin)
    final engineGlow = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF00D9FF), const Color(0xFF006B85)],
      ).createShader(Rect.fromCenter(center: Offset(0, 28 * scale), width: 16 * scale, height: 8 * scale));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 28 * scale), width: 16 * scale, height: 8 * scale),
      engineGlow,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(-8 * scale, 28 * scale), width: 3 * scale, height: 6 * scale),
      accent,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(8 * scale, 28 * scale), width: 3 * scale, height: 6 * scale),
      accent,
    );

    // Nose weapon
    canvas.drawCircle(Offset(0, -32 * scale), 2 * scale, accent);
  }

  // === FREIGHTER: Heavy industrial hauler ===
  void _paintFreighter(Canvas canvas, double scale) {
    final body = Paint()..color = const Color(0xFF8B6F47);
    final dark = Paint()..color = const Color(0xFF5C4A30);
    final accent = Paint()..color = const Color(0xFFFFB627);
    final glow = Paint()..color = const Color(0xFFFFB627);
    final highlight = Paint()..color = const Color(0xFFB89968);
    final panel = Paint()..color = const Color(0xFF3D2F1F);

    // Underside
    final underShadow = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, 4 * scale), width: 64 * scale, height: 44 * scale),
        Radius.circular(5 * scale),
      ));
    canvas.drawPath(underShadow, dark);

    // Main hull
    final hullRect = Rect.fromCenter(center: Offset(0, 0), width: 64 * scale, height: 40 * scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hullRect, Radius.circular(4 * scale)),
      body,
    );

    // Top highlight strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -16 * scale), width: 64 * scale, height: 6 * scale),
        Radius.circular(2 * scale),
      ),
      highlight,
    );

    // Cargo containers with separation lines
    for (int i = -2; i <= 2; i++) {
      final x = i * 12 * scale;
      // Container body
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, 0), width: 10 * scale, height: 30 * scale),
        dark,
      );
      // Container highlight
      canvas.drawLine(
        Offset(x - 4 * scale, -14 * scale),
        Offset(x - 4 * scale, 14 * scale),
        Paint()..color = panel.color..strokeWidth = 0.5,
      );
      // Container hatch
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, 4 * scale), width: 6 * scale, height: 4 * scale),
        panel,
      );
    }

    // Central spine
    canvas.drawLine(
      Offset(0, -14 * scale),
      Offset(0, 14 * scale),
      Paint()..color = accent.color..strokeWidth = 2,
    );

    // Bridge / command tower
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -22 * scale), width: 14 * scale, height: 8 * scale),
        Radius.circular(2 * scale),
      ),
      accent,
    );
    // Bridge window
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -22 * scale), width: 10 * scale, height: 3 * scale),
      panel,
    );

    // 4 engines (corner configuration)
    for (final dx in [-1, 1]) {
      for (final dy in [-1, 1]) {
        final ex = dx * 22 * scale;
        final ey = dy * 14 * scale;
        // Engine housing
        canvas.drawRect(
          Rect.fromCenter(center: Offset(ex, ey), width: 8 * scale, height: 8 * scale),
          dark,
        );
        // Engine glow
        canvas.drawOval(
          Rect.fromCenter(center: Offset(ex, ey + 6 * scale), width: 6 * scale, height: 4 * scale),
          Paint()..color = glow.color.withOpacity(0.7),
        );
      }
    }

    // Side rails
    canvas.drawLine(
      Offset(-32 * scale, 0),
      Offset(32 * scale, 0),
      Paint()..color = panel.color..strokeWidth = 1,
    );
  }

  // === CRUISER: Warship with command spire ===
  void _paintCruiser(Canvas canvas, double scale) {
    final body = Paint()..color = const Color(0xFF3D5876);
    final dark = Paint()..color = const Color(0xFF1F2D3D);
    final accent = Paint()..color = const Color(0xFFFFB627);
    final weapon = Paint()..color = const Color(0xFFFF3D57);
    final highlight = Paint()..color = const Color(0xFF5A7090);
    final panel = Paint()..color = const Color(0xFF0F1825);
    final glow = Paint()..color = const Color(0xFF00D9FF);

    // Underside
    final underPath = Path()
      ..moveTo(0, -38 * scale)
      ..lineTo(22 * scale, -8 * scale)
      ..lineTo(32 * scale, 8 * scale)
      ..lineTo(32 * scale, 24 * scale)
      ..lineTo(20 * scale, 30 * scale)
      ..lineTo(-20 * scale, 30 * scale)
      ..lineTo(-32 * scale, 24 * scale)
      ..lineTo(-32 * scale, 8 * scale)
      ..lineTo(-22 * scale, -8 * scale);
    canvas.drawPath(underPath, dark);

    // Main body
    final bodyPath = Path()
      ..moveTo(0, -40 * scale)
      ..lineTo(20 * scale, -10 * scale)
      ..lineTo(30 * scale, 8 * scale)
      ..lineTo(30 * scale, 22 * scale)
      ..lineTo(18 * scale, 28 * scale)
      ..lineTo(-18 * scale, 28 * scale)
      ..lineTo(-30 * scale, 22 * scale)
      ..lineTo(-30 * scale, 8 * scale)
      ..lineTo(-20 * scale, -10 * scale)
      ..close();
    canvas.drawPath(bodyPath, body);

    // Top highlight
    final topPath = Path()
      ..moveTo(0, -40 * scale)
      ..lineTo(15 * scale, -8 * scale)
      ..lineTo(-15 * scale, -8 * scale)
      ..close();
    canvas.drawPath(topPath, highlight);

    // Command spire (vertical tower)
    final spire = Path()
      ..moveTo(-6 * scale, -14 * scale)
      ..lineTo(6 * scale, -14 * scale)
      ..lineTo(8 * scale, -28 * scale)
      ..lineTo(0, -34 * scale)
      ..lineTo(-8 * scale, -28 * scale)
      ..close();
    canvas.drawPath(spire, dark);
    // Spire antenna
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -32 * scale), width: 1, height: 6 * scale),
      glow,
    );
    // Spire window
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -22 * scale), width: 6 * scale, height: 4 * scale),
      panel,
    );

    // Bridge dome
    canvas.drawCircle(Offset(0, -18 * scale), 4 * scale, accent);

    // 3 main weapon turrets
    for (int i = -1; i <= 1; i++) {
      final wx = i * 14 * scale;
      // Turret base
      canvas.drawCircle(Offset(wx, 22 * scale), 4 * scale, dark);
      // Turret top (red)
      canvas.drawCircle(Offset(wx, 22 * scale), 2.5 * scale, weapon);
      // Turret barrel
      canvas.drawRect(
        Rect.fromCenter(center: Offset(wx, 30 * scale), width: 2 * scale, height: 8 * scale),
        dark,
      );
    }

    // Side weapon pods
    for (final dx in [-1, 1]) {
      canvas.drawCircle(Offset(dx * 26 * scale, 8 * scale), 3 * scale, dark);
      canvas.drawCircle(Offset(dx * 26 * scale, 8 * scale), 1.5 * scale, weapon);
    }

    // Hull panel lines
    canvas.drawLine(
      Offset(-25 * scale, 4 * scale),
      Offset(25 * scale, 4 * scale),
      Paint()..color = panel.color..strokeWidth = 0.8,
    );
    canvas.drawLine(
      Offset(-20 * scale, 16 * scale),
      Offset(20 * scale, 16 * scale),
      Paint()..color = panel.color..strokeWidth = 0.8,
    );

    // Engine glow at bottom
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-12 * scale, 32 * scale), width: 8 * scale, height: 4 * scale),
      Paint()..color = glow.color.withOpacity(0.6),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(12 * scale, 32 * scale), width: 8 * scale, height: 4 * scale),
      Paint()..color = glow.color.withOpacity(0.6),
    );
  }

  // === DREADNOUGHT: Massive capital warship ===
  void _paintDreadnought(Canvas canvas, double scale) {
    final body = Paint()..color = const Color(0xFF1A2530);
    final dark = Paint()..color = const Color(0xFF0A1018);
    final accent = Paint()..color = const Color(0xFFFFB627);
    final weapon = Paint()..color = const Color(0xFFFF3D57);
    final highlight = Paint()..color = const Color(0xFF2C3E50);
    final panel = Paint()..color = const Color(0xFF050810);
    final glow = Paint()..color = const Color(0xFFFF3D57);

    // Underside shadow
    final underPath = Path()
      ..moveTo(0, -44 * scale)
      ..lineTo(28 * scale, -20 * scale)
      ..lineTo(40 * scale, 0)
      ..lineTo(38 * scale, 18 * scale)
      ..lineTo(22 * scale, 32 * scale)
      ..lineTo(-22 * scale, 32 * scale)
      ..lineTo(-38 * scale, 18 * scale)
      ..lineTo(-40 * scale, 0)
      ..lineTo(-28 * scale, -20 * scale);
    canvas.drawPath(underPath, dark);

    // Main hull
    final hullPath = Path()
      ..moveTo(0, -46 * scale)
      ..lineTo(26 * scale, -22 * scale)
      ..lineTo(38 * scale, -2 * scale)
      ..lineTo(36 * scale, 16 * scale)
      ..lineTo(20 * scale, 30 * scale)
      ..lineTo(-20 * scale, 30 * scale)
      ..lineTo(-36 * scale, 16 * scale)
      ..lineTo(-38 * scale, -2 * scale)
      ..lineTo(-26 * scale, -22 * scale)
      ..close();
    canvas.drawPath(hullPath, body);

    // Top edge highlight
    final topPath = Path()
      ..moveTo(0, -46 * scale)
      ..lineTo(20 * scale, -18 * scale)
      ..lineTo(-20 * scale, -18 * scale)
      ..close();
    canvas.drawPath(topPath, highlight);

    // Bridge superstructure (massive, layered)
    final bridge1 = Path()
      ..moveTo(-12 * scale, -16 * scale)
      ..lineTo(12 * scale, -16 * scale)
      ..lineTo(14 * scale, -28 * scale)
      ..lineTo(0, -34 * scale)
      ..lineTo(-14 * scale, -28 * scale)
      ..close();
    canvas.drawPath(bridge1, dark);

    // Bridge tower
    final tower = Path()
      ..moveTo(-6 * scale, -26 * scale)
      ..lineTo(6 * scale, -26 * scale)
      ..lineTo(8 * scale, -38 * scale)
      ..lineTo(-8 * scale, -38 * scale)
      ..close();
    canvas.drawPath(tower, dark);

    // Tower antenna
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -40 * scale), width: 1, height: 6 * scale),
      accent,
    );

    // Bridge windows (gold stripe)
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -22 * scale), width: 18 * scale, height: 2 * scale),
      accent,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -32 * scale), width: 10 * scale, height: 2 * scale),
      accent,
    );

    // 5 weapon batteries along the bottom
    for (int i = -2; i <= 2; i++) {
      final wx = i * 10 * scale;
      // Turret base
      canvas.drawCircle(Offset(wx, 22 * scale), 4 * scale, dark);
      // Turret top (red)
      canvas.drawCircle(Offset(wx, 22 * scale), 2.5 * scale, weapon);
      // Twin barrels
      canvas.drawRect(
        Rect.fromCenter(center: Offset(wx - 1.5 * scale, 28 * scale), width: 1.5 * scale, height: 6 * scale),
        dark,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(wx + 1.5 * scale, 28 * scale), width: 1.5 * scale, height: 6 * scale),
        dark,
      );
    }

    // Side weapon pods
    for (final dx in [-1, 1]) {
      canvas.drawCircle(Offset(dx * 30 * scale, 0), 5 * scale, dark);
      canvas.drawCircle(Offset(dx * 30 * scale, 0), 3 * scale, weapon);
    }

    // Hull plate lines
    canvas.drawLine(
      Offset(-30 * scale, 8 * scale),
      Offset(30 * scale, 8 * scale),
      Paint()..color = panel.color..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(-25 * scale, 18 * scale),
      Offset(25 * scale, 18 * scale),
      Paint()..color = panel.color..strokeWidth = 0.8,
    );

    // Massive engine glow at bottom
    for (final dx in [-12, 0, 12]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(dx * scale, 36 * scale), width: 8 * scale, height: 4 * scale),
        Paint()..color = glow.color.withOpacity(0.7),
      );
    }
  }

  // === DAMAGE OVERLAY ===
  void _paintDamage(Canvas canvas, double scale) {
    // Smoke puffs
    canvas.drawCircle(
      Offset(-14 * scale, 5 * scale),
      9 * scale,
      Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      Offset(16 * scale, -10 * scale),
      7 * scale,
      Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      Offset(0, 0),
      5 * scale,
      Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Sparks
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4 + 0.3;
      final r = (10 + (i % 3) * 4) * scale;
      final x = cos(angle) * r;
      final y = sin(angle) * r;
      canvas.drawCircle(
        Offset(x, y),
        1.5 * scale,
        Paint()..color = const Color(0xFFFFB627),
      );
    }
  }

  @override
  bool shouldRepaint(ShipPainter oldDelegate) {
    return oldDelegate.ship.id != ship.id ||
        oldDelegate.damaged != damaged ||
        oldDelegate.thrust != thrust ||
        oldDelegate.selected != selected;
  }
}

/// Color constants for ships (kept here to avoid circular deps).
class AppThemeColors {
  static const Color primary = Color(0xFF00D9FF);
}
