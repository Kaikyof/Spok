## Why

Этап 7 плана, необязательный. Spok читает файлы сам и для оригинального
OpenSpec этого достаточно. Но CLI `openspec`, если он установлен, даёт то,
чего в файлах нет: результат валидации, точное разрешение схемы
(`schema which`), состав артефактов с правилами `skip_specs`, счёт задач —
и им можно проверять, что наш парсер не отстал от upstream.

## What Changes

- `OpenSpecCliSource`: поиск бинаря через `ExecutableLocator`,
  `list --json`, `status --change --json`, `validate --all --json`,
  `schema which --json`; таймауты, журнал команд.
- Расширение `openspec-cli` с гейтом `runtime` (бинарь найден): бейдж
  «валидно · N замечаний» в группе и карточке.
- Схема из `schema which` предпочитается встроенной копии.
- Расхождение «файлы против CLI» (наш счёт задач ≠ `completedTasks`)
  показывается как предупреждение.

## Capabilities

### New Capabilities
- `openspec-cli`: что приложение берёт у CLI upstream и как ведёт себя
  без него.

### Modified Capabilities
- нет.

## Impact

- Новый пакет `packages/spok_ext_openspec_cli`; `SchemaResolver` получает
  необязательный источник.
- Без бинаря ничего не меняется — на avtoto и avelacom CLI не стоит.
- Зависит от `resolve-schema-like-upstream`; как расширение — от
  `add-extension-registry`.
