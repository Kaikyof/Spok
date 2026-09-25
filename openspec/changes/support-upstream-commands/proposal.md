## Why

Этап 3 плана. Команды, которые `openspec init` кладёт в проект, Spok читает
неверно: из frontmatter `name: OPSX: Propose` получается вызов
`/OPSX: Propose`, тогда как Claude Code регистрирует `/opsx:propose` по пути
файла `commands/opsx/propose.md`; команда и скилл об одном и том же
(`propose` и `openspec-propose`) попадают в палитру дважды; без
`argument-hint` разбор прозы раздела `**Input**` относит `propose` к меню
действий change'а, хотя она change создаёт. Роли «архивировать» нет, а для
оригинального OpenSpec это и есть завершение change'а.

## What Changes

- Имя вызова из пути: `commands/<ns>/<id>.md` → `/<ns>:<id>`,
  `commands/<id>.md` → `/<id>`; `name` из frontmatter используется, только
  если похож на вызов (начинается с `/` или без пробелов и заглавных).
- Дедуп скилла с командой по фразе `"opsx <id>"` в описании скилла; скилл
  без пары остаётся командой (`/openspec-propose`).
- Зеркала по таблице upstream: `.agents/skills`, `.opencode/commands`,
  `.gemini/commands` (только `.md`), дедуп по нормализованному id.
- Применимость без `argument-hint`: строка вызова в `**Input**` даёт слоты;
  проза без строки вызова — только палитра; известные роли дают
  применимость (`newChange` — общее меню, `apply`/`archive` — карточка).
- `CommandRole.archive`; следующие шаги после сессии — по стадии; подсказки
  аргументов: `opsx:apply` — id change'ей, `opsx:propose` — свободный текст.

## Capabilities

### New Capabilities
- `command-discovery`: откуда берутся команды спеки, как называется вызов,
  как склеиваются дубли и как определяется применимость и роль.

### Modified Capabilities
- нет.

## Impact

- `lib/data/sources/platform_files_source.dart` (`_loadSlashCommand`,
  `_commandKey`, `_commandDirs`, `_argumentHintFromBody`),
  `lib/domain/entities/slash_command.dart` (`scope`, `resolveCommandRoles`),
  `lib/presentation/bloc/sessions_bloc.dart` (следующие шаги),
  `lib/domain/usecases/suggest_command_arguments.dart`; тесты.
- Для avtoto: `name: /opsx-apply` — вызов тот же; число и имена команд в
  палитре не меняются (тест). Для avelacom — то же.
- Зависит от `resolve-schema-like-upstream` (стадия для следующих шагов —
  от `add-work-stage-and-tracker-port`).
