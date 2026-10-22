# Change'и по плану совместимости с оригинальным OpenSpec

Каждый change — этап `docs/openspec-upstream-plan.md`. Порядок и зависимости:

| Этап плана | Change | Зависит от | Объём |
|---|---|---|---|
| 0 | `add-upstream-test-bench` ✓ в архиве | — | S |
| 1 | `resolve-schema-like-upstream` ✓ в архиве | 0 | M |
| 2 | `add-work-stage-and-tracker-port` | 1 | M |
| 3 | `support-upstream-commands` ✓ в архиве | 1 (стадия — 2) | M |
| 4 | `add-extension-registry` | 2, 3 | L |
| 5 | `show-specs-in-docs` ✓ в архиве | 1 | S |
| 6 | `split-core-and-extensions` | 4 | M (+M локаль) |
| 7 | `add-openspec-cli-source` | 1, 4 | M, по желанию |
| 8 | `document-boundaries` | 4, 6 | S |
| 9 | `add-second-adapters` | 4, 6 | L |
| 10 | `add-agent-cli-port` | 3 (файлы — 6) | L |
| 10 | `add-light-theme-and-settings` | 6, `add-agent-cli-port` | M |
| 10 | `add-windows-and-distribution` | 6 | M |

**Совместимость с upstream** — этапы 0–3 (+5). **Открытый выпуск** — плюс
4 и 6, из 9 — адаптер GitHub, из 10 — порт агентных CLI и дистрибуция с
подписью.

Работа с change'ами — командами `/opsx:apply <change>`, `/opsx:update`,
`/opsx:archive` в Claude Code (файлы в `.claude/`), или CLI:
`openspec status --change <id>`, `openspec validate --changes --strict`.
Этап 4 нельзя начинать без живых спек avtoto и avelacom и эталонов «до»
(задача 2.3 в `archive/2026-10-15-add-upstream-test-bench`, сделана).
