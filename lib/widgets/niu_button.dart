import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NiuButtonVariant { primary, gold, outline }

class NiuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final NiuButtonVariant variant;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const NiuButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = NiuButtonVariant.primary,
    this.fontSize = 13,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.symmetric(vertical: 14);

    switch (variant) {
      case NiuButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: effectivePadding,
              elevation: 0,
            ),
            child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500)),
          ),
        );
      case NiuButtonVariant.gold:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: effectivePadding,
              elevation: 0,
            ),
            child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500)),
          ),
        );
      case NiuButtonVariant.outline:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: effectivePadding,
            ),
            child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500)),
          ),
        );
    }
  }
}
