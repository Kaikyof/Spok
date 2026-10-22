import '../../domain/repositories/tracker.dart';
import 'platform_files_source.dart';
import 'redmine_api.dart';
import 'tracker_resolver.dart';

/// Единственный пока адаптер — Redmine. Улика, по которой он включается,
/// живёт здесь же, а не в источнике файлов: что считать признаком Redmine,
/// знает только адаптер Redmine. Адрес может быть пустым: тогда трекер
/// объявлен, но не настроен, и это скажет `Tracker.configured`, а не
/// отсутствие адаптера.
class RedmineTrackerResolver implements TrackerResolver {
  const RedmineTrackerResolver();

  static const urlKey = 'REDMINE_URL';
  static const apiKey = 'REDMINE_API_KEY';

  /// Спека пользуется Redmine, если объявила семантику его статусов
  /// (`openspec/redmine.yaml`) или адрес системы в `.env.example`.
  bool declaredIn(PlatformFilesSource source) =>
      source.trackerFile.isNotEmpty || source.loadEnvExampleKeys().any((example) => example.key == urlKey);

  @override
  Tracker? resolve(PlatformFilesSource source, Map<String, String> env) =>
      declaredIn(source) ? RedmineApi(env[urlKey] ?? '', env[apiKey] ?? '') : null;
}
