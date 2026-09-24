/// Часть устройства спеки, которую приложение выводит из её файлов.
enum RecognizedPart {
  /// Схема артефактов — `openspec/schemas/*/schema.yaml`.
  schema,

  /// Стратегия группировки работы: спринты, мастер-спека, плоский список.
  grouping,

  /// Стеки работы — из схемы и файлов задач.
  stacks,

  /// Семантика статусов трекера — `openspec/redmine.yaml`.
  statuses,

  /// Команды спеки — схема, `.claude`, зеркала, `package.json`, `Makefile`.
  commands,

  /// Сервисы кода — `workspace.yaml`.
  services,
}

/// Одна строка разбора: что поняли, чем именно и где искали.
class RecognizedItem {
  final RecognizedPart part;

  /// Не распознано — экран не делает вид, что понял.
  final bool recognized;

  /// Понятое значение: имя схемы, список стеков, число команд. Данные,
  /// а не текст интерфейса.
  final String value;

  /// Где искали — путь или источник; показывается рядом.
  final String lookedIn;

  /// Абсолютный путь к файлу, который решает эту часть: его и открывает
  /// «изменить». Пусто — источник не один файл (команды собираются из
  /// пяти мест) или файла в спеке нет вовсе.
  final String sourcePath;

  const RecognizedItem({
    required this.part,
    required this.recognized,
    this.value = '',
    this.lookedIn = '',
    this.sourcePath = '',
  });
}

/// Что приложение поняло в спеке и чего не поняло.
///
/// Нераспознанное не прячется: спека может быть устроена не по-нашему, и
/// человек должен видеть, что именно приложение не разобрало, — иначе он
/// решит, что сломано приложение, и будет прав лишь отчасти (борд 19).
class SpecRecognition {
  final List<RecognizedItem> items;

  const SpecRecognition(this.items);

  static const empty = SpecRecognition([]);

  List<RecognizedItem> get unrecognized =>
      [for (final item in items) if (!item.recognized) item];

  int get recognizedCount => items.where((item) => item.recognized).length;

  /// Разобрано всё — блока «не распознано» на экране нет.
  bool get complete => items.isNotEmpty && unrecognized.isEmpty;
}
