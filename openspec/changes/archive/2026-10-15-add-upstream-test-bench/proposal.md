## Why

План `docs/openspec-upstream-plan.md` (этап 0) начинается со стенда: без
фикстуры оригинального OpenSpec и эталонных смоуков на avtoto и avelacom
все следующие change'и проверяются вслепую, а регрессию на живых спеках
команды заметит не тест, а человек. Сегодня тесты строят спеку в стиле
avelacom (`test/spec_discovery_test.dart`), фикстуры upstream нет, а смоук
`tool/smoke.dart` не печатает ни стадию, ни источник схемы.

## What Changes

- Фикстура «upstream» в тестах: проект после `openspec init` — `config.yaml`
  без схемы или со `schema: spec-driven`, change с `.openspec.yaml`,
  `proposal.md` без H1, `specs/<cap>/spec.md`, `tasks.md` с `*`-маркерами и
  `[X]`, второй change со `skip_specs: true`, архив с датой,
  `openspec/specs/<cap>/spec.md`, `.claude/commands/opsx/*.md` с
  `name: OPSX: Propose`, `.claude/skills/openspec-propose/SKILL.md`.
- Образец, сгенерированный настоящим `openspec init` + `openspec new change`,
  закоммичен в `test/fixtures/upstream-sample/` — CI проверяет его без npm.
- Смоук печатает стадию работы, источник схемы и список активных расширений
  (до появления реестра — заглушкой «все»).
- Третий проверочный сценарий в README: `SPEC_PLATFORM_DIR=~/OpenSpec dart run
  tool/smoke.dart`; ожидаемые числа по клону upstream — в тесте.
- Эталонный вывод смоуков на avtoto и avelacom сохраняется до любых правок
  и сравнивается после каждого этапа.

## Capabilities

### New Capabilities
- `test-bench`: проверочный стенд из трёх спек — какие фикстуры существуют,
  что печатает смоук и что считается эталоном «до».

### Modified Capabilities
- нет.

## Impact

- `test/`: новая фикстура и тест ожидаемых чисел; `test/fixtures/upstream-sample/`.
- `tool/smoke.dart`: три новые строки вывода.
- `README.md`: третий сценарий проверки.
- Код приложения не меняется. Зависимостей нет; все остальные change'и
  плана зависят от этого.
