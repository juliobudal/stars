# Academy Module

> **🚧 Documento v1.** A Academy migrou para o modelo de **Formação Humana v2**
> em 2026-05-16. Veja [`docs/academy-v2.md`](./academy-v2.md) para a
> arquitetura atual (26 tabelas, 7 áreas, currículo invisível via conceitos +
> skills, spaced repetition, segredos, adaptação). Este doc é mantido como
> referência histórica do **contrato de isolamento de módulo** (§11), que
> permanece válido.

LLM-guided pedagogical missions for kids. Lives **inside** the host Rails app but is **isolated** under the `Academy::` namespace, so it can grow without coupling to the rest of LittleStars and serve as the template for future modules (e.g. Journal, Reading, Music).

> Status: shipped 2026-05-15. Currently exposes 6 subjects · 60 missions · 138 medals seeded by `db/seeds/academy.rb`.
>
> Curriculum reframed 2026-05-16 around six **knowledge areas × pílulas multi-autor**. Cada área de conhecimento agrega *sacadas* (pílulas) destiladas de autores e tradições diferentes — não está mais amarrado a "um livro = uma trilha". Uma pílula = 1 sacada poderosa = 2 sessões curtas. Slugs antigos seguem soft-deactivated (preserva progresso).
>
> ## Áreas (6, duráveis)
>
> | Área (slug)            | Pílulas vêm de…                                                              |
> |---|---|
> | `inteligencia`         | Feynman · Dweck · Newport · Polya · Sócrates · Loewenstein                   |
> | `carater`              | Marco Aurélio · Sêneca · Clear · Duckworth · Provérbios · Aristóteles · Holiday |
> | `relacionamentos`      | Carnegie · Covey · Gottman · Brené Brown · Rosenberg · Gordon · Dweck         |
> | `dinheiro`             | Kiyosaki · Housel · Munger · Cialdini · Provérbios · Robin                    |
> | `saude`                | Walker · Huberman · Pollan · Hipócrates · Bortz · Harris · Mark Divine        |
> | `fe-sentido`           | Provérbios · C.S. Lewis · Agostinho · Frankl · Tomás de Kempis · Havel        |
>
> ## Framework PÍLULA (toda sessão segue 6 beats)
>
> Síntese de: **Heath/SUCCESs**, **Loewenstein/curiosity gap**, **Ogilvy+AIDA**, **Sócrates**, **Feynman**, **Pixar pitch**. Definido em `Academy::Llm::GuidePersona::VOICE` e auditável no prompt.
>
> 1. **GANCHO** — fato, paradoxo ou cena (NUNCA definição)
> 2. **PONTE** — por que importa pra VOCÊ hoje
> 3. **SACADA** — a ideia + citação da fonte ("Carnegie descobriu…")
> 4. **EXEMPLO VIVO** — mini-história Pixar ou experimento mental
> 5. **CHECKPOINT SOCRÁTICO** — aplica em situação nova; opções armadas com erros típicos
> 6. **AMARRAR + GANCHO PRÓXIMA** — síntese + mistério (`next_hook`)
>
> ## Critérios pra escolher uma sacada (os 5 testes)
>
> Toda pílula nova deve passar nos 5: **(1) contra-intuitiva, (2) compressível em 1 imagem ou regrinha, (3) aplicável hoje, (4) source-credível, (5) memorável**.
>
> ## `Mission#angle` é estruturado
>
> O campo `angle` é lido pelo prompt do Guia em formato `FONTE / FRAMEWORK / SACADA / CONDUÇÃO`. Veja exemplos em `db/seeds/academy.rb`. Ao criar uma pílula nova, mantenha essa estrutura — o Guia depende dela pra citar a fonte e calibrar o exemplo.
>
> As 3 primeiras seções (FONTE, FRAMEWORK, SACADA) são parseadas pelo seed e populadas nas colunas dedicadas `academy_missions.source`, `.framework`, `.sacada`. A biblioteca parental (`/parent/academy/library`) usa essas colunas pra filtrar.
>
> ## Auditoria de qualidade (2 camadas)
>
> ```sh
> docker compose exec web bin/rails 'academy:quality_check[mission-slug]'
> docker compose exec web bin/rails 'academy:quality_check[mission-slug,skip_judge]'   # só heurística
> docker compose exec web bin/rails academy:quality_check_all                          # tudo (custa)
> ```
>
> 1. **Heurística determinística** (sem custo) — 11 checks estruturais: gancho não-proibido, fonte citada, checkpoint bem-formado, next_hook curto, etc. `Academy::QualityCheck#run_checks`.
>
> 2. **LLM-as-judge** (gpt-5-nano via OpenRouter, temp 0.0) — grade beat-a-beat (0-2 por beat × 6 beats = 0-12). Retorna JSON com per-beat score + nota, verdict (PASS/REVISE/FAIL), critique e rewrite_hint. Prompt do juiz em `Academy::Llm::JudgePersona`, rubrica detalhada com âncoras por nota.
>
> Use após editar o `GuidePersona`, ou periodicamente em CI. Vars: `ACADEMY_JUDGE_MODEL`, `ACADEMY_JUDGE_TEMPERATURE`, `ACADEMY_JUDGE_MAX_TOKENS`.

---

## 1. Why a module, not an engine?

A mountable Rails engine adds gemspec/host wiring overhead and friction in dev. We get the same isolation with strict namespacing:

- All AR models live under `app/models/academy/` and target tables prefixed `academy_*`.
- All services live under `app/services/academy/` and inherit from `Academy::ApplicationService` (which mirrors the host `ApplicationService` contract — same `Result` Data class).
- Controllers live under `app/controllers/{kid,parent}/academy/*`. They are the **only** part of the module that talks to the host (`current_profile`, layouts).
- HTTP routes are namespaced `/kid/academy/*` and `/parent/academy/*`.
- There is **no FK** from any `academy_*` table to a host table. Learners are referenced by `learner_id` only.
- Host → Module communication goes through `Academy::Learner.from_profile(current_profile)` and `Academy::*::Service.call(...)`. The reverse is forbidden.
- `strict_loading_by_default` is opted out at `Academy::ApplicationRecord` — services own the access patterns; lazy chains like `session.mission` are intentional inside the module.

To add a new module later: copy this contract — top-level namespace file with `Config`, `Learner`-style adapter, `app/models/<mod>/`, `app/services/<mod>/`, namespaced routes, and a `config/initializers/<mod>.rb`.

---

## 2. Stack

- LLM: DeepSeek (default `deepseek/deepseek-v4-flash` — lite/non-reasoning para latência baixa) via OpenRouter (OpenAI-compatible API). O client envia `reasoning: { enabled: false }` em todo request para garantir modo não-thinking em modelos híbridos.
- Transport: `Academy::Llm::Client` — thin Net::HTTP wrapper. `langchainrb` is on the Gemfile and can replace the transport later without touching the agent/persona layer.
- Persona: "O Guia" — authoritative, mysterious, fascinated. See `app/services/academy/llm/guide_persona.rb`.
- Structured output: every turn returns a strict JSON envelope (`narrative`, `checkpoint`, `session_complete`, `mission_complete`, `next_hook`) parsed by `Academy::Llm::Parser`.

---

## 3. Domain model

| Table | Purpose |
|---|---|
| `academy_subjects` | 6 áreas de conhecimento duráveis (ver tabela acima). Currículos antigos permanecem como linhas inativas (`active: false`) — preserva progresso. |
| `academy_missions` | "Pílulas" — sacadas individuais com `angle` estruturado em FONTE/FRAMEWORK/SACADA/CONDUÇÃO. Default 2 sessões por pílula. |
| `academy_missions` | 10 missions per subject. Each has `title`, `hook` (teaser), `angle` (unique LLM angle), `learning_objective`, `sessions_count` (default 4). |
| `academy_mission_progresses` | One row per `(learner_id, mission_id)`. Tracks `status` (not_started/in_progress/completed/mastered), `current_session_index`, `correct_checkpoints`, `total_checkpoints`. |
| `academy_sessions` | Sub-units of a mission (default 4). Each is one focused chat sub-conversation. |
| `academy_messages` | Chat history: `system` (LLM-only), `guide` (LLM's narrated reply), `learner` (kid's input or option pick). `metadata` jsonb carries checkpoint payload + session/mission completion flags. |
| `academy_medals` | Catalog: per-mission (completed / perfect) + per-subject tier (apprentice / adept / master). |
| `academy_medal_awards` | Awards to a learner. Unique on `(learner_id, medal_id)`. |

---

## 4. Mission flow

1. Kid taps **Academia** in the bottom nav → `/kid/academy/subjects`.
2. Picks a subject → list of 10 missions, locked sequentially (next unlocks after the previous is `completed` or `mastered`).
3. Picks a mission → `Academy::StartMission` creates progress + session 0 (idempotent — re-opening picks up where they were).
4. Chat view fires opening turn via `Academy::AdvanceTurn` (Stimulus `academy-chat` controller POSTs the first turn with no input → LLM opens with narrative + first checkpoint).
5. Kid picks a checkpoint option → `AdvanceTurn` scores it, persists the learner message with correctness, calls LLM for the next beat.
6. When the LLM marks `session_complete: true` → the current session is closed and the footer shows a **"Próxima sessão (N/M) →"** button (deliberate gesture so the kid reads the next-session hook before diving in).
7. When the LLM marks `mission_complete: true` or sessions run out → finalize: status `:completed` (or `:mastered` if every checkpoint was correct), `Medals::AwardForMission` runs.

### Session-complete UX rule

After every session the LLM is required to emit a `next_hook` (one-line mysterious teaser). The UI renders it as a dashed-bordered footer inside the last guide bubble. This is part of the persona contract — see `GuidePersona::VOICE`.

---

## 5. UI architecture (kid surface)

All views live under `app/views/kid/academy/`. Layout follows the global Duolingo system (see `DESIGN.md`) — green `--primary`, Nunito 700/800, 10–16px radii, `0 4px 0` 3D shadows, `prefers-reduced-motion` honored.

| File | Role |
|---|---|
| `subjects/index.html.erb` | Subject gallery with per-subject progress bars. |
| `subjects/show.html.erb` | Mission list with sequential lock (number / check / star / 🔒). |
| `missions/show.html.erb` | Chat screen wrapper. Sticky header (back + breadcrumb + session chip + dot progress strip), thread, footer slot. |
| `missions/turn.turbo_stream.erb` | Response template for `POST /turn`. Appends learner msg + new guide msg, replaces the footer slot, removes typing indicator. |
| `_message.html.erb` | Guide vs learner bubble. Checkpoint is **embedded inside the last guide bubble** when active — no overlapping floats. Learner bubble color reflects correctness (green=correct / red=wrong / sky=neutral). |
| `_checkpoint.html.erb` | 3-4 lettered options (A/B/C…) as full-width 3D buttons. Submits via `button_to` with `data: { turbo_stream: true }`. |
| `_composer.html.erb` | Pill-shaped free-text input + circular send button. Shown only when no open checkpoint and mission not finished. Disables itself on submit (Stimulus `academy-composer`). |
| `_next_session.html.erb` | Sky-blue 3D CTA between sessions — `Próxima sessão (N/M) →`. |
| `_celebration.html.erb` | Big gradient card at mission finish. Gold gradient if `mastered`, green otherwise. Shows `correct/total checkpoints`, links to subject + medals. |
| `_typing.html.erb` | 3-dot bouncing indicator while the LLM is generating the opening turn. |
| `_flash.html.erb` | Red toast for LLM errors. |
| `medals/index.html.erb` | Trophy grid of every medal the kid has earned. |

Stimulus controllers (auto-registered via `stimulus-vite-helpers`):

- `academy_chat_controller.js` — observes the thread and auto-scrolls; fires the opening turn on first render via `fetch` + `Turbo.renderStreamMessage`.
- `academy_composer_controller.js` — disables input + submit button on form submit so the kid can't double-fire while the LLM is thinking.

### Layout rules learned the hard way

- **No `sticky`/`fixed` on the composer or checkpoint.** Everything stays in the natural flow with `padding-bottom: 140px` on the screen wrapper to clear the floating kid nav. (An earlier `sticky bottom-[88px]` composer caused the checkpoint to overlap the guide text — never reintroduce that.)
- **Checkpoint is part of the guide bubble**, not a separate floating card. This keeps the visual cause-and-effect tight and avoids vertical jumps.
- **One CTA per state.** When a checkpoint is open, the composer is hidden. When a session ends, the composer is replaced by the "Próxima sessão" button. When the mission ends, both are replaced by the celebration. Never show two competing actions.

---

## 6. Parent surface

`/parent/academy` → `Parent::Academy::DashboardController#index`. Shows:

- A matrix of (child × subject) with `done/total` per cell.
- A list of the 10 most recent medal awards across all children.

No write surface for parents yet — the curriculum is seed-driven.

---

## 7. Configuration

Required env vars (drop into `.env`):

```
OPENROUTER_API_KEY=sk-or-v1-...
ACADEMY_LLM_MODEL=deepseek/deepseek-v4-flash      # optional — lite/non-reasoning para resposta rápida
ACADEMY_LLM_TEMPERATURE=0.7                        # optional
ACADEMY_LLM_MAX_TOKENS=900                          # optional
ACADEMY_LLM_REFERER=https://littlestars.app         # optional, OpenRouter HTTP-Referer header
ACADEMY_LLM_APP_TITLE=LittleStars Academy           # optional, OpenRouter X-Title header
```

The module is **inert without `OPENROUTER_API_KEY`** — `Kid::Academy::BaseController` redirects to `kid_root` with a friendly notice instead of attempting to call the LLM. Parent dashboard works without the key (read-only view of catalog + progress).

Config is read at boot by `config/initializers/academy.rb` into `Academy.config`. The module **never reads ENV directly** — always go through `Academy.config`.

---

## 8. Running

```sh
make migrate                                         # applies academy_* tables
make seed                                            # host data + chains db/seeds/academy.rb (idempotent)

# Refresh only the academy curriculum without touching host data:
docker compose exec -T web bin/rails runner db/seeds/academy.rb

# Full reset (drops + recreates host data + academy):
make db-reset
```

> `make db-reset` stops the `web` container during the drop and restarts it after. Required because Puma + Solid Queue + Solid Cable hold persistent Postgres connections that reconnect within ms, so `pg_terminate_backend` is not enough.

Specs:

```sh
make rspec spec/services/academy
```

---

## 9. Persona contract

See `Academy::Llm::GuidePersona::VOICE` for the full system prompt. Headline rules:

- Authoritative without arrogance. Direct, short sentences.
- Mysterious — never spill everything in one session; always close with `next_hook`.
- Fascinated by the subject; treats every topic like hidden treasure.
- Concrete — every lesson must convert to an action the kid can do today.
- Always responds with a strict JSON envelope (no prose outside it).
- Christian-virtues subject is grounded in tradition (Proverbs/Gospels/Psalms) without proselytizing — framed as character formation.

The persona prompt is prepended to **every** LLM call (see `GuidePersona.system_prompt`). Per-mission angle and learner age band are interpolated into the system message.

---

## 10. Extending the curriculum

Add new subjects/missions by editing `db/seeds/academy.rb` and re-running it (idempotent on `slug`). Medals are auto-generated per mission (`completed` + `perfect`) and per subject tier (`apprentice` / `adept` / `master`). Constants you can tune:

- `Academy::Mission#sessions_count` per row (default 4, max 8).
- `Academy::Medals::AwardForMission::TIER_THRESHOLDS` for what % of a subject unlocks each tier.

---

## 11. Adding a future module (template)

To add e.g. a `Journal` module that mirrors Academy's isolation:

1. `app/models/journal.rb` — top-level namespace with `Config` + adapter (`Journal::Author`).
2. `app/models/journal/application_record.rb` — abstract base, `self.strict_loading_by_default = false` if you want the same opt-out.
3. `app/models/journal/*.rb` — AR models with `self.table_name = "journal_*"`.
4. `app/services/journal/application_service.rb < ::ApplicationService`.
5. `db/migrate/<ts>_create_journal_module.rb` — single migration for all `journal_*` tables, no FKs into host.
6. `config/initializers/journal.rb` — read ENV → `Journal.configure`.
7. `app/controllers/{kid,parent}/journal/*` — the only place that bridges to host (`current_profile`).
8. Routes: `namespace :kid do; namespace :journal do; ...; end; end`.
9. Bottom-nav entry in `app/views/shared/_kid_nav.html.erb` with `active_prefix: "/kid/journal"`.
10. `docs/journal.md` — same structure as this file.

The host never imports anything from `Journal::` except through controllers and the public service entrypoints.
