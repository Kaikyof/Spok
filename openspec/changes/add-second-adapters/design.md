## Context

Порты спроектированы на этапе 4 «с расчётом на второй адаптер»: явные
категории статусов, строковый `IssueRef`, `branchUrl` в адаптере,
`Chat.send` / `Chat.recipients?`, файл объявления с `kind`. См. proposal.md
и план, 4.8.

## Goals / Non-Goals

Goals: пять адаптеров без правок ядра; чеклист для внешних
контрибьюторов. Non-Goals: запись в трекер (создание задач, смена
статусов) — это команды спеки; Linear, YouTrack, Discord, Telegram,
Bitbucket — вторая очередь по чеклисту.

## Decisions

- **Порядок**: GitHub (код) → GitHub (задачи) → Jira → Slack → Teams.
  Первый адаптер каждого порта — самый частый случай; если ядро
  приходится править, это фиксируется как дефект порта и правится в ядре
  один раз, до следующего адаптера.
- **`code-github`**: REST v3, `GET /repos/{owner}/{repo}/pulls?head=owner:branch`,
  `GET /repos/{owner}/{repo}/compare/{base}...{head}` для влитости;
  `branchUrl` — `https://github.com/{owner}/{repo}/tree/{branch}`; улика —
  `GITHUB_TOKEN` в примере или `git remote get-url origin` с `github.com`.
- **`tracker-github`**: категории по объявлению в `tracker.yaml`
  (`labels: {working: [in progress], review: [review], …}`), `closed` →
  категория `closed` всегда; `IssueRef` — `#123`; комментарии —
  `GET /repos/{o}/{r}/issues/{n}/comments`.
- **`tracker-jira`**: REST v3 (Cloud) и v2 (Server) — одна реализация с
  переключателем по `tracker.yaml → api: cloud|server`; аутентификация:
  Cloud — email + API token (basic), Server — PAT (bearer); категории —
  карта имён статусов проекта в `tracker.yaml`; `IssueRef` — `PROJ-123`.
- **`chat-slack`**: `send` через Incoming Webhook (`SLACK_WEBHOOK_URL`);
  `recipients` через `users.list` при `SLACK_BOT_TOKEN`, упоминания
  `<@U…>`; форма ключей — оба ключа, второй необязательный.
- **`chat-teams`**: Incoming Webhook с Adaptive Card; получателей нет —
  берутся из скрипта спеки.
- **Кэш статусов в change'е** для новых трекеров не читается: стадия из
  файлов достаточна, кэш пишет команда синхронизации спеки, если есть.
- **Шаблон пакета** — `packages/_template_ext/` с README-чеклистом из 4.8
  плана; `CONTRIBUTING.md` ссылается на него.

## Risks / Trade-offs

- [Разные модели аутентификации] → форма ключей описывает тип ключа в
  подсказке; OAuth-приложение Slack — только если нужны получатели.
- [Лимиты запросов GitHub] → один запрос на change, кэш на слепок.
- [Матрица растёт] → в репозитории только адаптеры с фикстурой и тестами.

## Migration Plan

Каждый адаптер — отдельный PR с фикстурой спеки под него.
