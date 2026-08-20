import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_text_styles.dart';

/// Полноэкранный лоадер первой загрузки.
class AppLoader extends StatelessWidget {
  final String message;

  const AppLoader({super.key, required this.message});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.accent),
              ),
              const SizedBox(height: 16),
              Text(message, style: AppTextStyles.body),
            ],
          ),
        ),
      );
}
