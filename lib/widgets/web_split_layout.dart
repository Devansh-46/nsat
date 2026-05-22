import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A responsive split-layout wrapper for web/desktop.
/// Below [breakpoint] (default 800), it renders [mobileChild].
/// Above [breakpoint], it splits the screen into a dark left panel (~45%)
/// and a light right panel (~55%) with the [mobileChild] content.
class WebSplitLayout extends StatelessWidget {
  /// The content for the dark left panel on web.
  final Widget leftChild;

  /// The main content for the right panel on web (often a form or card).
  final Widget rightChild;

  /// The full-screen content for mobile.
  final Widget mobileChild;

  /// Width at which to switch from mobile to split layout.
  final double breakpoint;

  const WebSplitLayout({
    super.key,
    required this.leftChild,
    required this.rightChild,
    required this.mobileChild,
    this.breakpoint = 800,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return mobileChild;
        }

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          body: Row(
            children: [
              // Left Panel (Dark)
              Expanded(
                flex: 45,
                child: Container(
                  color: AppColors.ink,
                  child: Stack(
                    children: [
                      // Subtle gradient/mesh for the dark panel
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DarkMeshPainter(),
                        ),
                      ),
                      // Content
                      Positioned.fill(
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                            child: leftChild,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right Panel (Light)
              Expanded(
                flex: 55,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                          child: rightChild,
                        ),
                      ),
                    ),
                    // Shared Footer
                    Positioned(
                      bottom: 24,
                      left: 48,
                      right: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Need help? nsat@niu.edu.in',
                            style: AppTheme.body(size: 11.5, color: AppColors.ink4),
                          ),
                          Text(
                            '© 2026 Noida International University. All rights reserved.',
                            style: AppTheme.body(size: 11.5, color: AppColors.ink4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A subtle dark mesh background for the left panel.
class _DarkMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void paintRadial({
      required Color color,
      required Alignment center,
      required double radiusFrac,
    }) {
      final c = Offset(
        size.width * (center.x * 0.5 + 0.5),
        size.height * (center.y * 0.5 + 0.5),
      );
      final radius = size.longestSide * radiusFrac;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawRect(Offset.zero & size, paint);
    }

    // Subtle dark forest greens
    paintRadial(
      color: AppColors.forest.withValues(alpha: 0.15),
      center: const Alignment(-0.8, -0.8),
      radiusFrac: 0.7,
    );
    paintRadial(
      color: const Color(0xFF0A1F16).withValues(alpha: 0.3),
      center: const Alignment(0.8, 0.8),
      radiusFrac: 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
