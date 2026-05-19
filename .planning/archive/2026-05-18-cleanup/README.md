# Doc cleanup — 2026-05-18

Consolidação 80/20 dos docs do repo. Arquivado aqui o que estava superseded, concluído ou redundante. Originais preservados para rastreabilidade.

## Operating set atual (após o cleanup)

- **Raiz:** `CLAUDE.md`, `DESIGN.md`, `README.md`, `PRD_LittleStars.md`, `TECHSPEC.md`
- **`docs/`:** `academy-v2.md` (canônico), `academy-lesson-structure.md` (camadas de geração de aula)
- **`.planning/designs/`:** `academy-v4-spec.md`, `academy-v4-tasks.md`, `casa-magica/`
- **`.planning/audits/`:** `academy-v2-brutal-review-2026-05-16.md`, `2026-05-17-academy-lens-v3-followups.md`

## O que foi arquivado e por quê

| Arquivo / dir                                        | Motivo                                                   |
| ---------------------------------------------------- | -------------------------------------------------------- |
| `root/todo.md`                                       | 24/24 itens concluídos (review 2026-05-06)              |
| `docs/academy-v1.md`                                 | Marcado como histórico no próprio doc; v2 é canônico    |
| `docs/academy-v2-pending.md`                         | Pós-shipping checklist; itens 1-12 entregues             |
| `planning/PROJECT.md` · `QUESTIONS.md` · `REQUIREMENTS.md` | Milestone 2 (Duolingo rebrand) — concluído              |
| `planning/ROADMAP.md` · `STATE.md` · `SESSION-HANDOFF.md` | GSD state; fases 1-7 entregues (15/15 plans)          |
| `designs/academy-v3-vision.md` · `v3.1-adventure.md` | Superseded por `academy-v4-spec.md`                      |
| `designs/motion-improvement-plan.md`                 | Entregue em `c47867a refactor(motion): unify motion …`  |
| `phases/06-wishlist-goal-tracking/` · `07-pwa/`      | Fases concluídas                                         |
| `debug/kid-mission-click-no-action.md`               | `status: resolved` no frontmatter                        |
| `ui-reviews/*`                                       | Reviews históricas (Apr 2026)                            |
| `audits/2026-05-13-frontend-mobile-responsiveness.md`| Endereçada em Phase 5.4                                  |
| `codebase/*`                                         | Snapshot 2026-04-21; redundante com `CLAUDE.md`+`TECHSPEC.md` |

## Como restaurar

```bash
git mv .planning/archive/2026-05-18-cleanup/<path> <destino-original>
```
