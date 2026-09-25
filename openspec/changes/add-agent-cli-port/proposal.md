## Why

Этап 10 плана, первая и самая важная функциональная часть. Сессии прибиты
к `claude -p --output-format stream-json` (`agent_cli_source.dart:23`).
Upstream генерирует команды для 30+ инструментов, и у пользователя
оригинального OpenSpec с той же вероятностью стоит Codex, Gemini CLI,
OpenCode или Cursor. Без порта агентного CLI экран «Сессии» для половины
аудитории пуст.

## What Changes

- Порт `AgentCli` с адаптерами: `claude -p` (как сейчас), `codex exec`,
  `gemini` с JSON-выводом, `opencode run`; события сессии приводятся к
  общему виду.
- Определение, для каких агентов инициализирован проект, по каталогам из
  таблицы upstream (`.claude/`, `.agents/`, `.gemini/`, `.opencode/`,
  `.cursor/`); форма вызова команды по агенту (`/opsx:propose` у Claude,
  `$openspec-propose` у Codex, `/opsx-propose` у Cursor).
- «Скопировать команду» там, где headless-режима нет.
- Выбор агента по проекту рядом с моделью и effort; список моделей — по
  агенту.

## Capabilities

### New Capabilities
- `agent-cli`: запуск агентной сессии через установленный инструмент,
  выбор инструмента, форма вызова команд.

### Modified Capabilities
- нет.

## Impact

- `lib/domain/repositories/agent_cli.dart`, `lib/data/sources/agent_cli_source.dart`
  → адаптеры в `packages/spok_core/.../agents/`, `sessions_bloc.dart`,
  `sessions_screen.dart`, палитра (форма вызова), настройки сессии.
- Для avtoto и avelacom: Claude Code остаётся по умолчанию, поведение то
  же; появляется селектор агента.
- Зависит от `support-upstream-commands`; от `split-core-and-extensions` —
  только расположением файлов.
