/// Где на этой машине лежат секреты спеки.
///
/// Это не настройка, а факт: хранилище либо есть, либо его нет. Экран
/// ключей показывает его честно — «сохранено в Keychain» и «связки ключей
/// нет, значения в файле» отвечают на разные вопросы о безопасности.
enum SecretBackend {
  /// macOS Keychain через `security`.
  keychain,

  /// Linux Secret Service через `secret-tool` (gnome-keyring, KWallet).
  libsecret,

  /// Ни одного хранилища не нашлось — значения лежат в файле рядом
  /// с конфигом приложения, с правами `0600`.
  file,
}

extension SecretBackendX on SecretBackend {
  /// Секреты в системной связке ключей, а не в файле.
  bool get isKeyring => this != SecretBackend.file;
}
