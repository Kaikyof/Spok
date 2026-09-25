## Purpose

Поведение приложения на macOS, Linux и Windows: каталоги, хранилище
секретов, поиск инструментов.

## ADDED Requirements

### Requirement: Windows поддерживается наравне

Приложение SHALL собираться и работать на Windows: пути по раскладке
`Roaming`/`Local`, секреты в Credential Manager с файлом 0600 как
запасным, поиск `claude`, `openspec`, `git` с учётом `.cmd` и `.exe`.

#### Scenario: Секрет на Windows
- **WHEN** человек сохраняет `GITLAB_TOKEN` на Windows
- **THEN** значение лежит в Credential Manager, `.env` спеки собран из
  него, файл-хранилище не создан

#### Scenario: Windows без Credential Manager
- **WHEN** запись в Credential Manager невозможна
- **THEN** значение лежит в файле 0600 в каталоге данных с честной
  пометкой на экране, как на Linux без keyring

### Requirement: Три системы в CI

CI SHALL выполнять анализ, тесты и сборку на macOS, Linux и Windows для
каждого PR.

#### Scenario: PR ломает только Windows
- **WHEN** изменение использует путь с `/` вместо `path.join`
- **THEN** прогон на Windows красный, остальные зелёные
