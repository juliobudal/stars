# Implementation Plan: Academy — Arcos Narrativos nas Trilhas

**Branch**: `002-academy-content-arcs` | **Date**: 2026-05-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/002-academy-content-arcs/spec.md`

## Summary

Aprofundar o conteúdo das trilhas do Academy aplicando 5 padrões de arco (pagamento de arco, refrão recorrente, callback, cliffhanger cruzado nominal, anti-clichê) — **sem mudar schema**. A entrega é majoritariamente **curadoria de conteúdo** em `db/seeds/academy.rb`, sustentada por um **validador de arco** reaproveitável (seed + spec) que torna os padrões verificáveis e barra regressões no build/CI.

## Technical Context

**Language/Version**: Ruby 3.3+, Rails 8.1
**Primary Dependencies**: nenhuma nova. Usa `Academy::Trail`/`Academy::Lesson` (já existentes), seed Ruby, RSpec.
**Storage**: PostgreSQL — **sem migration**. Conteúdo em `Academy::Lesson#payload` (jsonb) já existente. Metadados de arco (refrão, slug-destino do cliffhanger) vivem só na **fonte do seed**, não persistidos.
**Testing**: RSpec (`make rspec`). Novo spec valida o conteúdo curado contra os 5 padrões.
**Target Platform**: app web Rails (interface `kid/`).
**Project Type**: módulo isolado `Academy::` dentro do monólito Rails (web).
**Performance Goals**: aula jogável em ≤3 min (inalterado); seed roda sem regressão de tempo perceptível.
**Constraints**: zero schema novo; ≤6 tabelas `academy_*`; isolamento do módulo (sem FK/refs a models host); DESIGN.md (Duolingo) para qualquer view.
**Scale/Scope**: 5 trilhas × ≥4 aulas (≈20–24 aulas curadas). ~1 validador + 1 spec + ajustes mínimos de view (opcional).

## Constitution Check

O `constitution.md` do projeto é um template não preenchido; as regras vinculantes são as do `CLAUDE.md`. Checagem contra elas:

- **Isolamento do módulo Academy** ✅ — nada toca `Profile`/`Family`; só conteúdo + validador interno ao módulo.
- **Zero schema / ≤6 tabelas** ✅ — FR-007; nenhuma migration. Metadados de arco ficam na fonte do seed.
- **Lógica em objetos / testável** ✅ — validador de arco é um objeto Ruby puro, exercitado por spec (não código solto no seed).
- **DESIGN.md para UI** ✅ — sem novas views obrigatórias; se houver ajuste, reusa `Ui::*` e tokens.
- **Conteúdo formativo cristão permitido** ✅ — versículos como "achado", nunca moralização (FR-005/FR-011).
- **Commits/código em inglês; conversa em pt-BR** ✅ — conteúdo das aulas é pt-BR (é o produto); nomes de código/seed em inglês.

**Resultado**: PASS. Nenhuma violação → seção *Complexity Tracking* vazia.

## Abordagem técnica

### 1. Extrair a fonte de conteúdo (testável)

Hoje a array de trilhas é local dentro de `db/seeds/academy.rb`. Para validar em spec sem rodar o seed inteiro, extrair a estrutura de dados para um ponto carregável por ambos:

- `db/seeds/academy_content.rb` retorna a constante/array `ACADEMY_CONTENT` (trilhas → aulas → payload) **+ metadados de arco por trilha**: `refrao:` (string) e `cliffhanger_to:` (slug-destino, ou `nil` para a última do conjunto).
- `db/seeds/academy.rb` passa a (a) `require` essa fonte, (b) rodar o validador, (c) criar os registros. Mantém idempotência atual (delete_all + recreate).

### 2. Validador de arco (`Academy::Content::ArcValidator`)

Objeto Ruby puro em `app/services/academy/content/arc_validator.rb` (dentro do módulo, sem host refs). Recebe a estrutura de conteúdo e retorna lista de violações (vazia = ok). Regras (cobrindo FR-010):

1. **Cliffhanger** (FR-004): para cada trilha com `cliffhanger_to` presente, o slug existe no conjunto e a trilha-destino está `active`; a última do conjunto tem `cliffhanger_to: nil`. (Opcional fraco: o `hook` da última aula menciona um termo do título-destino.)
2. **Refrão** (FR-002): `refrao` declarado aparece (substring, case-insensitive, com normalização leve) em cada aula da trilha — checado contra `revelation` (núcleo) com fallback para clues/hook.
3. **Callback** (FR-003): trilhas com 2+ aulas — a última aula compartilha um token significativo (palavra-chave declarada ou heurística) com a aula 1. Para robustez, usar um campo `callback_anchor:` declarado por trilha (palavra/expressão que deve aparecer na aula 1 **e** na última).
4. **Pagamento de arco** (FR-001): declarar `arc_payload_marker:` por trilha — um trecho/ideia do `hook` de abertura da trilha que deve reaparecer na `revelation`/`clues` da última aula. Validação confere presença.
5. **Anti-clichê** (FR-005): `BANNED_PHRASES` (lista negra: "reflita sobre", "moral da história", "nunca desista", "acredite em você", "siga seus sonhos", "o importante é…", etc.) — nenhuma pode aparecer em nenhum texto de conteúdo (enigma/clues/revelation/check/hook/title/trail.hook).

Decisão de design: declarar âncoras explícitas (`refrao`, `callback_anchor`, `arc_payload_marker`, `cliffhanger_to`) torna FR-001..FR-004 **deterministicamente verificáveis** sem NLP, mantendo o critério honesto (a curadoria precisa realmente escrevê-las no conteúdo).

### 3. Spec de conteúdo (CI gate)

`spec/seeds/academy_content_spec.rb`:
- Carrega `ACADEMY_CONTENT`, roda `ArcValidator`, espera **zero violações**.
- Asserta SC-005 (5 trilhas, cada uma ≥4 aulas).
- Asserta que cada aula construída passa em `Academy::Lesson#payload_well_formed` (sanidade de payload).

Isso entrega SC-001..SC-004 e SC-007 como testes verdes, e protege contra regressão futura.

### 4. Produção/curadoria de conteúdo

- **Reescrever as 3 trilhas existentes** (cérebro, corpo, forças invisíveis) adicionando refrão, callback na última aula, pagamento de arco e cliffhanger curado nominal. Preservar fatos/checks corretos (sem regressão de qualidade — US4).
- **Criar 2 trilhas novas**: "A luz é uma notícia velha" (luz/astronomia; refrão "toda luz é uma notícia atrasada") e "As palavras mudam o que você enxerga" (linguagem/percepção; com Provérbios 18:21 como achado).
- Costurar a **teia de cliffhangers** entre as 5 (curada): cada trilha aponta para outra existente; uma é a "última do conjunto" (gancho aberto).

### 5. Views (mínimo / opcional)

Nenhuma view nova é obrigatória — o arco vive no texto já renderizado (enigma da trilha como gancho de abertura; `hook` da última aula como cliffhanger). Ajuste **opcional**, se necessário pra realçar o fechamento: leve destaque na última aula via parcial existente, reusando `Ui::*` e tokens (FR-013). Decidir durante a implementação; não bloqueia o valor.

## Project Structure

### Documentation (this feature)

```text
specs/002-academy-content-arcs/
├── plan.md              # Este arquivo
├── spec.md              # Especificação (com Clarifications)
├── tasks.md             # Saída do /speckit-tasks
└── checklists/
    └── requirements.md  # Checklist de qualidade do spec (passou)
```

### Source Code (repository root)

```text
db/seeds/
├── academy.rb            # ALTERA: require da fonte + roda validador + cria registros
└── academy_content.rb    # NOVO: ACADEMY_CONTENT (5 trilhas + metadados de arco)

app/services/academy/content/
└── arc_validator.rb      # NOVO: valida os 5 padrões; retorna violações

spec/seeds/
└── academy_content_spec.rb   # NOVO: gate de CI dos 5 padrões + SC-005

# app/views/kid/academy/...   # OPCIONAL: realce de fechamento (só se necessário)
```

**Structure Decision**: monólito Rails, módulo `Academy::`. Tudo novo fica sob o namespace do módulo (`app/services/academy/content/`, `db/seeds/academy_content.rb`) e sob `spec/seeds/`. Nenhuma mudança em models, controllers ou migrations.

## Complexity Tracking

*Nenhuma violação de constituição/convenções — seção vazia.*

## Riscos & mitigações

- **Refrão/callback "forçado" no texto**: âncoras declaradas podem tentar curadoria preguiçosa (colar a string). Mitigação: revisão humana além do lint; o refrão deve **escalar de sentido**, não só repetir (critério de review).
- **Lista negra incompleta**: lint pega só o óbvio. Mitigação: checklist de revisão por trilha cobre o resto (clichê é qualitativo).
- **Reescrita regredir conteúdo bom**: US4 AC-2 + spec de payload bem-formado. Preservar fatos/checks já corretos.
- **Seed mais lento/maior**: desprezível (apenas mais texto); idempotência mantida.
