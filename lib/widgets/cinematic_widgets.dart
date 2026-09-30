import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movieradar/models/movie.dart';
import 'package:movieradar/theme/cinematic_theme.dart';

/// Slowly drifting aurora gradient + starfield + vignette behind everything.
class CinematicBackground extends StatefulWidget {
  const CinematicBackground({super.key, this.child});

  final Widget? child;

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Cinematic.bgTop : const Color(0xFFF4EEFB);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * pi;
        final driftX = sin(t) * 0.12;
        final driftY = cos(t * 0.8) * 0.10;

        return Container(
          color: baseColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Aurora 1
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.3 + driftX, -0.4 + driftY),
                    radius: 1.0,
                    colors: [
                      Cinematic.deepViolet.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Aurora 2
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.5 - driftX * 0.8, 0.6 + driftY),
                    radius: 1.1,
                    colors: [
                      Cinematic.nightViolet.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Vignette
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, 0.35),
                    radius: 1.3,
                    colors: [Color(0x00000000), Color(0x2A000000)],
                  ),
                ),
              ),
              CustomPaint(painter: _StarfieldPainter(isDark: isDark)),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({required this.isDark});

  final bool isDark;
  static final Random _rand = Random(1337);
  late final List<_Star> _stars = List.generate(34, (_) {
    return _Star(
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      r: 0.6 + _rand.nextDouble() * 1.6,
      o: 0.12 + _rand.nextDouble() * 0.30,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFFD9CFFF) : const Color(0xFF3A2A55);
    for (final star in _stars) {
      paint.color = paint.color.withValues(alpha: star.o);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _Star {
  final double x;
  final double y;
  final double r;
  final double o;
  _Star({required this.x, required this.y, required this.r, required this.o});
}

/// Cinema-style scaffolding: animated background + transparent scaffold.
class CinematicScaffold extends StatelessWidget {
  const CinematicScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.floatingActionButtonLocation,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: CinematicBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: SafeArea(bottom: false, child: body),
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ],
    );
  }
}

/// Animated shimmer placeholder used while posters load.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.color,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF221A3C)
            : const Color(0xFFE4DBF2));
    final highlight = Darken.lighten(base, 0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.8 + 3.6 * t, 0),
                  end: Alignment(-0.8 + 3.6 * t, 0),
                  colors: [base, highlight, base],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class Darken {
  static Color lighten(Color c, double amount) => Color.lerp(
        c,
        Colors.white,
        amount.clamp(0.0, 1.0),
      )!;
  static Color darken(Color c, double amount) => Color.lerp(
        c,
        Colors.black,
        amount.clamp(0.0, 1.0),
      )!;
}

/// Poster image with shimmer placeholder and cinematic fallback.
class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    required this.movie,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.fit = BoxFit.cover,
    this.glow = false,
  });

  final Movie movie;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    final value = movie.title.isNotEmpty ? movie.title.substring(0, 1) : '?';
    final radius = BorderRadius.circular(borderRadius);

    Widget content;
    final hasPoster = movie.posterUrl != null && movie.posterUrl!.isNotEmpty;

    if (hasPoster) {
      content = ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: movie.posterUrl!,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => ShimmerBox(
            width: width,
            height: height,
            borderRadius: borderRadius,
          ),
          errorWidget: (context, url, error) => _fallback(
            context,
            value,
            radius,
            colors,
          ),
        ),
      );
    } else {
      content = _fallback(context, value, radius, colors);
    }

    if (!glow) return content;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.glowSoft,
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _fallback(
    BuildContext context,
    String value,
    BorderRadius radius,
    CinematicColors colors,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Cinematic.deepViolet, Cinematic.nightViolet],
        ),
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.85),
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient CTA with a soft neon glow and press feedback.
class CinematicButton extends StatefulWidget {
  const CinematicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
    this.glow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;
  final bool glow;

  @override
  State<CinematicButton> createState() => _CinematicButtonState();
}

class _CinematicButtonState extends State<CinematicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    final canTap = widget.enabled && widget.onPressed != null;

    return GestureDetector(
      onTapDown: (_) {
        if (canTap) setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (canTap) setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () {
        if (canTap) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          decoration: BoxDecoration(
            gradient: canTap
                ? Cinematic.glowGradient
                : const LinearGradient(
                    colors: [Color(0xFF3B3057), Color(0xFF3B3057)],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canTap
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.transparent,
            ),
            boxShadow: canTap && widget.glow
                ? [
                    BoxShadow(
                      color: colors.glowSoft,
                      blurRadius: 20,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: canTap
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: canTap
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neon floating action button with a hover/scale bounce.
class NeonFab extends StatefulWidget {
  const NeonFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<NeonFab> createState() => _NeonFabState();
}

class _NeonFabState extends State<NeonFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: Cinematic.glowGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.glowSoft,
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

/// A small glowing pill used for stats/scrims.
class NeonChip extends StatelessWidget {
  const NeonChip({
    super.key,
    required this.label,
    this.icon,
    this.active = false,
  });

  final String label;
  final IconData? icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? colors.glow.withValues(alpha: 0.16)
            : colors.glass,
        border: Border.all(
          color: active
              ? colors.glow.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: colors.glow),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: active ? colors.glow : Cinematic.textSecondaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glowing gradient wordmark text.
class GlowText extends StatelessWidget {
  const GlowText(
    this.text, {
    super.key,
    this.style,
    this.gradient = Cinematic.glowGradient,
  });

  final String text;
  final TextStyle? style;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style ?? Theme.of(context).textTheme.headlineMedium;
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: effectiveStyle?.copyWith(
          color: Colors.white,
          shadows: [
            const Shadow(color: Color(0x59C77DFF), blurRadius: 18),
          ],
        ),
      ),
    );
  }
}