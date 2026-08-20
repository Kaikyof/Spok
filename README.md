# Platform Console

Десктопное приложение (Flutter, macOS) — оболочка над платформой разработки
avtoto. Делает состояние спринта видимым, а следующий шаг — очевидным.

Бриф: `avtoto-platform/docs/platform-console-idea.md`.
Макеты: Penpot, страница «Platform Console».

## Что уже работает

- **Спринт** — таблица change'ей iOS/Android: живые статусы Redmine, отметки
  задач из `tasks_*.md`, блок расхождений (статус против факта), плашка
  следующего шага.
- **Change'и** — список и карточка: чеклисты по стекам с выделением
  незакрытых задач, артефакты с открытием документации.
- **Документация** — рендер markdown (`proposal.md`, `design.md`,
  `tasks_*.md`) прямо в приложении.
- **Окружение** — наличие ключей `.env` (без значений), состояние
  репозиториев workspace (ветка, отставание), доступность
  Redmine/GitLab/Mattermost.
- Переключатель спринтов (`openspec/doc/*`), индикатор свежести, обновление.

Не реализовано (следующие этапы): экран передачи спринта, агентные сессии
(Claude Code headless), панель запуска команд, светлая тема.

## Как устроено

Приложение ничего не хранит и не вычисляет само: читает файлы
`avtoto-platform` (`workspace.yaml`, `.env`, `openspec/**`), опрашивает
Redmine по API и спрашивает git. Каждое обновление — полный пересбор слепка.

Путь к платформе: переменная окружения `AVTOTO_PLATFORM_DIR`, затем путь из
конфига приложения (`~/Library/Application Support/PlatformConsole/.env`,
ключ `AVTOTO_PLATFORM_DIR`), затем типовые пути. Если платформа не найдена,
приложение показывает экран настройки и сохраняет введённый путь в конфиг.

## Архитектура

Clean Architecture, слои:

```
lib/
  core/            ресурсы (AppColors, AppTextStyles, AppDimens) и тема
  domain/          сущности, контракты репозиториев, usecases (FindDivergences)
  data/            sources (файлы платформы, Redmine API на dio) + repositories
  presentation/    bloc (event/state/bloc), shell, screens, ui_kit
  l10n/            строки интерфейса (gen-l10n, app_ru.arb)
```

Правила стиля: тексты — только через локализацию (домен возвращает
структуры, форматирует presentation); подписка на блок — BlocBuilder;
виджеты — классами; каждый класс — отдельный файл (кроме приватных
виджетов); переиспользуемые компоненты — в `presentation/ui_kit`.

Стек: flutter_bloc, dio, get_it, intl, path, yaml, flutter_markdown_plus
(маинтейнящийся форк flutter_markdown с тем же API), window_manager.
auto_route и json_serializable подключим, когда появятся глубокие маршруты
(карточка change по id) и DTO-модели GitLab/Mattermost.

## Запуск

```bash
flutter run -d macos
```

Смоук данных без UI (печатает слепок по реальным файлам платформы):

```bash
dart run tool/smoke.dart
```
