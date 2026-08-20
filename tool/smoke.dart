// ignore_for_file: avoid_print
// Смоук: читает реальные файлы платформы и печатает слепок без UI.
import 'package:platform_console/data/repositories/platform_repository_impl.dart';
import 'package:platform_console/data/sources/platform_files_source.dart';

Future<void> main() async {
  final source = PlatformFilesSource.locate();
  print('repo: ${source?.path}');
  final repository = PlatformRepositoryImpl(source);
  final snapshot = await repository.load();
  print('sprints: ${snapshot.sprints.map((s) => '${s.id} · ${s.title} · ios=${s.buildIos?.versionName} android=${s.buildAndroid?.versionName}').join('; ')}');
  print('role: ${repository.role}');
  print('redmineProblem: ${snapshot.redmineProblem.name} ${snapshot.redmineProblemDetail}');
  for (final change in snapshot.changes) {
    print('  ${change.id}: «${change.title}» '
        'ios=${change.ios?.doneCount}/${change.ios?.tasks.length}(#${change.ios?.issueId},${change.ios?.redmineStatus}) '
        'android=${change.android?.doneCount}/${change.android?.tasks.length}(#${change.android?.issueId},${change.android?.redmineStatus}) '
        'deps=${change.dependsOn}');
  }
  print('divergences: ${snapshot.divergences.map((d) => '${d.changeId}/${d.stack}: ${d.kind.name} open=${d.openTaskNumbers}').join(' | ')}');
  print('env problems: ${snapshot.env.problemCount}');
  for (final check in snapshot.env.all) {
    print('  [${check.level.name}] ${check.name} · ${check.subtitle} · ${check.outcome.name}(${check.count}${check.param})');
  }
}
