## 1. Схема

- [x] 1.1 Скопировать `schemas/spec-driven/schema.yaml` upstream 1.13.2 в `assets/openspec/schemas/spec-driven/schema.yaml` с комментарием версии, добавить в `pubspec.yaml → flutter.assets`; проверить, что `rootBundle.loadString` читает файл в тесте
- [x] 1.2 Создать `lib/data/sources/schema_resolver.dart`: `resolve(name) → ResolvedSchema{schema, source}` по цепочке проект → пользователь → встроенная, с кэшем; тесты на четыре сценария спецификации `schema-resolution`
- [x] 1.3 В `PlatformFilesSource._loadChange` читать `.openspec.yaml` (`schema`, `created`, `goal`, `skip_specs`) в `ChangeUnit`, выбирать схему через `SchemaResolver` по цепочке change → конфиг → `spec-driven`; тест «схема из метаданных change'а»
- [ ] 1.4 Перевести `_taskFilesOf`, `_changeDocs`, `argumentValues`, `loadDocTree` и `change_screen._artifacts` на схему change'а; `loadSchema()` оставить для экрана распознавания с источником; проверить эталоном «до», что на avtoto и avelacom стеки, файлы и артефакты не изменились

## 2. Задачи и единица работы

- [x] 2.1 `SpecSchema.tracksFile` из `apply.tracks` (иначе артефакт `tasks`); `_taskFilesOf` возвращает `[(singleWorkStack, tracksFile)]`, когда стеков нет; убрать условие `links.groupIssueId != null`; тест «проект на схеме spec-driven» даёт 2/3
- [x] 2.2 Переписать `_loadTasksFile` по правилам upstream (маркеры `-`, `*`, `+`, `N.`, `N)`, отступ, один символ в скобках, запрет `(`/`[` после скобки, `x`/`X`, CRLF); номер `N.N` из текста, иначе порядковый; тесты на все строки сценариев `task-tracking` плюс `[ x]`, `[]`, `- [x]done`
- [x] 2.3 Перепроверить `FindDivergences`, `AssessHandoffReadiness` и таблицу группы на единице работы без трекера: статус `null`, задачи есть — экран показывает прогресс, а не «нет доступа»; виджет-тест на фикстуре upstream

## 3. Артефакты, заголовок, ветка

- [x] 3.1 Добавить `package:glob`, `SchemaArtifact.existsIn(changeDir)` для масок; `ArtifactState.skipped` при `skip_specs` и маске под `specs/`; карточка считает «N из M» с учётом масок и пропуска; тест «дельта спецификации написана» и «пропуск спецификаций»
- [x] 3.2 Без схемы в проекте `change_screen._artifacts` использует встроенную `spec-driven`, а не константы `proposal.md`/`design.md`; убрать константы; тест на фикстуре upstream — четыре артефакта
- [x] 3.3 `_proposalTitle`: снимать префикс `Proposal:`; при отсутствии H1 — id; тест «шаблон upstream без H1»
- [x] 3.4 `SpecSchema.branchTemplate` → `String?`, `branchFor` → `String?`; удалить умолчание `features/<change>`; `DocNode.branch` и блок «Код» принимают `null` с текстом «спека не объявляет имя ветки» (локализация в этой же группе); тесты: avtoto — ветка из `apply.instruction`, upstream — `null`
- [ ] 3.5 Обновить `tool/smoke.dart` (источник схемы — реальное значение) и прогнать `tool/compare_smoke.sh` на avtoto и avelacom — разница только в новых строках вывода
