import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The base unit of the NSAT UI — a frosted glass card that sits on the
/// mesh background. Matches design spec §6.1.
///
/// Stacks three shadow layers (top-edge highlight + tight contact + soft
/// ambient) and uses a backdrop blur for the real glass effect.
///
/// PERFORMANCE NOTE: BackdropFilter has a real cost on low-end Android.
/// If you see jank during testing, pass [blurEnabled]: false on stat
/// tiles or grids — the gradient fill still looks glassy without it.
class GlassCard extends StatelessWidget {
  /// Inner padding. Spec recommends 22–32px for primary cards.
  final EdgeInsetsGeometry padding;

  /// Corner radius. Spec: 22px floating cards, 16px flat tiles.
  final double radius;

  /// Whether to apply the backdrop blur. Set false on dense grids if
  /// you see performance issues.
  final bool blurEnabled;

  /// Stronger glass fill — use for cards that need more separation
  /// from the mesh (e.g. modals, focused inputs).
  final bool strong;

  final Widget child;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 22,
    this.blurEnabled = true,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: strong ? AppColors.glassBgStrong : AppColors.glassBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [
          // Inset top-edge highlight (the white gloss).
          BoxShadow(
            color: Color(0xB3FFFFFF),
            offset: Offset(0, 1),
            blurRadius: 0,
            spreadRadius: -1,
          ),
          // Tight contact shadow.
          BoxShadow(
            color: Color(0x0F0F2A1F),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          // Soft ambient.
          BoxShadow(
            color: Color(0x120F2A1F),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
          // Deep ambient for depth.
          BoxShadow(
            color: Color(0x0D0F2A1F),
            offset: Offset(0, 24),
            blurRadius: 60,
          ),
        ],
      ),
      child: child,
    );

    if (!blurEnabled) return card;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: card,
      ),
    );
  }
}
