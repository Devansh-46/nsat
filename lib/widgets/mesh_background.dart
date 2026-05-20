import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The ambient 4-colour radial mesh that sits behind every NSAT screen.
///
/// Matches design spec §7.1. A slow 22-second drift animation keeps the
/// background feeling alive without being noticeable. Respects the
/// platform's reduce-motion accessibility setting.
class MeshBackground extends StatefulWidget {
  /// The page content that sits on top of the mesh.
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce motion: stop the drift if the user has it enabled.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Container(
      color: AppColors.bgBase,
      child: Stack(
        children: [
          // The animated mesh layer.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = reduceMotion ? 0.5 : _controller.value;
                // Drift by ±1% on each axis, scale up to 1.02.
                final dx = (t - 0.5) * 0.02;
                final dy = (0.5 - t) * 0.02;
                final scale = 1 + (t * 0.02);

                return Transform(
                  transform: Matrix4.identity()
                    ..translateByDouble(dx * 100, dy * 100, 0, 1)
                    ..scaleByDouble(scale, scale, 1, 1),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    painter: _MeshPainter(),
                  ),
                );
              },
            ),
          ),
          // Content on top.
          widget.child,
        ],
      ),
    );
  }
}

/// Paints the 4 radial gradients from spec §7.1.
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Extend a touch past the edges so the drift never reveals base bg.
    final inset = -size.shortestSide * 0.1;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );

    void paintRadial({
      required Color color,
      required Alignment center,
      required double widthFrac,
      required double heightFrac,
    }) {
      final c = Offset(
        rect.left + rect.width * (center.x * 0.5 + 0.5),
        rect.top + rect.height * (center.y * 0.5 + 0.5),
      );
      final radius = (rect.width * widthFrac + rect.height * heightFrac) / 2;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 0.6],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawRect(rect, paint);
    }

    // mesh1 - warm champagne, top-left
    paintRadial(
      color: AppColors.mesh1,
      center: const Alignment(-0.7, -0.76),
      widthFrac: 0.60,
      heightFrac: 0.50,
    );
    // mesh2 - mint mist, top-right
    paintRadial(
      color: AppColors.mesh2,
      center: const Alignment(0.76, -0.64),
      widthFrac: 0.55,
      heightFrac: 0.50,
    );
    // mesh3 - soft sky, bottom-left
    paintRadial(
      color: AppColors.mesh3,
      center: const Alignment(-0.56, 0.84),
      widthFrac: 0.70,
      heightFrac: 0.55,
    );
    // mesh4 - parchment, bottom-right
    paintRadial(
      color: AppColors.mesh4,
      center: const Alignment(0.90, 0.56),
      widthFrac: 0.55,
      heightFrac: 0.45,
    );
  }

  @override
  bool shouldRepaint(_MeshPainter oldDelegate) => false;
}
