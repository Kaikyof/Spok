import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';

/// Бейдж статуса: точка + текст. Цвет — по стадии, не по «хорошо/плохо».
class StatusBadge extends StatelessWidget {
  final String text;
  final Color dotColor;
  final bool muted;

  /// Точка полая — данные не живые, а из файла спеки (борд 19). Полая
  /// точка видна и тем, кто не различает приглушённый цвет от обычного.
  final bool hollow;

  const StatusBadge({
    super.key,
    required this.text,
    required this.dotColor,
    this.muted = false,
    this.hollow = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: hollow ? Colors.transparent : dotColor,
              shape: BoxShape.circle,
              border: hollow ? Border.all(color: dotColor, width: 1.2) : null,
            ),
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
