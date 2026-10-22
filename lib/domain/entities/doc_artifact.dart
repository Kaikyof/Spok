/// Артефакт документации — markdown-файл группы или change'а.
class DocArtifact {
  final String label;
  final String fileName;
  final String path;
  final bool exists;

  /// Идентификатор артефакта в схеме (`proposal`, `design`, `tasks-ios`);
  /// пусто — файл схемой не объявлен, подписи ему дают по имени файла.
  final String id;

  /// Операции дельты спецификации по заголовкам `## ADDED Requirements`
  /// и подобным, в порядке появления; пусто — файл не дельта.
  final List<String> operations;

  const DocArtifact(this.label, this.fileName, this.path, this.exists,
      {this.id = '', this.operations = const []});

  /// Документы самой группы: схема их не объявляет, а подпись им нужна
  /// человеческая — отсюда собственные идентификаторы.
  static const masterDocId = '::master-doc';
  static const groupDocId = '::group-doc';
  static const specFileId = '::spec';
}
