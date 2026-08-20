import 'package:dio/dio.dart';

/// Минимальный клиент Redmine: только чтение статусов задач.
class RedmineApi {
  final Dio _dio;

  RedmineApi(String baseUrl, String apiKey)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'X-Redmine-API-Key': apiKey},
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ));

  /// id задачи → имя статуса («Ожидает тестирования» и т.д.).
  Future<Map<int, String>> issueStatuses(List<int> ids) async {
    if (ids.isEmpty) return {};
    final resp = await _dio.get('/issues.json', queryParameters: {
      'issue_id': ids.join(','),
      'status_id': '*',
      'limit': 100,
    });
    return {
      for (final issue in (resp.data['issues'] as List))
        issue['id'] as int: issue['status']['name'] as String,
    };
  }

  /// Лента комментариев задачи (журналы с текстом), новые сверху.
  Future<List<({String author, DateTime createdAt, String text})>> issueComments(
      int issueId) async {
    final resp = await _dio.get('/issues/$issueId.json',
        queryParameters: {'include': 'journals'});
    final journals = resp.data['issue']?['journals'];
    if (journals is! List) return const [];
    return [
      for (final journal in journals.reversed)
        if ((journal['notes']?.toString() ?? '').trim().isNotEmpty)
          (
            author: journal['user']?['name']?.toString() ?? '—',
            createdAt:
                DateTime.tryParse(journal['created_on']?.toString() ?? '') ??
                    DateTime.now(),
            text: journal['notes'].toString().trim(),
          ),
    ];
  }

  /// Проверка доступности; возвращает время ответа в мс.
  Future<int> ping() async {
    final sw = Stopwatch()..start();
    await _dio.get('/my/account.json');
    return sw.elapsedMilliseconds;
  }
}
