## ADDED Requirements

### Requirement: Адаптер GitHub Issues

Приложение SHALL поддерживать трекер GitHub Issues по объявлению
`openspec/tracker.yaml` с `kind: github` и картой меток в категории;
закрытая задача всегда относится к категории `closed`.

#### Scenario: Задача с меткой review
- **WHEN** в `tracker.yaml` метка `review` отнесена к категории `review`, а
  задача `#42` открыта с этой меткой
- **THEN** статус стека — «review», ссылка ведёт на задачу `#42`

### Requirement: Адаптер Jira

Приложение SHALL поддерживать Jira Cloud и Jira Server по объявлению
`tracker.yaml` с `kind: jira`, картой статусов проекта в категории и
идентификаторами вида `PROJ-123`.

#### Scenario: Статус Jira в категории
- **WHEN** в `tracker.yaml` статус `In Review` отнесён к `review`, а задача
  `PROJ-123` в этом статусе
- **THEN** статус стека — «In Review» с категорией `review`, расхождения
  считаются по категории

### Requirement: Ядро не меняется ради нового адаптера

Добавление адаптера трекера, хостинга или мессенджера SHALL не требовать
правок в пакете ядра.

#### Scenario: Пакет адаптера
- **WHEN** в репозиторий добавлен пакет `spok_ext_tracker_jira`
- **THEN** изменения затрагивают только новый пакет и точку регистрации
  приложения
