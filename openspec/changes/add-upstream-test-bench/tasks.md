## 1. Фикстура upstream

- [x] 1.1 Добавить `buildUpstreamSpec()` в `test/upstream_fixture.dart` со всеми файлами из сценария «Собранная фикстура» и проверить тестом, что `PlatformFilesSource.isPlatformRoot` её принимает
- [x] 1.2 Сгенерировать `test/fixtures/upstream-sample/` командами `npx @fission-ai/openspec@1.13.2 init --tools claude` и `openspec new change sample-change`, дописать `proposal.md`, `tasks.md`, `specs/sample/spec.md`, архивный change; записать версию CLI и команды пересборки в `test/fixtures/upstream-sample/README.md`; проверить, что `flutter test` читает каталог без сети
- [x] 1.3 Написать тест `test/upstream_current_behaviour_test.dart`, фиксирующий сегодняшнее поведение на фикстуре (схема пустая, задач нет, стеков нет) — он станет красным на этапе 1 и будет переписан; проверить, что тест зелёный на `develop`

## 2. Смоук и эталон

- [x] 2.1 Дополнить `tool/smoke.dart` строками «стадия», «источник схемы», «расширения» со значением «не реализовано» и проверить запуском на фикстуре `upstream-sample`
- [x] 2.2 Добавить `tool/compare_smoke.sh <spec>`: сохраняет вывод в `test/fixtures/baseline/<spec>.txt` при `--save`, иначе сравнивает `diff`'ом; путь `test/fixtures/baseline/` — в `.gitignore`; проверить на avelacom: `--save`, затем сравнение без изменений даёт нулевой код
- [ ] 2.3 Сохранить эталоны avtoto и avelacom на машине разработчика до правок кода и приложить их сводку (число change'ей, групп, команд, фич) в комментарий к этому change'у — проверить, что сводка совпадает с README («Проверено на двух спеках»)

## 3. Клон upstream как третья спека

- [x] 3.1 Написать `test/upstream_clone_test.dart`: ищет клон по `OPENSPEC_UPSTREAM_DIR` или `~/OpenSpec`, при отсутствии — `skip`; проверяет число каталогов в `openspec/changes` (27 на db23097), архива (≥5) и спецификаций (≥30); проверить локально с клоном и в CI без него
- [x] 3.2 Дописать в README раздел «Запуск» третьим сценарием `SPEC_PLATFORM_DIR=~/OpenSpec dart run tool/smoke.dart` и проверить, что команда из README выполняется
