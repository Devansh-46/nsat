import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Semantic message box — gold (info/warn), green (confirm), clay (error).
/// Matches design spec §6.4.
///
///   NoteBox.gold(
///     icon: Icons.info_outline,
///     title: 'Email verification next',
///     body: 'We will send a 6-digit code to your registered email.',
///   );
enum NoteTone { gold, green, clay }

class NoteBox extends StatelessWidget {
  final NoteTone tone;
  final IconData icon;
  final String? title;
  final String body;

  const NoteBox({
    super.key,
    required this.tone,
    required this.icon,
    required this.body,
    this.title,
  });

  /// Info / warning / indicative.
  const NoteBox.gold({
    super.key,
    required this.icon,
    required this.body,
    this.title,
  }) : tone = NoteTone.gold;

  /// Confirmation / success.
  const NoteBox.green({
    super.key,
    required this.icon,
    required this.body,
    this.title,
  }) : tone = NoteTone.green;

  /// Error / failure.
  const NoteBox.clay({
    super.key,
    required this.icon,
    required this.body,
    this.title,
  }) : tone = NoteTone.clay;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(tone);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.bg1, palette.bg2],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: palette.fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppTheme.body(
                      size: 13.5,
                      color: palette.fg,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  body,
                  style: AppTheme.body(
                    size: 12.5,
                    color: palette.fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _Palette _palette(NoteTone t) {
    switch (t) {
      case NoteTone.gold:
        return const _Palette(
          bg1: AppColors.goldTint2,
          bg2: AppColors.goldTint,
          border: Color(0x59C9A227), // 35% gold
          fg: Color(0xFF8A6516),
        );
      case NoteTone.green:
        return const _Palette(
          bg1: AppColors.forestTint2,
          bg2: AppColors.forestTint,
          border: Color(0x4D2C6B42), // 30% forest
          fg: AppColors.forest,
        );
      case NoteTone.clay:
        return const _Palette(
          bg1: AppColors.clayTint2,
          bg2: AppColors.clayTint,
          border: Color(0x4DB0432F), // 30% clay
          fg: AppColors.clay,
        );
    }
  }
}

class _Palette {
  final Color bg1;
  final Color bg2;
  final Color border;
  final Color fg;
  const _Palette({
    required this.bg1,
    required this.bg2,
    required this.border,
    required this.fg,
  });
}
