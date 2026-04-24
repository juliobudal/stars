# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

LittleStars — gamified family task manager with "star economy" for kids. Rails 8 fullstack app.

- `PRD_LittleStars.md` — product spec
- `TECHSPEC.md` — authoritative architecture reference (models, services, routes, UI mapping)
- `.planning/` — GSD workflow artifacts (ROADMAP, REQUIREMENTS, codebase/)
- Current milestone: UI/UX Duolingo rebranding (MVP core done)

## Stack

Rails 8.1 · Ruby 3.3+ · PostgreSQL 16 · Vite + Propshaft · Tailwind 4 · Stimulus · Turbo · ViewComponent 4.7 · RSpec + FactoryBot + Capybara · Solid Queue/Cache/Cable · Kamal.

Dev environment is Devcontainer/Docker Compose. Run commands inside `web` container.

Background jobs/cache/cable backed by Solid {Queue,Cache,Cable} → Postgres. No separate worker process in dev (Solid Queue runs embedded in Puma when configured).

## Commands

- `bin/dev` — start Rails + Vite (uses `Procfile.dev`)
- `bin/setup` — fresh-clone bootstrap (bundle + db:prepare)
- `bin/rails db:prepare` — create + migrate + seed
- `bin/rails db:seed` — reseed only
- `bundle exec rspec` — full suite; `bundle exec rspec spec/services/tasks/approve_service_spec.rb:42` — single example
- `bin/rubocop` — lint (rubocop-rails-omakase + standard)
- `bin/brakeman` — security static analysis
- `bin/bundler-audit` — gem CVE scan
- `bin/ci` — runs full CI locally
- `bin/vite build` — asset build

## Architecture

Namespaced dual-interface app: `parent/` vs `kid/` routes, controllers, views, and components. Root `SessionsController` sets `session[:profile_id]` (no auth in MVP — just profile selection).

**Data model** (`Family` → `Profile{role: child|parent}` → `ProfileTask{status enum}` ↔ `GlobalTask`; `Reward`; `ActivityLog{log_type: earn|redeem}`). Points live on `Profile.points`; `ActivityLog` is the append-only ledger.

**Business logic lives in service objects** under `app/services/` (e.g. `Tasks::ApproveService`, `Rewards::RedeemService`, `Tasks::DailyResetService`). Services wrap multi-step mutations in `ActiveRecord::Base.transaction` and return `OpenStruct(success?:, error:)`. Controllers never mutate points directly — always go through a service.

**UI layer**: ViewComponents under `app/components/{kid,parent}/` for reusable cards/widgets. ERB views under `app/views/{kid,parent}/`. Two layouts: `layouts/kid.html.erb` (playful) and `layouts/parent.html.erb` (dashboard).

**Real-time**: Turbo Frames for partial updates (approval queue, balance). Turbo Streams broadcast from services (e.g. `ApproveService` broadcasts balance update to `"kid_#{profile.id}"` channel so kid's wallet live-updates when parent approves).

**Stimulus controllers** in `app/assets/controllers/` (Vite-served, auto-registered via `stimulus-vite-helpers` in `app/assets/controllers/index.js`). Add new `*_controller.js` files there — no manual registration needed.

## Conventions

- Enums use Rails 8 hash form: `enum :role, { child: 0, parent: 1 }`
- `ProfileTask` delegates `title/category/points` to `global_task` — views read directly off `profile_task`
- Never allow negative `Profile.points` — `RedeemService` rolls back transaction if balance goes negative after decrement
- Race conditions on points matter (concurrent approve/redeem): keep mutations inside transactions with `reload` checks
- Commits/PRs/code in English; conversational responses in Brazilian Portuguese per user workspace CLAUDE.md
