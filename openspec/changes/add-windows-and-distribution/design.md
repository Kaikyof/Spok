## Context

`AppPaths` берёт систему и окружение полями, раскладка трёх систем
проверяется тестом на одной; `SecretStore` — Keychain, libsecret, файл
0600; CI — только Linux; сборка macOS — скриптом. См. proposal.md.

## Goals / Non-Goals

Goals: три системы собираются в CI и выходят релизом по тегу; секреты —
в системном хранилище каждой системы. Non-Goals: магазины приложений,
автообновление в фоне.

## Decisions

- **Windows**: `flutter create --platforms=windows .`; `SecretStore` —
  Credential Manager через `win32` (`CredWrite`/`CredRead`), запасной
  файл 0600 как на Linux; `ExecutableLocator` учитывает `.cmd`/`.exe`
  для `claude`, `openspec`, `git`.
- **CI-матрица**: `ubuntu`, `macos`, `windows` — `analyze`, `test`,
  сборка; Linux-прогон остаётся местом проверки запасного хранилища.
- **Релиз по тегу `v*`**: macOS — `codesign` + `notarytool` (секреты
  Developer ID в GitHub Secrets), `.dmg`, обновление cask в
  `homebrew-spok`; Linux — AppImage (`appimagetool`), Flatpak — второй
  очередью; Windows — MSIX (`msix` пакет) с самоподписью для начала;
  артефакты — в GitHub Releases, `CHANGELOG` — в описание релиза.
- **Проверка обновлений** — по кнопке в «О приложении»: `GET
  /repos/{o}/{r}/releases/latest`, сравнение с версией, ссылка на
  релиз. Никаких фоновых запросов.

## Risks / Trade-offs

- [Подпись требует аккаунта Apple Developer] → без него — `.dmg` без
  нотаризации с инструкцией; cask всё равно ставит.
- [MSIX-самоподпись даёт предупреждение SmartScreen] → честно описать в
  README; подпись сертификатом — позже.
- [Живые Windows и Linux для проверки] → выделить машины; CI не заменяет
  запуск с окном.

## Migration Plan

`build_dmg.sh` удаляется после первого успешного релиза из workflow.
