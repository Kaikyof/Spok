/// Состояние MR по одному стеку change'а: ярлык GitLab и факт влития.
/// Оба показываются рядом — где они расходятся, это видно (бриф §3.2).
enum MergeRequestState { none, opened, merged, closed }

class MergeRequestInfo {
  final String stack; // ios | android
  final String sourceBranch;
  final String targetBranch;
  final MergeRequestState state;
  final int? iid; // номер MR: !482
  final String webUrl;

  /// Факт: коммит слияния действительно есть в ветке спринта.
  /// null — проверить не удалось (нет доступа или MR ещё не слит).
  final bool? mergedIntoTarget;

  const MergeRequestInfo({
    required this.stack,
    required this.sourceBranch,
    required this.targetBranch,
    required this.state,
    this.iid,
    this.webUrl = '',
    this.mergedIntoTarget,
  });

  /// Ярлык говорит «слит», а коммита в целевой ветке нет.
  bool get diverged => state == MergeRequestState.merged && mergedIntoTarget == false;
}
