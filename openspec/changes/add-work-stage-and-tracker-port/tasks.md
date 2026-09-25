## 1. Стадия работы

- [ ] 1.1 Добавить `lib/domain/entities/work_stage.dart` (sealed class: `planning(next)`, `readyToApply`, `inProgress(done,total)`, `done`, `archived`) и `lib/domain/usecases/assess_work_stage.dart`; unit-тесты на четыре сценария спецификации `work-stage` и на порядок `requires` при двух готовых артефактах (берётся первый по схеме)
- [ ] 1.2 `StackState.stage` и `ChangeUnit.stage` заполняются в `PlatformFilesSource._loadChange`; смоук печатает стадию; проверить на фикстуре upstream и на avelacom (стадии совпадают с ручным подсчётом по файлам)
- [ ] 1.3 Экран группы: стадия с прогрессом в строке change'а (колонка или подпись — по решению макета), `AppColors.forStage`; виджет-тест: на фикстуре upstream в таблице нет текста «нет доступа»
- [ ] 1.4 Карточка change'а: стадия в шапке; статус трекера рядом при активном трекере; виджет-тест на обеих фикстурах
- [ ] 1.5 Плашка «следующий шаг» по стадии при отсутствии стеков (`_NextStepSection`): команда из ролей, без роли — без команды; локализация трёх текстов; тест «все change'и сделаны»

## 2. Порт трекера

- [ ] 2.1 `lib/domain/repositories/tracker.dart` (`name`, `issueUrl`, `statuses`, `comments`, `ping`); `RedmineApi` реализует; `PlatformRepositoryImpl` получает `Tracker?` вместо прямого `RedmineApi`; тесты на заглушке порта
- [ ] 2.2 Переименовать `StackState.redmineStatus` → `trackerStatus`, `RedmineProblem` → `TrackerProblem` (+ `notDeclared`), `ConsoleSnapshot.redmineBaseUrl` → `issueUrl` от порта, `RedmineIssueLink` → `IssueLink`; `flutter analyze` чист; эталон avtoto без изменений
- [ ] 2.3 Улика трекера в `PlatformFilesSource.trackerDeclared` (`openspec/redmine.yaml` или `REDMINE_URL` в примере); `_fetchStatuses` возвращает `notDeclared` без запроса; экран группы показывает полосу только для `noApiKey`/`unreachable`; тесты на оба сценария `tracker-integration`
- [ ] 2.4 Локализация: заменить 31 строку с «Redmine» на тексты с `{tracker}`; палитра `forRedmineStatus` переезжает в `lib/data/sources/redmine_status_colors.dart` и красит только ярлык; тест: на фикстуре upstream в дереве виджетов нет строки «Redmine»
- [ ] 2.5 «Что распознано»: строка схемы с источником (`project`/`user`/`builtin`), строка статусов только при улике трекера; обновить `recognition_step_test.dart`

## 3. Окружение

- [ ] 3.1 `_checkSystems` строит список по ключам `*_URL` из `.env.example` (карта имя → проверка); без ключей — пустой список, раздел скрыт; тесты «только Redmine» и «примера нет»
- [ ] 3.2 Раздел ключей и кнопка «Заполнить ключи» только при `.env.example`; `MissingKeyBlock` не показывается для необъявленных ключей; виджет-тест «проект без ключей»
- [ ] 3.3 Прогнать `tool/compare_smoke.sh` на avtoto и avelacom и `flutter test`; расхождения только в новых строках стадии
