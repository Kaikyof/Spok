/// Поле формы ключей: что спрашивает спека и что уже заполнено.
class EnvField {
  final String key;
  final String value;

  /// Подсказка — комментарий над строкой в `.env.example`.
  final String hint;

  /// Ключ в примере закомментирован — спека работает и без него.
  final bool optional;

  const EnvField({
    required this.key,
    required this.value,
    this.hint = '',
    this.optional = false,
  });

  /// Секрет не показывается на экране открытым: токены и пароли
  /// попадают в скриншоты и демонстрации экрана.
  bool get secret => RegExp(r'(TOKEN|KEY|SECRET|PASSWORD)$').hasMatch(key);

  EnvField copyWith({String? value}) => EnvField(
        key: key,
        value: value ?? this.value,
        hint: hint,
        optional: optional,
      );
}

/// Форма ключей спеки целиком: поля и то, безопасно ли писать .env.
class EnvForm {
  final List<EnvField> fields;

  /// `.env` попадает под .gitignore — иначе секреты уедут в репозиторий.
  final bool ignoredByGit;

  /// Путь к файлу, который будет записан.
  final String path;

  const EnvForm({
    required this.fields,
    required this.ignoredByGit,
    required this.path,
  });

  static const empty = EnvForm(fields: [], ignoredByGit: true, path: '');
}
