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
    final resp = await _dio.get(
      '/issues.json',
      queryParameters: {'issue_id': issueIds.join(','), 'status_id': '*', 'limit': 100},
    );
    return {for (final issue in (resp.data['issues'] as List)) issue['id'] as int: issue['status']['name'] as String};
  }

  /// Лента комментариев задачи (журналы с текстом), новые сверху.
  @override
  Future<List<TrackerComment>> comments(int issueId) async {
    final resp = await _dio.get('/issues/$issueId.json', queryParameters: {'include': 'journals'});
    final journals = resp.data['issue']?['journals'];
    if (journals is! List) return const [];
    return [
      for (final journal in journals.reversed)
        if ((journal['notes']?.toString() ?? '').trim().isNotEmpty)
          (
            author: journal['user']?['name']?.toString() ?? '—',
            createdAt: DateTime.tryParse(journal['created_on']?.toString() ?? '') ?? DateTime.now(),
            text: journal['notes'].toString().trim(),
          ),
    ];
  }

  /// Проверка доступности; возвращает время ответа в мс.
  @override
  Future<int> ping() async {
    final sw = Stopwatch()..start();
    await _dio.get('/my/account.json');
    return sw.elapsedMilliseconds;
  }
}
