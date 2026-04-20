# Technical Specification: LittleStars 🌟

> **Versão:** 1.0 · **Última atualização:** 2026-04-19 · **Referência:** [PRD_LittleStars.md](./PRD_LittleStars.md)

---

## 1. Stack Tecnológica

| Camada | Tecnologia | Versão |
|---|---|---|
| **Framework** | Ruby on Rails (fullstack) | 8.x |
| **Linguagem** | Ruby | 3.3+ |
| **Banco de Dados** | PostgreSQL | 16+ |
| **UI Components** | [JetRockets UI](https://ui.jetrockets.com/ui) | latest |
| **View Layer** | ViewComponent + ERB | — |
| **CSS** | TailwindCSS | 4.0 |
| **JS (interação)** | Stimulus | 3.x |
| **Navegação SPA-like** | Turbo (Drive + Frames + Streams) | 8.x |
| **Build** | Vite (via vite_rails) | — |
| **Containerização** | Docker + Docker Compose + Devcontainers | — |
| **Testes** | RSpec + FactoryBot + Capybara | — |

### Por que essa stack?

- **Rails fullstack** elimina a complexidade de um frontend separado. Turbo + Stimulus entregam interatividade suficiente para o scope do MVP sem SPA overhead.
- **JetRockets UI** fornece 29+ componentes prontos (Card, Modal, Avatar, Badge, Tabs, Timeline, Stat, etc.) que mapeiam diretamente para as telas do LittleStars.
- **PostgreSQL** garante transações ACID para a economia de estrelinhas (sem race conditions).
- **Docker + Devcontainers** padronizam perfeitamente o ambiente dos desenvolvedores (versões do Ruby, Node, extensões de VS Code). Todo o código, servidores (`bin/dev`) e testes rodam exclusivamente dentro do container `web`.

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

```ruby
# app/models/family.rb
class Family < ApplicationRecord
  has_many :profiles, dependent: :destroy
  has_many :global_tasks, dependent: :destroy
  has_many :rewards, dependent: :destroy

  validates :name, presence: true
end

# app/models/profile.rb
class Profile < ApplicationRecord
  belongs_to :family
  has_many :profile_tasks, dependent: :destroy
  has_many :activity_logs, dependent: :destroy

  enum :role, { child: 0, parent: 1 }

  validates :name, presence: true
  validates :points, numericality: { greater_than_or_equal_to: 0 }

  def parent? = role == 'parent'
  def child?  = role == 'child'
end

# app/models/global_task.rb
class GlobalTask < ApplicationRecord
  belongs_to :family
  has_many :profile_tasks, dependent: :destroy

  enum :category, { escola: 0, casa: 1, rotina: 2, outro: 3 }
  enum :frequency, { daily: 0, weekly: 1 }

  validates :title, :points, presence: true
  validates :points, numericality: { greater_than: 0 }
end

# app/models/profile_task.rb
class ProfileTask < ApplicationRecord
  belongs_to :profile
  belongs_to :global_task

  enum :status, {
    pending: 0,
    awaiting_approval: 1,
    approved: 2,
    rejected: 3
  }

  validates :assigned_date, presence: true

  scope :for_today, -> { where(assigned_date: Date.current) }
  scope :actionable, -> { where(status: [:pending, :awaiting_approval]) }

  # Delegates para a view não precisar navegar no belongs_to
  delegate :title, :category, :points, to: :global_task
end

# app/models/reward.rb
class Reward < ApplicationRecord
  belongs_to :family

  validates :title, :cost, presence: true
  validates :cost, numericality: { greater_than: 0 }
end

# app/models/activity_log.rb
class ActivityLog < ApplicationRecord
  belongs_to :profile

  enum :log_type, { earn: 0, redeem: 1 }

  validates :title, :points, :log_type, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
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

### Resgate de Recompensa (com Validação de Saldo)

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

## 7. Mapeamento de UI (JetRockets Components)

### Componentes Utilizados por Tela

| Tela | JetRockets Components | Stimulus Controllers |
|---|---|---|
| **Seleção de Perfil** | `Avatar`, `Card`, `Group` | — |
| **Parent Dashboard** | `Stat`, `Card`, `Badge`, `Tabs`, `Button` | — |
| **Aprovações** | `Card`, `Button`, `Badge`, `Alert`, `Flash Message` | `approval_animation` |
| **Banco de Tarefas** | `Table`, `Modal`, Form Builder (`TextField`, `Select`), `Button`, `Empty` | — |
| **Lojinha (Cadastro)** | `Table`, `Modal`, Form Builder, `Button` | — |
| **Kid — Missões** | `Card`, `Badge`, `Button`, `Modal`, `Tabs`, `Empty` | `mission_submit` |
| **Kid — Carteira** | `Stat`, `Card` | `animated_counter` |
| **Kid — Loja** | `Card`, `Badge`, `Button`, `Modal` | `idle_wobble`, `celebration` |
| **Extrato** | `Timeline`, `Badge`, `Tabs` | — |

### Stimulus Controllers Customizados

```
app/javascript/controllers/
├── animated_counter_controller.js  # Anima mudança de saldo (count up/down)
├── celebration_controller.js       # Confetes + glow no resgate de recompensa
├── approval_animation_controller.js # Flash verde/vermelho na aprovação/rejeição
├── idle_wobble_controller.js       # Rotação suave ±5° nos cards da loja
└── confetti_controller.js          # Partículas de confete reutilizável
```

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
        "bradlc.vscode-tailwindcss",
        "jetrockets.jetrockets-ui-vscode"
      ]
    }
  },
  "postCreateCommand": "bundle install && yarn install",
  "forwardPorts": [3000, 5432]
}
```

### Inicialização do Compose
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
├── components/              # ViewComponents (JetRockets pattern)
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
| **0** | 1 dia | Setup | Docker Compose rodando, Rails app criado, JetRockets UI instalado, DB migrations executadas. |
| **1** | 3-4 dias | Core Models + Parent CRUD | Models, services, Parent Dashboard (tarefas + recompensas + perfis de filhos). |
| **2** | 3-4 dias | Kid View | Missões do dia, carteira, loja, resgate com celebração. |
| **3** | 2-3 dias | Ciclo de Aprovação | Fila de aprovações, approve/reject com Turbo Streams, broadcast de saldo. |
| **4** | 2 dias | Extrato + Polish | Timeline de atividades, animações idle, testes de integração. |

---

## Changelog

| Versão | Data | Mudanças |
|---|---|---|
| 1.0 | 2026-04-19 | Documento inicial — stack Rails 8 + PostgreSQL + JetRockets UI + Docker Compose. |
