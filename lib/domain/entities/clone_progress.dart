import 'operation_progress.dart';

/// Разобранная причина, по которой клонирование не удалось.
///
/// Код ошибки git человеку не говорит ничего: «нет доступа по ключу» и
/// «неверный логин» лечатся по-разному, и экран обязан их различать.
enum CloneFailure {
  /// `Permission denied (publickey)` — ssh-ключа нет или он не тот.
  accessDenied,

  /// `Authentication failed` — логин или токен не приняты.
  authFailed,

  /// Каталог занят чужим содержимым: сносить его молча нельзя.
  directoryInUse,

  /// Репозитория по адресу нет либо он закрыт для этого пользователя.
  repoNotFound,

  /// Сети нет или хост не отвечает.
  networkUnreachable,

  /// Самого git на машине не нашлось.
  gitMissing,

  /// Человек нажал «Отменить».
  cancelled,

  /// Разобрать не удалось — показываем вывод git дословно.
  unknown,
}

/// Этап работы git. У каждого своя шкала процентов, поэтому этапы
/// раскладываются по участкам общей полосы — иначе она ехала бы назад
/// на каждом новом этапе.
enum ClonePhase {
  starting,
  counting,
  compressing,
  receiving,
  resolving,

  /// Раскладывание файлов в рабочий каталог — `Updating files`.
  checkout,

  done,
}

/// Ход клонирования спеки.
class CloneProgress {
  final OperationStage stage;
  final ClonePhase phase;

  /// Доля всей работы, 0..1; null — git ещё ничего не сказал о ходе.
  /// Именно всей, а не текущего этапа: человек смотрит на одну полосу,
  /// и она обязана только расти.
  final double? fraction;

  /// Объём и скорость — как их напечатал git («12.34 MiB», «3.20 MiB/s»):
  /// пересчитывать их значило бы врать в третьем знаке.
  final String volume;
  final String speed;

  /// Последняя строка вывода git, дословно.
  final String line;

  final CloneFailure? failure;

  /// Сообщение git об ошибке, дословно.
  final String failureDetail;

  /// Куда склонировано; заполнено, когда всё получилось.
  final String path;

  /// Обновляем уже склонированную спеку, а не скачиваем заново.
  final bool updating;

  const CloneProgress({
    this.stage = OperationStage.idle,
    this.phase = ClonePhase.starting,
    this.fraction,
    this.volume = '',
    this.speed = '',
    this.line = '',
    this.failure,
    this.failureDetail = '',
    this.path = '',
    this.updating = false,
  });

  static const idle = CloneProgress();

  bool get isRunning => stage == OperationStage.running;
  bool get isFailed => stage == OperationStage.failed;
  bool get isDone => stage == OperationStage.done;

  /// Вид для общего компонента прогресса.
  OperationProgress get operation => switch (stage) {
        OperationStage.idle => OperationProgress.idle,
        OperationStage.running =>
          OperationProgress.running(fraction: fraction, detail: line),
        OperationStage.failed => OperationProgress.failed(failureDetail),
        OperationStage.done => const OperationProgress.done(),
      };

  CloneProgress copyWith({
    OperationStage? stage,
    ClonePhase? phase,
    double? Function()? fraction,
    String? volume,
    String? speed,
    String? line,
    CloneFailure? Function()? failure,
    String? failureDetail,
    String? path,
    bool? updating,
  }) =>
      CloneProgress(
        stage: stage ?? this.stage,
        phase: phase ?? this.phase,
        fraction: fraction != null ? fraction() : this.fraction,
        volume: volume ?? this.volume,
        speed: speed ?? this.speed,
        line: line ?? this.line,
        failure: failure != null ? failure() : this.failure,
        failureDetail: failureDetail ?? this.failureDetail,
        path: path ?? this.path,
        updating: updating ?? this.updating,
      );
}
