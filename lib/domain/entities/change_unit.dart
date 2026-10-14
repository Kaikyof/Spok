import 'change_metadata.dart';
import 'spec_schema.dart';
import 'stack_state.dart';

/// Change — единица работы: спека, задачи, код, тест-кейсы.
class ChangeUnit {
  final String id; // имя папки openspec/changes/<id>
  final String title;
  final String dir; // абсолютный путь к папке change'а
  final String groupId; // id группы; пусто — вне групп
  final List<String> dependsOn; // предшественники из group.members

  /// Стеки change'а в порядке схемы; пусто — работа без разделения на стеки.
  final Map<String, StackState> stackStates;

  /// Формат `redmine.yaml` не распознан — показываем это, а не пустоту.
  final String formatWarning;

  /// Дата сдачи в архив из имени каталога (`2026-07-31-<change>`);
  /// null — change в работе. Сам id при этом хранится очищенным.
  final DateTime? archivedAt;

  /// Схема этого change'а: своя из `.openspec.yaml`, иначе схема спеки.
  /// Пустая — схема не найдена; экраны берут встроенную `spec-driven`.
  final SpecSchema schema;

  /// Метаданные `.openspec.yaml`; у спек команды файла нет — `none`.
  final ChangeMetadata meta;

  const ChangeUnit({
    required this.id,
    required this.title,
    required this.dir,
    this.groupId = '',
    this.stackStates = const {},
    this.dependsOn = const [],
    this.formatWarning = '',
    this.archivedAt,
    this.schema = SpecSchema.empty,
    this.meta = ChangeMetadata.none,
  });

  bool get archived => archivedAt != null;

  List<StackState> get stacks => stackStates.values.toList();

  StackState? stack(String id) => stackStates[id];
}
