/// Статус трекера, как его объявила спека: имя, id и что он значит.
class TrackerStatus {
  final int id;
  final String name;
  final bool closing;
  final bool completesTask;

  const TrackerStatus({
    required this.id,
    required this.name,
    this.closing = false,
    this.completesTask = false,
  });
}

/// Семантика статусов из `openspec/redmine.yaml`: правила расхождений
/// строятся на ней, а не на русских строках в коде.
class StatusSemantics {
  final List<TrackerStatus> statuses;

  /// Карта `sync.on_*_status_id` → id статуса.
  final Map<String, int> sync;

  const StatusSemantics({this.statuses = const [], this.sync = const {}});

  static const empty = StatusSemantics();

  bool get isEmpty => statuses.isEmpty;

  String? nameOf(int? id) =>
      statuses.where((status) => status.id == id).map((s) => s.name).firstOrNull;

  TrackerStatus? byName(String name) =>
      statuses.where((status) => status.name == name).firstOrNull;

  String? _syncName(String key) => nameOf(sync[key]);

  /// Работа ещё идёт: новая, в работе, возвращена, переоткрыта.
  Set<String> get workingStatuses => {
        for (final key in const [
          'on_push_new_issue_status_id',
          'on_dev_start_status_id',
          'on_returned_status_id',
          'on_change_reopen_status_id',
        ])
          ?_syncName(key),
      };

  /// Статус «код ушёл на ревью».
  String? get reviewStatus => _syncName('on_mr_open_status_id');

  /// Статус завершения change'а.
  String? get completeStatus => _syncName('on_change_complete_status_id');

  /// Статусы тестирования и релиза: работа объявлена сделанной, а значит
  /// незакрытые галочки — расхождение. Выводятся из имён статусов спеки.
  Set<String> get testingStatuses => {
        for (final status in statuses)
          if (!status.closing &&
              RegExp(r'тест|test|релиз|release', caseSensitive: false)
                  .hasMatch(status.name))
            status.name,
      };

  /// Закрывающие статусы — задача в трекере закрыта.
  Set<String> get closingStatuses =>
      {for (final status in statuses) if (status.closing) status.name};

  /// Статус, в котором работа передаётся тестировщику: первый статус
  /// ожидания тестирования, иначе — ревью.
  String? get handoffStatus {
    final waiting = statuses.where((status) =>
        !status.closing &&
        RegExp(r'ожидает тест|waiting.*test|ready.*test', caseSensitive: false)
            .hasMatch(status.name));
    return waiting.map((status) => status.name).firstOrNull ?? reviewStatus;
  }
}
