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
        db-create db-migrate db-seed db-prepare db-reset db-rollback \
        migrate seed prepare reset rollback \
        test rspec lint rubocop brakeman audit ci \
        routes assets-build assets-clobber \
        clean config \
        deploy deploy-check deploy-logs

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
	@echo "  make seed          bin/rails db:seed"
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
	$(EXEC) bin/rails db:migrate

db-seed:
	$(EXEC) bin/rails db:seed

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
test:
	$(EXEC) bundle exec rspec

rspec: test

lint:
	$(EXEC) bin/rubocop

rubocop: lint

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
	$(COMPOSE) up -d web
	@echo "→ waiting for web container to finish bundle install + boot..."
	@until $(COMPOSE) exec -T web bin/rails runner "puts :ok" >/dev/null 2>&1; do sleep 2; done
	@echo "→ ensuring gems + js deps installed inside container (bind mount safety)..."
	$(EXEC) bundle install
	$(EXEC) yarn install --frozen-lockfile
	@echo "→ preparing databases (drop + create + migrate all tables including Solid Queue)..."
	$(EXEC) bin/rails db:prepare
	$(EXEC) bin/rails db:prepare RAILS_ENV=test
	@echo "→ seeding development database..."
	$(EXEC) bin/rails db:seed
	@echo "→ annotating models with schema comments..."
	-$(EXEC) bundle exec annotaterb models
	@echo "→ building assets..."
	$(EXEC) bin/vite build
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

# Kamal deploy -----------------------------------------------------------------
deploy-check:
	bundle exec kamal config

deploy:
	bundle exec kamal deploy

deploy-logs:
	bundle exec kamal app logs -f
