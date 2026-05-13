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
        test rspec lint rubocop brakeman audit ci \
        routes assets-build assets-clobber \
        clean config \
        dokploy-deploy dokploy-migrate dokploy-seed dokploy-logs dokploy-status dokploy-restart dokploy-console \
        dokploy-db-reset

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
	$(EXEC) bin/rails db:drop db:create db:migrate db:seed

# Short aliases
migrate: db-migrate
seed: db-seed
prepare: db-prepare
rollback: db-rollback
reset: db-reset

# Tests & quality --------------------------------------------------------------
# RAILS_ENV=test prevents env drift that triggers EnvironmentMismatchError +
# protects dev DB from rspec's db:test:purge stomping if last command ran in dev.
test:
	$(EXEC) env RAILS_ENV=test bundle exec rspec $(ARGS)

rspec: test

lint:
	$(EXEC) bin/rubocop

rubocop: lint

lint-motion:
	bash scripts/check-motion-tokens.sh

brakeman:
	$(EXEC) bin/brakeman

audit:
	$(EXEC) bin/bundler-audit check --update

ci:
	$(EXEC) bin/ci

# Rails utils ------------------------------------------------------------------
routes:
	$(EXEC) bin/rails routes

assets-build:
	$(EXEC) bin/vite build

assets-clobber:
	$(EXEC) bin/rails assets:clobber

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

# Dokploy production deploy ----------------------------------------------------
# Same SSH-based pattern as ../study-flix. Requires .env.production at repo root
# (see .env.production.example). Deploys to app.iacomcafe.com via rsync + SSH.

ifneq (,$(wildcard ./.env.production))
    include .env.production
    export
endif

SSH_CMD := ssh -o StrictHostKeyChecking=no
ifneq ($(SSH_KEY_PATH),)
    SSH_CMD += -i $(SSH_KEY_PATH)
endif
ifneq ($(DEPLOY_PORT),)
    SSH_CMD += -p $(DEPLOY_PORT)
else
    DEPLOY_PORT := 22
endif

DOKPLOY_COMPOSE := docker compose --env-file .env.production -f docker-compose.dokploy.yml

dokploy-deploy:
	@echo "→ deploying LittleStars to Dokploy server..."
	@if [ -z "$(DEPLOY_HOST)" ] || [ -z "$(DEPLOY_USER)" ] || [ -z "$(DEPLOY_DIR)" ]; then \
		echo "✗ DEPLOY_HOST, DEPLOY_USER, DEPLOY_DIR must be set in .env.production"; exit 1; \
	fi
	@if [ ! -f .env.production ]; then \
		echo "✗ .env.production not found — copy .env.production.example and fill"; exit 1; \
	fi
	@echo "→ syncing files..."
	rsync -avz -e "ssh -p $(DEPLOY_PORT)" --progress --delete \
		--exclude .git --exclude node_modules --exclude tmp --exclude log \
		--exclude .planning --exclude .claude --exclude spec \
		--exclude '.env' --exclude '.env.local' --exclude '.env.development' \
		--exclude 'public/assets' --exclude 'public/vite' \
		--exclude '*.png' --exclude '*.md' \
		./ $(DEPLOY_USER)@$(DEPLOY_HOST):$(DEPLOY_DIR)/
	@echo "→ building + recreating containers on server..."
	$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) down --remove-orphans || true && \
		docker rm -f littlestars-app littlestars-db 2>/dev/null || true && \
		DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 $(DOKPLOY_COMPOSE) build --parallel && \
		$(DOKPLOY_COMPOSE) up -d --force-recreate --remove-orphans"
	@echo "→ waiting for /up health check..."
	@$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) '\
		for i in 1 2 3 4 5 6 7 8 9 10 11 12; do \
			if docker exec littlestars-app curl -fsS http://127.0.0.1:3000/up > /dev/null 2>&1; then \
				echo "✓ healthy on attempt $$i"; exit 0; \
			fi; \
			echo "  attempt $$i/12 — waiting 5s..."; sleep 5; \
		done; \
		echo "✗ health check failed — see make dokploy-logs"; exit 1'
	@echo "→ running db:prepare (create + migrate + seed if empty)..."
	@$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) exec -T littlestars-app bin/rails db:prepare" || \
		echo "⚠ db:prepare failed — run make dokploy-migrate manually"
	@echo "✓ deployed → https://$${DOMAIN_LITTLESTARS:-stars.iacomcafe.com}"

dokploy-migrate:
	@echo "→ running migrations on Dokploy..."
	@if [ -z "$(DEPLOY_HOST)" ]; then echo "✗ .env.production missing DEPLOY_HOST"; exit 1; fi
	$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) exec -T littlestars-app bin/rails db:migrate"
	@echo "✓ migrations applied"

dokploy-seed:
	@echo "→ seeding production DB (SEED_FORCE=$(SEED_FORCE))..."
	@if [ -z "$(DEPLOY_HOST)" ]; then echo "✗ .env.production missing DEPLOY_HOST"; exit 1; fi
	$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) exec -T -e SEED_FORCE=$(SEED_FORCE) littlestars-app bin/rails db:seed"

dokploy-logs:
	@if [ -z "$(DEPLOY_HOST)" ]; then echo "✗ .env.production missing DEPLOY_HOST"; exit 1; fi
	$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) logs -f --tail=100"

dokploy-status:
	@if [ -z "$(DEPLOY_HOST)" ]; then echo "✗ .env.production missing DEPLOY_HOST"; exit 1; fi
	$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) ps && \
		docker stats --no-stream littlestars-app littlestars-db || true"

dokploy-restart:
	@if [ -z "$(DEPLOY_HOST)" ]; then echo "✗ .env.production missing DEPLOY_HOST"; exit 1; fi
	$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) restart"

dokploy-console:
	@if [ -z "$(DEPLOY_HOST)" ]; then echo "✗ .env.production missing DEPLOY_HOST"; exit 1; fi
	$(SSH_CMD) -t $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) exec littlestars-app bin/rails console"

# DESTRUCTIVE: drops + recreates + migrates + seeds production DB. Wipes ALL data.
# Requires explicit confirm: make dokploy-db-reset CONFIRM=RESET-PROD
dokploy-db-reset:
	@if [ -z "$(DEPLOY_HOST)" ]; then echo "✗ .env.production missing DEPLOY_HOST"; exit 1; fi
	@if [ "$(CONFIRM)" != "RESET-PROD" ]; then \
		echo ""; \
		echo "⚠  DESTRUCTIVE: this will DROP the production database on $(DEPLOY_HOST)."; \
		echo "   ALL families, profiles, tasks, rewards, activity logs will be lost."; \
		echo ""; \
		echo "   To proceed, re-run:"; \
		echo "     make dokploy-db-reset CONFIRM=RESET-PROD"; \
		echo ""; \
		exit 1; \
	fi
	@echo "→ resetting production DB on $(DEPLOY_HOST)..."
	@echo "→ stopping app to release connections..."
	$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) stop littlestars-app"
	@echo "→ drop + create + migrate + seed (DISABLE_DATABASE_ENVIRONMENT_CHECK=1)..."
	$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) run --rm \
			-e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 \
			-e RAILS_ENV=production \
			littlestars-app bin/rails db:drop db:create db:migrate db:seed"
	@echo "→ restarting app..."
	$(SSH_CMD) $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_DIR) && \
		$(DOKPLOY_COMPOSE) start littlestars-app"
	@echo "✓ production DB reset complete"
