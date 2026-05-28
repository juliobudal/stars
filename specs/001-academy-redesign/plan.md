# Implementation Plan: Academy Redesign — Pílulas de Conhecimento

**Spec**: `specs/001-academy-redesign/spec.md`
**Branch**: `001-academy-redesign`
**Date**: 2026-05-28

## 1. Arquitetura-alvo (do complexo → simples)

```
TRILHA  (academy_trails)            ← tema ordenado, com gancho de arco
  └── AULA/PÍLULA (academy_lessons) ← conteúdo curado, formato enigma→fisgada
        └── progresso por aprendiz  ← academy_lesson_progresses (no-FK)

GUIA (opcional, LLM)
  academy_guide_conversations  (learner × lesson)
  academy_guide_messages
```

**5 tabelas** (era 25). **~2.000 LOC** alvo (era ~8.7k).

### O que MORRE (drop tables + delete code)
Tabelas: `academy_concepts`, `academy_concept_edges`, `academy_subjects`, `academy_trails`(antiga, recriada nova), `academy_missions`, `academy_discovery_cards`, `academy_mission_progresses`, `academy_sessions`, `academy_learner_concepts`, `academy_learner_signals`, `academy_learner_lens_visits`, `academy_lens_cache`, `academy_lens_signals`, `academy_pill_views`, `academy_lightning_round_runs`, `academy_learner_story_paths`, `academy_practice_wagers`, `academy_secrets`, `academy_secret_unlocks`, `academy_messages`.

Código: todos os models/services/controllers/views/specs/seeds das namespaces Cards, Compass, Connections, Lens, Missions, Pills, Pokedex, Secrets, Signals, Wagers, WisdomPills; admin/academy/*; parent/academy/{library,journeys,cards,practice_wagers}; kid/academy/{subjects,trails(antigo),missions,atlas,pills,lightning,cast,practice_wagers}.

### O que SOBREVIVE (reuso)
- `Academy` module config (`app/models/academy.rb`) — OpenRouter/DeepSeek.
- `Academy::Learner` value object + `from_profile`.
- `Academy::ApplicationService` + `Result` + `ApplicationRecord`.
- `Academy::Llm::Client` — sem mudança.
- `Academy::Guide::Persona` — voz/segurança/privacidade preservadas (conteúdo, não complexidade).
- `GuideConversation` / `GuideMessage` — recriadas apontando para `lesson_id`.
- `Academy::Guide::Ask` — adaptado (mission → lesson).
- Auth/sessão host + `Kid::Academy::BaseController` boundary.

## 2. Modelo de dados (migrations)

### `academy_trails` (recriar limpa)
| col | tipo | notas |
|---|---|---|
| slug | string | unique, not null |
| title | string | not null — nome curto (card) |
| hook | text | gancho do arco (1-2 frases) |
| accent | string | token de cor (não hex) — default "green" |
| emoji | string | ícone do card |
| position | integer | ordenação, not null |
| active | boolean | default true |

### `academy_lessons`
| col | tipo | notas |
|---|---|---|
| trail_id | bigint FK academy_trails | not null |
| slug | string | unique, not null |
| position | integer | not null; unique (trail_id, position) |
| title | string | rótulo curto p/ lista |
| enigma | string | pergunta-âncora (passo 1) |
| payload | jsonb | conteúdo estruturado (ver §3) |
| active | boolean | default true |

### `academy_lesson_progresses`
| col | tipo | notas |
|---|---|---|
| learner_id | bigint | no-FK; not null |
| lesson_id | bigint FK academy_lessons | not null |
| completed_at | datetime | |
| check_choice | integer | índice escolhido no teste (nullable) |
| check_correct | boolean | nullable |
| unique (learner_id, lesson_id) | | |

### `academy_guide_conversations` (recriar com lesson_id)
learner_id (no-FK), lesson_id (FK academy_lessons), prompt_version, started_at, closed_at, message_count (default 0), flagged (default false), flag_reasons (jsonb default []). unique (learner_id, lesson_id, started_at).

### `academy_guide_messages` (inalterada estruturalmente)
conversation_id (FK), role (int enum user/guide/system_note), content, tokens_in, tokens_out, flagged.

## 3. Schema do payload da aula (curado)

```jsonc
{
  "clues": ["micro-fato 1", "micro-fato 2", "micro-fato 3"],  // 2-4
  "revelation": "o insight central — frase que fica na cabeça",
  "check": {                                  // opcional (pode ser null)
    "kind": "multiple_choice",                // ou "predict"
    "prompt": "pergunta curta",
    "options": ["a", "b", "c"],
    "answer_index": 1,
    "explanation": "1 frase de feedback"
  },
  "hook": "fisgada p/ a próxima aula"
}
```

Validação no seed: cada aula tem `clues` (2-4), `revelation` (presente), `hook` (presente); se `check` existe, `answer_index` aponta para `options` válido.

## 4. Domínio / services

- `Academy::Lessons::Available(learner, trail)` — retorna o status de cada aula da trilha (`:completed | :available | :locked`) por regra sequencial (FR-002). Determinístico.
- `Academy::Lessons::Complete(learner, lesson, check_choice:)` — upsert idempotente em `LessonProgress`, grava `completed_at`, calcula `check_correct`. Retorna `ok(progress:, next_lesson:)`.
- `Academy::Guide::Ask` (adaptado) — agora `lesson:` em vez de `mission:`. Limite 5/dia por learner via contagem de `GuideMessage` role:user nas conversas do learner no dia (timezone do learner).
- `Academy::Guide::BuildPrompt` (reescrito simples) — monta system = `Persona::VOICE` + bloco "ESTA AULA" (enigma + revelation + clues + título da trilha). Sem Concept/Lens/edges.
- `Academy::Guide::FindOrStartConversation` (adaptado) — `lesson:`.
- Remover `Guide::Available` (lógica de quota migra para `Ask`) ou simplificar.

## 5. Rotas (kid + parent)

```ruby
# kid
namespace :academy do
  root to: "trails#index"                       # home
  resources :trails, only: %i[show], param: :slug do
    resources :lessons, only: %i[show], param: :slug do
      member { post :complete }
      resource :guide, only: %i[show create], controller: "guides"
    end
  end
end
# parent
namespace :academy do
  get "/", to: "dashboard#index", as: :dashboard   # read-only progresso
end
```
Admin academy: removido por ora (conteúdo é seed; sem CMS no MVP).

## 6. Controllers
- `Kid::Academy::BaseController` — mantém (boundary).
- `Kid::Academy::TrailsController#index` (home: trilhas + progresso + próxima aula), `#show` (aulas da trilha com status).
- `Kid::Academy::LessonsController#show` (render do conteúdo + estado concluído), `#complete` (chama service, redireciona/stream p/ próxima).
- `Kid::Academy::GuidesController#show/#create` (chat).
- `Parent::Academy::DashboardController#index` (read-only).

## 7. Views (Duolingo / DESIGN.md)
- `kid/academy/trails/index.html.erb` — grid de cards de trilha (emoji, título, hook, progresso x/y, CTA).
- `kid/academy/trails/show.html.erb` — lista vertical de aulas (estilo "trilha" Duolingo: nós available/locked/completed).
- `kid/academy/lessons/show.html.erb` — a pílula. Stimulus controller `academy_pill_controller.js` gerencia os passos (enigma → pistas tap-a-tap → revelação → teste → fisgada) client-side. Reuso `Ui::*` onde der.
- `kid/academy/guides/show` + `_message` partial — chat (reaproveitar layout existente simplificado).
- `parent/academy/dashboard/index.html.erb` — tabela simples.

Stimulus: `academy_pill_controller.js` (novo, passos da pílula). Remover controllers JS antigos do academy (loading overlay, lightning, etc.) se órfãos.

## 8. Seed de conteúdo (novo, anti-clichê)
`db/seeds/academy.rb` reescrito: cria 3-4 trilhas, ≥4 aulas cada, conteúdo original no método do mistério. Trilhas candidatas (decido na implementação, anti-clichê):
- "Seu cérebro mente pra você" (ilusões/percepção/memória)
- "Por que o corpo faz isso?" (cosquinha, soluço, arrepio, bocejo — fenômenos cotidianos com explicação real)
- "Coisas invisíveis que mandam em você" (hábito, dopamina, atrito, default — mas contado por fenômenos, não jargão)
- (talvez) "O dinheiro é uma ilusão coletiva" (valor, troca, escassez)

Conteúdo escrito por subagent + REVISÃO obrigatória minha (sem clichê, factualmente correto, tom misterioso). Context7/pesquisa quando precisar checar fato.

## 9. Limpeza (ordem segura)
1. Migrations: criar tabelas novas (trails/lessons/lesson_progresses) + recriar guide_* com lesson_id.
2. Migrations: drop das 20 tabelas mortas (depois que nada referencia).
3. Deletar arquivos de código legado (models/services/controllers/views/specs/seeds/JS).
4. Atualizar rotas, factories, e qualquer referência host (ex.: links no menu kid para `/kid/academy`).
5. `make migrate` + `make seed` + `make rspec` verdes.

## 10. Testes
- Model specs: Trail, Lesson, LessonProgress (unicidade, validações de payload).
- Service specs: `Lessons::Available` (locked/available/completed), `Lessons::Complete` (idempotência, check_correct), `Guide::Ask` (quota 5/dia, no_llm_key, lesson scope).
- Request specs: trails#index/show, lessons#show/#complete, guides#create (stub LLM).
- System (Capybara): fluxo completo home→trilha→aula→concluir→próxima.
- **Playwright E2E**: smoke real no app rodando (make dev) — login kid → home → trilha → aula → conclusão → próxima desbloqueada.

## 11. Riscos
- Remoção em massa quebrar referências host (menus, dashboards que linkam academy). Mitigação: grep por `academy_` e rotas antes do drop; rodar suite completa.
- Factories/specs host referenciando models removidos. Mitigação: limpar `spec/factories/academy.rb` e specs órfãos no mesmo PR.
- Guia depende de env em runtime; testes stubam `Llm::Client`.
