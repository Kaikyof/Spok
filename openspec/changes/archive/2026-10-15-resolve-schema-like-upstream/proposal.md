## Why

Этап 1 плана `docs/openspec-upstream-plan.md`. На проекте после
`openspec init` Spok не находит схему (она лежит в npm-пакете upstream, а не
в `openspec/schemas/`), не находит файл задач (`tasks.md` вместо
`tasks-<stack>`), не создаёт единицу работы без трекера и теряет чекбоксы
не в формате `- [ ] N.N`. В итоге 31 change показывается без задач, без
артефактов и без стадии (раздел 2 плана, строки «Схема», «Стеки», «Файлы
задач», «Единица работы», «Чекбоксы», «Артефакты карточки»).

## What Changes

- Встроенная копия схемы `spec-driven` upstream в `assets/openspec/schemas/`
  с версией пакета в комментарии.
- Разрешение схемы по цепочке upstream: `.openspec.yaml` change'а →
  `openspec/config.yaml` → `spec-driven`; источники — проект,
  `~/.local/share/openspec/schemas/`, встроенная копия. Схема хранится по
  change'у.
- Файл задач — из `apply.tracks` схемы; change без стеков, но с `tracks`,
  получает один «стек работы» независимо от трекера.
- Парсер чекбоксов по правилам upstream (`src/utils/task-progress.ts`):
  любой маркер списка, отступ, `[x]`/`[X]` — сделано, любой другой маркер —
  не сделано, ссылки не считаются, номер необязателен.
- `.openspec.yaml` читается в change (`schema`, `created`, `goal`,
  `skip_specs`); артефакты-маски (`specs/**/*.md`) считаются существующими
  при наличии хотя бы одного файла; `skip_specs` даёт состояние «пропущен».
- Заголовок change'а: H1 → `# Proposal: …` без префикса → id.
- `branchTemplate` становится необязательным: нет `checkout -B … <change…>`
  в `apply.instruction` — ветка не выдумывается.

## Capabilities

### New Capabilities
- `schema-resolution`: откуда берётся схема change'а и что происходит, когда
  её нет в проекте.
- `task-tracking`: как находится файл задач, как считаются чекбоксы, что
  такое единица работы без стеков.
- `change-artifacts`: метаданные `.openspec.yaml`, артефакты-маски,
  `skip_specs`, заголовок и ветка change'а.

### Modified Capabilities
- нет.

## Impact

- `lib/domain/entities/spec_schema.dart`, `change_unit.dart`, новый
  `schema_resolver.dart`; `lib/data/sources/platform_files_source.dart`
  (`_readSchema`, `_loadChange`, `_taskFilesOf`, `_loadTasksFile`,
  `_proposalTitle`, `_branchTemplate`); `lib/presentation/screens/change_screen.dart`
  (`_artifacts`); `pubspec.yaml` (assets); тесты.
- Для avtoto и avelacom: схема в проекте найдена как раньше, стеки те же,
  ветка та же — проверяется эталоном «до».
- Зависит от `add-upstream-test-bench`.
