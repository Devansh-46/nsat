import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NiuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;

  const NiuAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
              ),
            ),
          if (showBack) const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
