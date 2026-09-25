## Purpose

Дерево документов спеки: группы, change'и с артефактами, архив и
спецификации проекта как источник правды.

## ADDED Requirements

### Requirement: Узел спецификаций проекта

Дерево документов SHALL содержать узел «Спецификации» с содержимым
`openspec/specs/` с вложенностью по каталогам; каждый `spec.md` открывается
тем же просмотром, что и артефакты change'а.

#### Scenario: Клон upstream
- **WHEN** открыт клон Fission-AI/OpenSpec
- **THEN** в узле «Спецификации» видны все каталоги `openspec/specs/*`
  с файлом `spec.md`, заголовок — из первого заголовка файла

#### Scenario: Спецификаций нет
- **WHEN** в спеке нет каталога `openspec/specs/` или он пуст
- **THEN** узла «Спецификации» в дереве нет

### Requirement: Дельты change'а в дереве

Для артефакта с маской пути дерево SHALL показывать каждый найденный файл
отдельной строкой с относительным путём и пометкой операции
(ADDED, MODIFIED, REMOVED, RENAMED) по заголовкам файла.

#### Scenario: Change с двумя дельтами
- **WHEN** в change'е есть `specs/auth/spec.md` с `## ADDED Requirements`
  и `specs/ui/spec.md` с `## MODIFIED Requirements`
- **THEN** под change'ем две строки `specs/auth/spec.md · ADDED` и
  `specs/ui/spec.md · MODIFIED`

#### Scenario: Архивный change
- **WHEN** change в архиве и у него нет файлов по маске `specs/**`
- **THEN** строка «объявлен схемой, файлов нет» не показывается
