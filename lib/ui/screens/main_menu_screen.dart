import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../painters/planet_painter.dart';
import '../../game/game_state_controller.dart';
import 'planet_screen.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _starfieldController;
  late AnimationController _titleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _starfieldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starfieldController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _startNewGame() {
    ref.read(gameStateProvider.notifier).startNewGame();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PlanetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated starfield background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _starfieldController,
              builder: (_, __) => CustomPaint(
                painter: _AnimatedStarfieldPainter(_starfieldController.value),
              ),
            ),
          ),
          // Background planet
          Center(
            child: SizedBox(
              width: 500,
              height: 500,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => CustomPaint(
                  painter: _BackgroundPlanetPainter(pulse: _pulseController.value),
                ),
              ),
            ),
          ),
          // Nebula overlay
          Positioned.fill(
            child: CustomPaint(painter: _NebulaPainter()),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _AnimatedTitle(controller: _titleController),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _titleController,
                  child: Text(
                    'TRADE  •  TRAVEL  •  TRIUMPH',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primary.withOpacity(0.8),
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                _AnimatedMenuButton(
                  label: 'NEW GAME',
                  icon: Icons.rocket_launch,
                  gradient: AppTheme.primaryGradient,
                  onTap: _startNewGame,
                  delayMs: 800,
                ),
                const SizedBox(height: 14),
                _AnimatedMenuButton(
                  label: 'CONTINUE',
                  icon: Icons.play_circle_outline,
                  gradient: AppTheme.surfaceGradient,
                  onTap: _startNewGame,
                  delayMs: 1000,
                  outline: true,
                ),
                const SizedBox(height: 14),
                _AnimatedMenuButton(
                  label: 'SETTINGS',
                  icon: Icons.settings_outlined,
                  gradient: AppTheme.surfaceGradient,
                  onTap: () {},
                  delayMs: 1200,
                  outline: true,
                ),
                const Spacer(flex: 1),
                FadeTransition(
                  opacity: _titleController,
                  child: Text(
                    'v1.0  •  BUILD 5,265',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTitle extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedTitle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(controller.value);
        return Transform.translate(
          offset: Offset(0, (1 - t) * 30),
          child: Opacity(
            opacity: t,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow shadow
                Text(
                  'SPACE\nTRADERS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    height: 1.0,
                    foreground: Paint()
                      ..shader = AppTheme.primaryGradient.createShader(
                        const Rect.fromLTWH(0, 0, 600, 200),
                      )
                      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
                    color: AppTheme.primary,
                  ),
                ),
                // Main text
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFFFFB627)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'SPACE\nTRADERS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedMenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final int delayMs;
  final bool outline;

  const _AnimatedMenuButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
    required this.delayMs,
    this.outline = false,
  });

  @override
  State<_AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<_AnimatedMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
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
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, (1 - Curves.easeOutCubic.transform(_controller.value)) * 30),
          child: Opacity(opacity: _controller.value, child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 320,
            height: 54,
            decoration: BoxDecoration(
              gradient: widget.outline ? null : widget.gradient,
              border: widget.outline
                  ? Border.all(color: AppTheme.primary.withOpacity(_hovered ? 0.8 : 0.4), width: 1.5)
                  : null,
              borderRadius: BorderRadius.circular(8),
              boxShadow: widget.outline
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(_hovered ? 0.6 : 0.3),
                        blurRadius: _hovered ? 24 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: widget.outline
                        ? (_hovered ? AppTheme.primary : AppTheme.textDim)
                        : AppTheme.background,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: widget.outline
                          ? (_hovered ? AppTheme.primary : AppTheme.text)
                          : AppTheme.background,
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

class _AnimatedStarfieldPainter extends CustomPainter {
  final double t; // 0-1
  _AnimatedStarfieldPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final starCount = 200;
    final w = size.width;
    final h = size.height;
    // Slow drift to the right
    final driftX = t * w * 0.3;
    for (int i = 0; i < starCount; i++) {
      // Use index to make stars deterministic
      final baseX = rng.nextDouble() * w;
      final baseY = rng.nextDouble() * h;
      final x = (baseX + driftX) % w;
      final y = baseY;
      final sizeFactor = rng.nextDouble();
      final starSize = sizeFactor < 0.7 ? 0.4 : (sizeFactor < 0.95 ? 0.9 : 1.5);
      final baseOpacity = 0.3 + rng.nextDouble() * 0.5;
      // Twinkle effect (sin wave)
      final twinkle = 0.5 + 0.5 * sin(t * 2 * pi + i);
      final opacity = baseOpacity * (0.7 + 0.3 * twinkle);

      Color color = Colors.white;
      final colorRoll = rng.nextDouble();
      if (colorRoll < 0.1) color = const Color(0xFFAACCFF);
      else if (colorRoll < 0.15) color = const Color(0xFFFFE5B4);

      canvas.drawCircle(Offset(x, y), starSize, Paint()..color = color.withOpacity(opacity));
      if (starSize > 1.0) {
        canvas.drawCircle(
          Offset(x, y),
          starSize * 3,
          Paint()
            ..color = color.withOpacity(opacity * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AnimatedStarfieldPainter oldDelegate) => oldDelegate.t != t;
}

class _NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle purple/blue nebula clouds
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      size.width * 0.3,
      Paint()
        ..color = const Color(0xFF6B2D8B).withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.3),
      size.width * 0.25,
      Paint()
        ..color = const Color(0xFF2D6B8B).withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
  }

  @override
  bool shouldRepaint(_NebulaPainter oldDelegate) => false;
}

class _BackgroundPlanetPainter extends CustomPainter {
  final double pulse;
  _BackgroundPlanetPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 3;

    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          const Color(0xFF4A9EFF),
          const Color(0xFF1E3A5F),
          const Color(0xFF0A0E1A),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, body);

    // Outer glow
    canvas.drawCircle(
      center,
      radius * 1.2,
      Paint()
        ..color = AppTheme.primary.withOpacity(0.2 + pulse * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  @override
  bool shouldRepaint(_BackgroundPlanetPainter oldDelegate) => oldDelegate.pulse != pulse;
}
