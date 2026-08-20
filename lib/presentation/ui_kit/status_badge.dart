import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';

/// Бейдж статуса: точка + текст. Цвет — по стадии, не по «хорошо/плохо».
class StatusBadge extends StatelessWidget {
  final String text;
  final Color dotColor;
  final bool muted;

  const StatusBadge({
    super.key,
    required this.text,
    required this.dotColor,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: muted ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      );
}
