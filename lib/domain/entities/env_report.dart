import 'env_check.dart';
import 'secret_backend.dart';

class EnvReport {
  final List<EnvCheck> keys;
  final List<EnvCheck> repos;
  final List<EnvCheck> systems;

  /// Где лежат секреты на этой машине. Экран говорит это прямо: человек,
  /// вводящий токен, вправе знать, куда он попадёт.
  final SecretBackend backend;

  /// Спека объявляет ключи — у неё есть `.env.example`. Нет файла — нет и
  /// требований «ключ не заполнен у меня»: раздел ключей и форма их
  /// заполнения не показываются. Умолчание — «объявлены»: отчёт без
  /// файла примера строит только слой данных, и он говорит это явно.
  final bool keysDeclared;

  const EnvReport({
    required this.keys,
    required this.repos,
    required this.systems,
    this.backend = SecretBackend.file,
    this.keysDeclared = true,
  });

  List<EnvCheck> get all => [...keys, ...repos, ...systems];

  int get problemCount =>
      all.where((check) => check.level != CheckLevel.ok).length;
}
