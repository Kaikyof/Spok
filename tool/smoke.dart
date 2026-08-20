// Смоук: читает реальные файлы платформы и печатает слепок без UI.
import 'package:platform_console/data/repositories/platform_repository_impl.dart';
import 'package:platform_console/data/sources/platform_files_source.dart';

Future<void> main() async {
  final src = PlatformFilesSource.locate();
  print('repo: ${src?.path}');
  final repo = PlatformRepositoryImpl(src);
  final s = await repo.load();
  print('sprints: ${s.sprints.map((e) => '${e.id} · ${e.title} · ios=${e.buildIos?.versionName} android=${e.buildAndroid?.versionName}').join('; ')}');
  print('role: ${repo.role}');
  print('redmineProblem: ${s.redmineProblem}');
  for (final c in s.changes) {
    print('  ${c.id}: «${c.title}» ios=${c.ios?.doneCount}/${c.ios?.tasks.length}(#${c.ios?.issueId},${c.ios?.redmineStatus}) android=${c.android?.doneCount}/${c.android?.tasks.length}(#${c.android?.issueId},${c.android?.redmineStatus}) deps=${c.dependsOn}');
  }
  print('divergences: ${s.divergences.map((d) => '${d.changeId}/${d.stack}: ${d.message}').join(' | ')}');
  print('env problems: ${s.env.problems}');
  for (final g in [s.env.keys, s.env.repos, s.env.systems]) {
    for (final c in g) { print('  [${c.level.name}] ${c.name} · ${c.detail} · ${c.result}'); }
  }
}
