## Why

Этап 5 плана. Источник правды оригинального OpenSpec — `openspec/specs/<capability>/spec.md`
— в дереве документов Spok не показывается вовсе, как и дельты
`changes/<id>/specs/**`: артефакты-маски пропускаются (`isSingleFile`). У
клона upstream это 30+ спецификаций, которых экран «Документы» не видит.

## What Changes

- Узел «Спецификации» в дереве документов с вложенностью по каталогам
  `openspec/specs/`.
- Дельты change'а: файлы `specs/**` под change'ем с пометкой
  ADDED / MODIFIED / REMOVED / RENAMED по заголовкам `##`.
- У архивного change'а — те же дельты, без «ненаписанных».

## Capabilities

### New Capabilities
- `docs-tree`: состав дерева документов — спецификации проекта и дельты
  change'ей.

### Modified Capabilities
- нет.

## Impact

- `lib/data/sources/platform_files_source.dart` (`loadDocTree`, `_changeDocs`),
  `lib/domain/entities/doc_node.dart`, `doc_artifact.dart`,
  `lib/presentation/screens/docs_screen.dart`, локализация.
- Для avtoto и avelacom — новый узел «Спецификации» (у avtoto
  `openspec/specs/` есть), остальное дерево не меняется.
- Зависит от `resolve-schema-like-upstream` (маски артефактов).
