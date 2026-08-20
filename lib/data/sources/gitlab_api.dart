import 'package:dio/dio.dart';

import '../../domain/entities/merge_request_info.dart';

/// Минимальный клиент GitLab: MR по ветке и проверка факта влития.
class GitLabApi {
  final Dio _dio;

  GitLabApi(String baseUrl, String token)
      : _dio = Dio(BaseOptions(
          baseUrl: '$baseUrl/api/v4',
          headers: {'PRIVATE-TOKEN': token},
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ));

  /// «git@host:group/project.git» или «https://host/group/project.git»
  /// → «group%2Fproject» для path-параметра GitLab.
  static String? projectPathFromRepo(String repoUrl) {
    final match = RegExp(r'[:/]([^:/]+/[^/]+?)(?:\.git)?$').firstMatch(repoUrl);
    return match == null ? null : Uri.encodeComponent(match.group(1)!);
  }

  /// MR стека: ищем по ветке change'а, при равенстве берём самый свежий.
  Future<MergeRequestInfo> mergeRequestFor({
    required String projectPath,
    required String stack,
    required String sourceBranch,
    required String targetBranch,
  }) async {
    final resp = await _dio.get('/projects/$projectPath/merge_requests',
        queryParameters: {
          'source_branch': sourceBranch,
          'order_by': 'updated_at',
          'per_page': 5,
        });
    final list = resp.data;
    if (list is! List || list.isEmpty) {
      return MergeRequestInfo(
        stack: stack,
        sourceBranch: sourceBranch,
        targetBranch: targetBranch,
        state: MergeRequestState.none,
      );
    }
    final mr = list.first;
    final state = switch (mr['state']?.toString()) {
      'opened' => MergeRequestState.opened,
      'merged' => MergeRequestState.merged,
      'closed' => MergeRequestState.closed,
      _ => MergeRequestState.none,
    };
    final mergeSha = (mr['merge_commit_sha'] ?? mr['squash_commit_sha'] ?? mr['sha'])
        ?.toString();
    final actualTarget = mr['target_branch']?.toString() ?? targetBranch;
    return MergeRequestInfo(
      stack: stack,
      sourceBranch: sourceBranch,
      targetBranch: actualTarget,
      state: state,
      iid: int.tryParse('${mr['iid']}'),
      webUrl: mr['web_url']?.toString() ?? '',
      mergedIntoTarget: state == MergeRequestState.merged && mergeSha != null
          ? await _commitIsInBranch(
              projectPath: projectPath, sha: mergeSha, branch: actualTarget)
          : null,
    );
  }

  /// Факт влития: коммит числится в целевой ветке.
  Future<bool?> _commitIsInBranch({
    required String projectPath,
    required String sha,
    required String branch,
  }) async {
    try {
      final resp = await _dio.get(
          '/projects/$projectPath/repository/commits/$sha/refs',
          queryParameters: {'type': 'branch', 'per_page': 100});
      final refs = resp.data;
      if (refs is! List) return null;
      return refs.any((ref) => ref['name']?.toString() == branch);
    } on DioException {
      return null; // нет прав или коммит недоступен — не выдумываем факт
    }
  }
}
