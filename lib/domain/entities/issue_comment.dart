/// Комментарий в задаче Redmine — лента, по которой общаются
/// разработчик и тестировщик.
class IssueComment {
  final int issueId;
  final String author;
  final DateTime createdAt;
  final String text;

  const IssueComment({
    required this.issueId,
    required this.author,
    required this.createdAt,
    required this.text,
  });
}
