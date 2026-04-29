# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

LittleStars — gamified family task manager with "star economy" for kids. Rails 8 fullstack app.

- `PRD_LittleStars.md` — product spec
- `TECHSPEC.md` — authoritative architecture reference (models, services, routes, UI mapping)
- `.planning/` — GSD workflow artifacts (ROADMAP, REQUIREMENTS, codebase/)
- Current milestone: UI/UX Duolingo rebranding (MVP core done)
- Visual language: **Duolingo style** (green primary `#58CC02`, Nunito 700/800, 3D `0 4px 0` shadows, 10–16px radii). See `DESIGN.md` for the full system. Old Berry Pop / lilac / Fraunces tokens retired.

## Stack

Rails 8.1 · Ruby 3.3+ · PostgreSQL 16 · Vite + Propshaft · Tailwind 4 · Stimulus · Turbo · ViewComponent 4.7 · RSpec + FactoryBot + Capybara · Solid Queue/Cache/Cable · Kamal.

Dev environment is Devcontainer/Docker Compose. Run commands inside `web` container.

Background jobs/cache/cable backed by Solid {Queue,Cache,Cable} → Postgres. No separate worker process in dev (Solid Queue runs embedded in Puma when configured).

## Commands

Dev workflow is Docker Compose. Use `make` targets — they exec inside the `web` container. Running `bundle exec rspec` or `bin/rails` from the host fails (db host unreachable).

- `make setup` — full bootstrap (build image, migrate, seed)
- `make dev` / `make dev-detached` — start stack
- `make rspec` (alias `make test`) — full RSpec suite. For a single example: `make shell` then `bundle exec rspec spec/services/tasks/approve_service_spec.rb:42` inside the container
- `make lint` (alias `make rubocop`) — rubocop-rails-omakase + standard
- `make brakeman` · `make audit` · `make ci` — security + full CI
- `make migrate` · `make seed` · `make db-reseed` · `make reset` — db ops
- `make shell` — bash into web container · `make c` — rails console · `make shell-db` — psql
- `make routes` · `make assets-build`

## Architecture

Namespaced dual-interface app: `parent/` vs `kid/` routes, controllers, views, and components. Two-tier session: `FamilySessionsController` (parent password login) → `ProfileSessionsController` (PIN-gated profile select, sets `session[:profile_id]`). Invitation + password reset flows live under `app/services/auth/` with corresponding mailers.

**Data model** (`Family` → `Profile{role: child|parent}` → `ProfileTask{status enum}` ↔ `GlobalTask`; `Reward`; `ActivityLog{log_type: earn|redeem}`). Points live on `Profile.points`; `ActivityLog` is the append-only ledger.

**Business logic lives in service objects** under `app/services/` — namespaces: `tasks/`, `rewards/`, `auth/`, `streaks/`, `categories/`, `ui/`. All inherit `ApplicationService` (callable via `Service.call(...)`), wrap multi-step mutations in `ActiveRecord::Base.transaction`, and return `ApplicationService::Result = Data.define(:success, :error, :data)` via `ok(data)` / `fail_with(error)` helpers. Check `result.success?` then read `result.data` or `result.error`. Controllers never mutate points directly — always go through a service.

**UI layer**: ViewComponents under `app/components/{kid,parent}/` for reusable cards/widgets. ERB views under `app/views/{kid,parent}/`. Two layouts: `layouts/kid.html.erb` (playful) and `layouts/parent.html.erb` (dashboard).

**Real-time**: Turbo Frames for partial updates (approval queue, balance). Turbo Streams broadcast from services (e.g. `ApproveService` broadcasts balance update to `"kid_#{profile.id}"` channel so kid's wallet live-updates when parent approves).

**Stimulus controllers** in `app/assets/controllers/` (Vite-served, auto-registered via `stimulus-vite-helpers` in `app/assets/controllers/index.js`). Add new `*_controller.js` files there — no manual registration needed.

## Conventions

- Enums use Rails 8 hash form: `enum :role, { child: 0, parent: 1 }`
- `ProfileTask` delegates `title/category/points` to `global_task` — views read directly off `profile_task`
- Never allow negative `Profile.points` — `RedeemService` rolls back transaction if balance goes negative after decrement
- Race conditions on points matter (concurrent approve/redeem): keep mutations inside transactions with `reload` checks
- Commits/PRs/code in English; conversational responses in Brazilian Portuguese per user workspace CLAUDE.md

## UI work

Before writing or editing any view/component/stylesheet: **read `DESIGN.md`**. It is the single source of truth for tokens, components, motion, and a11y rules.

- Reach for `Ui::*` ViewComponents first; only write inline markup if no component fits (then add a row to DESIGN.md §6 in the same PR).
- All color/font/radius/shadow values via CSS variables from `app/assets/stylesheets/tailwind/theme.css`. Raw hex outside that file is forbidden.
- Any element with a depth shadow (`0 4px 0`) must honor the 3D motion contract (DESIGN.md §5) and `prefers-reduced-motion`.
- Do not reintroduce retired tokens: Fraunces, lilac `#A78BFA`, Berry Pop / Soft Candy shadows.
