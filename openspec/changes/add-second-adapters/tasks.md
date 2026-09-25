## 1. GitHub

- [ ] 1.1 `packages/spok_ext_code_github`: улика (токен или remote), pull request по ветке, влитость через compare, ссылка на ветку, ping, гейт; фикстура проекта на GitHub и тесты «проект на GitHub», «GitHub и GitLab», «remote без ключей»
- [ ] 1.2 `packages/spok_ext_tracker_github`: `tracker.yaml` с `kind: github` и картой меток, статусы, комментарии, `IssueRef` `#N`; тест «задача с меткой review»; проверить, что ядро не изменилось (`git diff packages/spok_core` пуст)

## 2. Jira

- [ ] 2.1 `packages/spok_ext_tracker_jira`: Cloud и Server по `api:`, аутентификация обоих видов в форме ключей, статусы → категории по `tracker.yaml`, комментарии, ссылка; тест «статус Jira в категории»; шаблон `tracker.yaml` для Jira в `assets/extensions/`

## 3. Мессенджеры

- [ ] 3.1 `packages/spok_ext_chat_slack`: `send` через вебхук, `recipients` через `users.list` при токене бота, упоминания `<@U…>`; тесты «Slack с ботом» и «отмена на предпросмотре»
- [ ] 3.2 `packages/spok_ext_chat_teams`: вебхук с Adaptive Card, получатели из скрипта; тест «Teams через вебхук»

## 4. Для контрибьюторов

- [ ] 4.1 `packages/_template_ext/` с чеклистом адаптера (улики, гейт, адаптер порта, вклад в разбор, локализация, фикстура и тесты); ссылка из `CONTRIBUTING.md`; проверить, что копия шаблона собирается
- [ ] 4.2 Приёмка: проект на GitHub после `openspec init` с `GITHUB_TOKEN` показывает PR и задачи; эталоны avtoto и avelacom без изменений
