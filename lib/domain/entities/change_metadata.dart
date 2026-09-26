/// Метаданные change'а из `.openspec.yaml` — формат оригинального OpenSpec.
///
/// У спек команды этого файла нет (там `redmine.yaml`), и все поля здесь
/// необязательные: отсутствие файла — не ошибка, а обычный случай.
class ChangeMetadata {
  /// Схема change'а; null — берётся из `openspec/config.yaml` или умолчание.
  final String? schemaName;

  /// Дата создания из `created: YYYY-MM-DD`.
  final DateTime? created;

  /// Цель change'а — свободный текст, если автор его записал.
  final String? goal;

  /// Change нарочно без дельт спецификаций (рефакторинг, инструменты,
  /// документация): артефакт спецификаций считается пропущенным, а не
  /// ненаписанным.
  final bool skipSpecs;

  const ChangeMetadata({
    this.schemaName,
    this.created,
    this.goal,
    this.skipSpecs = false,
  });

  /// Файла нет — ни одно поле не задано.
  static const none = ChangeMetadata();
}
