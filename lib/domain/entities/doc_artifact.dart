/// Артефакт документации — markdown-файл спринта или change'а.
class DocArtifact {
  final String label;
  final String fileName;
  final String path;
  final bool exists;

  const DocArtifact(this.label, this.fileName, this.path, this.exists);
}
