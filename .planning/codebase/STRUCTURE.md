# Codebase Structure

**Analysis Date:** 2026-04-21

## Directory Layout

```
guardian/
├── app/                       # Rails application code
│   ├── assets/                # Images, stylesheets, JS entrypoints (Vite)
│   │   ├── controllers/       # Stimulus controllers (JS)
│   │   ├── entrypoints/       # Vite JS/CSS entry points
│   │   ├── images/            # Icons (SVG), app graphics
│   │   ├── stylesheets/       # CSS files, Tailwind imports
│   │   ├── init/              # DOM ready scripts
│   │   └── utils/             # Shared JS utilities
│   ├── components/            # ViewComponent library (99 components)
│   │   ├── ui/                # Atomic UI components (atoms, molecules)
│   │   │   ├── btn/           # Button component
│   │   │   ├── card/          # Card component with header/footer
│   │   │   ├── modal/         # Modal dialog with slots
│   │   │   ├── mission_card/  # Mission card (kid-specific)
│   │   │   ├── lumi/          # Lumi character (mood-aware)
│   │   │   ├── balance_chip/  # Points/stars display
│   │   │   ├── badge/         # Badge (category, points)
│   │   │   └── [40+ more...]  # Dropdowns, tables, tabs, drawers, etc.
│   │   └── form_builders/     # Form field components
│   │       ├── text_field/
│   │       ├── select/
│   │       ├── checkbox/
│   │       └── [more...]
│   ├── controllers/           # HTTP request handlers
│   │   ├── application_controller.rb  # Base controller
│   │   ├── sessions_controller.rb     # Profile selection
│   │   ├── concerns/          # Shared concerns
│   │   │   └── authenticatable.rb     # Auth guards
│   │   ├── parent/            # Parent-role controllers
│   │   │   ├── dashboard_controller.rb
│   │   │   ├── global_tasks_controller.rb
│   │   │   ├── approvals_controller.rb
│   │   │   ├── rewards_controller.rb
│   │   │   ├── activity_logs_controller.rb
│   │   │   └── profiles_controller.rb
│   │   └── kid/               # Child-role controllers
│   │       ├── dashboard_controller.rb
│   │       ├── missions_controller.rb
│   │       ├── rewards_controller.rb
│   │       └── wallet_controller.rb
│   ├── helpers/               # View helpers
│   │   ├── application_helper.rb
│   │   ├── component_docs_helper.rb
│   │   └── meta_tags_helper.rb
│   ├── jobs/                  # Background jobs (Solid Queue)
│   ├── mailers/               # Email generation
│   ├── models/                # ActiveRecord models
│   │   ├── application_record.rb
│   │   ├── family.rb
│   │   ├── profile.rb
│   │   ├── global_task.rb
│   │   ├── profile_task.rb
│   │   ├── reward.rb
│   │   ├── redemption.rb
│   │   ├── activity_log.rb
│   │   └── concerns/          # Shared model concerns
│   ├── queries/               # Query objects (data retrieval)
│   │   └── approvals/
│   │       ├── pending_tasks_query.rb
│   │       └── pending_redemptions_query.rb
│   ├── services/              # Service objects (business logic)
│   │   ├── application_service.rb    # Base service, Result object
│   │   ├── tasks/
│   │   │   ├── approve_service.rb
│   │   │   ├── reject_service.rb
│   │   │   └── daily_reset_service.rb
│   │   └── rewards/
│   │       ├── redeem_service.rb
│   │       ├── approve_redemption_service.rb
│   │       └── reject_redemption_service.rb
│   └── views/                 # ERB view templates
│       ├── layouts/
│       │   ├── application.html.erb
│       │   ├── kid.html.erb   # Kid-specific layout (playful)
│       │   └── parent.html.erb # Parent-specific layout (dashboard)
│       ├── sessions/
│       │   └── index.html.erb # Profile selection
│       ├── parent/            # Parent-role views
│       │   ├── dashboard/
│       │   ├── global_tasks/
│       │   ├── approvals/
│       │   ├── rewards/
│       │   ├── activity_logs/
│       │   └── profiles/
│       ├── kid/               # Kid-role views
│       │   ├── dashboard/
│       │   ├── missions/
│       │   ├── rewards/
│       │   └── wallet/
│       ├── shared/            # Shared view partials
│       └── pwa/               # PWA manifest templates
├── config/                    # Rails configuration
│   ├── routes.rb              # URL routing
│   ├── database.yml           # DB config
│   └── [other config files]
├── db/                        # Database
│   ├── migrate/               # Database migrations
│   ├── schema.rb              # Current schema
│   └── seeds.rb               # Seed data
├── lib/                       # Library code
├── public/                    # Static files (served as-is)
├── spec/                      # RSpec tests
│   ├── factories/             # FactoryBot factories
│   ├── models/                # Model specs
│   ├── requests/              # Request/integration specs
│   │   ├── kid/
│   │   ├── parent/
│   │   └── security/
│   ├── services/              # Service specs
│   │   ├── tasks/
│   │   └── rewards/
│   ├── system/                # System/feature tests (Capybara)
│   └── support/               # Spec helpers
├── scripts/                   # Utility scripts
├── .planning/                 # GSD planning artifacts
│   └── codebase/              # Generated architecture docs
├── CLAUDE.md                  # Project guidelines for Claude
├── TECHSPEC.md                # Technical specification
├── PRD_LittleStars.md         # Product requirements document
├── Dockerfile                 # Container build
├── docker-compose.yml         # Local dev environment
├── Gemfile                    # Ruby dependencies
├── Makefile                   # Dev commands
├── tailwind.config.js         # Tailwind CSS config
├── vite.config.js             # Vite bundler config
├── package.json               # Node dependencies
├── .ruby-version              # Ruby version (3.3+)
├── .rspec                     # RSpec config
├── .rubocop.yml               # Linter config
└── README.md                  # Project overview
```

## Directory Purposes

**app/models/:**
- Purpose: Define data model, relationships, validations, enums
- Contains: ActiveRecord class files
- Key files: `profile.rb` (dual-role), `profile_task.rb` (task state machine), `activity_log.rb` (audit trail)

**app/controllers/:**
- Purpose: Handle HTTP requests, delegate to services, format responses
- Contains: Class files organized by role namespace
- Pattern: One controller per resource; lean controllers that route to services
- Key files: `sessions_controller.rb` (auth), `parent/approvals_controller.rb` (main parent workflow)

**app/services/:**
- Purpose: Encapsulate business logic in transaction-wrapped methods
- Contains: Service objects organized by domain (tasks, rewards)
- Pattern: Each service has `initialize` + `call` method, returns `Result` object
- Key files: `tasks/approve_service.rb`, `rewards/redeem_service.rb`

**app/components/:**
- Purpose: Reusable, testable UI components
- Contains: 99 component classes (`.rb`) + templates (`.html.erb`)
- Organization: Grouped by category (ui, form_builders) and size (atomic → composite)
- Key components: `ui/btn/component.rb`, `ui/mission_card/component.rb`, `ui/modal/component.rb`

**app/views/:**
- Purpose: Display templates assembling components + ERB
- Structure: Dual namespaces (`kid/`, `parent/`) mirror controller structure
- Pattern: Views call controller instance variables, render ViewComponents
- Key files: `kid/dashboard/index.html.erb`, `parent/approvals/index.html.erb`

**app/assets/controllers/:**
- Purpose: Stimulus controllers for client-side interactivity
- Contains: JS files (not classic Sprockets; Vite-served)
- Key files: `celebration_controller.js` (confetti), `count_up_controller.js` (animation), `tabs_controller.js` (tab switching)

**app/assets/stylesheets/:**
- Purpose: CSS files compiled by Tailwind + Vite
- Contains: Tailwind imports, component overrides, utility classes
- Pattern: Mostly Tailwind utilities; custom CSS in components

**app/queries/:**
- Purpose: Encapsulate complex SQL aggregations
- Contains: Query objects organized by domain
- Pattern: Initialize with filter params, `call` returns relation
- Usage: `Approvals::PendingTasksQuery.new(family: current_profile.family).call`

**db/migrate/:**
- Purpose: Versioned database schema changes
- Pattern: Rails migration files (numbered by timestamp)
- Run via: `bin/rails db:migrate`

**spec/:**
- Purpose: RSpec test suite
- Structure: Mirrors `app/` structure
- Types: `models/`, `services/`, `requests/`, `system/`
- Key pattern: FactoryBot fixtures + RSpec describe/it blocks

## Key File Locations

**Entry Points:**
- `app/controllers/sessions_controller.rb`: Profile selection (root `/`)
- `app/controllers/kid/dashboard_controller.rb`: Kid home page (`/kid`)
- `app/controllers/parent/dashboard_controller.rb`: Parent home page (`/parent`)
- `config/routes.rb`: URL routing definition

**Configuration:**
- `config/routes.rb`: Route definitions
- `tailwind.config.js`: Tailwind CSS configuration
- `vite.config.js`: Vite bundler configuration
- `config/database.yml`: Database connection
- `.ruby-version`: Ruby version constraint

**Core Logic:**
- `app/services/application_service.rb`: Service base class + Result object
- `app/models/profile.rb`: User model with role enum + points broadcasting
- `app/models/profile_task.rb`: Task state machine + status enum
- `app/controllers/concerns/authenticatable.rb`: Auth & authorization guards

**Testing:**
- `spec/factories/` : FactoryBot model factories
- `spec/services/` : Service specs
- `spec/requests/` : Controller/integration specs

## Naming Conventions

**Files:**

| Type | Pattern | Example |
|------|---------|---------|
| Model | `snake_case.rb` | `profile_task.rb` |
| Controller | `plural_snake_case_controller.rb` | `approvals_controller.rb` |
| Service | `action_service.rb` | `approve_service.rb` |
| Query | `plural_description_query.rb` | `pending_tasks_query.rb` |
| Component | `component.rb` (in nested dir) | `app/components/ui/btn/component.rb` |
| Controller (JS) | `action_controller.js` | `celebration_controller.js` |
| Test | `*_spec.rb` | `approve_service_spec.rb` |
| Migration | `[timestamp]_description.rb` | `20260101000001_create_profiles.rb` |

**Directories:**

| Type | Pattern | Example |
|------|---------|---------|
| Models | `app/models/` (no namespace) | — |
| Services | `app/services/{domain}/` | `app/services/tasks/` |
| Controllers | `app/controllers/{role}/` | `app/controllers/kid/` |
| Components | `app/components/{category}/{component_name}/` | `app/components/ui/btn/` |
| Views | `app/views/{role}/{resource}/` | `app/views/kid/missions/` |
| Queries | `app/queries/{domain}/` | `app/queries/approvals/` |

**Classes & Methods:**

- **Classes:** `PascalCase` with namespaces (e.g., `Tasks::ApproveService`, `Approvals::PendingTasksQuery`)
- **Methods:** `snake_case`
- **Enums:** `snake_case` hash keys (e.g., `enum :role, { child: 0, parent: 1 }`)
- **Variables:** `snake_case`
- **Constants:** `SCREAMING_SNAKE_CASE`

## Where to Add New Code

**New Feature (Multi-step Workflow):**
- Primary logic: `app/services/{domain}/{action}_service.rb` — Implement service with transaction
- Model changes: `app/models/*.rb` — Add associations, scopes, callbacks
- Controller action: `app/controllers/{role}/{resource}_controller.rb` — Call service, format response
- View template: `app/views/{role}/{resource}/{action}.html.erb` — Render components, pass data
- Tests: `spec/services/{domain}/{action}_service_spec.rb`, `spec/requests/{role}/{resource}_spec.rb`

**New Component/Widget:**
- Implementation: `app/components/ui/{component_name}/component.rb` — Define properties, render
- Template: `app/components/ui/{component_name}/component.html.erb` — Combine HTML + yield slots
- Styles: Inline via `style=` or `class=` attributes (Tailwind)
- Tests: Reference in integration tests; no isolated unit tests for components (legacy)

**New Stimulus Interaction:**
- Controller: `app/assets/controllers/{action}_controller.js` — Define targets, actions, methods
- HTML data attributes: Use in templates (`data-controller="action"`, `data-action="click->action#method"`)
- Auto-registered: Vite + `stimulus-vite-helpers` auto-discovers JS files

**Utilities/Helpers:**
- Shared helpers: `app/helpers/application_helper.rb` — Methods callable from all views
- Query object: `app/queries/{domain}/{description}_query.rb` — Encapsulate SQL filters
- Service utility: Extract into `ApplicationService` subclass if multi-use

**Database Changes:**
- Migration: `bin/rails generate migration DescriptionOfChange` — Create in `db/migrate/`
- Schema: Edit models after migration runs
- Seeds: `db/seeds.rb` — Add test data for local dev

## Special Directories

**app/assets/entrypoints/:**
- Purpose: Vite JS/CSS entry points (compiled separately)
- Generated: Vite compiles at build time
- Committed: Yes (source files)
- Contains: `application.js`, `application.css` — imports for all pages

**public/:**
- Purpose: Served directly by web server (bypass Rails)
- Generated: Some files from asset pipeline
- Committed: Partial (404.html, favicon.ico yes; build output no)
- Contents: Static assets, compiled CSS/JS (in prod)

**storage/:**
- Purpose: Local file storage for development
- Generated: Yes (runtime created)
- Committed: No (in .gitignore)
- Use: ActiveStorage file attachments

**tmp/:**
- Purpose: Temporary files (cache, pids, sessions)
- Generated: Yes (runtime)
- Committed: No (in .gitignore)

**log/:**
- Purpose: Application logs
- Generated: Yes (runtime)
- Committed: No (in .gitignore)

---

*Structure analysis: 2026-04-21*
