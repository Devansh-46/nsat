import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Small uppercase tracked label that introduces every section, card,
/// and form field. Matches design spec §4 ("eyebrow rule") and §6.5.
///
/// Examples: `STEP 01 OF 04`, `CANDIDATE`, `QUICK ACTIONS`, `NIU ID`.
///
/// The text is auto-uppercased — pass any case.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  final TextAlign? textAlign;

  const Eyebrow(
    this.text, {
    super.key,
    this.color = AppColors.ink4,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      style: AppTheme.eyebrow(color: color),
    );
  }
}
