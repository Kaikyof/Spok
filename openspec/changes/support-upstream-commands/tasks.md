## 1. Имя вызова и дедуп

- [ ] 1.1 В `_loadSlashCommand` вычислять вызов из пути (`<ns>:<id>` под `commands/<ns>/`), применять `name` только через `looksLikeInvocation`; тесты на три формы: `name: /opsx-apply`, `name: OPSX: Propose`, `.cursor/commands/opsx-apply.md`
- [ ] 1.2 Дедуп скилла с командой по фразе `"opsx <id>"` в описании; `SlashCommand.sources` вместо одного `source`; палитра показывает «команда · скилл»; тесты «пара скилл и команда» и «только скиллы»
- [ ] 1.3 Расширить `_commandDirs` каталогами из таблицы upstream (`.agents/skills`, `.opencode/commands`, `.github/prompts`), читать `.prompt.md` как `.md`, пропускать `.toml`; нормализованный id для дедупа; тест «проект для трёх инструментов» и тест, что число и имена команд avtoto не изменились

## 2. Применимость и роли

- [ ] 2.1 `_argumentHintFromBody`: слоты только из строки вызова в `**Input**`; проза больше не даёт `[change]`; тест «команда создания change'а»
- [ ] 2.2 `SlashCommand.scope` учитывает роль при пустой сигнатуре (`newChange` → general, `apply`/`archive` → change); `CommandRole.archive` в `resolveCommandRoles`; тесты «команда реализации» и «роль архивирования»
- [ ] 2.3 Подсказки аргументов: `opsx:apply` без сигнатуры предлагает id change'ей (по роли), `opsx:propose` — свободный текст; тест в `sessions_suggestions_test.dart`

## 3. Следующие шаги

- [ ] 3.1 `SessionsBloc`: состав следующих шагов по стадии change'а сессии (`done` → архивировать, `planning` → продолжить, `readyToApply` → реализовать) и ролям; локализация подписей; тест «завершённая сессия по сделанному change'у»
- [ ] 3.2 Прогнать палитру на фикстуре upstream (6 команд без дублей), на avtoto и avelacom эталоном — состав не изменился
