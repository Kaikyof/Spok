import '../../domain/repositories/tracker.dart';
import 'platform_files_source.dart';
import 'redmine_api.dart';
import 'tracker_resolver.dart';

/// Единственный пока адаптер — Redmine, по улике спеки. Адрес может быть
/// пустым: тогда трекер объявлен, но не настроен, и это скажет
/// `Tracker.configured`, а не отсутствие адаптера.
class RedmineTrackerResolver implements TrackerResolver {
  const RedmineTrackerResolver();

  static const urlKey = 'REDMINE_URL';
  static const apiKey = 'REDMINE_API_KEY';

  @override
  Tracker? resolve(PlatformFilesSource source, Map<String, String> env) =>
      source.trackerDeclared
          ? RedmineApi(env[urlKey] ?? '', env[apiKey] ?? '')
          : null;
}
