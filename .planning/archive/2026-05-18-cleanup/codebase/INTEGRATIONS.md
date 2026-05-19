# External Integrations

**Analysis Date:** 2026-04-21

## APIs & External Services

**Status:** Self-contained MVP - No external API integrations currently implemented.

The application operates as a closed system with no third-party API calls for:
- Payment processing (Stripe, PayPal)
- Authentication (Auth0, Firebase Auth, OAuth)
- Email sending (SendGrid, Mailgun, AWS SES)
- Push notifications (Firebase Cloud Messaging, OneSignal)
- Analytics (Mixpanel, Segment, Google Analytics)
- Cloud storage (AWS S3, Google Cloud Storage, Azure Blob)

## Data Storage

**Databases:**
- PostgreSQL 16-alpine
  - Connection: Via `config/database.yml` (development: `db` container hostname)
  - Client: ActiveRecord ORM (built into Rails)
  - Databases: Primary (`littlestars_development/test/production`), Cache, Queue, Cable
  - Backup strategy: Not configured (future consideration)

**File Storage:**
- Local filesystem only via Active Storage
  - Development: `storage/` directory (local disk)
  - Test: `tmp/storage/` directory
  - Production: Mounted volume `app_storage:/rails/storage` via Kamal
  - ORM: Active Storage (Rails)
  - Note: S3/GCS not currently configured (commented out in `config/storage.yml`)

**Caching:**
- Development: `:memory_store` (in-process, not persistent)
- Production: solid_cache (PostgreSQL-backed, persistent)
- No Redis dependency (replaces typical Redis cache layer)

## Authentication & Identity

**Auth Provider:**
- None (MVP)
- Current approach: Profile selection via `session[:profile_id]` in `SessionsController`
  - No password authentication
  - No user account system
  - Designed for demo/family-only usage
- Location: `app/controllers/sessions_controller.rb`
- Concern: `app/controllers/concerns/authenticatable.rb`

**Future:** OAuth/Devise integration planned post-MVP

## Monitoring & Observability

**Error Tracking:**
- None configured (planned: Sentry, Rollbar, or Honeybadger)

**Logs:**
- Development: STDOUT to console via Rails logger
- Production: STDOUT to Docker logs (via `config/environments/production.rb`)
  - Tagged with `:request_id` for tracing
  - Log level: Configurable via `RAILS_LOG_LEVEL` env var (default: `info`)
  - Healthcheck path `/up` excluded from logs

**Performance Monitoring:**
- Server timing enabled in development
- No APM (application performance monitoring) currently integrated

## CI/CD & Deployment

**Hosting:**
- Docker-containerized deployment
- Deployment tool: Kamal (container orchestration)
- Target: Any Linux server or cloud platform supporting Docker
- Configuration: `config/deploy.yml`
- Registry: Configurable (localhost:5555 in dev, external registry in production)

**CI Pipeline:**
- Not detected - tests run locally via `bundle exec rspec`
- GitHub Actions config available: `.github/dependabot.yml` (dependency updates only)
- Local CI script: `bin/ci` (runs full test suite, linters, security scans)

**Security Scanning:**
- Brakeman: `bin/brakeman` (Rails security vulnerabilities)
- Bundler-Audit: `bin/bundler-audit` (gem CVE scanning)
- Configuration: `config/bundler-audit.yml` (CVE ignore list)

**Asset Delivery:**
- Vite for asset bundling (development and production)
- Propshaft for Rails asset pipeline
- Thruster for HTTP caching and compression (optional, production)
- Fingerprinted assets with far-future caching (1-year expiry)

## Environment Configuration

**Required env vars (Production):**
- `RAILS_MASTER_KEY` - Rails credentials encryption key (for `config/credentials.yml.enc`)
- `APP_DATABASE_PASSWORD` - PostgreSQL password for production database
- `RAILS_LOG_LEVEL` - Log verbosity (default: `info`)
- `REDIS_URL` - Redis connection string (optional, for production Action Cable if not using PostgreSQL)
- `JOB_CONCURRENCY` - Solid Queue worker process count (default: 1)
- `WEB_CONCURRENCY` - Puma worker process count (default: 1)
- `DATABASE_HOST`, `DATABASE_USER`, `DATABASE_PASSWORD` - Database credentials (defaults provided for dev)

**Secrets location:**
- `config/credentials.yml.enc` - Rails encrypted credentials (decrypted via `RAILS_MASTER_KEY`)
- `.kamal/secrets` - Kamal deployment secrets (not checked into git)
- No `.env` files detected (credentials via Rails secrets system)

**Development defaults:**
- `.ruby-version`: Ruby 3.3.11
- `Dockerfile`: Sets build context (Ruby 3.3-slim, Node.js, npm)
- `docker-compose.yml`: Local development stack
  - PostgreSQL credentials: user `littlestars`, password `littlestars_dev`
  - Rails environment: `development`

## Webhooks & Callbacks

**Incoming:**
- None detected
- Future: Parent approval notifications, task completion callbacks

**Outgoing:**
- None detected
- Future: Push notifications to kid devices, parent alerts

## Real-Time Communication

**Action Cable (WebSocket):**
- Adapter: Async (development), test (test environment), Redis or PostgreSQL (production)
- Broadcasts: From service objects (e.g., `ApproveService`, `RedeemService`)
- Example channels: `"kid_#{profile.id}"` for kid wallet updates, parent approval queue
- Configuration: `config/cable.yml`

**Turbo Streams:**
- Server-sent HTML fragments via WebSocket or form submissions
- Use cases: Real-time balance updates, approval queue refresh
- No external stream broker (PostgreSQL via solid_cable)

## Background Jobs & Scheduling

**Job Processor:**
- Solid Queue (PostgreSQL-backed, replaces Sidekiq/Redis)
- Configuration: `config/queue.yml`
- Dispatcher: 1-second polling, 500-job batch
- Workers: 3 threads per process
- Location: `app/jobs/`

**Recurring/Scheduled Jobs:**
- `config/recurring.yml` - Task scheduling configuration
- Configured jobs:
  - `clear_solid_queue_finished_jobs` - Cleans up finished jobs hourly
- Daily reset job: `app/jobs/daily_reset_job.rb` (not explicitly scheduled in recurring.yml yet)

**Mail Delivery:**
- Mailer: `app/mailers/application_mailer.rb`
- Delivery method: Not configured (commented out SMTP in `config/environments/production.rb`)
- Future: Email notifications for approvals, rewards

## Third-Party UI Libraries

**Icons:**
- Lucide Rails - SVG icon set, available via `lucide-rails` gem
- Icons rendered via ViewComponents or inline SVG

**UI Components:**
- JetRockets UI referenced in TECHSPEC.md (29+ components: Card, Modal, Avatar, Badge, Tabs, Timeline, Stat, etc.)
- Status: Design reference, not directly imported as gem
- Implementation: Custom ViewComponents following JetRockets patterns
- Location: `app/components/`

**CSS/Design System:**
- Tailwind CSS 4.0.6 - Atomic utilities, no custom design system dependency
- Plugins: @tailwindcss/forms (0.5.10), @tailwindcss/typography (0.5.18)

## No Current Integrations With

- Payment/Billing (Stripe, Chargebee, Paddle)
- SMS (Twilio, AWS SNS)
- Email (SendGrid, Mailgun, AWS SES)
- Cloud Storage (AWS S3, Google Cloud Storage, Azure)
- Search (Elasticsearch, Algolia)
- CDN (CloudFlare, AWS CloudFront)
- Analytics (Segment, Mixpanel, Google Analytics)
- Error Tracking (Sentry, Honeybadger, Rollbar)
- Feature Flags (LaunchDarkly, Split.io)
- Database (SupaBase, Firebase, DynamoDB)

---

*Integration audit: 2026-04-21*
