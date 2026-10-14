import 'dart:io';

import 'package:path/path.dart' as p;

/// Спека в стиле оригинального OpenSpec (upstream 1.13.2): проект после
/// `openspec init --tools claude` и пары `openspec new change`.
///
/// Здесь нарочно всё, чего у спек команды нет: схема не в проекте (она в
/// npm-пакете upstream), один `tasks.md` без стеков, `.openspec.yaml` вместо
/// `redmine.yaml`, чекбоксы через `*` и с `[X]`, `proposal.md` без заголовка
/// первого уровня, `skip_specs`, команды с `name: OPSX: Propose`. И ничего из
/// того, что есть: ни `.env.example`, ни `workspace.yaml`, ни `openspec/doc`.
///
/// Сегодня на этой фикстуре приложение показывает поломки из раздела 2
/// `docs/openspec-upstream-plan.md` — это и есть её ценность: каждый
/// следующий этап переписывает тест, который здесь красный.
Directory buildUpstreamSpec() {
  final root = Directory.systemTemp.createTempSync('spec-upstream');
  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  write('openspec/config.yaml', 'schema: spec-driven\n');

  // Источник правды — спецификации проекта.
  write('openspec/specs/ui/spec.md', '''
# ui Specification

## Purpose
Поведение интерфейса: темы и переключатели.

## Requirements

### Requirement: Theme toggle
The system SHALL expose a theme toggle in settings.

#### Scenario: Toggle visible
- **WHEN** settings are opened
- **THEN** the toggle is shown
''');

  // Change в работе: все артефакты схемы spec-driven, чекбоксы в формах,
  // которые upstream считает задачами, а сегодняшний парсер Spok — нет.
  write('openspec/changes/add-dark-mode/.openspec.yaml', '''
schema: spec-driven
created: 2026-09-20
''');
  write('openspec/changes/add-dark-mode/proposal.md', '''
## Why

Users asked for a dark mode to reduce eye strain.

## What Changes

- Add a theme toggle to settings.

## Capabilities

### New Capabilities
- `ui`: theme toggle

## Impact

Settings screen and theme provider.
''');
  write('openspec/changes/add-dark-mode/specs/ui/spec.md', '''
## ADDED Requirements

### Requirement: Dark theme
The system SHALL provide a dark theme.

#### Scenario: System dark
- **WHEN** the OS is in dark mode
- **THEN** the app uses the dark theme
''');
  write('openspec/changes/add-dark-mode/design.md', '''
## Context

Theme lives in a provider.

## Decisions

- CSS variables over runtime class toggling.
''');
  write('openspec/changes/add-dark-mode/tasks.md', '''
# Tasks

## 1. Theme

* [X] 1.1 Create theme provider and verify the unit test passes
* [ ] 1.2 Add toggle to settings and verify it renders
  - [ ] 1.3 Persist choice and verify it survives restart
- [~] Wire system preference detection
- [Design notes](./design.md)
''');

  // Change без спецификаций — pure refactor с явным пропуском.
  write('openspec/changes/refactor-config/.openspec.yaml', '''
schema: spec-driven
created: 2026-09-22
skip_specs: true
''');
  write('openspec/changes/refactor-config/proposal.md', '''
## Why

Config loading is duplicated.

## What Changes

- Extract a loader.

## Capabilities

### New Capabilities
- none (skip_specs)

## Impact

Internal only.
''');
  write('openspec/changes/refactor-config/tasks.md', '''
## 1. Loader

- [ ] 1.1 Extract loader and verify existing tests pass
''');

  // Архив с датой в имени — тот же формат, что у спек команды.
  write('openspec/changes/archive/2026-09-01-add-login/.openspec.yaml', '''
schema: spec-driven
created: 2026-08-15
''');
  write('openspec/changes/archive/2026-09-01-add-login/proposal.md', '''
## Why

Login was missing.
''');
  write('openspec/changes/archive/2026-09-01-add-login/tasks.md', '''
## 1. Login

- [x] 1.1 Add login form and verify the widget test passes
''');

  // Команды и скиллы, как их генерирует upstream для Claude Code:
  // вызов `/opsx:propose` — из пути, `name` во frontmatter — не вызов.
  write('.claude/commands/opsx/propose.md', '''
---
name: OPSX: Propose
description: Propose a new change - create it and generate all artifacts in one step
allowed-tools: Bash(openspec:*)
category: OpenSpec
tags: [openspec, propose]
---

Propose a new change - create the change and generate all artifacts in one step.

**Input**: The user's request should include a change name (kebab-case) OR a description of what they want to build.
''');
  write('.claude/commands/opsx/apply.md', '''
---
name: OPSX: Apply
description: Implement tasks from an OpenSpec change (Experimental)
allowed-tools: Bash(openspec:*)
category: OpenSpec
tags: [openspec, apply]
---

Implement tasks from an OpenSpec change.

**Input**: Optionally specify a change name (e.g., `/opsx:apply add-auth`).
''');
  write('.claude/skills/openspec-propose/SKILL.md', '''
---
name: openspec-propose
description: Propose a new OpenSpec change with all artifacts generated in one step. Also use when the user says "openspec propose" or "opsx propose".
allowed-tools: Bash(openspec:*)
license: MIT
---

Propose a new change - create the change and generate all artifacts in one step.
''');

  return root;
}
