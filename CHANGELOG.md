# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Russian version: [CHANGELOG.ru.md](CHANGELOG.ru.md).

## [Unreleased]

### Added

- Connect your team's spec by git URL or local path, with clone progress, cancel and clear error messages. Cloning uses your own git, ssh keys and settings.
- "What was recognized" step before a spec is opened for the first time: what the app understood from the spec, where it found it and which screens it enables.
- Group screen: changes of a sprint, a master spec or the whole spec by stack — Redmine statuses, task checkmarks, status-versus-reality mismatches and the next step.
- Change card: the change's spec, per-stack checklists, schema artifacts, dependencies, branches and GitLab MRs with merge status, Redmine comments.
- Docs screen: spec tree with change artifacts and the archive, markdown preview and opening a file in your IDE.
- Environment screen: checks for keys from `.env.example`, repository state and Redmine, GitLab and Mattermost availability; a form to fill in keys, with import from an existing `.env`.
- Secrets are stored in Keychain on macOS and secret-tool on Linux, or in a 0600 file when no system store is available. The spec's `.env` is generated from the store automatically.
- Sessions screen: Claude Code conversations in the spec repository — a palette of spec commands with argument hints, model, access mode and effort selection, markdown in replies.
- Handoff screen: readiness with blockers, builds, recipient selection and a message preview before handing off a stack.
- Run panel: the last command, exit code, duration and output, with copy buttons.
- A feature the spec does not support stays visible and explains what is missing.
- Loading, partial errors and stale data are shown inside the screen, with Retry and Refresh right next to the message.
- Support for projects on the original OpenSpec: the `spec-driven` schema and tasks without stacks or a tracker.
- Linux build; settings and spec clones live in the system's standard directories.
- Release notes on GitHub are built from this changelog, in English and Russian.
- Work stage of a change derived from the spec files — planning, ready to apply, in progress, done, archived — in the group table and the change card header; for a spec without stacks the next step follows the stage.
- After a session on a change, the next step follows its stage: archive a done change, continue planning, or apply a ready one. The next-step banner of a done change now carries the archive command.
- Commands and skills are also read from other tools' directories — `.agents/skills`, `.opencode`, `.github/prompts`; copies of the same command appear once.
- Docs screen: a "Specifications" node with `openspec/specs/` by directory, and change deltas — each `specs/**` file on its own row marked ADDED, MODIFIED, REMOVED or RENAMED.

### Changed

- The tracker status is a label next to the stage rather than the only status; the app names the system as the spec declares it instead of "Redmine". A spec without a tracker no longer hears "no access" or "no key".
- Environment screen: the keys section exists only with `.env.example`, external systems only for the addresses it declares.
- Arguments of a command without `argument-hint` come only from the invocation line in its `**Input**` section. A command described there in prose stays in the palette instead of the change card menu.

### Fixed

- Original OpenSpec commands are invoked the way Claude Code registers them (`/opsx:propose`), not by the title in the file (`/OPSX: Propose`); a command and a skill for the same thing are one palette row.
- The create-change command no longer appears in the change card's action menu; Apply and Archive appear by the command's purpose, even without an argument description.

[Unreleased]: https://github.com/Kaikyof/Spok/commits/develop
