#!/usr/bin/env bash
# Тег для dev-сборки на CI: v{версия-из-pubspec}-dev.N, где N подбирается
# автоматически как «последний существующий + 1». version в pubspec.yaml
# не трогается — годится, пока каждая CI-сборка не должна поднимать
# «настоящую» версию.
#
#   ./scripts/tag_dev_build.sh            — создать и запушить следующий тег
#   ./scripts/tag_dev_build.sh --dry-run  — только показать, какой тег получится
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

VERSION="$(grep -m1 '^version:' pubspec.yaml | sed 's/^version:[[:space:]]*//' | cut -d'+' -f1)"
PREFIX="v${VERSION}-dev."

echo "==> git fetch --tags"
git fetch --tags --quiet origin

# Тег — единственный источник правды о том, какой N уже занят: локальные
# теги после fetch --tags актуальны, считать по ним быстрее, чем парсить
# ls-remote.
LAST_N="$(git tag -l "${PREFIX}*" | sed "s/^${PREFIX}//" | sort -n | tail -1)"
NEXT_N=$(( ${LAST_N:-0} + 1 ))
TAG="${PREFIX}${NEXT_N}"

echo "==> Следующий тег: $TAG"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "--dry-run: тег не создан и не запушен"
  exit 0
fi

git tag "$TAG"
git push origin "$TAG"

echo "==> Готово: $TAG"
