import '../../domain/repositories/tracker.dart';
import 'platform_files_source.dart';

/// Подбирает адаптер трекера под спеку: по улике в её файлах и ключам
/// `.env`. Репозиторий получает резолвер снаружи и знает только контракт
/// — какой адаптер и по какой улике, решает реализация, и тесты
/// подставляют свою без сети.
abstract class TrackerResolver {
  /// Трекер спеки; null — спека трекером не пользуется.
  Tracker? resolve(PlatformFilesSource source, Map<String, String> env);
}
