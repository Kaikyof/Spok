## Why

Этап 2 плана. У change'а без трекера сегодня нет статуса вовсе: таблица
показывает «нет доступа», над ней полоса «нет ключа REDMINE_API_KEY», хотя
трекера у процесса нет по замыслу. Стадия работы — какие артефакты написаны,
сколько задач закрыто, в архиве ли — выводится из файлов и есть у любой
спеки; трекер должен стать слоем поверх неё, а не единственным источником
статуса. Одновременно код должен перестать знать слово «Redmine» в ядре
(`redmineStatus`, `RedmineProblem`, `redmineBaseUrl`, `RedmineIssueLink`,
31 строка локализации) — это первый шаг к расширениям (этап 4).

## What Changes

- Сущность `WorkStage` (`planning(next)` · `readyToApply` · `inProgress` ·
  `done` · `archived`) и usecase `AssessWorkStage` по артефактам в порядке
  `requires`, отметкам файла `tracks` и архиву.
- `StackState.stage`; `redmineStatus` → `trackerStatus`; `RedmineProblem` →
  `TrackerProblem` со значением `notDeclared`; `redmineBaseUrl` → адрес
  задачи от порта.
- Порт `Tracker` в `domain/repositories`; `RedmineApi` — его адаптер;
  `RedmineIssueLink` → `IssueLink`.
- Улика трекера: `openspec/redmine.yaml` или `REDMINE_URL` в `.env.example`;
  без улики трекер не опрашивается, полосы над таблицей и подписи «из файла»
  нет.
- Экран группы: колонка стадии с прогрессом; плашка «следующий шаг» по
  стадии, когда стеков нет. Карточка: стадия в шапке; цвет точки — по
  стадии, имя статуса трекера рядом.
- «Что распознано»: строка схемы с источником; строка статусов — только при
  улике трекера.
- «Окружение»: раздел систем строится из ключей `.env.example`; без ключей
  раздел не показывается.
- Локализация: стадии; слово «трекер» с подстановкой имени вместо «Redmine»
  в строках ядра.

## Capabilities

### New Capabilities
- `work-stage`: стадия работы change'а из файлов и её показ.
- `tracker-integration`: трекер как необязательный слой — улика, порт,
  состояние «не объявлен».
- `environment-screen`: разделы экрана «Окружение» строятся по уликам.

### Modified Capabilities
- нет.

## Impact

- `lib/domain/entities/{stack_state,console_snapshot,work_stage}.dart`,
  `lib/domain/usecases/assess_work_stage.dart`, `lib/domain/repositories/tracker.dart`,
  `lib/data/sources/redmine_api.dart`, `lib/data/repositories/platform_repository_impl.dart`
  (`_fetchStatuses`, `_checkSystems`, `_buildRecognition`),
  `lib/presentation/screens/{group,change}_screen.dart`, `ui_kit/issue_link.dart`,
  `core/resources/app_colors.dart`, `l10n/app_ru.arb`.
- Для avtoto и avelacom: статус трекера, расхождения и передача — как
  раньше; добавляется стадия рядом со статусом (нужен макет, борды 01, 02).
- Зависит от `resolve-schema-like-upstream`.
