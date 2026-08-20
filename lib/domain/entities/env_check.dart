enum CheckLevel { ok, warn, error }

/// Результат проверки — структурный: текст даёт слой представления.
enum CheckOutcome {
  keyFilled,
  keyMissing,
  roleValue, // param — значение роли
  repoSynced,
  repoBehind, // count — на сколько коммитов
  repoNotCloned,
  systemResponds, // count — мс
  systemRespondsWithCode, // count — HTTP-код
  systemTimeout,
  systemNoConnection,
  systemNotConfigured,
}

/// Одна проверка окружения: ключ .env, репозиторий или внешняя система.
class EnvCheck {
  final CheckLevel level;
  final String name; // имя ключа / репозитория / системы

  /// Данные, не текст: ветка репозитория, хост системы, ожидаемый ref.
  final String subtitle;

  final CheckOutcome outcome;
  final int count; // мс, коммиты или HTTP-код — по смыслу outcome
  final String param; // строковый параметр (значение роли и т.п.)

  const EnvCheck({
    required this.level,
    required this.name,
    required this.outcome,
    this.subtitle = '',
    this.count = 0,
    this.param = '',
  });
}
