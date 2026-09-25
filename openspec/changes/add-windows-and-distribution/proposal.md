## Why

Этап 10 плана, платформенная часть. `AppPaths` знает раскладку Windows, но
каталога `windows/` нет; Linux-сборка не проверена на живой машине; релиз
— `scripts/build_dmg.sh` с ноутбука без подписи, и первый запуск у
любого человека — предупреждение Gatekeeper. Открытому проекту нужны три
системы в CI и в релизе.

## What Changes

- Windows: каталог `windows/`, `AppPaths` на живой машине, `SecretStore`
  через Credential Manager с файлом 0600 как запасным, матрица CI.
- Linux: прогон на живой машине, keyring через libsecret с запасным
  файлом.
- Дистрибуция: workflow релиза по тегу — подписанный и нотаризованный
  `.dmg` и Homebrew cask, AppImage или Flatpak, MSIX; артефакты в GitHub
  Releases; `build_dmg.sh` уходит.
- Проверка обновлений по кнопке через GitHub Releases.

## Capabilities

### New Capabilities
- `distribution`: как приложение попадает к человеку и как узнаёт о новой
  версии.
- `platform-support`: поведение на трёх системах — пути, секреты,
  инструменты.

### Modified Capabilities
- нет.

## Impact

- `windows/`, `lib/core/platform/app_paths.dart`, `secret_store.dart`,
  `.github/workflows/{linux,windows,macos,release}.yml`, `scripts/`.
- Для avtoto и avelacom на macOS ничего не меняется, кроме подписанного
  установщика.
- Зависит от `split-core-and-extensions` (CI-матрица строится на новой
  структуре).
