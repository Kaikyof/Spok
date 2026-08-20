import 'build_info.dart';

/// Спринт — папка `openspec/doc/<id>`: мастер-спека, ветка, сборки.
class Sprint {
  final String id;
  final String title; // человеческое название из doc.md
  final String? branchIos;
  final String? branchAndroid;
  final String delivery; // batch | per-change
  final BuildInfo? buildIos;
  final BuildInfo? buildAndroid;

  const Sprint({
    required this.id,
    required this.title,
    this.branchIos,
    this.branchAndroid,
    this.delivery = 'batch',
    this.buildIos,
    this.buildAndroid,
  });
}
