# upstream-sample

Образец проекта на оригинальном OpenSpec для тестов Spok. Сгенерирован
настоящим CLI upstream, а не собран руками, чтобы ловить расхождения с тем,
что мы «помним» о формате.

- CLI: `@fission-ai/openspec@1.13.2`
- Команды: `openspec init --tools claude --no-copilot-cloud`,
  `openspec new change sample-change`, `openspec new change refactor-only`;
  затем дописаны `proposal.md`, `specs/greeting/spec.md`, `design.md`,
  `tasks.md`, `refactor-only` со `skip_specs: true`, архивный change
  `2026-09-10-add-health-check` и `openspec/specs/greeting/spec.md`.
- Пересборка при новой версии upstream: удалить каталог, повторить команды,
  дописать те же файлы, обновить версию здесь.

`.claude/` внутри — часть образца (команды `/opsx:*` и скиллы, как их пишет
upstream), а не настройка Spok.
