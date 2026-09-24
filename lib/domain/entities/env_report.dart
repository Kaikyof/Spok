import 'env_check.dart';
import 'secret_backend.dart';

class EnvReport {
  final List<EnvCheck> keys;
  final List<EnvCheck> repos;
  final List<EnvCheck> systems;

  /// Где лежат секреты на этой машине. Экран говорит это прямо: человек,
  /// вводящий токен, вправе знать, куда он попадёт.
  final SecretBackend backend;

  const EnvReport({
    required this.keys,
    required this.repos,
    required this.systems,
    this.backend = SecretBackend.file,
  });

  List<EnvCheck> get all => [...keys, ...repos, ...systems];

  int get problemCount =>
      all.where((check) => check.level != CheckLevel.ok).length;
}
