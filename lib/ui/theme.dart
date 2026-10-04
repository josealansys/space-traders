import 'package:flutter/material.dart';

/// Space Traders theme — premium dark sci-fi palette with gold/cyan accents.
class AppTheme {
  // Backgrounds
  static const Color background = Color(0xFF050810);
  static const Color backgroundDeep = Color(0xFF020409);
  static const Color surface = Color(0xFF0F1623);
  static const Color surfaceDeep = Color(0xFF080C18);
  static const Color surfaceLight = Color(0xFF1A2438);
  static const Color surfaceGlass = Color(0xFF0F1623); // for glassmorphism

  // Brand colors
  static const Color primary = Color(0xFF00D9FF); // cyan
  static const Color primaryDark = Color(0xFF0099BB);
  static const Color accent = Color(0xFFFFB627); // gold
  static const Color accentDark = Color(0xFFCC8E00);

  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFF9500);
  static const Color danger = Color(0xFFFF3D57);
  static const Color info = Color(0xFF64B5F6);

  // Text
  static const Color text = Color(0xFFE8EEF7);
  static const Color textBright = Color(0xFFFFFFFF);
  static const Color textDim = Color(0xFF7A8AA3);
  static const Color textMuted = Color(0xFF4A5870);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D9FF), Color(0xFF0099BB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFB627), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF3D57), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1A2438), Color(0xFF0F1623)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2438), Color(0xFF0F1623)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Tier color for stock icons.
  static Color tierColor(String tier) {
    switch (tier) {
      case 'SURPLUS': return const Color(0xFF00E676);
      case 'LOW': return const Color(0xFF7ED321);
      case 'NORMAL': return const Color(0xFFFFB627);
      case 'HIGH': return const Color(0xFFFF6B35);
      case 'PREMIUM': return const Color(0xFFFF3D57);
      default: return textDim;
    }
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        tertiary: success,
        surface: surface,
        error: danger,
        onPrimary: background,
        onSecondary: background,
        onSurface: text,
        onError: textBright,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: surfaceLight.withOpacity(0.5), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: text, fontWeight: FontWeight.w900, letterSpacing: 3),
        displayMedium: TextStyle(color: text, fontWeight: FontWeight.w800, letterSpacing: 2),
        displaySmall: TextStyle(color: text, fontWeight: FontWeight.w700, letterSpacing: 2),
        headlineLarge: TextStyle(color: text, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        headlineMedium: TextStyle(color: text, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        headlineSmall: TextStyle(color: text, fontWeight: FontWeight.w600, letterSpacing: 1),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: text, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: text, height: 1.4),
        bodyMedium: TextStyle(color: text, height: 1.4),
        bodySmall: TextStyle(color: textDim, height: 1.3),
        labelLarge: TextStyle(color: text, fontWeight: FontWeight.w600, letterSpacing: 1),
        labelMedium: TextStyle(color: textDim, letterSpacing: 1),
        labelSmall: TextStyle(color: textDim, letterSpacing: 1),
      ),
      iconTheme: const IconThemeData(color: text),
      dividerColor: surfaceLight,
    );
  }
}

/// Glass-morphism card widget.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double glowIntensity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
    this.gradient,
    this.borderColor,
    this.onTap,
    this.glowIntensity = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppTheme.surfaceLight.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: glowIntensity > 0
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(glowIntensity * 0.3),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Glowing button with gradient background.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final IconData? icon;
  final double width;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = AppTheme.primaryGradient,
    this.icon,
    this.width = double.infinity,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1.0,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : gradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: AppTheme.background),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.background,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stat chip with icon (used in app bar).
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? tooltip;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          ),
          border: Border.all(color: color.withOpacity(0.6), width: 1),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated glow pulse for active elements.
class GlowPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  const GlowPulse({
    super.key,
    required this.child,
    this.color = AppTheme.primary,
    this.minOpacity = 0.2,
    this.maxOpacity = 0.6,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = widget.minOpacity +
            (widget.maxOpacity - widget.minOpacity) * _controller.value;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(t),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
