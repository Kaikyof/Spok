/// Имена статусов Redmine, как их называют спеки команды. Знание
/// адаптера: ядро со статусами работает по семантике из
/// `openspec/redmine.yaml`, а не по этим строкам.
abstract class RedmineStatusNames {
  static const newIssue = 'Новая';
  static const inProgress = 'В работе';
  static const inReview = 'На ревью';
  static const reviewDone = 'Ревью завершено';
  static const waitingTest = 'Ожидает тестирования';
  static const testing = 'На тестировании';
  static const readyToRelease = 'Готово к релизу';
  static const returnedFromReview = 'Возвращена с ревью';
  static const returned = 'Возвращена';
}
