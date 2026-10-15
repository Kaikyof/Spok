## Purpose

Проверочный стенд Spok: фикстуры трёх устройств спеки (avtoto, avelacom,
оригинальный OpenSpec), смоук без интерфейса и эталонные выводы, по которым
проверяется каждый этап совместимости.

## ADDED Requirements

### Requirement: Фикстура оригинального OpenSpec

Набор тестов SHALL содержать фикстуру проекта после `openspec init`
(версия upstream 1.13.2) в двух формах: собранную в тесте и закоммиченный
образец в `test/fixtures/upstream-sample/`, созданный самим CLI upstream.

#### Scenario: Собранная фикстура воспроизводит формат upstream
- **WHEN** тест строит фикстуру upstream во временном каталоге
- **THEN** в ней есть `openspec/config.yaml`, change с `.openspec.yaml`,
  `proposal.md` без заголовка первого уровня, `specs/<cap>/spec.md`,
  `tasks.md` со списком через `*` и отметкой `[X]`, второй change со
  `skip_specs: true`, архивный change с датой в имени, `openspec/specs/<cap>/spec.md`,
  `.claude/commands/opsx/propose.md` с `name: OPSX: Propose` и
  `.claude/skills/openspec-propose/SKILL.md`

#### Scenario: Закоммиченный образец проверяется в CI без npm
- **WHEN** CI запускает `flutter test`
- **THEN** тесты читают `test/fixtures/upstream-sample/` как спеку и не
  обращаются к сети и к npm

### Requirement: Смоук печатает поля следующих этапов

`tool/smoke.dart` SHALL печатать для каждого change'а стадию работы, для
спеки — источник схемы (`project`, `user`, `builtin`, `none`) и список
активных расширений; до реализации соответствующих этапов поля печатаются
со значением «не реализовано».

#### Scenario: Смоук на клоне upstream
- **WHEN** смоук запущен с `SPEC_PLATFORM_DIR`, указывающим на клон
  Fission-AI/OpenSpec
- **THEN** он завершается без исключения и печатает число change'ей,
  архивных change'ей и спецификаций

### Requirement: Эталон «до» для живых спек

Инструменты проекта SHALL позволять сохранить вывод смоука на avtoto и
avelacom как эталон и сравнить с ним вывод после правок.

#### Scenario: Сравнение с эталоном
- **WHEN** разработчик запускает `tool/compare_smoke.sh avtoto`
- **THEN** скрипт печатает построчную разницу между текущим выводом смоука и
  сохранённым эталоном и завершается ненулевым кодом при расхождении
