/// Ход длинной операции: клонирование репозитория, запись ключей,
/// перечитывание спеки.
///
/// Правило борда 19: у идущей операции всегда видна отмена, а ошибка
/// остаётся внутри экрана — человека с него не уводят. Поэтому состояния
/// описаны одним типом, а не тремя разными полями в разных блоках.
enum OperationStage { idle, running, failed, done }

class OperationProgress {
  final OperationStage stage;

  /// Доля выполненного, 0..1; null — объём заранее неизвестен и полоса
  /// идёт неопределённой. Угадывать проценты нельзя: скачущая полоса
  /// врёт про оставшееся время.
  final double? fraction;

  /// Живая строка операции — как её выдал инструмент (вывод git и т.п.).
  /// Данные, не текст интерфейса: перевод здесь нечего делать.
  final String detail;

  /// Сообщение инструмента об ошибке, дословно: по нему человек узнаёт
  /// свою проблему, даже если разобрать её причину мы не смогли.
  final String failure;

  const OperationProgress({
    this.stage = OperationStage.idle,
    this.fraction,
    this.detail = '',
    this.failure = '',
  });

  static const idle = OperationProgress();

  const OperationProgress.running({this.fraction, this.detail = ''})
      : stage = OperationStage.running,
        failure = '';

  const OperationProgress.failed(this.failure, {this.detail = ''})
      : stage = OperationStage.failed,
        fraction = null;

  const OperationProgress.done({this.detail = ''})
      : stage = OperationStage.done,
        fraction = null,
        failure = '';

  bool get isRunning => stage == OperationStage.running;
  bool get isFailed => stage == OperationStage.failed;
  bool get isDone => stage == OperationStage.done;

  /// Операция идёт, но объём неизвестен — полоса неопределённая.
  bool get isIndeterminate => isRunning && fraction == null;

  /// Проценты для подписи; null — показывать нечего.
  int? get percent =>
      fraction == null ? null : (fraction!.clamp(0.0, 1.0) * 100).round();

  OperationProgress copyWith({
    OperationStage? stage,
    double? Function()? fraction,
    String? detail,
    String? failure,
  }) =>
      OperationProgress(
        stage: stage ?? this.stage,
        fraction: fraction != null ? fraction() : this.fraction,
        detail: detail ?? this.detail,
        failure: failure ?? this.failure,
      );
}
