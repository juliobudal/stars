# LittleStars

Gamified family task manager with a "star economy" for kids. Rails 8 fullstack app.

## Docs

- [`PRODUCT.md`](./PRODUCT.md) — product spec (users, purpose, brand, anti-references, a11y)
- [`TECHSPEC.md`](./TECHSPEC.md) — architecture reference (models, services, routes; §13 = Academy module)
- [`DESIGN.md`](./DESIGN.md) — Duolingo-style design system (tokens, components, motion, a11y)
- [`specs/001-academy-redesign/`](./specs/001-academy-redesign/) — **authoritative** Academy spec (the 2026-05-28 "Pílulas de Conhecimento" redesign)
- [`CLAUDE.md`](./CLAUDE.md) — agent guidance, stack, commands, conventions

## Modules

- **Core (`Family` / `Profile` / `GlobalTask` / `ProfileTask` / `Reward` / `Redemption` / `ActivityLog`)** — gamified star economy: parents configure tasks → kid does them → parents approve → stars credited → kid redeems rewards. See `TECHSPEC.md` §3–§8.
- **Academy (`Academy::*`, `/kid/academy/*`)** — isolated learning module. Model: **Trilha → Aulas (pílulas)** unlocked in sequence, each built on the *método do mistério*. `academy_*` tables, zero FK into host. The only runtime LLM is the "O Guia" chatbot (DeepSeek via a custom OpenRouter client). Set `OPENROUTER_API_KEY` to enable it; without it the lessons work and the 🦉 button just disappears. See `specs/001-academy-redesign/`.

## Stack

Rails 8.1 · Ruby 3.3+ · PostgreSQL 16 · Vite + Propshaft · Tailwind 4 · Stimulus · Turbo · ViewComponent 4.7 · RSpec + FactoryBot + Capybara · Solid Queue/Cache/Cable · Kamal · custom `Net::HTTP` OpenRouter client (`Academy::Llm::Client`, Academy chatbot only — no langchain/openai gems).

## Run

Dev runs in Docker Compose; commands exec inside the `web` container via `make` (running `bundle exec rspec` / `bin/rails` from the host fails — the DB host is unreachable).

```sh
make setup        # full bootstrap: build image, migrate, seed
make dev          # start the stack (foreground)
make rspec        # full test suite (alias: make test)
make lint         # rubocop (alias: make rubocop)
make lint-motion  # block raw motion durations in views/components
make lint-js      # JS syntax gate
make ci           # full quality/security/test pipeline
```

See `CLAUDE.md` for the full command reference.
