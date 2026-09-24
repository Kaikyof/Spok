import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import 'tappable.dart';

/// Сегментированный переключатель стеков: Все · iOS · Android.
class StackFilterControl<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const StackFilterControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimens.controlRadius + 3),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in options)
              _SegmentButton(
                label: label,
                active: value == selected,
                onTap: () => onChanged(value),
              ),
          ],
        ),
      );
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Tappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.cardHighlight : null,
            borderRadius: BorderRadius.circular(AppDimens.controlRadius),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      );
}
