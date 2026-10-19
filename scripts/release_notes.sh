#!/usr/bin/env bash
# Описание GitHub Release из CHANGELOG.md и CHANGELOG.ru.md (формат
# Keep a Changelog): вырезает раздел версии из обоих файлов и печатает
# их одно под другим — сначала английский, потом русский.
#
#   ./scripts/release_notes.sh v0.2.0        — раздел [0.2.0]
#   ./scripts/release_notes.sh v0.2.0-dev.3  — раздел [Unreleased]
#
# Dev-тег (с суффиксом после версии) не поднимает version в pubspec.yaml,
# и раздела под него в журнале нет — в описание идёт то, что накоплено в
# [Unreleased] с прошлого релиза. Для релизного тега раздел обязан быть в
# обоих файлах: релиз без описания — ошибка, а не пустая страница.
#
# Совместим с bash 3.2 (macOS), чтобы проверить вывод локально до тега.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

TAG="${1:?usage: $0 <tag>}"
VERSION="${TAG#v}"

if [[ "$VERSION" == *-* ]]; then
  SECTION="Unreleased"
else
  SECTION="$VERSION"
fi

# Тело раздела: всё после «## [SECTION]» до следующего «## [» или до
# ссылок-сносок внизу файла; пустые строки по краям срезаются.
extract() {
  awk -v section="$SECTION" '
    index($0, "## [" section "]") == 1 { found = 1; next }
    found && (/^## \[/ || /^\[[^]]+\]: /) { exit }
    found { lines[++n] = $0 }
    END {
      if (!found) exit 2
      first = 1; while (first <= n && lines[first] ~ /^[[:space:]]*$/) first++
      last = n;  while (last >= first && lines[last] ~ /^[[:space:]]*$/) last--
      for (i = first; i <= last; i++) print lines[i]
    }
  ' "$1"
}

section_or_fail() {
  local file="$1" empty="$2" body
  if ! body="$(extract "$file")"; then
    echo "error: в $file нет раздела [$SECTION]" >&2
    exit 1
  fi
  if [[ -z "$body" ]]; then
    if [[ "$SECTION" != "Unreleased" ]]; then
      echo "error: раздел [$SECTION] в $file пуст" >&2
      exit 1
    fi
    body="$empty"
  fi
  printf '%s\n' "$body"
}

EN="$(section_or_fail CHANGELOG.md '_No notable changes._')"
RU="$(section_or_fail CHANGELOG.ru.md '_Заметных изменений нет._')"

printf '## English\n\n%s\n\n## Русский\n\n%s\n' "$EN" "$RU"
