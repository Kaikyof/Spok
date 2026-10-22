import 'package:dio/dio.dart';

import '../../domain/repositories/tracker.dart';

/// Адаптер Redmine к контракту трекера: только чтение статусов,
/// комментариев и доступности. Единственное место, где ядро узнаёт
/// слово «Redmine», — через `name`.
class RedmineApi implements Tracker {
  final String baseUrl;
  final String apiKey;
  final Dio _dio;

  RedmineApi(this.baseUrl, this.apiKey)
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'X-Redmine-API-Key': apiKey},
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

  @override
  String get name => 'Redmine';

  @override
  List<String> get credentialKeys => const ['REDMINE_API_KEY'];

  @override
  bool get configured => baseUrl.isNotEmpty && apiKey.isNotEmpty;

  @override
  String? issueUrl(int issueId) => baseUrl.isEmpty ? null : '$baseUrl/issues/$issueId';

  /// id задачи → имя статуса («Ожидает тестирования» и т.д.).
  @override
  Future<Map<int, String>> statuses(List<int> issueIds) async {
    if (issueIds.isEmpty) return {};
    final resp = await _dio.get<Object?>(
      '/issues.json',
      queryParameters: {'issue_id': issueIds.join(','), 'status_id': '*', 'limit': 100},
    );
    // Ответ без списка задач — сбой Redmine, а не «статусов нет».
    if (resp.data case {'issues': final List<Object?> issues}) {
      return {
        for (final issue in issues)
          if (issue case {'id': final int id, 'status': {'name': final String name}}) id: name,
      };
    }
    throw const FormatException('в ответе Redmine нет списка issues');
  }

  /// Лента комментариев задачи (журналы с текстом), новые сверху.
  @override
  Future<List<TrackerComment>> comments(int issueId) async {
    final resp = await _dio.get<Object?>('/issues/$issueId.json', queryParameters: {'include': 'journals'});
    if (resp.data case {'issue': {'journals': final List<Object?> journals}}) {
      return [
        for (final journal in journals.reversed)
          if (journal case {'notes': final Object notes} when notes.toString().trim().isNotEmpty)
            (
              author: switch (journal) {
                {'user': {'name': final Object name}} => name.toString(),
                _ => '—',
              },
              createdAt: DateTime.tryParse('${journal['created_on'] ?? ''}') ?? DateTime.now(),
              text: notes.toString().trim(),
            ),
      ];
    }
    return const [];
  }

  /// Проверка доступности; возвращает время ответа в мс.
  @override
  Future<int> ping() async {
    final sw = Stopwatch()..start();
    await _dio.get<Object?>('/my/account.json');
    return sw.elapsedMilliseconds;
  }
}
