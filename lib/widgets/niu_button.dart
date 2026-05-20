import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The NSAT pill button. Matches design spec §6.2.
///
/// Variants:
///   - primary  : ink gradient fill, ivory text (default)
///   - forest   : forest gradient fill, white text (success / confirm)
///   - gold     : gold gradient fill, dark text (final submit, warning)
///   - outline  : glass fill + ink border, ink text
///
/// Sizes: sm (36), md (48 — default), lg (56).
enum NiuButtonVariant { primary, forest, gold, outline }

enum NiuButtonSize { sm, md, lg }

class NiuButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final NiuButtonVariant variant;
  final NiuButtonSize size;

  /// If true, shows a right-pointing arrow (spec rule: primary forward
  /// actions always carry the arrow).
  final bool showArrow;

  /// If true, button stretches to fill its parent's width.
  final bool fullWidth;

  /// Optional override for label font size. Otherwise uses the size.
  final double? fontSize;

  /// Optional explicit padding override (rarely needed).
  final EdgeInsetsGeometry? padding;

  const NiuButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = NiuButtonVariant.primary,
    this.size = NiuButtonSize.md,
    this.showArrow = false,
    this.fullWidth = true,
    this.fontSize,
    this.padding,
  });

  @override
  State<NiuButton> createState() => _NiuButtonState();
}

class _NiuButtonState extends State<NiuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    // Sizing per spec.
    final height = switch (widget.size) {
      NiuButtonSize.sm => 36.0,
      NiuButtonSize.md => 48.0,
      NiuButtonSize.lg => 56.0,
    };
    final hPadding = switch (widget.size) {
      NiuButtonSize.sm => 14.0,
      NiuButtonSize.md => 22.0,
      NiuButtonSize.lg => 28.0,
    };
    final labelSize = widget.fontSize ??
        (widget.size == NiuButtonSize.sm
            ? 13.0
            : widget.size == NiuButtonSize.lg
                ? 15.5
                : 14.5);

    final palette = _palette(widget.variant);

    final child = Container(
      height: height,
      padding: widget.padding ?? EdgeInsets.symmetric(horizontal: hPadding),
      decoration: BoxDecoration(
        gradient: palette.gradient,
        borderRadius: BorderRadius.circular(999),
        border: palette.border != null
            ? Border.all(color: palette.border!, width: 1)
            : null,
        boxShadow: disabled ? null : palette.shadows,
      ),
      child: Row(
        mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.label,
            style: AppTheme.body(
              size: labelSize,
              color: disabled
                  ? palette.foreground.withValues(alpha: 0.5)
                  : palette.foreground,
              weight: FontWeight.w500,
            ),
          ),
          if (widget.showArrow) ...[
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: disabled
                  ? palette.foreground.withValues(alpha: 0.5)
                  : palette.foreground,
            ),
          ],
        ],
      ),
    );

    final wrapped = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.identity()
        ..translateByDouble(0, _pressed ? 0 : -1, 0, 1),
      child: child,
    );

    return GestureDetector(
      onTap: disabled ? null : widget.onTap,
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: widget.fullWidth
          ? SizedBox(width: double.infinity, child: wrapped)
          : wrapped,
    );
  }

  _BtnPalette _palette(NiuButtonVariant v) {
    switch (v) {
      case NiuButtonVariant.primary:
        return const _BtnPalette(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ink2, AppColors.ink],
          ),
          foreground: AppColors.ivory,
          shadows: [
            BoxShadow(
              color: Color(0x1AFFFFFF),
              offset: Offset(0, 1),
              blurRadius: 0,
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Color(0x330F2A1F),
              offset: Offset(0, 8),
              blurRadius: 22,
            ),
            BoxShadow(
              color: Color(0x240F2A1F),
              offset: Offset(0, 16),
              blurRadius: 40,
            ),
          ],
        );
      case NiuButtonVariant.forest:
        return const _BtnPalette(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.forest2, AppColors.forest],
          ),
          foreground: Colors.white,
          shadows: [
            BoxShadow(
              color: Color(0x332C6B42),
              offset: Offset(0, 8),
              blurRadius: 22,
            ),
          ],
        );
      case NiuButtonVariant.gold:
        return const _BtnPalette(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gold2, AppColors.gold],
          ),
          foreground: Color(0xFF3A2C09),
          shadows: [
            BoxShadow(
              color: Color(0x33C9A227),
              offset: Offset(0, 8),
              blurRadius: 22,
            ),
          ],
        );
      case NiuButtonVariant.outline:
        return const _BtnPalette(
          gradient: AppColors.glassBg,
          foreground: AppColors.ink,
          border: AppColors.ink,
          shadows: [
            BoxShadow(
              color: Color(0x0A0F2A1F),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        );
    }
  }
}

class _BtnPalette {
  final LinearGradient? gradient;
  final Color foreground;
  final Color? border;
  final List<BoxShadow> shadows;
  const _BtnPalette({
    this.gradient,
    required this.foreground,
    this.border,
    this.shadows = const [],
  });
}
