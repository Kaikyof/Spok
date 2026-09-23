// ignore_for_file: avoid_print
// Смоук: читает реальные файлы спеки и печатает слепок без UI.
// Путь к спеке — SPEC_PLATFORM_DIR, конфиг приложения или типовые пути.
import 'package:spok/data/repositories/platform_repository_impl.dart';
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/domain/entities/doc_node.dart';
import 'package:spok/domain/entities/project_profile.dart';

Future<void> main() async {
  final source = PlatformFilesSource.locate();
  print('repo: ${source?.path}');
  final repository = PlatformRepositoryImpl(source);
  final snapshot = await repository.load();
  final profile = snapshot.profile;

  print('schema: ${profile.schema.name} · стеки: ${profile.stacks} · '
      'ветка change: ${profile.schema.branchFor('<change>')}');
  print('группировка: ${profile.grouping.name}');
  for (final feature in SpecFeature.values) {
    final gate = profile.gate(feature);
    print('фича ${feature.name}: '
        '${gate.available ? 'доступна' : 'недоступна'} '
        '(${gate.satisfiedCount}/${gate.requirements.length})');
    for (final requirement in gate.requirements) {
      print('    ${requirement.satisfied ? '✓' : '○'} '
          '${requirement.id.name} [${requirement.scope.name}'
          '${requirement.optional ? ', необязательное' : ''}] '
          '${requirement.lookedIn}');
    }
  }
  print('статусы: работа=${profile.statuses.workingStatuses} · '
      'передача=${profile.statuses.handoffStatus}');
  for (final group in snapshot.groups) {
    print('группа ${group.id.isEmpty ? '(вне групп)' : group.id} '
        '[${group.kind.name}] «${group.title}» '
        'changes=${group.changeIds.length} ветки=${group.branches} '
        'сборки=${group.builds.keys.toList()}');
  }
  print('role: ${repository.role} (${repository.roleKey})');
  print('redmineProblem: ${snapshot.redmineProblem.name} '
      '${snapshot.redmineProblemDetail}');
  for (final change in snapshot.changes) {
    final stacks = change.stacks
        .map((stack) => '${stack.stack}=${stack.doneCount}/${stack.tasks.length}'
            '(#${stack.issueId},${stack.redmineStatus}'
            '${stack.statusFromCache ? ',из файла' : ''})')
        .join(' ');
    print('  ${change.id}: «${change.title}» $stacks deps=${change.dependsOn}');
  }
  print('divergences: ${snapshot.divergences.map((d) => '${d.changeId}/${d.stack}: ${d.kind.name} open=${d.openTaskNumbers}').join(' | ')}');
  print('документы:');
  void printDocs(DocNode node, String indent) {
    print('$indent${node.id.isEmpty ? '(вне групп)' : node.id} '
        '[${node.kind.name}] «${node.title}» '
        '${node.presentCount}/${node.declaredCount}'
        '${node.archivedAt == null ? '' : ' архив ${node.archivedAt}'}');
    for (final doc in node.docs) {
      print('$indent  ${doc.exists ? '✓' : '○'} ${doc.fileName} [${doc.id}]');
    }
    for (final child in node.children) {
      printDocs(child, '$indent  ');
    }
  }

  for (final node in snapshot.docs) {
    printDocs(node, '  ');
  }
  print('commands: ${repository.slashCommands().length}');
  print('env problems: ${snapshot.env.problemCount}');
  for (final check in snapshot.env.all) {
    print('  [${check.level.name}] ${check.name} · ${check.subtitle} · '
        '${check.outcome.name}(${check.count}${check.param})');
  }
}
