import '../entities/change_unit.dart';
import '../entities/spec_schema.dart';

/// Состояние одного артефакта change'а на диске.
class ArtifactState {
  final SchemaArtifact artifact;

  /// Файлы артефакта, которые есть; пусто — не написан или пропущен.
  final List<String> files;

  /// Change объявил `skip_specs`, и это артефакт дельт спецификаций:
  /// его не ждут и не считают ненаписанным.
  final bool skipped;

  /// Предшественники по `requires`, которых ещё нет, — подсказка «ждёт».
  final List<String> waitingFor;

  const ArtifactState({
    required this.artifact,
    required this.files,
    required this.skipped,
    required this.waitingFor,
  });

  bool get exists => files.isNotEmpty;

  /// Первый файл артефакта — его открывает карточка; у маски это первая
  /// дельта по алфавиту.
  String? get firstFile => files.firstOrNull;
}

/// Артефакты change'а по схеме: какие написаны, какие ждут предшественников,
/// какие пропущены. Порядок — по зависимостям `requires`, как объявила схема.
///
/// Артефакт-маска (`specs/**/*.md`) написан, когда есть хотя бы один файл;
/// с `skip_specs` — пропущен, что не ненаписан и в счёт «N из M» не входит.
class ListChangeArtifacts {
  const ListChangeArtifacts();

  List<ArtifactState> call(ChangeUnit change, SpecSchema schema) {
    final ordered = _inRequiredOrder(schema.artifacts);
    final files = {
      for (final artifact in ordered) artifact.id: artifact.filesIn(change.dir),
    };
    final skipped = {
      for (final artifact in ordered)
        artifact.id: change.meta.skipSpecs && artifact.isSpecsDelta,
    };
    bool satisfied(String id) =>
        (files[id]?.isNotEmpty ?? false) || (skipped[id] ?? false);
    return [
      for (final artifact in ordered)
        ArtifactState(
          artifact: artifact,
          files: files[artifact.id]!,
          skipped: skipped[artifact.id]!,
          // Ждём только тех предшественников, которых схема знает сама.
          waitingFor: [
            for (final required in artifact.requires)
              if (files.containsKey(required) && !satisfied(required)) required,
          ],
        ),
    ];
  }

  /// Сколько артефактов заполнено и сколько всего — без пропущенных.
  static ({int done, int total}) progress(List<ArtifactState> states) {
    final counted = states.where((state) => !state.skipped);
    return (
      done: counted.where((state) => state.exists).length,
      total: counted.length,
    );
  }

  /// Артефакты по порядку зависимостей: сначала те, от кого зависят.
  /// Схема обычно уже перечисляет их верно — порядок объявления сохраняем.
  List<SchemaArtifact> _inRequiredOrder(List<SchemaArtifact> artifacts) {
    final placed = <String>{};
    final ordered = <SchemaArtifact>[];
    final pending = [...artifacts];
    while (pending.isNotEmpty) {
      final ready = pending.where(
        (artifact) => artifact.requires.every(
          (required) =>
              placed.contains(required) ||
              !artifacts.any((other) => other.id == required),
        ),
      );
      // Цикл в схеме не должен ронять экран — выкладываем как объявлено.
      final next = ready.firstOrNull ?? pending.first;
      ordered.add(next);
      placed.add(next.id);
      pending.remove(next);
    }
    return ordered;
  }
}
