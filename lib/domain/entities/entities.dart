/// Модель данных консоли. Приложение ничего не хранит: всё читается из
/// файлов avtoto-platform, Redmine и git (Приложение В брифа).
library;

class Sprint {
  final String id; // имя папки openspec/doc/<id>
  final String title; // человеческое название из doc.md
  final String? branchIos;
  final String? branchAndroid;
  final String delivery; // batch | per-change
  final BuildInfo? buildIos;
  final BuildInfo? buildAndroid;

  Sprint({
    required this.id,
    required this.title,
    this.branchIos,
    this.branchAndroid,
    this.delivery = 'batch',
    this.buildIos,
    this.buildAndroid,
  });
}

class BuildInfo {
  final String versionName;
  final String? channel; // TestFlight / Nextcloud APK
  final DateTime? publishedAt;
  BuildInfo({required this.versionName, this.channel, this.publishedAt});
}

class TaskItem {
  final String num; // «3.3»
  final String title;
  final bool done;
  TaskItem(this.num, this.title, this.done);
}

class StackState {
  final String stack; // ios | android
  final int? issueId;
  final List<TaskItem> tasks;
  String? redmineStatus; // null — статус недоступен (нет ключа/сети)
  StackState({required this.stack, this.issueId, required this.tasks});

  int get doneCount => tasks.where((t) => t.done).length;
  List<TaskItem> get openTasks => tasks.where((t) => !t.done).toList();
}

class ChangeUnit {
  final String id; // имя папки openspec/changes/<id>
  final String title; // redmine_title из tasks_*.md или заголовок proposal.md
  final String dir; // абсолютный путь к папке change'а
  final StackState? ios;
  final StackState? android;
  final List<String> dependsOn; // group.members до этого change'а
  ChangeUnit({
    required this.id,
    required this.title,
    required this.dir,
    this.ios,
    this.android,
    this.dependsOn = const [],
  });

  List<StackState> get stacks => [?ios, ?android];
}

/// Расхождение: статус/отметка против факта.
class Divergence {
  final String changeId;
  final String changeTitle;
  final String stack;
  final String message;
  Divergence(this.changeId, this.changeTitle, this.stack, this.message);
}

enum CheckLevel { ok, warn, error }

class EnvCheck {
  final CheckLevel level;
  final String name; // моноширинное имя (ключ, репозиторий, система)
  final String detail; // человеческое пояснение
  final String result; // правая колонка
  EnvCheck(this.level, this.name, this.detail, this.result);
}

class EnvReport {
  final List<EnvCheck> keys;
  final List<EnvCheck> repos;
  final List<EnvCheck> systems;
  EnvReport({required this.keys, required this.repos, required this.systems});

  int get problems => [...keys, ...repos, ...systems]
      .where((c) => c.level != CheckLevel.ok)
      .length;
}

/// Артефакт документации (файл в папке спринта или change'а).
class DocArtifact {
  final String label; // «Спека», «Задачи iOS»…
  final String fileName;
  final String path;
  final bool exists;
  DocArtifact(this.label, this.fileName, this.path, this.exists);
}
