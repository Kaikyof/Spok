import 'build_info.dart';

/// Как спека группирует change'и. Стратегию выбирает discovery,
/// человек может её сменить.
enum GroupingKind {
  /// `openspec/doc/<id>/` со `sprint.yaml` — спринт: ветки, сборки, передача.
  sprintDir,

  /// `openspec/doc/<id>.md` — мастер-спека, ветки и сборок нет.
  masterDoc,

  /// Change'и, не попавшие ни в одну группу.
  none,
}

/// Группа change'ей: спринт, мастер-спека или плоский список.
class Group {
  final String id;
  final String title;
  final GroupingKind kind;

  /// Ветки по стекам; пусто — у группы нет цели MR.
  final Map<String, String> branches;

  /// Сборки по стекам; пусто — фича сборок выключена.
  final Map<String, BuildInfo> builds;

  /// Мастер-спека или doc.md группы для рендера; null — документа нет.
  final String? docPath;

  final List<String> changeIds;
  final String delivery; // batch | per-change

  const Group({
    required this.id,
    required this.title,
    required this.kind,
    this.branches = const {},
    this.builds = const {},
    this.docPath,
    this.changeIds = const [],
    this.delivery = 'batch',
  });

  String? branchFor(String stack) => branches[stack] ?? branches.values.firstOrNull;

  BuildInfo? buildFor(String stack) => builds[stack];
}
