## Why

Этап 9 плана. Порт с одним адаптером — это переименование, а не
абстракция: форму портов `Tracker`, `CodeHosting`, `Chat` проверяет только
вторая система. И открытый выпуск с одним Redmine, одним GitLab и одним
Mattermost — выпуск для одной команды. По распространённости (Stack
Overflow 2025: GitHub 81 %, Jira 46 %, GitLab 36 %) первым идёт GitHub —
один адаптер и один токен закрывают и хостинг кода, и трекер, и это самый
частый случай у того, кто поставил оригинальный OpenSpec.

## What Changes

- `code-github`: pull request по ветке, влитость коммита, ссылка на ветку,
  ping; улика — `GITHUB_TOKEN` в `.env.example` или remote проекта на
  github.com.
- `tracker-github`: задачи `open`/`closed` плюс метки как категории,
  комментарии, ссылка `#123`; объявление `openspec/tracker.yaml` с
  `kind: github` и картой меток → категорий.
- `tracker-jira`: статусы проекта → категории по объявлению в
  `tracker.yaml`, идентификаторы `PROJ-123`, комментарии, ссылка;
  облачный и серверный Jira.
- `chat-slack`: отправка через входящий вебхук (обязательная часть),
  получатели и упоминания через API бота (необязательная).
- `chat-teams`: входящий вебхук; получатели — только из скрипта спеки.
- Шаблон пакета адаптера и чеклист контрибьютора в README.

## Capabilities

### New Capabilities
- `code-hosting`: хостинг кода как порт — что приложение показывает о
  ветке и запросе на слияние независимо от системы.
- `chat`: мессенджер как порт — отправка сообщения передачи и подбор
  получателей.

### Modified Capabilities
- `tracker-integration`: добавляются адаптеры GitHub и Jira (описаны как
  ADDED — основная спецификация ещё в незаархивированных change'ах).

## Impact

- Новые пакеты `spok_ext_code_github`, `spok_ext_tracker_github`,
  `spok_ext_tracker_jira`, `spok_ext_chat_slack`, `spok_ext_chat_teams`;
  ядро не меняется — если меняется, значит порт спроектирован неверно.
- Для avtoto и avelacom не меняется ничего: улик GitHub, Jira, Slack там
  нет.
- Зависит от `add-extension-registry` и `split-core-and-extensions`.
  GitHub стоит сделать до публикации, остальное — следующими релизами.
