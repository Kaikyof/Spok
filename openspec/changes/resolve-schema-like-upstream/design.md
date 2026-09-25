## Context

`PlatformFilesSource._readSchema` читает только
`openspec/schemas/<config.schema>/schema.yaml`; `_taskFilesOf` со схемой берёт
артефакты `tasks-<stack>`, без схемы — маску `tasks[_-]*.md`; `_loadChange`
создаёт «стек работы» лишь при `group.issue_id` в `redmine.yaml`; регулярка
чекбоксов `^-\s*\[( |x)\]\s*(\d+\.\d+)\s+(.+)$`. См. proposal.md — Why и
раздел 2 плана.

## Goals / Non-Goals

Goals: change'и проекта на оригинальном OpenSpec читаются с задачами и
артефактами; поведение на avtoto и avelacom не меняется.

Non-Goals: стадия работы (этап 2), команды (этап 3), спецификации в дереве
документов (этап 5), CLI `openspec` (этап 7).

## Decisions

- **Копия встроенной схемы в assets, а не запрос к CLI.** Приложение должно
  открывать проект без установленного `openspec`. Копия помечена версией
  upstream; когда появится `add-openspec-cli-source`, `schema which --json`
  станет предпочтительным источником, копия — запасным.
- **`SchemaResolver` — отдельный класс в `lib/data/sources/`**, а не рост
  `PlatformFilesSource`: цепочка из трёх источников и кэш по имени схемы
  заслуживают своего файла и своих тестов. Возвращает `ResolvedSchema
  {schema, source: project|user|builtin}`.
- **Схема по change'у.** `ChangeUnit.schema` заполняется при чтении; все
  места, где сегодня вызывается `loadSchema()` ради конкретного change'а
  (`_taskFilesOf`, `_changeDocs`, `change_screen._artifacts`,
  `branchFor`), переходят на схему change'а. `loadSchema()` остаётся как
  «схема по умолчанию» для экрана распознавания.
- **Единица работы — файл `apply.tracks`.** Порядок: артефакты `tasks-<stack>`
  → стеки; иначе `apply.tracks` (или артефакт с id `tasks`) → один стек
  `StackState.singleWorkStack`. Условие `links.groupIssueId != null`
  удаляется: у стека работы может не быть задачи трекера.
- **Парсер задач — перенос правил upstream дословно**, включая
  комментарии-обоснования: любой маркер списка (`-`, `*`, `+`, `1.`, `1)`),
  ведущие пробелы, один символ в скобках, запрет `(` и `[` после скобки
  (ссылки), `x`/`X` — сделано, остальное — нет, конец строки не привязан
  (CRLF). Номер `N.N` берётся из текста, если есть; иначе порядковый номер
  в файле — `TaskItem.number` остаётся строкой.
- **`branchTemplate: String?`.** `SpecSchema.branchFor` возвращает `null`
  без шаблона; `DocNode.branch` и блок «Код» обрабатывают `null` как «спека
  не объявляет ветку». Значение по умолчанию `features/<change>` удаляется.
- **Артефакты-маски.** `SchemaArtifact.matches(changeDir)` разворачивает
  `generates` с `*` через `Glob` из `package:glob`; «существует» = найден
  хотя бы один файл. `skip_specs: true` + маска под `specs/` → состояние
  `ArtifactState.skipped` (то же правило, что у upstream: по префиксу пути,
  а не по id).

## Risks / Trade-offs

- [Схема по change'у делает чтение дороже] → кэш `SchemaResolver` по имени;
  у одной спеки обычно одна схема.
- [Мягкий парсер посчитает задачей строку вроде `- [1] …`] → та же цена, что
  у upstream: громкий ложноположительный вместо тихой потери.
- [Удаление умолчания `features/<change>`] → avtoto объявляет ветку в
  `apply.instruction`, avelacom тоже — проверяется эталоном; спека без
  объявления теряет ссылку на ветку, которой у неё и не было.

## Migration Plan

Правки только в чтении; данных на диске не трогаем. Откат — возврат
коммита.

## Open Questions

- Нужна ли поддержка `openspec/config.yml` (без `a`)? Upstream читает его
  только когда нет `config.yaml`. Решение можно отложить: обе спеки команды
  и upstream используют `.yaml`.
