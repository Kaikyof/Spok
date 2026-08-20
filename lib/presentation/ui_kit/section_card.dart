import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';

/// Карточка-секция в стиле макета.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = AppDimens.cardPadding,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? AppColors.card,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          border: Border.all(color: borderColor ?? AppColors.borderSoft),
        ),
        child: child,
      );
}
