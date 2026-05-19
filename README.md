# LittleStars

Gamified family task manager with a "star economy" for kids. Rails 8 fullstack app.

## Docs

- [`PRD_LittleStars.md`](./PRD_LittleStars.md) — product spec
- [`TECHSPEC.md`](./TECHSPEC.md) — architecture reference (models, services, routes; §13 = Academy module)
- [`DESIGN.md`](./DESIGN.md) — Duolingo-style design system (tokens, components, motion, a11y)
- [`docs/academy.md`](./docs/academy.md) — Academy module (LLM-guided learning missions: isolation contract, persona, mission flow, ops)
- [`CLAUDE.md`](./CLAUDE.md) — agent guidance, stack, commands, conventions
- `.planning/` — GSD workflow artifacts (roadmap, requirements, codebase intel)

## Modules

- **Core (`Profile` / `GlobalTask` / `Reward` / `ActivityLog`)** — gamified task economy. See `TECHSPEC.md` §3–§8.
- **Academy (`Academy::*`, `/kid/academy/*`)** — LLM-guided learning. Isolated namespace, `academy_*` tables, OpenRouter + DeepSeek. Set `OPENROUTER_API_KEY` in `.env` to enable. See `docs/academy.md`.

## Stack

Rails 8.1 · Ruby 3.3+ · PostgreSQL 16 · Vite + Propshaft · Tailwind 4 · Stimulus · Turbo · ViewComponent · RSpec · Solid Queue/Cache/Cable · Kamal · `langchainrb` + `ruby-openai` (Academy).

## Run

Dev environment is Devcontainer / Docker Compose. From the `web` container:

```sh
bin/setup    # bundle + db:prepare
bin/dev      # Rails + Vite (Procfile.dev)
make rspec   # full test suite (runs inside container)
```

See `CLAUDE.md` for the full command reference.
