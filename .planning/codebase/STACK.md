# Technology Stack

**Analysis Date:** 2026-04-21

## Languages

**Primary:**
- Ruby 3.3.11 - Server-side application logic, Rails framework (enforced via `.ruby-version`)
- JavaScript/ECMAScript - Client-side interactivity via Stimulus and Vite
- HTML/ERB - View templates via Rails ActionView and ViewComponent

**Secondary:**
- SQL - PostgreSQL queries via ActiveRecord ORM
- CSS - Tailwind CSS v4 for styling (atomic utility-first approach)
- YAML - Configuration files (database, queue, cable, deploy, Tailwind)

## Runtime

**Environment:**
- Rails 8.1.3 - Fullstack web framework (pinned in `Gemfile`: `gem "rails", "~> 8.1.3"`)
- Ruby 3.3.11 - Via `.ruby-version`
- Node.js - For frontend asset bundling and build tools

**Package Manager:**
- Bundler 2.5.22 - Ruby gem dependency manager
- npm/Yarn - JavaScript dependencies (see `package.json`)
- Lockfiles: `Gemfile.lock` (Ruby dependencies), `yarn.lock` (JavaScript)

## Frameworks

**Core:**
- Rails 8.1.3 - Fullstack application framework with ActionPack, ActiveRecord, ActionView, ActionCable, Mailers, Jobs
- Turbo 2.0.23 - Hotwire framework for SPA-like interactivity
  - Turbo Drive - Client-side navigation without full page reload
  - Turbo Frames - Partial HTML replacement (e.g., approval queue, wallet balance)
  - Turbo Streams - Server-sent updates via WebSocket (real-time broadcasts)
- Stimulus 1.3.4 - Modest JavaScript framework for attaching behavior to DOM elements
- ViewComponent 4.7.0 - Component-based view layer, Ruby classes that render views

**Frontend Build & Styling:**
- Vite 7.1.7 (via `vite_rails` 3.10.0) - Modern frontend build tool with HMR (Hot Module Replacement)
- Tailwind CSS 4.0.6 - Utility-first CSS framework
- Propshaft - Rails asset pipeline (modern replacement for Sprockets)
- @tailwindcss/vite 4.0.6 - Vite plugin for processing Tailwind CSS

**Testing & Quality:**
- RSpec Rails 8.0.x - Behavior-driven testing framework for Rails
- FactoryBot Rails 6.5.x - Test data factory builder
- Capybara - Integration testing DSL with browser simulation
- Selenium WebDriver - Browser automation for system tests
- Shoulda-Matchers 7.0.x - RSpec matchers for Rails models and associations
- Database Cleaner 2.2.x - Atomic database cleanup between test runs
- Faker 3.8.x - Fake data/fixture generation
- Standard 1.54.0 - Ruby code style enforcer (Rails Omakase)
- RuboCop 1.84.0 (via Standard) - Ruby static analysis and linting
- Brakeman - Security vulnerability scanning for Rails
- Bundler-Audit - Gem CVE checking

**Development Tools:**
- AnnotateRb - Automatic Rails model annotation with schema info
- Web Console - Rails debugging console in browser error pages
- Puma 5.0+ - Ruby application server
- Bootsnap - Ruby boot-time optimization via caching

**Deployment & Operations:**
- Kamal - Docker orchestration and deployment tool
- Thruster 0.1.20 - HTTP caching and compression layer for Puma

## Key Dependencies

**Database & ORM:**
- pg 1.6.3 - PostgreSQL client adapter for ActiveRecord

**Real-Time & Background Processing (Solid Suite - PostgreSQL-backed):**
- solid_queue 1.4.0 - Database-backed background job processor (replaces Sidekiq/Redis)
  - Configured in `config/queue.yml`
  - Workers: 3 threads per process, configurable via `JOB_CONCURRENCY` env var
  - Located at: `app/jobs/`
- solid_cache 1.0.10 - Database-backed cache store (replaces Redis cache)
  - Development: `:memory_store` (in-process)
  - Production: Solid Cache (PostgreSQL)
  - Migrations: `db/cache_migrate`
- solid_cable 3.0.12 - Database-backed Action Cable adapter (replaces Redis pub/sub)
  - Development: `async` adapter
  - Production: Solid Cable (PostgreSQL) or Redis (`REDIS_URL`)
  - Configured in `config/cable.yml`

**UI Components & Icons:**
- view_component 4.7.0 - Ruby component framework for views
- lucide-rails - SVG icon library for Rails (Lucide icon set)

**Stimulus Controllers & Frontend Utilities:**
- @hotwired/stimulus 3.2.2 - Core Stimulus framework (JavaScript)
- @hotwired/turbo-rails 8.0.2 - Turbo bridge for Rails integration
- stimulus-rails-autosave 5.1.0 - Auto-saving form fields
- stimulus-textarea-autogrow 4.1.0 - Auto-expanding textarea
- stimulus-use 0.52.2 - Stimulus controller utilities
- stimulus-vite-helpers 3.1.0 - Auto-registration of Stimulus controllers with Vite

**Frontend Libraries:**
- canvas-confetti 1.9.4 - Celebration/confetti animation effects
- highlight.js 11.11.1 - Syntax highlighting for code blocks
- imask 7.6.1 - Input masking (phone numbers, dates)
- choices.js 11.1.0 - Select/dropdown enhancements
- @floating-ui/dom 1.7.6 - Positioning utilities (tooltips, popovers)
- @easepick/bundle 1.2.1 - Date range picker component
- @rails/request.js 0.0.9 - Rails AJAX request utility
- mjml 4.15.3 - Email template markup language

**Pagination:**
- pagy 43.5 - Lightweight pagination library (replaces Kaminari)

**Image Processing:**
- image_processing 1.2 - ImageMagick/libvips integration for Active Storage

## Configuration

**Environment Configuration:**

Database (`config/database.yml`):
- Adapter: PostgreSQL
- Development: `littlestars_development` on `db` host
- Test: `littlestars_test`
- Production: Primary + Cache + Queue + Cable databases with separate migrations paths
- Connection pooling: 5 (configurable via `RAILS_MAX_THREADS`)

Rails Environments (`config/environments/`):
- **Development** (`development.rb`):
  - Code reloading enabled
  - Cache store: `:memory_store` (in-process)
  - Action Mailer: `localhost:3000`
  - Strict loading by default (requires explicit `includes` in queries)
  - Server timing enabled
  - Verbose logging for queries and jobs
- **Production** (`production.rb`):
  - Code reloading disabled, eager loading enabled
  - Cache store: Fragment caching enabled
  - Solid Queue adapter for background jobs
  - STDOUT logging with request IDs
  - Asset caching (1-year max-age)

**Queue Configuration (`config/queue.yml`):**
- Solid Queue with polling dispatcher
- Dispatcher: 1-second polling interval, 500-job batch size
- Workers: 3 threads, 1 process (scalable via `JOB_CONCURRENCY`)

**Real-Time Configuration (`config/cable.yml`):**
- Development: Async adapter (in-process)
- Test: Test adapter
- Production: Redis (requires `REDIS_URL`) or Solid Cable (PostgreSQL)

**Asset Pipeline (`vite.config.mjs`):**
- Vite server: Port 3036, HMR on 127.0.0.1:3036
- Plugins: `@tailwindcss/vite`, `vite-plugin-rails`
- Content scanning for Tailwind: `app/**/*.{html,erb,js}`, `app/components/**/*.{rb,erb}`, `app/views/**/*.{erb,html}`

**Tailwind Configuration (`tailwind.config.js`):**
- Content paths: `app/**/*.{html,erb,js}`, `app/components/**/*.{rb,erb}`, `app/views/**/*.{erb,html}`

**Deployment (`config/deploy.yml`):**
- Kamal-based container orchestration
- Service name: `app`
- Registry: localhost:5555 (development/local)
- Solid Queue runs in-process: `SOLID_QUEUE_IN_PUMA: true`
- Persistent storage volume: `app_storage:/rails/storage`
- Asset path bridging for zero-downtime deployments

## Platform Requirements

**Development:**
- Docker Desktop or Docker Engine with Docker Compose
- VS Code with Dev Containers extension (recommended)
- Ruby 3.3.11 (via Docker or local rbenv/rvm if running outside container)
- Node.js 16+ (included in Docker image)

**Production:**
- Docker-compatible server (Linux, cloud: AWS, DigitalOcean, Heroku, etc.)
- PostgreSQL 16+ (separate instance or containerized)
- 1+ CPU cores (scales via `WEB_CONCURRENCY`, `JOB_CONCURRENCY` env vars)
- Storage volume for Active Storage and Solid Queue persistence
- Optional: Redis for Action Cable in multi-server deployments (else use PostgreSQL adapter)

**Development Container (Docker):**
- Base image: `ruby:3.3-slim`
- Installed packages: build-essential, libpq-dev, Node.js, npm, git, libyaml-dev, pkg-config
- Docker Compose services:
  - `web`: Rails application server
  - `db`: PostgreSQL 16-alpine
- Port mappings: 3000 (Rails), 3036 (Vite dev server), 5432 (PostgreSQL)

---

*Stack analysis: 2026-04-21*
