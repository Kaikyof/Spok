## Context

`_loadSlashCommand` берёт id из `frontmatter['name']`, иначе из имени
файла; `_commandKey` дедупит по имени файла или каталогу скилла;
`_argumentHintFromBody` ищет `**Input**` и по прозе подставляет `[change]`;
`SlashCommand.scope` выводит применимость из слотов; `resolveCommandRoles`
знает роли `apply`, `newChange`, `newGroup`, `handover`. Upstream
(`invocation.ts`) выводит имя вызова из пути файла, префикс — из адаптера
инструмента. См. proposal.md — Why.

## Goals / Non-Goals

Goals: команды проекта после `openspec init` вызываются правильно, без
дублей, с верной применимостью; палитра avtoto не меняется.

Non-Goals: другие агентные CLI и их формы вызова (`$openspec-propose` у
Codex) — change `add-agent-cli-port`.

## Decisions

- **Имя вызова — из пути, `name` — только если это вызов.** Правило
  `looksLikeInvocation(name)`: начинается с `/`, или не содержит пробелов и
  заглавных. `OPSX: Propose` не проходит, `/opsx-apply` проходит,
  `openspec-propose` проходит. Для файла под `commands/<ns>/<id>.md` вызов
  `<ns>:<id>` — так Claude Code регистрирует вложенные каталоги; `<ns>`
  берётся из первого подкаталога после `commands/`.
- **Дедуп скилла с командой — по фразе из описания.** Upstream пишет в
  каждый скилл «Also use when the user says "openspec propose" or "opsx
  propose"». Регулярка `"opsx ([a-z-]+)"` в описании скилла даёт id
  команды; если команда с таким id найдена — скилл к ней приклеивается
  (в палитре одна строка, источник «команда + скилл»), иначе скилл —
  самостоятельная команда. Никакой зашитой таблицы имён.
- **Применимость без `argument-hint`.** Порядок: `argument-hint` →
  строка вызова в `**Input**` (`/opsx:apply <change>`) → роль команды →
  `paletteOnly`. Проза больше не даёт `[change]`: это давало ложную
  применимость `propose`. Роль `newChange` → `general`, `apply` и
  `archive` → `change` — карточка получает «Реализовать» и «Архивировать»
  без сигнатуры в файле.
- **`CommandRole.archive`** с ключевыми словами `archive`; `sync`
  и `verify` — без роли, остаются в меню «Ещё» по применимости.
- **Зеркала** — только те каталоги из таблицы upstream, где лежат `.md`:
  `.agents/skills`, `.opencode/commands`, `.cursor/commands` (уже),
  `.gemini/commands` (там `.toml` — пропускаются), `.github/prompts`
  (`.prompt.md` — читаем как `.md`). Дедуп по нормализованному id:
  `opsx-apply`, `opsx:apply`, `apply` под `opsx/` — одно.
- **Следующие шаги после сессии — по стадии change'а**, если он известен
  сессии: `done` → архивировать, `planning` → продолжить (`continue`/`update`),
  `readyToApply` → реализовать. Состав кнопок — из ролей.

## Risks / Trade-offs

- [Скилл с описанием без фразы «opsx …» останется дублем] → в палитре это
  видно как две строки с разным источником; допустимо.
- [Правило `looksLikeInvocation` ошибётся на экзотическом имени] → тест на
  три реальных формы: avtoto, upstream-команда, upstream-скилл.

## Migration Plan

Только код. Нет данных на диске.
