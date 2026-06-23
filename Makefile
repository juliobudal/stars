# LittleStars — dev Makefile.
# Docker Compose stack (web + db). Commands exec inside the `web` container
# per CLAUDE.md convention. Kamal deploy wrappers at bottom.

-include .env

COMPOSE := docker compose
EXEC    := $(COMPOSE) exec -T web
RUN     := $(COMPOSE) run --rm web

.PHONY: help setup dev dev-detached build down restart ps \
        logs logs-web logs-db \
        shell shell-db c \
        db-create db-migrate db-seed db-reseed db-prepare db-reset db-rollback \
        migrate seed prepare reset rollback \
        test rspec lint rubocop lint-js lint-motion brakeman audit ci \
        routes assets-build assets-clobber \
        clean config \
        dokploy-deploy dokploy-redeploy dokploy-status dokploy-logs dokploy-deploy-logs \
        dokploy-stop dokploy-start dokploy-console dokploy-db-reset

help:
	@echo "LittleStars Makefile — common targets:"
	@echo ""
	@echo "  make setup         full bootstrap (wipe volumes, build, migrate, seed)"
	@echo "  make dev           start stack in foreground"
	@echo "  make dev-detached  start stack in background"
	@echo "  make down          stop stack (keeps volumes)"
	@echo "  make clean         stop stack AND wipe volumes (DATA LOSS)"
	@echo ""
	@echo "  make migrate       bin/rails db:migrate"
	@echo "  make seed          bin/rails db:seed (idempotent — skip if families exist)"
	@echo "  make db-reseed     SEED_FORCE=1 db:seed (wipes data)"
	@echo "  make prepare       bin/rails db:prepare"
	@echo "  make reset         drop + create + migrate + seed"
	@echo "  make rollback      bin/rails db:rollback"
	@echo ""
	@echo "  make shell         bash into web container"
	@echo "  make c             rails console"
	@echo "  make shell-db      psql into postgres"
	@echo "  make test          bundle exec rspec"
	@echo "  make lint          bin/rubocop"
	@echo "  make lint-js       JS syntax check (node --check)"
	@echo "  make ci            bin/ci"
	@echo ""
	@echo "  make logs          tail all logs"
	@echo "  make logs-web      tail web logs"
	@echo "  make logs-db       tail db logs"

# Stack ------------------------------------------------------------------------
dev:
	$(COMPOSE) up --build

dev-detached:
	$(COMPOSE) up --build -d

build:
	$(COMPOSE) build

down:
	$(COMPOSE) down
	@-lsof -ti:3000,3036 | xargs kill -9 2>/dev/null; pkill -9 -f "vite|puma|bin/dev" 2>/dev/null; true

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

# Logs -------------------------------------------------------------------------
logs:
	$(COMPOSE) logs -f

logs-web:
	$(COMPOSE) logs -f web

logs-db:
	$(COMPOSE) logs -f db

# Shells -----------------------------------------------------------------------
shell:
	$(COMPOSE) exec web bash

shell-db:
	$(COMPOSE) exec db psql -U littlestars -d littlestars_development

c:
	$(COMPOSE) exec web bin/rails console

# Rails DB ---------------------------------------------------------------------
db-create:
	$(EXEC) bin/rails db:create

db-migrate:
	$(EXEC) env RAILS_ENV=development bin/rails db:migrate

db-seed:
	$(EXEC) env RAILS_ENV=development bin/rails db:seed

# Force-reseed dev DB (DESTRUCTIVE — wipes all families, profiles, etc).
db-reseed:
	$(EXEC) env RAILS_ENV=development SEED_FORCE=1 bin/rails db:seed

db-prepare:
	$(EXEC) bin/rails db:prepare

db-rollback:
	$(EXEC) bin/rails db:rollback

db-reset:
	@# Puma/SolidQueue/SolidCable in the web container hold open Postgres
	@# connections and auto-reconnect, blocking db:drop. Stop web for the
	@# drop window, then bring it back up.
	-$(COMPOSE) stop web
	$(COMPOSE) run --rm web bin/rails db:drop db:create db:migrate db:seed
	$(COMPOSE) up -d web

# Short aliases
migrate: db-migrate
seed: db-seed
prepare: db-prepare
rollback: db-rollback
reset: db-reset

# Tests & quality --------------------------------------------------------------
# Use one-shot containers (`docker compose run --rm web`) so these targets do
# not depend on `web` already being up. `RAILS_ENV=test` + explicit DATABASE_URL
# prevents env drift (EnvironmentMismatchError) and keeps test DB isolated.
# Backwards-compat with historical docs: `make rspec SPEC=spec/path_spec.rb`.
RSPEC_TARGET ?= $(or $(SPEC),$(ARGS))
test:
	$(RUN) env RAILS_ENV=test DATABASE_URL=postgres://littlestars:littlestars_dev@db:5432/littlestars_test bin/rails db:environment:set
	$(RUN) env RAILS_ENV=test DATABASE_URL=postgres://littlestars:littlestars_dev@db:5432/littlestars_test bundle exec rspec $(RSPEC_TARGET)

rspec: test

# Academy v5 — structural eval for lens generators. Validates that every
# LLM-output payload conforms to its per-type JSON schema. Does NOT call
# OpenRouter — uses stubbed LLM responses for fast feedback in CI.
# Live LLM eval is opt-in: ACADEMY_LIVE_EVAL=1 make eval-v5.
eval-v5:
	$(RUN) env RAILS_ENV=test DATABASE_URL=postgres://littlestars:littlestars_dev@db:5432/littlestars_test bundle exec rspec \
	  spec/services/academy/lens/ \
	  spec/services/academy/missions/lifecycle_spec.rb \
	  spec/services/academy/pokedex/

eval-v4-legacy:
	@echo "eval-v4-legacy: no-op (v4 persona eval deleted; v5 eval is `make eval-v5`)"

lint:
	$(RUN) bin/rubocop

rubocop: lint

lint-motion:
	$(RUN) bash scripts/check-motion-tokens.sh

lint-js:
	$(RUN) bash scripts/check-js-syntax.sh

brakeman:
	$(RUN) bin/brakeman

audit:
	$(RUN) bin/bundler-audit check --update

ci:
	$(RUN) bin/ci

# Rails utils ------------------------------------------------------------------
routes:
	$(EXEC) bin/rails routes

assets-build:
	$(EXEC) bin/vite build

assets-clobber:
	$(EXEC) bin/rails assets:clobber

# Academy --------------------------------------------------------------------
# One-shot generation of pill illustrations via OpenRouter. See
# openspec/changes/add-pill-illustrations/design.md for the pipeline contract.
# Pass options via ENV, e.g.: `make academy-illustrations DRY_RUN=1`,
# `make academy-illustrations FORCE=1 ONLY=agua-quebra-pedra`.
academy-illustrations:
	$(EXEC) bin/rails academy:illustrations:generate

# Full bootstrap ---------------------------------------------------------------
# Wipes volumes, rebuilds images from scratch, boots the stack, installs deps
# inside the container (bind mount masks image-time node_modules), then prepares
# both DBs (development + test) — drop → create → migrate → seed (dev only).
# DATA LOSS INTENDED on the Postgres volume.
setup:
	@if [ ! -f config/master.key ] && [ ! -f config/credentials/development.key ] && [ -z "$$RAILS_MASTER_KEY" ]; then \
		echo "⚠ no config/master.key found — credentials-backed features may fail"; \
	fi
	$(COMPOSE) down -v --remove-orphans
	$(COMPOSE) build --no-cache
	$(COMPOSE) up -d db
	@echo "→ waiting for postgres to accept connections..."
	@until $(COMPOSE) exec -T db pg_isready -U littlestars >/dev/null 2>&1; do sleep 1; done
	@echo "→ installing gems + js deps via one-shot container (no Foreman, no jobs)..."
	$(COMPOSE) run --rm --no-deps web bundle install
	$(COMPOSE) run --rm --no-deps web yarn install --frozen-lockfile
	@echo "→ preparing databases (drop + create + migrate all tables including Solid Queue)..."
	$(COMPOSE) run --rm web bin/rails db:prepare
	$(COMPOSE) run --rm web bin/rails db:prepare RAILS_ENV=test
	@echo "→ seeding development database..."
	$(COMPOSE) run --rm web bin/rails db:seed
	@echo "→ annotating models with schema comments..."
	-$(COMPOSE) run --rm web bundle exec annotaterb models
	@echo "→ building assets..."
	$(COMPOSE) run --rm --no-deps web bin/vite build
	@echo "→ starting web (Foreman: rails+jobs+vite) now that schema exists..."
	$(COMPOSE) up -d web
	@echo ""
	@echo "✓ setup complete — stack up, deps installed, dev+test DBs prepared + migrated, dev DB seeded, assets built."
	@echo "  app → http://localhost:3000"
	@echo "  vite → http://localhost:3036"

# Utilities --------------------------------------------------------------------
config:
	$(COMPOSE) config

# DANGEROUS: removes containers AND named volumes (wipes DB data).
clean:
	$(COMPOSE) down -v --remove-orphans

# Dokploy production deploy (API — servidor Dokploy nativo) --------------------
# O deploy é gerenciado pelo Dokploy (Compose service "guardian"). Não há mais
# rsync/SSH: o Dokploy clona o repo (git@github.com:juliobudal/stars.git @ main
# via deploy key) e faz build no servidor. As targets abaixo falam com a API do
# Dokploy usando DOKPLOY_URL / DOKPLOY_API_KEY / DOKPLOY_COMPOSE_ID (.env.production).
# Migrations + seed rodam sozinhas no boot (compose command → db:prepare && db:seed).

ifneq (,$(wildcard ./.env.production))
    include .env.production
    export
endif

DOKPLOY_API := curl -fsS -H "x-api-key: $(DOKPLOY_API_KEY)" -H "Content-Type: application/json"

define _check_dokploy
	@if [ -z "$(DOKPLOY_URL)" ] || [ -z "$(DOKPLOY_API_KEY)" ] || [ -z "$(DOKPLOY_COMPOSE_ID)" ]; then \
		echo "✗ DOKPLOY_URL, DOKPLOY_API_KEY e DOKPLOY_COMPOSE_ID devem estar em .env.production"; exit 1; \
	fi
endef

dokploy-deploy: ## Dispara deploy no Dokploy (clone main + build + up)
	$(call _check_dokploy)
	@echo "→ disparando deploy no Dokploy..."
	@$(DOKPLOY_API) -X POST "$(DOKPLOY_URL)/api/compose.deploy" \
		-d '{"composeId":"$(DOKPLOY_COMPOSE_ID)","title":"make dokploy-deploy"}' && echo
	@echo "✓ enfileirado — acompanhe: make dokploy-status / make dokploy-deploy-logs"

dokploy-redeploy: ## Redeploy (rebuild) no Dokploy
	$(call _check_dokploy)
	@$(DOKPLOY_API) -X POST "$(DOKPLOY_URL)/api/compose.redeploy" \
		-d '{"composeId":"$(DOKPLOY_COMPOSE_ID)","title":"make dokploy-redeploy"}' && echo

dokploy-status: ## Status do compose no Dokploy
	$(call _check_dokploy)
	@$(DOKPLOY_API) "$(DOKPLOY_URL)/api/compose.one?composeId=$(DOKPLOY_COMPOSE_ID)" \
		| python3 -c "import json,sys;d=json.load(sys.stdin);print('status:',d.get('composeStatus'),'| source:',d.get('sourceType'),'| branch:',d.get('customGitBranch'))"

dokploy-logs: ## Logs de runtime (SERVICE=littlestars-app|littlestars-db, TAIL=100)
	$(call _check_dokploy)
	@$(DOKPLOY_API) "$(DOKPLOY_URL)/api/compose.readLogs?composeId=$(DOKPLOY_COMPOSE_ID)&containerId=$(or $(SERVICE),littlestars-app)&tail=$(or $(TAIL),100)"

dokploy-deploy-logs: ## Status/log do último deploy (build)
	$(call _check_dokploy)
	@$(DOKPLOY_API) "$(DOKPLOY_URL)/api/deployment.allByCompose?composeId=$(DOKPLOY_COMPOSE_ID)" \
		| python3 -c "import json,sys;d=json.load(sys.stdin);x=d[0];print('último:',x.get('status'),'|',x.get('title'));print('log (via ssh):',x.get('logPath'))"

dokploy-stop: ## Para o compose no Dokploy
	$(call _check_dokploy)
	@$(DOKPLOY_API) -X POST "$(DOKPLOY_URL)/api/compose.stop" -d '{"composeId":"$(DOKPLOY_COMPOSE_ID)"}' && echo

dokploy-start: ## Sobe o compose no Dokploy
	$(call _check_dokploy)
	@$(DOKPLOY_API) -X POST "$(DOKPLOY_URL)/api/compose.start" -d '{"composeId":"$(DOKPLOY_COMPOSE_ID)"}' && echo

# Migrations + seed rodam sozinhas no boot. Para reseed/console use o terminal
# do painel Dokploy (Compose → littlestars-app → Terminal).
dokploy-console: ## (use o terminal do painel Dokploy: littlestars-app → bin/rails console)
	@echo "→ Abra o painel Dokploy → projeto guardian → littlestars-app → Terminal e rode: bin/rails console"
	@echo "  $(DOKPLOY_URL)"

dokploy-db-reset: ## DESTRUTIVO: faça pelo painel Dokploy (littlestars-db) ou Terminal do littlestars-app
	@echo "⚠  Operação destrutiva. Faça pelo painel Dokploy (volume littlestars-db-data) ou"
	@echo "   pelo Terminal do littlestars-app: bin/rails db:drop db:prepare db:seed"
