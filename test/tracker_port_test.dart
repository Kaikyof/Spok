import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/repositories/platform_repository_impl.dart';
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/data/sources/redmine_tracker_resolver.dart';
import 'package:spok/data/sources/tracker_resolver.dart';
import 'package:spok/domain/entities/console_snapshot.dart';
import 'package:spok/domain/entities/env_check.dart';
import 'package:spok/domain/entities/spec_recognition.dart';
import 'package:spok/domain/repositories/tracker.dart';

import 'upstream_fixture.dart';

/// Заглушка контракта: отвечает тем, что ей задали, и помнит, что у неё
/// спрашивали. Сеть здесь не нужна — проверяется, что ядро ходит в трекер
/// только через контракт и только когда он объявлен.
class _FakeTracker implements Tracker {
  final Map<int, String> byIssue;
  final bool configuredValue;
  final askedStatuses = <List<int>>[];
  final askedComments = <int>[];
  int pings = 0;

  _FakeTracker({this.byIssue = const {}, this.configuredValue = true});

  @override
  String get name => 'FakeTracker';

  @override
  List<String> get credentialKeys => const ['FAKE_TOKEN'];

  @override
  bool get configured => configuredValue;

  @override
  String? issueUrl(int issueId) => 'https://tracker.example/i/$issueId';

  @override
  Future<Map<int, String>> statuses(List<int> issueIds) async {
    askedStatuses.add(issueIds);
    return {for (final id in issueIds) id: ?byIssue[id]};
  }

  @override
  Future<List<TrackerComment>> comments(int issueId) async {
    askedComments.add(issueId);
    return [(author: 'qa', createdAt: DateTime(2026, 9, 1), text: 'ок')];
  }

  @override
  Future<int> ping() async {
    pings++;
    return 7;
  }
}

/// Резолвер, который отдаёт заданный трекер и считает обращения.
class _FixedResolver implements TrackerResolver {
  final Tracker? tracker;
  int calls = 0;

  _FixedResolver(this.tracker);

  @override
  Tracker? resolve(PlatformFilesSource source, Map<String, String> env) {
    calls++;
    return tracker;
  }
}

/// Спека с трекером: семантика статусов, задача у стека, ключ в примере.
Directory _buildTrackedSpec({bool fillKey = false}) {
  final root = Directory.systemTemp.createTempSync('tracker-port');
  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  write('.env.example', 'REDMINE_URL=https://redmine.example.com\nREDMINE_API_KEY=\n');
  if (fillKey) {
    write('.env', 'REDMINE_URL=https://redmine.example.com\nREDMINE_API_KEY=k\n');
  }
  write('openspec/config.yaml', 'schema: spec-driven\n');
  write('openspec/redmine.yaml', '''
statuses:
  - id: 2
    name: В работе
''');
  write('openspec/changes/a/proposal.md', '# А\n');
  write('openspec/changes/a/tasks.md', '- [x] 1.1 Шаг\n- [ ] 1.2 Шаг\n');
  write('openspec/changes/a/redmine.yaml', '''
version: 3
stacks:
  work:
    issue_id: 100
    status_name: В работе
group:
  issue_id: 100
''');
  return root;
}

void main() {
  final roots = <Directory>[];

  tearDown(() {
    for (final root in roots) {
      root.deleteSync(recursive: true);
    }
    roots.clear();
  });

  group('контракт трекера', () {
    test('статусы, адрес задачи и имя приходят от контракта', () async {
      final root = _buildTrackedSpec(fillKey: true)..also(roots.add);
      final tracker = _FakeTracker(byIssue: {100: 'На ревью'});
      final repository = PlatformRepositoryImpl(PlatformFilesSource(root), trackers: _FixedResolver(tracker));

      final snapshot = await repository.load();

      expect(tracker.askedStatuses, [
        [100],
      ]);
      final stack = snapshot.changes.single.stacks.single;
      expect(stack.trackerStatus, 'На ревью');
      expect(stack.statusFromCache, isFalse);
      expect(snapshot.trackerProblem, TrackerProblem.none);
      expect(snapshot.trackerName, 'FakeTracker');
      expect(snapshot.trackerKeys, ['FAKE_TOKEN']);
      expect(snapshot.issueUrl(100), 'https://tracker.example/i/100');
      // Доступность системы на «Окружении» спрашивается через тот же
      // контракт, под именем, которое он назвал.
      expect(tracker.pings, 1);
      expect(snapshot.env.systems.single.name, 'FakeTracker');
      expect(snapshot.env.systems.single.outcome, CheckOutcome.systemResponds);
    });

    test('комментарии — через контракт, без ключа не спрашиваются', () async {
      final root = _buildTrackedSpec(fillKey: true)..also(roots.add);
      final tracker = _FakeTracker();
      final repository = PlatformRepositoryImpl(PlatformFilesSource(root), trackers: _FixedResolver(tracker));

      final comments = await repository.issueComments([100]);
      expect(comments.single.text, 'ок');
      expect(tracker.askedComments, [100]);

      final silent = _FakeTracker(configuredValue: false);
      final unconfigured = PlatformRepositoryImpl(PlatformFilesSource(root), trackers: _FixedResolver(silent));
      expect(await unconfigured.issueComments([100]), isEmpty);
      expect(silent.askedComments, isEmpty);
    });
  });

  group('улика трекера', () {
    test('проект без трекера: запросов нет, состояние «не объявлен», '
        'полосы и строки статусов в разборе нет', () async {
      final root = buildUpstreamSpec()..also(roots.add);
      final source = PlatformFilesSource(root);
      const resolver = RedmineTrackerResolver();
      expect(resolver.declaredIn(source), isFalse);

      // Настоящий резолвер: улики нет — адаптера нет, и ни один запрос
      // к трекеру не делается.
      final repository = PlatformRepositoryImpl(source, trackers: resolver);
      final snapshot = await repository.load();

      expect(snapshot.trackerProblem, TrackerProblem.notDeclared);
      expect(snapshot.trackerActive, isFalse);
      expect(snapshot.trackerName, isEmpty);
      expect(snapshot.issueUrl(1), isNull);
      for (final stack in snapshot.changes.expand((c) => c.stacks)) {
        expect(stack.trackerStatus, isNull);
        expect(stack.statusFromCache, isFalse);
      }
      expect(snapshot.profile.recognition.items.map((item) => item.part).contains(RecognizedPart.statuses), isFalse);
      // Статусы не считаются непонятыми там, где их нет: нераспознанным
      // остаётся только то, чего у спеки нет из другого (репозитории
      // workspace.yaml — до реестра расширений).
      expect(snapshot.profile.recognition.unrecognized.map((item) => item.part), [RecognizedPart.services]);
      // Внешних систем и ключей у спеки нет — разделов нет.
      expect(snapshot.env.systems, isEmpty);
      expect(snapshot.env.keysDeclared, isFalse);
    });

    test('трекер объявлен, ключ не заполнен: «нет ключа», статус из файла', () async {
      final root = _buildTrackedSpec()..also(roots.add);
      final source = PlatformFilesSource(root);
      expect(const RedmineTrackerResolver().declaredIn(source), isTrue);

      final snapshot = await PlatformRepositoryImpl(source).load();

      expect(snapshot.trackerProblem, TrackerProblem.noApiKey);
      expect(snapshot.trackerName, 'Redmine');
      expect(snapshot.trackerKeys, ['REDMINE_API_KEY']);
      final stack = snapshot.changes.single.stacks.single;
      expect(stack.trackerStatus, 'В работе');
      expect(stack.statusFromCache, isTrue);
      expect(snapshot.profile.recognition.items.map((item) => item.part).contains(RecognizedPart.statuses), isTrue);
      expect(snapshot.env.keysDeclared, isTrue);
    });

    test('улика — и один лишь REDMINE_URL в примере, без redmine.yaml', () {
      final root = Directory.systemTemp.createTempSync('tracker-evidence')..also(roots.add);
      Directory(p.join(root.path, 'openspec')).createSync();
      final source = PlatformFilesSource(root);
      const resolver = RedmineTrackerResolver();
      expect(resolver.resolve(source, const {}), isNull);

      File(p.join(root.path, '.env.example')).writeAsStringSync('REDMINE_URL=\n');
      expect(resolver.resolve(source, const {}), isNotNull);
    });
  });

  group('внешние системы из ключей примера', () {
    test('только Redmine: одна строка, без «GitLab не настроен»', () async {
      final root = _buildTrackedSpec()..also(roots.add);
      final snapshot = await PlatformRepositoryImpl(
        PlatformFilesSource(root),
        trackers: _FixedResolver(_FakeTracker()),
      ).load();

      expect(snapshot.env.systems.map((check) => check.name), ['FakeTracker']);
    });

    test('ключ объявлен, адрес не заполнен — «адрес не задан», а не тишина', () async {
      final root = _buildTrackedSpec()..also(roots.add);
      File(p.join(root.path, '.env.example')).writeAsStringSync('REDMINE_URL=\nGITLAB_URL=\n');
      final snapshot = await PlatformRepositoryImpl(
        PlatformFilesSource(root),
        trackers: _FixedResolver(_FakeTracker()),
      ).load();

      expect(snapshot.env.systems.map((check) => check.name), ['FakeTracker', 'GitLab']);
      expect(snapshot.env.systems.last.outcome, CheckOutcome.systemNotConfigured);
    });

    test('примера нет — систем и ключей нет', () async {
      final root = buildUpstreamSpec()..also(roots.add);
      final snapshot = await PlatformRepositoryImpl(PlatformFilesSource(root)).load();

      expect(snapshot.env.systems, isEmpty);
      expect(snapshot.env.keys, isEmpty);
      expect(snapshot.env.keysDeclared, isFalse);
    });
  });
}

extension _Also<T> on T {
  T also(void Function(T value) block) {
    block(this);
    return this;
  }
}
