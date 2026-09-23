import 'doc_artifact.dart';

/// Что за узел дерева документов: группа работы, change или архивный change.
enum DocNodeKind { group, change, archivedChange }

/// Узел дерева документов спеки.
///
/// Группа — спринт (каталог с `doc.md`) или мастер-спека, лежащая одним
/// файлом; у мастер-спеки собственный документ есть, а детей может не быть
/// вовсе. Архивный change приходит с датой из имени каталога, а id у него
/// хранится очищенным — иначе рвётся связь с трекером и группой.
class DocNode {
  final String id;
  final String title;
  final DocNodeKind kind;

  /// Документы узла в порядке схемы; пустой список — узел без файлов.
  final List<DocArtifact> docs;

  final List<DocNode> children;

  /// Ветка узла из спеки; пусто — спека веток не ведёт.
  final String branch;

  /// Дата из имени каталога архива; null — узел не архивный.
  final DateTime? archivedAt;

  const DocNode({
    required this.id,
    required this.title,
    required this.kind,
    this.docs = const [],
    this.children = const [],
    this.branch = '',
    this.archivedAt,
  });

  /// Сколько файлов узла и его детей лежит на диске.
  int get presentCount =>
      docs.where((doc) => doc.exists).length +
      children.fold(0, (sum, child) => sum + child.presentCount);

  /// Сколько файлов объявлено — вместе с теми, которых ещё нет.
  int get declaredCount =>
      docs.length + children.fold(0, (sum, child) => sum + child.declaredCount);
}
