# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

LittleStars — gamified family task manager with "star economy" for kids. Rails 8 fullstack app.

- `PRODUCT.md` — product spec
- `TECHSPEC.md` — authoritative architecture reference (models, services, routes, UI mapping)
- `specs/001-academy-redesign/` — **authoritative** Academy spec (redesign 2026-05-28): `spec.md`, `plan.md`, `tasks.md`. Read before touching anything under `Academy::`.
- Current milestone: UI/UX Duolingo rebranding (MVP core done)
- Visual language: **Duolingo style** (green primary `#58CC02`, Nunito 700/800, 3D `0 4px 0` shadows, 10–16px radii). See `DESIGN.md` for the full system. Old Berry Pop / lilac / Fraunces tokens retired.

## Stack

Rails 8.1 · Ruby 3.3+ · PostgreSQL 16 · Vite + Propshaft · Tailwind 4 · Stimulus · Turbo · ViewComponent 4.7 · RSpec + FactoryBot + Capybara · Solid Queue/Cache/Cable · Kamal · OpenRouter (Academy chatbot only, via `Academy::Llm::Client`).

Dev environment is Devcontainer/Docker Compose. Run commands inside `web` container.

Background jobs/cache/cable backed by Solid {Queue,Cache,Cable} → Postgres. No separate worker process in dev (Solid Queue runs embedded in Puma when configured).

## Commands

Dev workflow is Docker Compose. Use `make` targets — they exec inside the `web` container. Running `bundle exec rspec` or `bin/rails` from the host fails (db host unreachable).

- `make setup` — full bootstrap (build image, migrate, seed)
- `make dev` / `make dev-detached` — start stack
- `make rspec` (alias `make test`) — full RSpec suite. For a single/path run: `make rspec SPEC=spec/services/tasks/approve_service_spec.rb` (or `make test ARGS='spec/...:42'`)
- `make lint` (alias `make rubocop`) — rubocop-rails-omakase
- `make lint-motion` — blocks raw motion durations in views/components
- `make lint-js` — JS syntax gate (`node --check` across frontend files)
- `make brakeman` · `make audit` · `make ci` — security + full CI
- `make migrate` · `make seed` · `make db-reseed` · `make reset` — db ops
- `make shell` — bash into web container · `make c` — rails console · `make shell-db` — psql
- `make routes` · `make assets-build`
- `make dokploy-deploy` / `dokploy-migrate` / `dokploy-logs` / `dokploy-status` / `dokploy-restart` / `dokploy-console` / `dokploy-db-reset` — production (Dokploy) wrappers

## Architecture

Namespaced dual-interface app: `parent/` vs `kid/` routes, controllers, views, and components. Two-tier session: `FamilySessionsController` (parent password login) → `ProfileSessionsController` (PIN-gated profile select, sets `session[:profile_id]`). Invitation + password reset flows live under `app/services/auth/` with corresponding mailers.

**Data model** (`Family` → `Profile{role: child|parent}`; `GlobalTask` assigned to profiles via the `GlobalTaskAssignment` join → materialized as `ProfileTask{status: pending|awaiting_approval|approved|rejected|missed|expired, source: catalog|custom}` with optional `proof_photo`; `Reward` → `Category`, redeemed via `Redemption{status: pending|approved|rejected}`; `ActivityLog{log_type: earn|redeem|adjust|decay}`; plus `ProfileInterest`, `ProfileInvitation`). Points live on `Profile.points`; `ActivityLog` is the append-only ledger and `Redemption` is the redeem record. `db/schema.rb` is authoritative.

**Business logic lives in service objects** under `app/services/` — namespaces: `tasks/`, `rewards/`, `auth/`, `streaks/`, `categories/`, `ui/`. All inherit `ApplicationService` (callable via `Service.call(...)`), wrap multi-step mutations in `ActiveRecord::Base.transaction`, and return `ApplicationService::Result = Data.define(:success, :error, :data)` via `ok(data)` / `fail_with(error)` helpers. Check `result.success?` then read `result.data` or `result.error`. Controllers never mutate points directly — always go through a service.

**UI layer**: ViewComponents under `app/components/{kid,parent}/` for reusable cards/widgets. ERB views under `app/views/{kid,parent}/`. Two layouts: `layouts/kid.html.erb` (playful) and `layouts/parent.html.erb` (dashboard).

**Real-time**: Turbo Frames for partial updates (approval queue, balance). Turbo Streams broadcast from services (e.g. `ApproveService` broadcasts balance update to `"kid_#{profile.id}"` channel so kid's wallet live-updates when parent approves).

**Stimulus controllers** in `app/assets/controllers/` (Vite-served, auto-registered via `stimulus-vite-helpers` in `app/assets/controllers/index.js`). Add new `*_controller.js` files there — no manual registration needed.

## Modules (isolated subsystems)

Sub-features that justify their own boundary live under a top-level namespace with prefixed tables and zero FK into host tables. They communicate with the host only through controllers and a `Module::Learner`-style value adapter. **Never reference host models (`Profile`, `Family`, ...) from inside a module.**

- **`Academy::`** — "Pílulas de Conhecimento" (redesign 2026-05-28, spec `specs/001-academy-redesign/`). Radicalmente simples: **5 tabelas** (`academy_trails`, `academy_lessons`, `academy_lesson_progresses`, `academy_guide_conversations`, `academy_guide_messages`). Modelo: **Trilha → Aulas (pílulas) ordenadas**, desbloqueadas em sequência. O v2/v4 (pokédex, conceitos/grafo, lens, signals, skills, ranks, segredos, wagers, lightning, missions/subjects) foi **removido**. All under `app/{models,services,controllers,views}/academy/` and `/kid/academy/*`, `/parent/academy/*`. Tables prefixed `academy_*`.

  **Formato da aula (método do mistério, conteúdo 100% curado em `db/seeds/academy.rb`)**: `enigma → pistas → revelação → teste → fisgada`, definido no `payload` jsonb de `Academy::Lesson` (`clues[]`, `revelation`, `check{}`, `hook`). O reveal passo-a-passo é client-side via `academy_pill_controller.js`. Serviços: `Lessons::Available` (status locked/available/completed), `Lessons::Complete` (idempotente). O único LLM em runtime é o chatbot "O Guia" (`Academy::Guide::Ask`, persona "authoritative + mysterious + fascinated") escopado a uma aula em `/kid/academy/trails/:slug/lessons/:slug/guide` — 5 perguntas/dia por kid, via DeepSeek/OpenRouter (env `OPENROUTER_API_KEY`). Sem a env, o botão 🦉 some e a aula funciona normal.

To add a new module, mirror the Academy contract: top-level namespace, prefixed tables, zero FK into host, communicate via controllers + a `Module::Learner` value adapter only.

## Conventions

- Enums use Rails 8 hash form: `enum :role, { child: 0, parent: 1 }`
- `ProfileTask` delegates `title/category/points` to `global_task` — views read directly off `profile_task`
- Never allow negative `Profile.points` — `RedeemService` rolls back transaction if balance goes negative after decrement
- Race conditions on points matter (concurrent approve/redeem): keep mutations inside transactions with `reload` checks
- Commits/PRs/code in English; conversational responses in Brazilian Portuguese per user workspace CLAUDE.md
- `make db-reset` stops `web` during the drop and brings it back up — Puma + Solid Queue hold persistent Postgres connections that reconnect within ms, so `pg_terminate_backend` is not enough. Keep this behavior when editing the Makefile target.
- `Academy::ApplicationRecord` opts out of `strict_loading_by_default` on purpose (services own access patterns inside the module). Don't mirror that pattern blindly in host models.

## UI work

Before writing or editing any view/component/stylesheet: **read `DESIGN.md`**. It is the single source of truth for tokens, components, motion, and a11y rules.

- Reach for `Ui::*` ViewComponents first; only write inline markup if no component fits (then add a row to DESIGN.md §6 in the same PR).
- All color/font/radius/shadow values via CSS variables from `app/assets/stylesheets/tailwind/theme.css`. Raw hex outside that file is forbidden.
- Any element with a depth shadow (`0 4px 0`) must honor the 3D motion contract (DESIGN.md §5) and `prefers-reduced-motion`.
- Do not reintroduce retired tokens: Fraunces, lilac `#A78BFA`, Berry Pop / Soft Candy shadows.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:
`specs/003-academy-content-arcs-next/plan.md`
<!-- SPECKIT END -->
