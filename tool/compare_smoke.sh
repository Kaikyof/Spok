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
baseline="${baseline_dir}/${name}.txt"

# Те же типовые пути, по которым спеку ищет само приложение
# (`PlatformFilesSource.locate`), плюс SPEC_PLATFORM_DIR первым.
# Переменные — только в фигурных скобках: bash 3.2 на macOS путает
# `$name` вплотную к не-ASCII символу с несуществующей переменной.
is_spec_root() {
  [[ -d "${1}/openspec" || -f "${1}/workspace.yaml" ]]
}

resolve_spec_dir() {
  # Явный путь обязан быть спекой: смоук при негодном SPEC_PLATFORM_DIR
  # молча ищет спеку сам, и эталон снялся бы неизвестно с чего.
  if [[ -n "${SPEC_PLATFORM_DIR:-}" ]]; then
    if is_spec_root "${SPEC_PLATFORM_DIR}"; then
      echo "${SPEC_PLATFORM_DIR}"
      return
    fi
    echo "SPEC_PLATFORM_DIR=${SPEC_PLATFORM_DIR} — не корень спеки (нет openspec/ и workspace.yaml)" >&2
    exit 2
  fi
  # Переменная спеки в стиле AVTOTO_PLATFORM_DIR — её же читает приложение.
  local var="$(echo "${name}" | tr '[:lower:]-' '[:upper:]_')_PLATFORM_DIR"
  local from_var="${!var:-}"
  local candidate
  for candidate in \
    "${from_var}" \
    "${HOME}/webAnt-poject/${name}-platform" \
    "${HOME}/webant-project/${name}-platform" \
    "${HOME}/${name}-platform" \
    "${HOME}/${name}"; do
    if [[ -n "${candidate}" ]] && is_spec_root "${candidate}"; then
      echo "${candidate}"
      return
    fi
  done
  echo "спека \"${name}\" не найдена: задайте SPEC_PLATFORM_DIR или ${var}" >&2
  exit 2
}

normalize() {
  # Только то, что меняется от прогона к прогону: миллисекунды ответа
  # системы и отставание ветки. Счётчики требований `(5/5)` и задач —
  # смысл эталона, их трогать нельзя.
  sed -E 's/(systemResponds|repoBehind)\([0-9]+/\1(N/g'
}

if [[ "$mode" != "--save" && ! -f "$baseline" ]]; then
  echo "эталона нет: $baseline — сначала запустите с --save" >&2
  exit 2
fi

spec_dir="$(resolve_spec_dir)"
echo "спека: ${spec_dir}"
current="$(cd "$here/.." && SPEC_PLATFORM_DIR="$spec_dir" dart run tool/smoke.dart | normalize)"

if [[ "$mode" == "--save" ]]; then
  mkdir -p "$baseline_dir"
  printf '%s\n' "$current" > "$baseline"
  echo "эталон сохранён: $baseline ($(wc -l < "$baseline") строк)"
  exit 0
fi

if diff -u "$baseline" <(printf '%s\n' "$current"); then
  echo "совпадает с эталоном: ${name}"
else
  echo "расхождение с эталоном: ${name}" >&2
  exit 1
fi
