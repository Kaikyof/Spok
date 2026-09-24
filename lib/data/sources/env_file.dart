/// Разбор файла `.env`.
///
/// Формат простой, но не совсем очевидный: строка может начинаться с
/// `export`, значение — быть в кавычках, а после `#` идти комментарий.
/// Разбор один на всё приложение: форма ключей, импорт из чужого файла
/// и чтение `.env` спеки обязаны понимать одно и то же, иначе
/// импортированное значение не совпадёт с прочитанным.
abstract class EnvFile {
  static final _entry =
      RegExp(r'^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$');

  /// Пары ключ-значение в порядке файла. Строки не в формате `KEY=value`
  /// пропускаются молча: в чужом `.env` бывает что угодно.
  static Map<String, String> parse(String content) {
    final values = <String, String>{};
    for (final raw in content.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final match = _entry.firstMatch(line);
      if (match == null) continue;
      values[match.group(1)!] = _value(match.group(2)!);
    }
    return values;
  }

  /// Значение без кавычек и без хвостового комментария. Комментарий
  /// отрезаем только у значения без кавычек: внутри кавычек `#` — часть
  /// пароля, а не примечание.
  static String _value(String raw) {
    final trimmed = raw.trim();
    for (final quote in ['"', "'"]) {
      if (trimmed.length >= 2 &&
          trimmed.startsWith(quote) &&
          trimmed.endsWith(quote)) {
        return trimmed.substring(1, trimmed.length - 1);
      }
    }
    final comment = RegExp(r'\s+#').firstMatch(trimmed);
    return comment == null
        ? trimmed
        : trimmed.substring(0, comment.start).trim();
  }
}
