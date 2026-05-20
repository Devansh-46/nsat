import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'eyebrow.dart';

/// The NSAT glass input field. Matches design spec §6.3.
///
/// Renders an eyebrow label above, a glass-filled rounded box with an
/// optional leading icon, and an optional helper line below. Focus state
/// adds a forest glow ring.
class NiuField extends StatefulWidget {
  /// Uppercase eyebrow label (e.g. "NIU ID"). Auto-uppercased.
  final String label;

  /// Placeholder text inside the input.
  final String? hint;

  /// Optional leading icon (e.g. Icons.badge_outlined).
  final IconData? icon;

  /// Helper line under the field. Hidden when null.
  final String? helper;

  /// Error message — if non-null, switches helper line to clay color
  /// and adds a clay border.
  final String? errorText;

  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final int? maxLength;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const NiuField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.helper,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.maxLength,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<NiuField> createState() => _NiuFieldState();
}

class _NiuFieldState extends State<NiuField> {
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    final borderColor = hasError
        ? AppColors.clay
        : _focused
            ? AppColors.forest
            : AppColors.glassBorder;

    final glow = _focused && !hasError
        ? const [
            BoxShadow(
              color: Color(0x332C6B42), // forest @ 20%
              offset: Offset(0, 0),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ]
        : hasError
            ? const [
                BoxShadow(
                  color: Color(0x33B0432F), // clay @ 20%
                  offset: Offset(0, 0),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : <BoxShadow>[];

    final fieldInner = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.glassBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: borderColor, width: hasError || _focused ? 1.5 : 1),
        boxShadow: glow,
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: AppColors.ink3),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              maxLength: widget.maxLength,
              textCapitalization: widget.textCapitalization,
              style: AppTheme.body(size: 15, color: AppColors.ink),
              cursorColor: AppColors.forest,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTheme.body(size: 15, color: AppColors.ink4),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(widget.label, color: AppColors.ink4),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: fieldInner,
          ),
        ),
        if (widget.helper != null || hasError) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText ?? widget.helper!,
            style: AppTheme.body(
              size: 12,
              color: hasError ? AppColors.clay : AppColors.ink4,
            ),
          ),
        ],
      ],
    );
  }
}
