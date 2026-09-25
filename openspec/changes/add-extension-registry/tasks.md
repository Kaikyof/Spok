## 1. Контракт и реестр

- [ ] 1.1 `lib/domain/extensions/spec_extension.dart`: `SpecExtension`, `ExtensionEvidence`, `ExtensionData`, описания вкладов (`NavItem`, `ChangeCardBlock`, `GroupColumn`, `RecognizedItem`, `EnvSystem`, `DivergenceRule`); реестр `ExtensionRegistry` с проверкой `dependsOn`; unit-тесты на активацию, зависимость «ждёт», порядок вкладов
- [ ] 1.2 `ConsoleSnapshot.extensions: Map<String, ExtensionData>`; `PlatformRepositoryImpl.load` грузит расширения параллельно и изолированно (`catchError` → `ExtensionData.failed`); тест «трекер не отвечает» — ядро загружено
- [ ] 1.3 Порты «с расчётом на второй адаптер»: `StatusSemantics.categories`, `IssueRef`, `Tracker.declarationFile`, `CodeHosting.branchUrl`, `Chat.send`/`Chat.recipients?`; тесты «спека Redmine без явных категорий», «ссылка на задачу Redmine», «объявление через tracker.yaml»

## 2. Расширения по одному (после каждого — эталон avtoto и avelacom)

- [ ] 2.1 `lib/extensions/tracker_redmine/`: улики, гейт, статусы, комментарии, ссылки, правила расхождений по статусу, колонка группы, строка разбора, система «Окружения»; `RedmineApi` и палитра статусов переезжают сюда; эталон avtoto без изменений
- [ ] 2.2 `lib/extensions/workspace/`: `workspace.yaml`, роли машины `*_ROLE`, репозитории на «Окружении», сервисы для других расширений; эталон
- [ ] 2.3 `lib/extensions/code_gitlab/`: порт `CodeHosting`, блок «Код», ссылка на ветку, гейт с природами нехватки; тест «хостинг объявлен сервисами, ключ не объявлен» (avelacom) — блок с объяснением
- [ ] 2.4 `lib/extensions/chat_mattermost/`: улика `MATTERMOST_*`, система, предпросмотр; эталон
- [ ] 2.5 `lib/extensions/sprints/`: стратегии `sprintDir` и `masterDoc`, `builds.yaml`, экран передачи, готовность, получатели, роли `newGroup`/`handover`, `dependsOn: [tracker, workspace]`; тест «спринты без трекера»; эталон avtoto — передача та же

## 3. Композиция интерфейса

- [ ] 3.1 `shell.dart`: навигация из пунктов ядра и активных расширений, счётчик только у активных; удалить `SpecFeature` и `ProjectProfile.features`; тесты состава навигации на трёх фикстурах (upstream — три пункта)
- [ ] 3.2 Таблица группы, карточка, разбор, «Окружение» — из вкладов; тест «проект на оригинальном OpenSpec» (нет блока «Код», нет строк о статусах и сервисах)
- [ ] 3.3 «Окружение» в навигации только при активном разделе; ветка и отставание репозитория спеки — в шапку к чипу проекта; тесты «проект без окружения», «только ключи», «отставание»
- [ ] 3.4 Раздел «Расширения» в настройках проекта: список с состоянием, уликами, требованиями, «Скопировать шаблон» и «Создать через агента» из `assets/extensions/<id>.md`; `FeatureUnavailableView` теряет эти кнопки; локализация; тест «включить передачу в проекте без спринтов»
- [ ] 3.5 Смоук печатает активные расширения; `tool/compare_smoke.sh` на avtoto и avelacom — разница только в новой строке; `flutter test` зелёный
