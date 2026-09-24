import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/operation_progress.dart';
import '../../l10n/gen/app_localizations.dart';

/// Общий вид длинной операции: клонирование, запись ключей, перечитывание
/// спеки. Один компонент на всё приложение — иначе каждый экран заводит
/// свою полосу, и отмена оказывается то рядом, то в другом углу.
///
/// Правила борда 19:
/// * пока операция идёт — отмена рядом с полосой, всегда;
/// * объём неизвестен — полоса неопределённая, проценты не выдумываем;
/// * ошибка остаётся внутри блока: текст инструмента дословно и «Повторить».
class ProgressPanel extends StatelessWidget {
  /// Что делаем — короткой фразой («Клонируем репозиторий»).
  final String title;

  final OperationProgress progress;

  /// Объём словами («12 МБ из 40 МБ») — собирает вызывающий: единицы
  /// у каждой операции свои.
  final String measure;

  /// null — операция неотменяема (и кнопки не будет).
  final VoidCallback? onCancel;

  /// null — повторять нечем; кнопка появляется только при ошибке.
  final VoidCallback? onRetry;

  const ProgressPanel({
    super.key,
    required this.title,
    required this.progress,
    this.measure = '',
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.stage == OperationStage.idle) return const SizedBox.shrink();
    final texts = AppLocalizations.of(context);
    final failed = progress.isFailed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: failed ? AppColors.card : AppColors.cardHighlight,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(
            color: failed ? AppColors.danger : AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (failed)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.error_outline,
                      size: 15, color: AppColors.danger),
                )
              else if (progress.isDone)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle_outline,
                      size: 15, color: AppColors.success),
                ),
              Expanded(
                child: Text(title,
                    style: AppTextStyles.rowTitle.copyWith(
                        color: failed
                            ? AppColors.danger
                            : AppColors.textPrimary)),
              ),
              if (progress.percent case final percent?) ...[
                const SizedBox(width: AppDimens.gapS),
                Text(texts.progressPercent(percent),
                    style: AppTextStyles.monospace(12,
                        color: AppColors.textSecondary)),
              ],
              // Отмена стоит рядом с полосой и не исчезает, пока операция
              // идёт: искать её в другом месте экрана человеку некогда.
              if (progress.isRunning && onCancel != null) ...[
                const SizedBox(width: AppDimens.gapM),
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text(texts.progressCancel,
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
              if (failed && onRetry != null) ...[
                const SizedBox(width: AppDimens.gapM),
                OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: Text(texts.progressRetry,
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
          if (!failed) ...[
            const SizedBox(height: AppDimens.gapS),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                // null — неопределённая полоса: процентов мы не знаем
                // и не выдумываем их.
                value: progress.isDone ? 1 : progress.fraction,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                    progress.isDone ? AppColors.success : AppColors.accent),
              ),
            ),
          ],
          if (measure.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gapS),
            Text(measure, style: AppTextStyles.hint),
          ],
          if (progress.failure.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gapS),
            // Сообщение инструмента дословно: по нему человек узнаёт свою
            // проблему, даже когда разобрать её причину мы не смогли.
            Text(progress.failure,
                style: AppTextStyles.monospace(11.5,
                    color: AppColors.textSecondary)),
          ],
          if (progress.detail.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gapS),
            Text(progress.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.monospace(11.5,
                    color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
