# LittleStars

Gamified family task manager with a "star economy" for kids. Rails 8 fullstack app.

## Docs

- [`PRD_LittleStars.md`](./PRD_LittleStars.md) — product spec
- [`TECHSPEC.md`](./TECHSPEC.md) — architecture reference (models, services, routes)
- [`DESIGN.md`](./DESIGN.md) — Duolingo-style design system (tokens, components, motion, a11y)
- [`CLAUDE.md`](./CLAUDE.md) — agent guidance, stack, commands, conventions
- `.planning/` — GSD workflow artifacts (roadmap, requirements, codebase intel)

## Stack

Rails 8.1 · Ruby 3.3+ · PostgreSQL 16 · Vite + Propshaft · Tailwind 4 · Stimulus · Turbo · ViewComponent · RSpec · Solid Queue/Cache/Cable · Kamal.

## Run

Dev environment is Devcontainer / Docker Compose. From the `web` container:

```sh
bin/setup    # bundle + db:prepare
bin/dev      # Rails + Vite (Procfile.dev)
make rspec   # full test suite (runs inside container)
```

See `CLAUDE.md` for the full command reference.
