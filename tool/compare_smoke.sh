#!/usr/bin/env bash
# Эталон вывода смоука на живой спеке — и сравнение с ним после правок.
#
# Живые спеки команды (avtoto, avelacom) в CI недоступны, а регрессию на них
# должен ловить не человек глазами, а diff. Поэтому до правок кода вывод
# смоука сохраняется как эталон «до», а после — сравнивается построчно.
#
#   tool/compare_smoke.sh avtoto --save     # сохранить эталон
#   tool/compare_smoke.sh avtoto            # сравнить; код 1 при разнице
#
# Путь к спеке: SPEC_PLATFORM_DIR, иначе ~/<имя>-platform, иначе ~/<имя>.
# Эталоны лежат в test/fixtures/baseline/<имя>.txt — каталог в .gitignore:
# в выводе есть внутренние имена и номера задач, им не место в репозитории.
#
# Изменчивые числа — миллисекунды ответа систем и отставание веток — перед
# сравнением заменяются на N: иначе каждый прогон отличался бы сам от себя.
set -euo pipefail

name="${1:?использование: tool/compare_smoke.sh <spec> [--save]}"
mode="${2:-}"

here="$(cd "$(dirname "$0")" && pwd)"
baseline_dir="$here/../test/fixtures/baseline"
baseline="$baseline_dir/$name.txt"

resolve_spec_dir() {
  if [[ -n "${SPEC_PLATFORM_DIR:-}" ]]; then
    echo "$SPEC_PLATFORM_DIR"
  elif [[ -d "$HOME/$name-platform" ]]; then
    echo "$HOME/$name-platform"
  elif [[ -d "$HOME/$name" ]]; then
    echo "$HOME/$name"
  else
    echo "спека «$name» не найдена: задайте SPEC_PLATFORM_DIR" >&2
    exit 2
  fi
}

normalize() {
  # `(123ms)` → `(Nms)`, `отстаёт на 3` и прочие счётчики в скобках → N.
  sed -E 's/\(([0-9]+)/(N/g; s/behind: [0-9]+/behind: N/g'
}

if [[ "$mode" != "--save" && ! -f "$baseline" ]]; then
  echo "эталона нет: $baseline — сначала запустите с --save" >&2
  exit 2
fi

spec_dir="$(resolve_spec_dir)"
current="$(cd "$here/.." && SPEC_PLATFORM_DIR="$spec_dir" dart run tool/smoke.dart | normalize)"

if [[ "$mode" == "--save" ]]; then
  mkdir -p "$baseline_dir"
  printf '%s\n' "$current" > "$baseline"
  echo "эталон сохранён: $baseline ($(wc -l < "$baseline") строк)"
  exit 0
fi

if diff -u "$baseline" <(printf '%s\n' "$current"); then
  echo "совпадает с эталоном: $name"
else
  echo "расхождение с эталоном: $name" >&2
  exit 1
fi
