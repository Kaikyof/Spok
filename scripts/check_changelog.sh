#!/usr/bin/env bash
# Сверка CHANGELOG.ru.md и CHANGELOG.md: у обоих файлов должен быть один
# и тот же «скелет» — те же версии с датами, те же разделы в каждой и
# столько же пунктов в каждом разделе. Текст пунктов не сравнивается
# (он на разных языках), так что проверка ловит забытый перевод, а не
# качество перевода.
#
# Заодно проверяется, что заголовки разделов — только из Keep a Changelog
# (Добавлено/Added, Изменено/Changed, ...): опечатка в заголовке иначе
# выглядела бы как «разные разделы» без понятной причины.
#
#   ./scripts/check_changelog.sh
#
# Совместим с bash 3.2 (macOS).
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Скелет файла: строка на каждую версию, раздел и пункт верхнего уровня.
# Русские названия разделов приводятся к английским, чтобы скелеты двух
# файлов можно было сравнить построчно.
skeleton() {
  awk -v file="$1" '
    BEGIN {
      map["Добавлено"] = "Added";      map["Added"] = "Added"
      map["Изменено"] = "Changed";     map["Changed"] = "Changed"
      map["Устарело"] = "Deprecated";  map["Deprecated"] = "Deprecated"
      map["Удалено"] = "Removed";      map["Removed"] = "Removed"
      map["Исправлено"] = "Fixed";     map["Fixed"] = "Fixed"
      map["Безопасность"] = "Security"; map["Security"] = "Security"
      bad = 0
    }
    /^## \[/ { print $0; next }
    /^### / {
      name = substr($0, 5); sub(/[[:space:]]+$/, "", name)
      if (!(name in map)) {
        printf "%s:%d: неизвестный раздел «%s»\n", file, NR, name > "/dev/stderr"
        bad = 1
      }
      print "### " ((name in map) ? map[name] : name)
      next
    }
    /^- / { print "-" }
    END { exit bad }
  ' "$1"
}

# Неизвестный заголовок не обрывает проверку сразу: diff ниже всё равно
# полезен, а исправлять удобнее, видя все ошибки за один прогон.
STATUS=0
RU="$(skeleton CHANGELOG.ru.md)" || STATUS=1
EN="$(skeleton CHANGELOG.md)" || STATUS=1

if [[ "$RU" != "$EN" ]]; then
  echo "error: структура CHANGELOG.ru.md и CHANGELOG.md расходится" >&2
  echo "(версии, разделы, число пунктов; слева — ru, справа — en):" >&2
  diff <(printf '%s\n' "$RU") <(printf '%s\n' "$EN") >&2 || true
  STATUS=1
fi

[[ $STATUS -eq 0 ]] || exit 1

echo "CHANGELOG.ru.md и CHANGELOG.md совпадают по структуре"
