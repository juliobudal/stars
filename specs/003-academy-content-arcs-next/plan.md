# Implementation Plan: Academy — Próximas Trilhas (priorizadas por qualidade)

**Branch**: `003-academy-content-arcs-next` | **Date**: 2026-05-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-academy-content-arcs-next/spec.md`

## Summary

Ampliar o catálogo do Academy de 5 para **7 trilhas ativas**, priorizando por **qualidade de conteúdo** (escore de 6 eixos, FR-101). Entrega obrigatória = as 2 trilhas Tier S, cada uma com 4 aulas no formato pílula (enigma → pistas → revelação → teste → fisgada):

- **T6 `tudo-quase-vazio`** — "Tudo que parece sólido é quase vazio" (átomos/vazio/toque).
- **T7 `voce-feito-de-estrelas`** — "Você é feito de estrelas mortas" (nucleossíntese/ciclo da matéria).

Fecha a ponta solta atual: `as-palavras-mudam` → `tudo-quase-vazio` → `voce-feito-de-estrelas` → gancho aberto. **Zero schema**: tudo vive no `payload` jsonb de `Academy::Lesson` e nos metadados de arco do seed (`db/seeds/academy_content.rb`), reusando `Academy::Content::ArcValidator` como gate de qualidade (build + CI). A abordagem é curadoria de conteúdo disciplinada por validação — nenhuma engenharia de modelo.

## Technical Context

**Language/Version**: Ruby 3.3+ / Rails 8.1 (conteúdo é Ruby data em `db/seeds/`)

**Primary Dependencies**: Nenhuma nova. Reusa `Academy::Content::ArcValidator`, `Academy::Lessons::Available/Complete`, reveal client-side `academy_pill_controller.js`, layout/views de aula existentes.

**Storage**: PostgreSQL (tabelas `academy_*` já existentes). **Sem migration** — nenhuma coluna/tabela nova.

**Testing**: RSpec via `make rspec`. Gate de conteúdo: `spec/seeds/academy_content_spec.rb` (roda `ArcValidator` sobre o conjunto completo). Validação também no build do seed (`db/seeds/academy.rb` faz `raise` se houver violação).

**Target Platform**: App web Rails (kid em `/kid/academy/*`).

**Project Type**: Web app fullstack (módulo isolado `Academy::`).

**Performance Goals**: Conclusão de uma aula em ≤ 3 min (SC-104) — o arco não alonga a pílula individual.

**Constraints**: Banda etária única ~7–10; só conteúdo (payload + seed + views existentes); zero schema; honrar DESIGN.md / `prefers-reduced-motion`; respeitar os mecanismos do `ArcValidator` (frase de refrão contígua na revelação; callback/marker por word-start; cliffhanger nomeia o título exato da trilha-destino).

**Scale/Scope**: +2 trilhas × 4 aulas = 8 aulas novas + 1 edição de fisgada na trilha existente `as-palavras-mudam`. Backlog priorizado (Tier A/B) documentado, não implementado.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

A `.specify/memory/constitution.md` está em estado de **template não preenchido** (placeholders) — não há princípios ratificados que imponham gates formais a esta feature. Na ausência de constituição ratificada, aplico as restrições de fato do projeto (CLAUDE.md / spec de `002`) como gates substitutos:

| Gate (de fato) | Status | Nota |
|---|---|---|
| Módulo isolado: zero FK no host, sem referência a `Profile/Family` | ✅ Pass | Conteúdo é dado puro em `academy_*`; nada toca o host. |
| Zero schema novo (≤6 tabelas `academy_*`) | ✅ Pass | FR-108 — nenhuma migration. |
| Reuso de `Ui::*` e tokens DESIGN.md; sem UI nova | ✅ Pass | FR-111 — renderização inalterada. |
| Gate de qualidade por validação (build + CI) | ✅ Pass | FR-106 — reusa `ArcValidator`. |
| Sem regressão nas 5 trilhas atuais | ✅ Pass | FR-104/109 — única edição é `as-palavras-mudam.cliffhanger_to` + `hook` da última aula. |

Nenhuma violação. **Complexity Tracking** vazio (sem desvios a justificar).

## Project Structure

### Documentation (this feature)

```text
specs/003-academy-content-arcs-next/
├── plan.md              # Este arquivo
├── research.md          # Fase 0 — enigmas travados + base factual + mecânica do validador
├── data-model.md        # Fase 1 — shape do payload + metadados de arco (sem schema novo)
├── quickstart.md        # Fase 1 — como seedar, validar e conferir no browser
├── contracts/
│   └── arc-content.contract.md   # Contrato de conteúdo que o ArcValidator exige
├── checklists/
│   └── requirements.md  # Checklist de qualidade da spec (do /speckit-specify)
└── tasks.md             # Fase 2 (/speckit-tasks — NÃO criado aqui)
```

### Source Code (repository root)

```text
db/seeds/
├── academy_content.rb   # ALTERAR: +2 trilhas (T6, T7) na constante ACADEMY_CONTENT;
│                        #          editar as-palavras-mudam.cliffhanger_to + hook final
└── academy.rb           # INALTERADO (já consome ACADEMY_CONTENT via ArcValidator)

app/services/academy/content/
└── arc_validator.rb     # INALTERADO (régua reusada como está)

spec/seeds/
└── academy_content_spec.rb  # ALTERAR se necessário: assertivas de contagem (5→7 trilhas)
                              # e dos novos slugs/cadeia de cliffhanger

app/views/kid/academy/        # INALTERADO — as aulas novas renderizam no fluxo existente
app/assets/controllers/academy_pill_controller.js  # INALTERADO
```

**Structure Decision**: Feature de **conteúdo dentro do módulo `Academy::`**. Toda a mudança concentra-se em `db/seeds/academy_content.rb` (a fonte única de verdade do conteúdo) e nas assertivas de `spec/seeds/academy_content_spec.rb`. Nenhum modelo, controller, view, componente ou asset novo. O motor (services/reveal/Guia) e o validador são reusados intactos.

## Complexity Tracking

> Sem violações de constituição/gates de fato. Nada a justificar.
