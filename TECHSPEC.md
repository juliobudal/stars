# Technical Specification: LittleStars 🌟

> **Versão:** 1.4 · **Última atualização:** 2026-06-05 · **Produto:** [PRODUCT.md](./PRODUCT.md) · **Design:** [DESIGN.md](./DESIGN.md)

---

## 1. Stack Tecnológica

| Camada | Tecnologia | Versão |
|---|---|---|
| **Framework** | Ruby on Rails (fullstack) | 8.x |
| **Linguagem** | Ruby | 3.3+ |
| **Banco de Dados** | PostgreSQL | 16+ |
| **UI Components** | Custom Duolingo design system — `Ui::*` ViewComponents (see [DESIGN.md](./DESIGN.md)) | — |
| **View Layer** | ViewComponent + ERB | 4.7 |
| **CSS** | TailwindCSS | 4.0 |
| **JS (interação)** | Stimulus | 3.x |
| **Navegação SPA-like** | Turbo (Drive + Frames + Streams) | 8.x |
| **Build** | Vite (via vite_rails) | — |
| **Containerização** | Docker + Docker Compose + Devcontainers | — |
| **Testes** | RSpec + FactoryBot + Capybara | — |

### Por que essa stack?

- **Rails fullstack** elimina a complexidade de um frontend separado. Turbo + Stimulus entregam interatividade suficiente para o scope do MVP sem SPA overhead.
- **Duolingo design system** (`Ui::*` ViewComponents em `app/components/ui/`) entrega ~50 componentes próprios (Btn, Card, Modal, FilterChips, SmileyAvatar, etc.) com tokens, motion e a11y centralizados em `DESIGN.md`.
- **PostgreSQL** garante transações ACID para a economia de estrelinhas (sem race conditions).
- **Docker + Devcontainers** padronizam perfeitamente o ambiente dos desenvolvedores (versões do Ruby, Node, extensões de VS Code). Todo o código, servidores e testes rodam exclusivamente dentro do container `web`, via `make` (rodar `bundle exec rspec`/`bin/rails` do host falha — o host do DB é inacessível).

---

## 2. Arquitetura da Aplicação

```
┌─────────────────────────────────────────────────┐
│                   Browser                        │
│  Turbo Drive (navegação) + Stimulus (interação) │
└──────────────────────┬──────────────────────────┘
                       │ HTTP / Turbo Streams
┌──────────────────────▼──────────────────────────┐
│              Rails Application                   │
│                                                  │
│  Controllers ──► ViewComponents ──► ERB Views    │
│       │                                          │
│  Services (business logic)                       │
│       │                                          │
│  Models (ActiveRecord) ──► PostgreSQL            │
└─────────────────────────────────────────────────┘
```

### Padrões Adotados

- **Service Objects** para lógica de negócio (aprovação, resgate, crédito de pontos).
- **ViewComponents** para toda UI reutilizável (cards de missão, carteira, itens da loja).
- **Turbo Frames** para atualizações parciais sem reload (fila de aprovações, saldo).
- **Turbo Streams** para broadcast real-time (saldo atualiza no Kid View quando pai aprova).
- **Stimulus Controllers** para animações e micro-interações (confetes, glow, idle animations).

---

## 3. Modelagem de Banco de Dados

> **`db/schema.rb` is authoritative** (schema version `2026_05_28_120100`). The data model grew well past the original 6-table core. Current host tables:
>
> | Table | Purpose |
> |---|---|
> | `families` | Tenant root; holds `has_secure_password` (parent login). |
> | `profiles` | Members (`role: child\|parent`), `points` balance, optional `wishlist_reward`. |
> | `categories` | Per-family reward categories (`Reward` belongs to one). |
> | `global_tasks` | Task templates (`category`, `frequency`, points). |
> | `global_task_assignments` | Join: which profiles a `global_task` targets. |
> | `profile_tasks` | A task materialized for a kid (`status` 6-state, `source: catalog\|custom`, `proof_photo`). |
> | `rewards` | Redeemable items (cost in stars, belongs to a `category`). |
> | `redemptions` | Redeem records (`status: pending\|approved\|rejected`) — the redeem ledger. |
> | `activity_logs` | Append-only points ledger (`log_type: earn\|redeem\|adjust\|decay`). |
> | `profile_interests` | Kid-selected interest tags (used to personalize Academy). |
> | `profile_invitations` | Family-member invites. |
>
> **Academy module** owns 5 prefixed tables with **zero FK into host** (see §13): `academy_trails`, `academy_lessons`, `academy_lesson_progresses`, `academy_guide_conversations`, `academy_guide_messages`.
>
> The ERD and migration snippets below depict the **original core** for context; consult `db/schema.rb` and `app/models/` for the current shape (§4 lists every model).

### ERD (Entity Relationship Diagram)

```
┌──────────────┐     ┌──────────────────┐     ┌───────────────┐
│   families   │     │     profiles      │     │  global_tasks  │
├──────────────┤     ├──────────────────┤     ├───────────────┤
│ id (PK)      │◄───┤ family_id (FK)    │     │ id (PK)       │
│ name         │     │ id (PK)          │     │ family_id(FK) │
│ created_at   │     │ name             │     │ title         │
│ updated_at   │     │ avatar           │     │ category      │
└──────────────┘     │ role (enum)      │     │ points        │
                     │ points (default 0)│     │ frequency     │
                     │ created_at       │     │ days_of_week  │
                     │ updated_at       │     │ created_at    │
                     └────────┬─────────┘     │ updated_at    │
                              │               └───────┬───────┘
                              │                       │
                     ┌────────▼─────────┐    ┌───────▼────────┐
                     │  activity_logs   │    │ profile_tasks   │
                     ├──────────────────┤    ├────────────────┤
                     │ id (PK)         │    │ id (PK)        │
                     │ profile_id (FK) │    │ profile_id(FK) │
                     │ log_type (enum) │    │ global_task_id │
                     │ title           │    │ status (enum)  │
                     │ points          │    │ completed_at   │
                     │ created_at      │    │ assigned_date  │
                     └─────────────────┘    │ created_at     │
                                            │ updated_at     │
                     ┌──────────────────┐   └────────────────┘
                     │     rewards      │
                     ├──────────────────┤
                     │ id (PK)         │
                     │ family_id (FK)  │
                     │ title           │
                     │ cost            │
                     │ icon            │
                     │ created_at      │
                     │ updated_at      │
                     └──────────────────┘
```

### Migrations

```ruby
# db/migrate/001_create_families.rb
class CreateFamilies < ActiveRecord::Migration[8.0]
  def change
    create_table :families do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end

# db/migrate/002_create_profiles.rb
class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :family, null: false, foreign_key: true
      t.string     :name, null: false
      t.string     :avatar, null: false, default: '🦊'
      t.integer    :role, null: false, default: 0  # enum: child=0, parent=1
      t.integer    :points, null: false, default: 0
      t.timestamps
    end

    add_index :profiles, [:family_id, :role]
  end
end

# db/migrate/003_create_global_tasks.rb
class CreateGlobalTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :global_tasks do |t|
      t.references :family, null: false, foreign_key: true
      t.string     :title, null: false
      t.integer    :category, null: false, default: 0  # enum
      t.integer    :points, null: false
      t.integer    :frequency, null: false, default: 0 # enum: daily=0, weekly=1
      t.integer    :days_of_week, array: true, default: [] # PG array [0..6]
      t.timestamps
    end
  end
end

# db/migrate/004_create_profile_tasks.rb
class CreateProfileTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :profile_tasks do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :global_task, null: false, foreign_key: true
      t.integer    :status, null: false, default: 0 # enum
      t.datetime   :completed_at
      t.date       :assigned_date, null: false
      t.timestamps
    end

    add_index :profile_tasks, [:profile_id, :assigned_date]
    add_index :profile_tasks, [:profile_id, :status]
  end
end

# db/migrate/005_create_rewards.rb
class CreateRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :rewards do |t|
      t.references :family, null: false, foreign_key: true
      t.string     :title, null: false
      t.integer    :cost, null: false
      t.string     :icon, null: false, default: '🎁'
      t.timestamps
    end
  end
end

# db/migrate/006_create_activity_logs.rb
class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.references :profile, null: false, foreign_key: true
      t.integer    :log_type, null: false # enum: earn=0, redeem=1
      t.string     :title, null: false
      t.integer    :points, null: false
      t.timestamps # created_at serve como timestamp do evento
    end

    add_index :activity_logs, [:profile_id, :created_at]
  end
end
```

---

## 4. Models (ActiveRecord)

Current associations + enums (validations/scopes trimmed for brevity — see `app/models/`):

```ruby
# app/models/family.rb — tenant root, holds parent password
class Family < ApplicationRecord
  has_secure_password                       # parent login
  has_many :profiles, dependent: :destroy
  has_many :global_tasks, dependent: :destroy
  has_many :rewards, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :profile_invitations, dependent: :destroy
  has_many :profile_tasks, through: :profiles
  has_many :redemptions,   through: :profiles
end

# app/models/profile.rb — a family member (kid or parent)
class Profile < ApplicationRecord
  belongs_to :family
  belongs_to :wishlist_reward, class_name: "Reward", optional: true
  has_many :profile_tasks, dependent: :destroy
  has_many :redemptions, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :global_task_assignments, dependent: :destroy
  has_many :sent_invitations, class_name: "ProfileInvitation",
                              foreign_key: :invited_by_id, dependent: :nullify
  has_many :profile_interests, -> { order(:rank, :id) }, dependent: :destroy

  enum :role, { child: 0, parent: 1 }, default: :child
  # points balance lives here; never mutate directly — go through a service
end

# app/models/category.rb — per-family reward category
class Category < ApplicationRecord
  belongs_to :family
  has_many :rewards, dependent: :restrict_with_error
end

# app/models/global_task.rb — a task template
class GlobalTask < ApplicationRecord
  belongs_to :family
  has_many :profile_tasks, dependent: :destroy
  has_many :global_task_assignments, dependent: :destroy
  has_many :assigned_profiles, through: :global_task_assignments, source: :profile

  enum :category, { escola: 0, casa: 1, rotina: 2, saude: 3, outro: 4 }
  enum :frequency, { daily: 0, weekly: 1, monthly: 2, once: 3 }
end

# app/models/global_task_assignment.rb — join: which kids a task targets
class GlobalTaskAssignment < ApplicationRecord
  belongs_to :global_task
  belongs_to :profile
end

# app/models/profile_task.rb — task materialized for one kid
class ProfileTask < ApplicationRecord
  belongs_to :profile
  belongs_to :global_task, optional: true                 # nil for custom tasks
  belongs_to :custom_category, class_name: "Category", optional: true
  has_one_attached :proof_photo

  enum :status, { pending: 0, awaiting_approval: 1, approved: 2,
                  rejected: 3, missed: 4, expired: 5 }, default: :pending
  enum :source, { catalog: 0, custom: 1 }, default: :catalog

  # Views read title/category/points off profile_task directly
  delegate :title, :category, :points, to: :global_task
end

# app/models/reward.rb — redeemable item
class Reward < ApplicationRecord
  belongs_to :family
  belongs_to :category
  has_many :redemptions, dependent: :restrict_with_error
end

# app/models/redemption.rb — redeem record (the redeem ledger)
class Redemption < ApplicationRecord
  belongs_to :profile
  belongs_to :reward
  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending
  delegate :title, to: :reward
end

# app/models/activity_log.rb — append-only points ledger
class ActivityLog < ApplicationRecord
  belongs_to :profile
  enum :log_type, { earn: 0, redeem: 1, adjust: 2, decay: 3 }
  scope :recent, -> { order(created_at: :desc) }
end

# Plus: ProfileInterest (belongs_to :profile) and
#       ProfileInvitation (belongs_to :family, :invited_by → Profile)
```

---

## 5. Service Objects (Business Logic)

### Aprovação de Tarefa (Transação Atômica)

```ruby
# app/services/tasks/approve_service.rb
module Tasks
  class ApproveService
    def initialize(profile_task:, approved_by:)
      @task = profile_task
      @parent = approved_by
    end

    def call
      return failure("Tarefa não está aguardando aprovação") unless @task.awaiting_approval?
      return failure("Apenas pais podem aprovar") unless @parent.parent?

      ActiveRecord::Base.transaction do
        @task.update!(status: :approved, completed_at: Time.current)
        @task.profile.increment!(:points, @task.points)

        ActivityLog.create!(
          profile: @task.profile,
          log_type: :earn,
          title: @task.title,
          points: @task.points
        )
      end

      success
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def success  = OpenStruct.new(success?: true)
    def failure(msg) = OpenStruct.new(success?: false, error: msg)
  end
end
```

### Resgate de Recompensa — Fluxo de 2 Etapas (Intencional)

O resgate de recompensa **não é atômico na submissão**. O fluxo é:

1. **Criança solicita** via `Rewards::RedeemService` → cria `Redemption{status: :pending}` (sem debitar pontos ainda).
2. **Pai aprova** na fila de aprovações → debita `Profile.points`, muda `Redemption.status` para `:approved`, cria `ActivityLog{log_type: :redeem}` — tudo em transação atômica.
3. **Pai rejeita** → `Redemption.status: :rejected`, sem efeito em pontos.

Essa separação é **intencional** e espelha o ciclo de aprovação de tarefas (`ProfileTask` → `awaiting_approval` → `approved`). Justificativa:
- Dá ao pai controle sobre resgates caros antes do débito de pontos.
- Evita débito-depois-estorno em caso de rejeição (estado mais simples, menos `ActivityLog` de reversão).
- Reusa a fila de aprovações já existente na `Parent::ApprovalsController`.

A validação de saldo ocorre **na solicitação** (criança não pode pedir resgate se `profile.points < reward.cost`) e **novamente na aprovação** (com `reload` dentro da transação, para evitar race condition caso a criança tenha gasto em outro resgate nesse intervalo).

### Resgate de Recompensa (Serviço de Solicitação)

```ruby
# app/services/rewards/redeem_service.rb
module Rewards
  class RedeemService
    def initialize(profile:, reward:)
      @profile = profile
      @reward = reward
    end

    def call
      return failure("Saldo insuficiente") if @profile.points < @reward.cost

      ActiveRecord::Base.transaction do
        @profile.decrement!(:points, @reward.cost)
        @profile.reload # garante leitura do valor atualizado

        raise ActiveRecord::Rollback if @profile.points.negative?

        ActivityLog.create!(
          profile: @profile,
          log_type: :redeem,
          title: @reward.title,
          points: @reward.cost
        )
      end

      success
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def success  = OpenStruct.new(success?: true)
    def failure(msg) = OpenStruct.new(success?: false, error: msg)
  end
end
```

### Reset Diário de Tarefas

```ruby
# app/services/tasks/daily_reset_service.rb
module Tasks
  class DailyResetService
    def call
      Family.find_each do |family|
        family.global_tasks.each do |task|
          next unless should_instantiate_today?(task)

          family.profiles.child.find_each do |child|
            child.profile_tasks.find_or_create_by!(
              global_task: task,
              assigned_date: Date.current
            ) do |pt|
              pt.status = :pending
            end
          end
        end
      end
    end

    private

    def should_instantiate_today?(task)
      return true if task.daily?
      return task.days_of_week.include?(Date.current.wday) if task.weekly?
      false
    end
  end
end
```

---

## 6. Rotas e Controllers

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "sessions#index" # Tela de seleção de perfil

  # Sessão (sem auth real no MVP — apenas seleção de perfil)
  resource :session, only: [:create, :destroy]

  # === PARENT ROUTES ===
  namespace :parent do
    root "dashboard#index"
    resources :profiles, only: [:new, :create, :edit, :update, :destroy] # filhos
    resources :global_tasks, only: [:index, :new, :create, :destroy]
    resources :rewards, only: [:index, :new, :create, :destroy]
    resources :approvals, only: [:index] do
      member do
        patch :approve
        patch :reject
      end
    end
    resources :activity_logs, only: [:index]
  end

  # === KID ROUTES ===
  namespace :kid do
    root "missions#index"
    resources :missions, only: [:index, :show] do
      member { patch :submit }
    end
    resource :wallet, only: [:show]
    resources :store, only: [:index] do
      member { post :redeem }
    end
    resources :activity_logs, only: [:index]
  end
end
```

### Estrutura de Controllers

| Controller | Namespace | Responsabilidade |
|---|---|---|
| `SessionsController` | root | Seleção de perfil, set `session[:profile_id]` |
| `Parent::DashboardController` | parent | Dashboard com stats e fila de aprovações |
| `Parent::ProfilesController` | parent | CRUD de filhos |
| `Parent::GlobalTasksController` | parent | CRUD de tarefas no banco global |
| `Parent::RewardsController` | parent | CRUD de recompensas na lojinha |
| `Parent::ApprovalsController` | parent | Aprovar/Rejeitar tasks pendentes |
| `Parent::ActivityLogsController` | parent | Histórico consolidado de todos os filhos |
| `Kid::MissionsController` | kid | Lista de missões do dia + submit |
| `Kid::WalletsController` | kid | Cartão de saldo |
| `Kid::StoreController` | kid | Lojinha + resgate |
| `Kid::ActivityLogsController` | kid | Histórico pessoal |

---

## 7. Mapeamento de UI (Duolingo `Ui::*` ViewComponents)

> The old "JetRockets components" naming is retired. The UI is a custom **Duolingo-style design system** built from `Ui::*` ViewComponents under `app/components/ui/`. **`DESIGN.md` is the single source of truth** for tokens, components, motion, and a11y — read it before any UI work.

### Component library (`app/components/ui/<name>/`)

Reach for an existing `Ui::*` component before writing inline markup; if a pattern recurs twice, extract a component in the same PR. The library is large (~50 components). Representative primitives:

| Group | Components |
|---|---|
| Actions | `Ui::Btn`, `Ui::Toggle`, `Ui::IconPicker`, `Ui::ColorSwatchPicker` |
| Surfaces | `Ui::Card`, `Ui::StatCard`, `Ui::Group`, `Ui::Header`, `Ui::PageHeader`, `Ui::Empty` |
| Tabs / chips | `Ui::FilterChips`, `Ui::CategoryTabs`, `Ui::Tabs`, `Ui::Chip`, `Ui::Badge`, `Ui::StarBadge`, `Ui::StreakBadge` |
| Lists / rows | `Ui::ApprovalRow`, `Ui::RedemptionRow`, `Ui::HistoryRow`, `Ui::CategoryRow`, `Ui::MissionCard`, `Ui::RewardCatalogCard` |
| Identity | `Ui::Avatar`, `Ui::SmileyAvatar`, `Ui::LogoMark`, `Ui::Brand` |
| Overlays | `Ui::Modal`, `Ui::Drawer`, `Ui::PinModal`, `Ui::Toast`, `Ui::Flash` |
| Forms | `Ui::Select`, `Ui::FormSection`, `Ui::FormErrors`, `Ui::ProgressSteps` |
| Decor / fx | `Ui::Icon` (HugeIcons SVG), `Ui::BgShapes`, `Ui::Confetti`, `Ui::Celebration`, `Ui::Spinner` |

### Stimulus controllers

Live in `app/assets/controllers/` (Vite-served, auto-registered via `stimulus-vite-helpers` in `index.js` — drop a `*_controller.js` file in, no manual registration). ~28 controllers, e.g. `count-up` (balance count up/down), `filter-tabs` / `tabs` (tab switching + `aria-selected` sync), `ui-modal`, `pin-pad`, `sidebar-toggle`, `bulk-select`, `star-picker`, `confetti`, and the Academy `academy-pill` (client-side `enigma → … → fisgada` reveal).

---

## 8. Turbo: Real-Time sem WebSockets

### Turbo Frames (Atualizações Parciais)

```erb
<%# Parent: Fila de aprovações atualiza sem reload %>
<%= turbo_frame_tag "approvals_list" do %>
  <%# lista de cards awaiting_approval %>
<% end %>

<%# Kid: Saldo atualiza após resgate %>
<%= turbo_frame_tag "wallet_balance" do %>
  <%# Stat component com saldo %>
<% end %>
```

### Turbo Streams (Broadcast Real-Time)

```ruby
# Após aprovação, broadcast para a Kid View:
# app/services/tasks/approve_service.rb (dentro da transaction)
Turbo::StreamsChannel.broadcast_update_to(
  "kid_#{@task.profile.id}",
  target: "wallet_balance",
  partial: "kid/wallets/balance",
  locals: { profile: @task.profile }
)
```

```erb
<%# Kid layout: subscribe ao canal %>
<%= turbo_stream_from "kid_#{current_profile.id}" %>
```

Isso permite que quando o pai aprova uma tarefa na sala, o saldo da criança atualize automaticamente no quarto — sem polling, sem WebSocket manual.

---

## 9. Docker Compose e Devcontainer

Para isolamento puro e Developer Experience impecável, todo o ambiente de desenvolvimento será controlado via [Devcontainers](https://containers.dev/). O terminal de trabalho principal deve ser o shell do container gerador pelo VS Code/Cursor.

### `.devcontainer/devcontainer.json`
```json
{
  "name": "LittleStars",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "web",
  "workspaceFolder": "/app",
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "Shopify.ruby-lsp",
        "castwide.solargraph",
        "bradlc.vscode-tailwindcss"
      ]
    }
  },
  "postCreateCommand": "bundle install && yarn install",
  "forwardPorts": [3000, 5432]
}
```

### Inicialização do Compose

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: littlestars
      POSTGRES_PASSWORD: littlestars_dev
      POSTGRES_DB: littlestars_development
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  web:
    build: .
    command: bin/dev
    ports:
      - "3000:3000"
    depends_on:
      - db
    environment:
      DATABASE_URL: postgres://littlestars:littlestars_dev@db:5432/littlestars_development
      RAILS_ENV: development
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle

volumes:
  pgdata:
  bundle_cache:
```

```dockerfile
# Dockerfile
FROM ruby:3.3-slim

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm git && \
    npm install -g corepack && \
    corepack enable

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
```

---

## 10. Estrutura de Diretórios

```
app/
├── components/              # ViewComponents — ui/ (Ui::* design system), kid/, parent/
│   ├── kid/
│   │   ├── mission_card_component.rb
│   │   ├── wallet_card_component.rb
│   │   └── store_item_component.rb
│   └── parent/
│       ├── approval_card_component.rb
│       └── stats_overview_component.rb
├── controllers/
│   ├── sessions_controller.rb
│   ├── kid/
│   │   ├── missions_controller.rb
│   │   ├── wallets_controller.rb
│   │   ├── store_controller.rb
│   │   └── activity_logs_controller.rb
│   └── parent/
│       ├── dashboard_controller.rb
│       ├── profiles_controller.rb
│       ├── global_tasks_controller.rb
│       ├── rewards_controller.rb
│       ├── approvals_controller.rb
│       └── activity_logs_controller.rb
├── javascript/controllers/   # Stimulus
│   ├── animated_counter_controller.js
│   ├── celebration_controller.js
│   ├── approval_animation_controller.js
│   ├── idle_wobble_controller.js
│   └── confetti_controller.js
├── models/
│   ├── family.rb
│   ├── profile.rb
│   ├── global_task.rb
│   ├── profile_task.rb
│   ├── reward.rb
│   └── activity_log.rb
├── services/
│   ├── tasks/
│   │   ├── approve_service.rb
│   │   ├── reject_service.rb
│   │   └── daily_reset_service.rb
│   └── rewards/
│       └── redeem_service.rb
└── views/
    ├── layouts/
    │   ├── kid.html.erb       # Layout lúdico (bordas, cores vibrantes)
    │   └── parent.html.erb    # Layout dashboard (clean, eficiente)
    ├── sessions/
    │   └── index.html.erb     # Seleção de perfil
    ├── kid/
    │   ├── missions/
    │   ├── wallets/
    │   ├── store/
    │   └── activity_logs/
    └── parent/
        ├── dashboard/
        ├── profiles/
        ├── global_tasks/
        ├── rewards/
        ├── approvals/
        └── activity_logs/
```

---

## 11. Testes

```ruby
# Gemfile (group :test)
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'shoulda-matchers'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
end
```

### Estratégia de Testes

| Tipo | Target | Ferramenta |
|---|---|---|
| **Model specs** | Validações, scopes, enums | RSpec |
| **Service specs** | Transações atômicas, edge cases (saldo negativo, double-approve) | RSpec |
| **Request specs** | Rotas, responses, autorização (pai vs filho) | RSpec |
| **System specs** | Fluxos completos (criar tarefa → atribuir → submeter → aprovar) | Capybara |

### Casos Críticos para Testar

```ruby
# spec/services/rewards/redeem_service_spec.rb
RSpec.describe Rewards::RedeemService do
  it "deduz pontos e cria activity_log" do
    # ...
  end

  it "recusa se saldo insuficiente" do
    # ...
  end

  it "não permite saldo negativo via race condition" do
    # Two concurrent redeems for the same profile
    # ...
  end
end
```

---

## 12. Cronograma de Implementação

| Sprint | Duração | Foco | Entregáveis |
|---|---|---|---|
| **0** | 1 dia | Setup | Docker Compose rodando, Rails app criado, Vite + Tailwind 4 configurados, DB migrations executadas. |
| **1** | 3-4 dias | Core Models + Parent CRUD | Models, services, Parent Dashboard (tarefas + recompensas + perfis de filhos). |
| **2** | 3-4 dias | Kid View | Missões do dia, carteira, loja, resgate com celebração. |
| **3** | 2-3 dias | Ciclo de Aprovação | Fila de aprovações, approve/reject com Turbo Streams, broadcast de saldo. |
| **4** | 2 dias | Extrato + Polish | Timeline de atividades, animações idle, testes de integração. |

---

## 13. Academy Module ("Pílulas de Conhecimento")

> **Status:** redesigned 2026-05-28 (replaced the v2 missions/medals system) · **Authoritative spec:** [`specs/001-academy-redesign/`](./specs/001-academy-redesign/)

Academy is an isolated learning subsystem layered on the core app. The model is radically simple: a **Trilha (trail)** holds an ordered list of **Aulas / pílulas (lessons)** that unlock in sequence. Each lesson teaches one idea through the **método do mistério** — `enigma → pistas → revelação → teste → fisgada` — defined entirely in curated seed content. The only runtime LLM is the **"O Guia"** chatbot, scoped to a single lesson.

The v2/v4 system (subjects, missions, sessions, medals, concepts/graph, skills, ranks, secrets, wagers, lightning) was **removed**.

### 13.1 Isolation contract

Academy is **not** a Rails engine — it's a strictly namespaced module that mirrors the host service contract while owning its own tables, persona, and HTTP surface.

- All tables prefixed `academy_*`. **Zero FK** into host tables (no `family_id`, no `profile_id` — the learner is referenced by bare id).
- All models under `Academy::`, inheriting `Academy::ApplicationRecord` (which opts out of `strict_loading_by_default` — services own access patterns).
- Host → Academy bridge: `Academy::Learner.from_profile(current_profile)`, a `Data.define(:id, :display_name, :age_band, :timezone, :interests)`. Reverse direction (Academy → host models) is forbidden.
- All services under `Academy::*` inherit `Academy::ApplicationService < ::ApplicationService` and return the same `Result` Data class as the host.

### 13.2 Stack additions

| Layer | Tech | Why |
|---|---|---|
| LLM gateway | OpenRouter (OpenAI-compatible REST) | One key, many models. Default model `deepseek/deepseek-v4-flash`. |
| Transport | `Academy::Llm::Client` (`Net::HTTP`) | Thin, testable client. **No** `langchainrb`/`ruby-openai` gems. |
| Persona | `Academy::Guide::Persona` + `Academy::Guide::BuildPrompt` | "O Guia": authoritative · mysterious · fascinated, scoped to the current lesson. |
| Config | `Academy.config` (via `config/initializers/academy.rb`) | Reads credentials/ENV once; the module never reads ENV directly. |

### 13.3 Data model (5 tables)

```
academy_trails ──< academy_lessons               (ordered by `position`, unlocked in sequence)
academy_lessons ──< academy_lesson_progresses    (one per learner × lesson: completed_at, check_choice, check_correct)

academy_guide_conversations ──< academy_guide_messages   (per learner × lesson chat with "O Guia")
```

Each `Academy::Lesson` carries a `payload` jsonb encoding the método do mistério: `clues[]`, `revelation`, `check{}` (multiple-choice with `answer_index`), and `hook`. The step-by-step reveal is client-side (`academy_pill_controller.js`). Progress is keyed by `learner_id` (a profile id) — no FK.

### 13.4 Service objects

| Service | Responsibility |
|---|---|
| `Academy::Lessons::Available` | Resolves each lesson's unlock status for a learner → `:completed \| :available \| :locked`. Sequential: lesson N unlocks once N-1 is completed; the first is always available. |
| `Academy::Lessons::Complete` | Idempotent: records first `completed_at`, stores the check answer/correctness, returns `next_lesson`. **Awards no stars** — Academy is formation, not economy. |
| `Academy::Guide::Ask` | Drives one "O Guia" question scoped to a lesson. Enforces `DAILY_QUESTION_LIMIT = 5` per learner across all lessons (`fail_with(:quota_exceeded)` beyond that). |
| `Academy::Guide::FindOrStartConversation` | Idempotent per learner × lesson conversation. |
| `Academy::Content::ArcValidator` | Dev/seed guard over the curated narrative arcs. |

### 13.5 HTTP surface

```
GET  /kid/academy                                          trails index (root)
GET  /kid/academy/trails/:slug                             lesson list (sequentially locked)
GET  /kid/academy/trails/:slug/lessons/:slug               a pílula (enigma → … → fisgada)
GET  /kid/academy/trails/:slug/lessons/:slug/guide         "O Guia" chat for this lesson
POST /kid/academy/trails/:slug/lessons/:slug/guide         ask one question (5/day)

GET  /parent/academy                                       per-child progress dashboard
```

Kid surface lives under `app/views/kid/academy/` and follows the global Duolingo system (DESIGN.md). Controllers under `Kid::Academy::` / `Parent::Academy::` build an `Academy::Learner` at the boundary and call services — no host model leaks in.

### 13.6 UI rules specific to Academy

- Bottom-nav entry "Academia" (sparkle icon) stays highlighted across nested pages.
- The lesson reveal (`enigma → pistas → revelação → teste → fisgada`) is staged client-side via `academy_pill_controller.js`.
- "O Guia" is the **one** place emoji are sanctioned as decorative narrative content (🤔 💡 🔮 🦉) — always `aria-hidden`, never the sole label of a control (DESIGN.md §5).
- Without `OPENROUTER_API_KEY` the 🦉 Guia button disappears and the lesson works normally.

### 13.7 Environment

```
OPENROUTER_API_KEY=sk-or-v1-...        # or Rails credentials :openrouter/:api_key
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
ACADEMY_LLM_MODEL=deepseek/deepseek-v4-flash
ACADEMY_LLM_TEMPERATURE=0.7
ACADEMY_LLM_MAX_TOKENS=10000
```

Module is inert without a key — `Academy.configured?` is false, the Guide button hides, and lessons stay fully usable. `config/initializers/academy.rb` reads credentials/ENV → `Academy.configure`; the module never reads ENV directly.

### 13.8 Seeds & ops

- `db/seeds/academy.rb` + `db/seeds/academy_content.rb` — the entire curriculum (trails + ordered lessons with their `payload` arcs) is curated here, idempotent on `slug`.
- Chained from `db/seeds.rb` so `make seed` refreshes the curriculum even when host data exists.
- `make db-reset` stops the `web` container during the drop (Puma + Solid Queue hold persistent connections that reconnect within ms).

### 13.9 Extending into new modules

To add another isolated subsystem (Journal, Reading, …) mirror the Academy contract — see `app/models/academy.rb`: top-level namespace + `Config` + `Learner` adapter, `<module>_*` table prefix, **zero host FKs**, host bridge only at the controller layer, a dedicated initializer reading credentials/ENV.

---

## Changelog

| Versão | Data | Mudanças |
|---|---|---|
| 1.4 | 2026-06-05 | A11y pass: contrast tokens (`--text-muted`/`--text-soft`/`--c-reward-text` cleared to WCAG AA), `h1` coverage (TopBar always-`h1` + kid dashboard), tab ARIA on `Ui::CategoryTabs`, modal/drawer blur reconciled with DESIGN.md. Docs refreshed (PRODUCT/README/TECHSPEC/CLAUDE) to match the current schema + Academy redesign. |
| 1.3 | 2026-06-01 | Duolingo design system + "quase plano" pass; retired the Berry Pop / Fraunces / lilac era. `DESIGN.md` is now the UI source of truth (§7). |
| 1.2 | 2026-05-28 | **Academy redesign — "Pílulas de Conhecimento"** (§13). v2 subjects/missions/sessions/medals **removed**; replaced by the 5-table **Trilha → Aulas** model + método do mistério. "O Guia" LLM retained (custom `Net::HTTP` OpenRouter client; langchain/openai gems dropped). Host data model also grew: `categories`, `global_task_assignments`, `redemptions`, `profile_interests`, `profile_invitations` (§3–§4). |
| 1.1 | 2026-05-15 | §13 — Academy module v2 (LLM-guided missions/medals) shipped. **Superseded by 1.2.** |
| 1.0 | 2026-04-19 | Documento inicial — stack Rails 8 + PostgreSQL + JetRockets UI + Docker Compose. |
