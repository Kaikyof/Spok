## Purpose

Как Spok находит схему артефактов для спеки и для каждого change'а, когда
схема лежит в проекте, у пользователя или только в пакете оригинального
OpenSpec.

## ADDED Requirements

### Requirement: Цепочка разрешения схемы как у upstream

Для каждого change'а приложение SHALL определять имя схемы в порядке:
`schema` из `.openspec.yaml` change'а, затем `schema` из
`openspec/config.yaml`, затем `spec-driven`.

#### Scenario: Схема из метаданных change'а
- **WHEN** у change'а есть `.openspec.yaml` со `schema: rapid`, а в
  `config.yaml` указана `spec-driven`
- **THEN** артефакты и файл задач этого change'а берутся из схемы `rapid`

#### Scenario: Конфига нет
- **WHEN** в спеке нет `openspec/config.yaml` и у change'а нет `.openspec.yaml`
- **THEN** используется схема `spec-driven`

### Requirement: Источники схемы

Приложение SHALL искать файл схемы по имени в порядке: `openspec/schemas/<name>/schema.yaml`
проекта, `~/.local/share/openspec/schemas/<name>/schema.yaml`, встроенная копия
в ресурсах приложения; и SHALL сообщать источник (`project`, `user`,
`builtin`).

#### Scenario: Проект после openspec init
- **WHEN** открыт проект без `openspec/schemas/` со схемой `spec-driven`
- **THEN** используется встроенная копия, а экран распознавания показывает
  «spec-driven · встроенная»

#### Scenario: Схема команды в проекте
- **WHEN** открыт avtoto со `schema: spec-driven-redmine` и файлом в
  `openspec/schemas/spec-driven-redmine/`
- **THEN** используется файл проекта, источник — `project`, стеки и имена
  файлов те же, что до этого change'а

#### Scenario: Схема не найдена нигде
- **WHEN** `config.yaml` называет схему, которой нет ни в проекте, ни у
  пользователя, ни во встроенных
- **THEN** приложение не падает, схема считается пустой, а экран
  распознавания показывает «схема `<name>` не найдена» с местами поиска
