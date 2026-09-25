# Spok и оригинальный OpenSpec — оценка и план работ

**Дата:** 25.09.2026 · **Статус:** оценка, к обсуждению
**Ветка Spok:** `develop` (49b2159) · **Upstream:** [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)
v1.13.2, коммит db23097 от 23.09.2026
**Связанные документы:** `platform-console-master.md` (части 2, 3, 8),
`feature-plan.md` (§1, §2, §10), `finding-recmeet-spec.md`

---

## Короткая версия

**Сделать можно, и переписывать приложение не нужно.** Оригинальный OpenSpec
для Spok — не третий «сорт» спеки, а вырожденный случай уже поддерживаемой
модели: схема есть, но лежит не в проекте; стеков нет; трекера нет;
группировки нет; `workspace.yaml` нет. Почти всё это Spok уже умеет
показывать как «фича выключена, вот чего не хватает». Ломается ровно то,
что до сих пор считалось обязательным: схема в `openspec/schemas/`, задачи
по стекам `tasks-<stack>`, статус из трекера как единственный «статус».

Работа сводится к четырём вещам:

1. **Схема** — брать встроенную `spec-driven` из пакета upstream (у нас —
   копия в assets), разрешать её по цепочке upstream (change → конфиг →
   по умолчанию), читать `apply.tracks`.
2. **Единица работы без стеков и без трекера** — change с одним файлом
   `tasks.md` и парсером чекбоксов, совместимым с upstream.
3. **Нейтральный статус** — стадия работы из файлов (что из артефактов
   написано, сколько задач закрыто, в архиве ли), поверх которой трекер
   идёт необязательным слоем.
4. **Команды upstream** — `.claude/commands/opsx/<id>.md` и
   `.claude/skills/openspec-*/SKILL.md`: имя вызова из пути, дедуп
   команды и скилла, применимость без `argument-hint`.

Объём: четыре этапа S–M плюс необязательный пятый (интеграция с CLI
`openspec`). Ни один этап не требует новых экранов — правки в слое данных,
доменных сущностях и текстах.

### Что не удалось проверить

- **Спеки avtoto и avelacom не открывались.** Хост
  `gitlab.core.pl.webant.ru` запрещён сетевой политикой окружения (403 на
  CONNECT, ssh отсутствует). Всё об этих спеках взято из `docs/` Spok и
  тестовых фикстур. Чтобы прогнать план на живых спеках, хост нужно добавить
  в разрешённые домены окружения.
- **Смоук не запускался.** В окружении нет Dart/Flutter. Список поломок
  ниже получен чтением кода, а не прогоном — каждая строка указывает на
  место в коде, которое её даёт.
- Третьей проверочной спекой служит **сам репозиторий OpenSpec**: у него
  живой `openspec/` с 31 change'ем, архивом и спецификациями, но без
  `.claude/` (команды upstream генерирует `openspec init` в проекте
  пользователя, в своём репозитории они не закоммичены).

---

## 1. Как устроен оригинальный OpenSpec

В терминах, которыми Spok уже пользуется. Колонка «recmeet» — из
`finding-recmeet-spec.md`, для полноты картины.

| | avtoto | avelacom | recmeet | **upstream OpenSpec** |
|---|---|---|---|---|
| Где схема | `openspec/schemas/<name>/` | там же | там же | **в npm-пакете** (`schemas/spec-driven/`), в проекте только если форкнута; ещё `~/.local/share/openspec/schemas/` |
| Имя схемы | `config.yaml → schema` | там же | там же | цепочка: `--schema` → `.openspec.yaml` change'а → `config.yaml` → **`spec-driven` по умолчанию**; `config.yaml` может отсутствовать |
| Артефакты | proposal, specs, design, tasks-ios, tasks-android … | proposal, specs, tasks-backend, test_case … | proposal, system_design, `<stack>/tasks.md` | `proposal` → `specs/**/*.md` → `design` → **`tasks` (один файл)** |
| Кто отслеживает задачи | артефакты `tasks-<stack>` | там же | там же | **`apply.tracks: tasks.md`** в схеме |
| Формат задачи | `- [ ] 1.1 текст` | там же | там же | любой маркер списка (`-`, `*`, `+`, `1.`), вложенность, `[x]`/`[X]` — сделано, любой другой маркер (`[~]`, `[]`) — **не сделано**, номер необязателен |
| Метаданные change'а | `redmine.yaml` (v3/v4) | `redmine.yaml` v3 | v2 у группы, v4 у change'а | **`.openspec.yaml`**: `schema`, `created`, `goal`, `skip_specs`, `retire_capabilities`, `affected_areas`, `initiative` |
| Трекер | Redmine, `openspec/redmine.yaml` | Redmine | Redmine | **нет** — статус выводится из файлов: `no-tasks · in-progress · complete` (`openspec list`), готовность артефактов (`openspec status`) |
| Группировка | каталог спринта | мастер-спека файлом | каталог-группа в `changes/` | **нет**; вложенные каталоги в `changes/` upstream **явно не поддерживает** (диагностика `nested-change.ts`, issue #1846) |
| Ветка change'а | из `apply.instruction` | там же | там же | **не объявлена** — upstream веток не диктует |
| Архив | `changes/archive/YYYY-MM-DD-<id>/` | там же | там же | **то же самое** |
| Спецификации | `openspec/specs/**` есть, Spok не показывает | — | — | `openspec/specs/<capability>/spec.md` — **источник правды**, дельты в `changes/<id>/specs/**` (ADDED/MODIFIED/REMOVED) |
| Команды агента | `.claude/commands/opsx-*.md`, `name: /opsx-apply` | + `package.json`, `Makefile` | — | `.claude/commands/opsx/<id>.md` (`name: OPSX: Propose`, вызов **`/opsx:propose` из пути**) и `.claude/skills/openspec-<skill>/SKILL.md` (`name: openspec-propose`), без `argument-hint`; зеркала для 30+ инструментов |
| Набор команд | opsx-apply, submit, reviewer, sprint, doc … | opsx:new, propose … | — | core: `explore · propose · apply · update · sync · archive`; expanded: `new · continue · ff · verify · bulk-archive · onboard` |
| Окружение | `.env.example`, `workspace.yaml`, сервисы | там же | там же | **ничего**: `openspec/` лежит внутри репозитория кода, ключей и сервисов нет |
| CLI | — | — | — | `openspec list/status/validate/show/schemas … --json` |
| Хранилища (beta) | — | — | — | `config.yaml → store: <id>` — change'и живут в другом репозитории, зарегистрированном на машине |

Главный вывод: **новых сущностей нет**. Всё, что есть у upstream, в модели
Spok либо уже описано (схема, артефакты, архив, команды), либо является
«отсутствием» того, что Spok уже умеет объяснять (трекер, группы, стеки,
сервисы). Новое только одно — понятие **стадии работы без трекера**.

---

## 2. Что сломается сегодня на проекте после `openspec init`

По коду `develop`. Тяжесть: 🔴 не работает вовсе · 🟠 показывает неверное ·
🟡 шум, работает с оговорками · ✅ работает.

| Область | Что произойдёт | Где в коде | |
|---|---|---|---|
| Корень | распознаётся: достаточно `openspec/` | `platform_files_source.dart:37-39` | ✅ |
| Схема | пустая: ищется только `openspec/schemas/<name>/schema.yaml`, а у upstream схема в пакете; без `config.yaml` — тем более | `platform_files_source.dart:102-108` | 🔴 |
| Схема из `.openspec.yaml` | не читается: у change'а может быть своя схема, Spok знает только уровень конфига | `platform_files_source.dart:103` | 🟠 |
| Стеки | пусто — стек = артефакт `tasks-<x>`, у upstream артефакт называется `tasks` | `spec_schema.dart:46-47` | 🔴 |
| Файлы задач | не находятся: со схемой берутся `tasks-<stack>`, без схемы — маска `tasks[_-]*.md`; `tasks.md` не подходит ни туда, ни туда | `platform_files_source.dart:492-507` | 🔴 |
| Единица работы | change без стеков получает «стек работы» только при `group.issue_id` из `redmine.yaml` — без трекера `stackStates` пуст, и change показывается без задач, статуса и следующего шага | `platform_files_source.dart:470` | 🔴 |
| Чекбоксы | регулярка требует `- [ ] N.N`: `*`, `1.`, вложенные и ненумерованные строки теряются, `[X]` не считается сделанным | `platform_files_source.dart:567` | 🟠 |
| Заголовок change'а | шаблон upstream начинается с `## Why`, H1 нет → заголовком становится id | `platform_files_source.dart:581-588` | 🟡 |
| Ветка change'а | `features/<change>` придумывается за спеку: в `apply.instruction` upstream ветки нет | `platform_files_source.dart:134-139` | 🟠 |
| Статус в таблице | «нет доступа» у каждого change'а, полоса «нет ключа REDMINE_API_KEY» над таблицей — хотя трекера у процесса нет по замыслу | `platform_repository_impl.dart:627-634`, `group_screen.dart:67-68` | 🟠 |
| Цвета статусов | палитра по русским именам статусов Redmine | `app_colors.dart:40-50` | 🟡 |
| Расхождения | пусто — семантики нет, правил нет | `find_divergences.dart:16` | ✅ честно |
| Передача, MR, сборки, чат | выключены с чеклистом требований | `platform_repository_impl.dart:479-612` | ✅ |
| «Что распознано» | «схема не распознана», «статусы не распознаны» → кнопка «Указать вручную», хотя понять тут нечего: это не пробел, а устройство спеки | `platform_repository_impl.dart:420-475` | 🟠 |
| Окружение · ключи | `.env.example` нет → пустой список без объяснения | `platform_repository_impl.dart:665-671` | 🟡 |
| Окружение · системы | три предупреждения «не настроено» для Redmine, GitLab, Mattermost — список зашит | `platform_repository_impl.dart:727-737` | 🟡 |
| Окружение · репозитории | пусто, `workspace.yaml` нет | — | ✅ |
| `.env` в чужой репозиторий | `EnvMaterializer` пишет файл только когда есть что подставить из хранилища; при пустом `.env.example` ничего не пишет | `env_materializer.dart:52-74` | ✅ |
| Артефакты карточки | без схемы — константы `proposal.md`/`design.md`; `specs/**/*.md` не показывается никогда (`isSingleFile`), `skip_specs` не учитывается | `change_screen.dart:193-201`, `spec_schema.dart:24-25` | 🟠 |
| Документы | `openspec/specs/**` (источник правды) не показывается; дельты `changes/<id>/specs/**` тоже; архив с датой — работает | `platform_files_source.dart:356-438` | 🟠 |
| Команды · имя | `name: OPSX: Propose` из frontmatter становится id → в сессию уйдёт `/OPSX: Propose`, а Claude Code знает `/opsx:propose` (имя от пути `commands/opsx/propose.md`) | `platform_files_source.dart:900-904` | 🔴 |
| Команды · дубли | команда `propose` и скилл `openspec-propose` — разные ключи дедупа, в палитре обе | `platform_files_source.dart:786-791` | 🟡 |
| Команды · применимость | без `argument-hint` разбирается раздел `**Input**`; у `propose` там «change name» → команда попадает в меню действий карточки change'а, хотя она change создаёт | `platform_files_source.dart:919-941`, `slash_command.dart:64-78` | 🟠 |
| Роли | `apply` → `opsx:apply` ✓, `newChange` → `propose` ✓, `handover` — нет ✓ (передача выключена честно); роли «архивировать» нет, а для upstream это и есть завершение change'а | `slash_command.dart:87-119` | 🟡 |
| Сессии | `claude -p` в каталоге проекта — работает, если id команды правильный | `agent_cli_source.dart` | ✅ |
| Следующий шаг | плашка ищет «самую частую незакрытую задачу по стекам» — при нуле стеков молчит | `group_screen.dart:692-727` | 🟠 |

Итого: приложение **не упадёт** (в отличие от случая RecMeet), но покажет
31 change без задач, без статуса и с полосой про ключ Redmine, а запуск
команды из палитры уйдёт с неверным именем.

---

## 3. Целевое поведение

Критерий готовности — сценарий на репозитории после `openspec init`
(core-профиль, Claude Code):

1. Подключение по пути или URL → шаг «Что распознано»: *схема `spec-driven`
   (встроенная upstream), трекер — не используется, группировка — нет, стеки —
   нет, команды — 6, сервисы — нет*. «Не распознано» — пусто.
2. Группа «Change'и» (плоский список): у каждого change'а **стадия** и
   прогресс задач: «планирование · следующий: design», «готов к реализации»,
   «в работе 3/7», «сделано 7/7 — архивировать», «архив 12.09».
3. Карточка change'а: спека, артефакты «3 из 4» с учётом `specs/**` и
   `skip_specs`, чеклист задач, кнопка «Реализовать» (`/opsx:apply`), меню
   «Ещё» (`/opsx:update`, `/opsx:verify`, `/opsx:archive`), блок «Код»
   выключен с причиной «спека не объявляет ветки и хостинг».
4. Документы: узел «Спецификации» (`openspec/specs/**`), у change'а —
   `proposal.md · specs/… · design.md · tasks.md`, архив с датой.
5. Сессии: палитра без дублей, `/opsx:propose <описание>` и
   `/opsx:apply [change]` подставляются в строку и уходят в `claude -p`;
   после завершения — «следующие шаги» по стадии.
6. Окружение: «спека не объявляет ключей и сервисов» вместо трёх
   предупреждений; репозиторий спеки и его ветка показаны.
7. avtoto, avelacom и фикстуры тестов работают как прежде — их сценарии
   в `test/` и смоук не меняют поведения.

### Проектные решения

**Схема разрешается как у upstream.** Цепочка `.openspec.yaml` change'а →
`config.yaml` → `spec-driven`. Источники по порядку: проект
(`openspec/schemas/<name>/`), пользователь (`~/.local/share/openspec/schemas/`),
встроенная копия в приложении (`assets/openspec/schemas/spec-driven/schema.yaml`,
с пометкой версии upstream). Схема хранится **по change'у**, а не одна на
спеку; «схема спеки» на экране распознавания — та, что по умолчанию, плюс
отметка «у N change'ей своя».

**Единица работы — файл из `apply.tracks`.** Стеки по-прежнему — артефакты
`tasks-<stack>`. Если таких нет, а схема объявляет `apply.tracks`
(или артефакт `tasks`), у change'а один «стек работы» с этим файлом —
независимо от того, есть ли трекер. Условие `groupIssueId != null` уходит.
Это закрывает «WorkUnit» из части 3 сводного документа без нового типа.

**Парсер задач совместим с upstream.** Та же логика, что в
`src/utils/task-progress.ts`: любой маркер списка, отступ, `[x]`/`[X]` —
сделано, прочее — нет, ссылки `- [x](…)` не задачи. Номер задачи
необязателен — без него берётся порядковый.

**Стадия работы — из файлов, трекер — поверх.** Новая сущность
`WorkStage`: `planning(next)` · `readyToApply` · `inProgress` · `done` ·
`archived`. Считается по существованию артефактов в порядке `requires`
(готовность — как в `openspec status`: артефакт «ready», когда все его
`requires` есть), по чекбоксам файла `tracks` и по архиву. Стадия есть у
**любой** спеки, включая avtoto: там она становится «фактом», который
сравнивается с ярлыком трекера, — это укладывается в принцип «факт рядом
с ярлыком». Цвет точки — по стадии; имя статуса трекера при его наличии
показывается рядом, как сейчас.

**Трекер — фича с гейтом, а не данность.** `SpecFeature.tracker`: требования
`spec` (объявлен: `openspec/redmine.yaml` или `REDMINE_*` в `.env.example`),
`personal` (ключ заполнен), `runtime` (отвечает). Полоса над таблицей и
подпись «из файла» показываются только при объявленном трекере.
`RedmineProblem` получает значение `notDeclared`. Расхождения и передача
как требовали семантику, так и требуют.

**Команды: имя из пути, `name` — только если это вызов.** Для файла в
`commands/<ns>/<id>.md` вызов — `/<ns>:<id>`; для `commands/<id>.md` —
`/<id>`. `name` из frontmatter используется, когда выглядит как вызов
(начинается с `/` или без пробелов и заглавных) — это сохраняет avtoto
(`name: /opsx-apply`). Скилл склеивается с командой, если его описание
называет её («Also use when the user says "opsx propose"» — фраза, которую
upstream пишет в каждый скилл), иначе остаётся отдельной командой
(`/openspec-propose` — тоже валидный вызов в Claude Code). Применимость без
`argument-hint`: строка вызова в `**Input**` даёт слоты, как сейчас; проза
без строки вызова — только `paletteOnly`, а не угадывание по слову «change».
Роли: добавляется `archive` (нужна стадии «сделано» и следующим шагам) —
её нет ни у avtoto, ни у avelacom, и там кнопки не будет.

**Ветка не выдумывается.** `branchTemplate` становится nullable; нет
`checkout -B … <change…>` в `apply.instruction` — ветки нет, дерево документов
её не показывает, блок «Код» объясняет: «спека не объявляет имя ветки».

**CLI `openspec` — необязательное обогащение.** Принцип Spok — читать файлы,
и для upstream этого достаточно. CLI, если найден `ExecutableLocator`'ом,
даёт то, чего в файлах нет: результат `validate`, разрешение схемы через
`schema which --json` (вместо копии в assets), состав артефактов через
`status --json` с правилами `skip_specs`. Отдельная фича `validation` с
гейтом `runtime`; её отсутствие ничего не ломает.

**Хранилища (`store:`) и вложенные change'и — не поддерживаем, объясняем.**
Указатель `store:` в `config.yaml` распознаётся и показывается: «change'и
этой спеки живут в хранилище `<id>` — откройте его каталог». Вложенные
каталоги в `changes/` upstream не поддерживает сам; для RecMeet это довод
за вариант A из `finding-recmeet-spec.md` как обязательный, а B — как
расширение Spok, а не совместимость.

---

## 4. План работ

Объём: S — до дня, M — 2–3 дня, L — неделя. Этапы 1–4 идут по порядку;
5 и 6 — независимы от них после первого.

### Этап 0. Стенд · S

Без него остальное проверяется вслепую.

- [ ] фикстура «upstream» в тестах рядом с `_buildSpec()` из
      `spec_discovery_test.dart`: `openspec/config.yaml` без схемы или со
      `schema: spec-driven`, change с `.openspec.yaml`, `proposal.md`,
      `specs/auth/spec.md`, `tasks.md` с `*`-маркерами и `[X]`, второй change
      со `skip_specs: true`, архив с датой, `openspec/specs/auth/spec.md`,
      `.claude/commands/opsx/{propose,apply,archive}.md` с
      `name: OPSX: Propose` и `.claude/skills/openspec-propose/SKILL.md`
- [ ] образец, сгенерированный настоящим `openspec init` + `new change`,
      закоммичен в `test/fixtures/upstream-sample/` — CI прогоняет его без npm
- [ ] смоук на клоне upstream: `SPEC_PLATFORM_DIR=~/OpenSpec dart run
      tool/smoke.dart` в README как третий проверочный сценарий; ожидаемые
      числа (31 change, архив, спецификации) — в тесте, а не в голове
- [ ] `tool/smoke.dart` печатает стадию и источник схемы

### Этап 1. Схема и задачи · M

Слой данных; экраны почти не трогаем.

- [ ] `assets/openspec/schemas/spec-driven/schema.yaml` — копия из upstream
      с версией пакета в комментарии; `pubspec.yaml → flutter.assets`
- [ ] `SchemaResolver`: цепочка change → конфиг → умолчание; источники
      проект → пользователь → встроенная; результат несёт `source`
      (`project · user · builtin`) для экрана распознавания
- [ ] `SpecSchema`: `tracksFile` из `apply.tracks`; `branchTemplate`
      nullable; `stacks` без изменений
- [ ] `PlatformFilesSource._loadChange`: схема по change'у; «стек работы» —
      из `tracksFile`, без условия на трекер; чтение `.openspec.yaml`
      (`schema`, `created`, `goal`, `skip_specs`) в `ChangeUnit`
- [ ] парсер задач по правилам upstream; тесты на `*`, `1.`, отступ, `[X]`,
      `[~]`, `[]`, `- [x](link)`, CRLF
- [ ] заголовок: H1 → `# Proposal: …` без префикса → id
- [ ] артефакты-маски (`specs/**/*.md`): существование = хотя бы один файл;
      `skip_specs` → состояние «пропущен по `.openspec.yaml`»; карточка
      считает «N из M» с их учётом; без схемы — не константы, а встроенная
      `spec-driven`
- [ ] `_argumentValues`, `loadDocTree`, `_changeDocs` — через схему change'а
- [ ] **Приёмка:** на фикстуре и на клоне upstream change'и показывают
      задачи N/M и артефакты; avtoto/avelacom-тесты зелёные; смоук не падает

### Этап 2. Стадия работы и трекер как фича · M

- [ ] `WorkStage` в `domain/entities`, usecase `AssessWorkStage` (по
      артефактам в порядке `requires`, чекбоксам и архиву); тесты на все
      пять стадий и на `skip_specs`
- [ ] `StackState`: `stage` рядом с `cachedStatus`/`liveStatus`;
      `redmineStatus` переименовывается в `trackerStatus` (ярлык), стадия —
      факт
- [ ] `SpecFeature.tracker` и гейт (`spec · personal · runtime`);
      `RedmineProblem.notDeclared`; `_fetchStatuses` не ходит в трекер, если
      он не объявлен
- [ ] экран группы: колонка стадии с прогрессом, полоса трекера только при
      объявленном трекере, плашка «следующий шаг» по стадии (создать
      `<артефакт>` · реализовать · архивировать — команда из ролей), при
      стеках — прежняя логика по задачам
- [ ] карточка change'а: стадия в шапке; `AppColors` — по стадии, палитра
      по именам Redmine остаётся для ярлыка трекера
- [ ] «Что распознано»: часть `schema` со значением и источником
      («spec-driven · встроенная upstream»), новая часть `tracker` со
      значением «не используется» как распознанным; «Указать вручную» не
      предлагается там, где понимать нечего
- [ ] окружение: список систем — из ключей `.env.example`
      (`REDMINE_URL` → Redmine, `GITLAB_URL` → GitLab, `MATTERMOST_URL` →
      Mattermost), нет ключей — строка «спека не объявляет внешних систем»;
      то же для ключей и сервисов
- [ ] локализация: стадии, причины «спека не объявляет …», подпись «факт из
      файлов» вместо «нет доступа» там, где трекера нет
- [ ] `find_divergences`: без изменений; проверить, что стадия не
      порождает псевдостатусов (принцип «только реальные статусы»)
- [ ] **Приёмка:** upstream-проект без единого упоминания Redmine на
      экранах; avtoto показывает стадию рядом со статусом и те же
      расхождения, что раньше

### Этап 3. Команды upstream · M

- [ ] вызов из пути: `commands/<ns>/<id>.md` → `<ns>:<id>`; `name` — только
      если похож на вызов; тесты на avtoto-стиль (`name: /opsx-apply`),
      upstream-стиль (`name: OPSX: Propose`) и `.cursor/commands/opsx-apply.md`
- [ ] дедуп скилла с командой по фразе `"opsx <id>"` в описании скилла;
      источник в палитре: «команда» и «скилл» различимы
- [ ] зеркала: `.agents/skills`, `.opencode/commands`, `.gemini/commands`
      (только `.md`; `.toml` — не читаем) — по таблице upstream, дедуп по
      нормализованному id
- [ ] применимость без `argument-hint`: строка вызова в `**Input**` —
      слоты; проза — `paletteOnly`; известные роли дают scope
      (`newChange` → general, `apply`/`archive` → change)
- [ ] `CommandRole.archive`; следующие шаги после сессии — по стадии:
      `done` → архивировать, `planning` → продолжить
      (`opsx:continue`/`opsx:update`), `readyToApply` → реализовать
- [ ] подсказки аргументов: `opsx:apply` — id change'ей; `opsx:propose` —
      свободный текст (слот `[change|описание]` уже поддержан)
- [ ] **Приёмка:** на фикстуре палитра — 6 команд без дублей, строка
      `/opsx:apply <id>` собирается и уходит в `claude -p`; у avtoto палитра
      не изменилась (тест на число и имена команд)

### Этап 4. Спецификации в документах · S

- [ ] узел «Спецификации» в дереве документов: `openspec/specs/<capability>/spec.md`
      с вложенностью по каталогам
- [ ] дельты change'а: файлы `specs/**` под change'ем, пометка
      ADDED/MODIFIED/REMOVED по заголовкам `##`
- [ ] у архивного change'а — те же дельты, без «ненаписанных»
- [ ] **Приёмка:** на клоне upstream видны 30+ спецификаций и дельты у
      change'ей; у avtoto дерево не изменилось, кроме нового узла

### Этап 5. CLI `openspec` как необязательный источник · M (по желанию)

- [ ] `OpenSpecCliSource`: поиск бинаря, `list --json`, `status --change --json`,
      `validate --all --json`, `schema which --json`; таймауты, журнал команд
- [ ] `SpecFeature.validation` с гейтом `runtime`; колонка/бейдж «валидно ·
      N замечаний» в группе и карточке
- [ ] схема из `schema which` предпочитается встроенной копии — копия
      остаётся запасной
- [ ] расхождение «файлы против CLI» (наш счёт задач ≠ `completedTasks`) —
      сигнал, что парсер отстал от upstream; показывать, не прятать
- [ ] **Приёмка:** без бинаря ничего не меняется; с бинарём — валидация и
      та же схема, что у CLI

### Этап 6. Границы и документация · S

- [ ] `store:` в `config.yaml` → распознаётся, экран объясняет, куда идти
- [ ] вложенные каталоги в `changes/` → защита от формы (вариант A из
      `finding-recmeet-spec.md`) обязательна в этом же плане; B — отдельное
      решение
- [ ] README: третья спека в «Проверено на», таблица «что откуда читается»
      дополняется `.openspec.yaml`, `apply.tracks`, встроенной схемой
- [ ] `platform-console-master.md`, часть 8: пункт «Не-openspec спека
      поедет только на эвристике» переформулировать — теперь оригинальный
      OpenSpec поддержан по метаданным, эвристика остаётся для спек без
      схемы вовсе
- [ ] `feature-plan.md` §1: пункт «`openspec/redmine.yaml` нет вовсе —
      спросить статусы» дополняется: спрашивать только если трекер объявлен
      ключами, иначе трекера нет

### Порядок и зависимости

| Этап | Зависит | Риск | Объём |
|---|---|---|---|
| 0. Стенд | — | низкий | S |
| 1. Схема и задачи | 0 | средний: разрешение схемы по change'у трогает все чтения | M |
| 2. Стадия и трекер-фича | 1 | **средний-высокий**: меняет колонку статуса у всех спек | M |
| 3. Команды | 1 | средний: правило имени должно сохранить avtoto | M |
| 4. Спецификации | 1 | низкий | S |
| 5. CLI | 1 | низкий (необязательно) | M |
| 6. Границы и документация | 2, 3 | низкий | S |

Минимально работающий результат — этапы 0–3. После них upstream-проект
открывается, показывает работу и запускает команды. Этап 4 делает полезным
экран «Документы», 5 и 6 — качество.

---

## 5. Риски и открытые вопросы

- **Дрейф upstream.** Формат схемы стабилен с OPSX, но `skip_specs`,
  хранилища и `initiative` появились недавно и помечены beta. Встроенная
  копия схемы протухает — потому предпочитать `schema which`, когда CLI
  есть (этап 5), и держать версию в комментарии копии.
- **Скиллы без команд.** Если проект инициализирован с
  `delivery: skills`, каталога `.claude/commands/opsx/` нет — вызов идёт по
  имени скилла (`/openspec-propose`). Правило дедупа это учитывает: скилл
  без пары остаётся полноправной командой.
- **Разрешения в headless-сессии.** Скиллы upstream объявляют
  `allowed-tools: Bash(openspec:*)`; `claude -p` без `--permission-mode`
  может упереться в запрос разрешения (часть 8 сводного документа,
  «Разрешения агента»). Ничего нового, но на upstream проявится чаще —
  `openspec` вызывается на каждом шаге.
- **`git pull --ff-only` на каждом обновлении.** Для платформенной спеки
  это ожидаемо; для репозитория кода с локальной работой — неожиданный
  побочный эффект (ошибка тихая, но сеть дёргается). Стоит вынести в
  настройку проекта или делать только при чистом дереве. Не блокирует.
- **Стадия у avtoto.** Появление стадии рядом со статусом Redmine — новое
  на экране, где раньше был один столбец. Нужен макет: либо второй столбец,
  либо стадия как подпись под статусом. Решить до этапа 2.
- **Заголовок без H1.** Оставляем id; «очеловечивание» (`add-dark-mode` →
  «add dark mode») — вкусовщина, не делаем без запроса.
- **Живые спеки.** avtoto и avelacom в этой среде не открылись — сетевой
  запрет хоста GitLab. До правок кода прогнать существующие смоуки на них
  локально, чтобы иметь эталон «до».

---

## 6. Как перепроверить

```bash
# клон upstream рядом со Spok
git clone --depth 1 https://github.com/Fission-AI/OpenSpec.git ~/OpenSpec

# схема живёт в пакете, не в проекте
ls ~/OpenSpec/schemas/spec-driven/          # schema.yaml, templates/
ls ~/OpenSpec/openspec/schemas 2>/dev/null  # нет такого каталога
cat ~/OpenSpec/openspec/config.yaml | head -3

# change без стеков и без трекера
ls -a ~/OpenSpec/openspec/changes/add-change-stacking-awareness/
cat   ~/OpenSpec/openspec/changes/add-change-stacking-awareness/.openspec.yaml

# apply.tracks — кто отслеживает задачи
grep -A3 '^apply:' ~/OpenSpec/schemas/spec-driven/schema.yaml

# правила чекбоксов upstream
sed -n '/TASK_LINE_PATTERN =/p' ~/OpenSpec/src/utils/task-progress.ts

# имя команды во frontmatter — не вызов
grep -n "name:" ~/OpenSpec/src/core/templates/workflows/propose.ts
sed -n 1,30p ~/OpenSpec/src/core/command-generation/invocation.ts

# вложенные change'и upstream не поддерживает
sed -n 1,30p ~/OpenSpec/src/utils/nested-change.ts

# смоук Spok на upstream (после этапа 1)
SPEC_PLATFORM_DIR=~/OpenSpec dart run tool/smoke.dart
```

В коде Spok:

```bash
sed -n '100,110p;130,140p;452,507p;565,570p' lib/data/sources/platform_files_source.dart
sed -n '625,652p;727,737p' lib/data/repositories/platform_repository_impl.dart
sed -n '898,905p' lib/data/sources/platform_files_source.dart   # id из name
```
