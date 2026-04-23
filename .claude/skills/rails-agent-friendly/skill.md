---
name: rails-agent-friendly
description: Rails Agent-Friendly guide — conventions and patterns for AI agents to produce assertive, predictable Rails code without regressions. Use when writing any backend Rails code (controllers, services, models, queries, jobs, specs).
---

# Rails Agent-Friendly — Guia de Referência v2

Regras e padrões para que agentes de IA produzam código Rails assertivo, previsível e sem regressões.

> **Princípio organizador:** O melhor código para agentes é o mesmo código que DHH defende para humanos — convenção forte, explícito sobre implícito, e cada coisa no lugar que o framework espera. O agente não precisa de patterns especiais — precisa que você siga os patterns que o Rails já oferece, consistentemente.

---

## 1. CLAUDE.md (obrigatório na raiz)

O agente lê isso antes de qualquer tool call. Substitui 5–10 chamadas de exploração.

```markdown
# [Nome do Projeto]

## Stack
- Ruby X.X, Rails X.X, PostgreSQL, Redis, Sidekiq

## Domínios
app/domains/
  billing/   → Assinaturas, cobranças
  catalog/   → Produtos, categorias
  identity/  → Usuários, autenticação

## Rotas principais
POST   /billing/subscriptions      → Billing::SubscriptionsController#create
DELETE /billing/subscriptions/:id   → Billing::SubscriptionsController#destroy
GET    /catalog/plans               → Catalog::PlansController#index

## Convenções
- Controllers: apenas 7 actions REST, sem actions customizadas
- Lógica de negócio: Services com interface `.call` (ver padrão abaixo)
- Queries: QueryObjects em app/domains/[domain]/queries/
- Cross-domain: apenas via IDs, nunca ActiveRecord relations diretas
- N+1: eager loading sempre no QueryObject, nunca no controller
- Enums: sempre integer-backed com `prefix: true`
- Frontend: Hotwire (Turbo Frames + Turbo Streams + Stimulus)

## O que NÃO delegar ao agente
- Migrations com dados existentes
- Alterações em schema de tabelas críticas
- Lógica de autenticação e autorização
- Qualquer coisa que dependa do estado de produção
- Criar/editar credentials (precisa de master key)
- Seeds / fixtures de produção
- Rollback de migrations

## Testes
bundle exec rspec                        # tudo
bundle exec rspec spec/domains/billing/  # domínio isolado

## NÃO FAZER
- Sem lógica em helpers
- Sem metaprogramação (method_missing, define_method, send dinâmico)
- Sem callbacks afetando outros domínios
- Sem importar classes de outro domínio diretamente
- Sem hardcode de tokens, chaves ou URLs de API
- Sem `rescue StandardError` ou `rescue Exception`
- Sem endpoints JSON para consumo frontend (usar Turbo)
```

---

## 2. Naming

Nomes expressivos eliminam a necessidade de o agente ler o corpo do método para entender o que ele faz.

```ruby
# ❌
def process(order)
def handle(user, type)
class DataService

# ✅
def charge_subscription(order)
def suspend_user_for_fraud(user)
class SubscriptionBillingService
```

Padrão: `VerboDomínio + Contexto`. Sempre. Nomes longos são baratos; ambiguidade é cara.

---

## 3. Schema como Documentação

O agente frequentemente lê `db/schema.rb` inteiro para entender um modelo — caro em tokens. Declare o schema diretamente no model.

Use a gem `annotate` para automatizar. Sem automação, o schema comment fica desatualizado no segundo migration e o agente lê informação errada — pior do que não ter.

```ruby
# Gemfile
gem 'annotate', group: :development

# Gera automaticamente após migrate:
# lib/tasks/auto_annotate_models.rake
# annotate --position before --show-foreign-keys --show-indexes
```

Resultado no model:

```ruby
# app/domains/billing/models/subscription.rb

# == Schema
# id          :bigint
# account_id  :bigint    (FK → accounts, index)
# plan_id     :bigint    (FK → plans, index)
# status      :integer   (0=active, 1=suspended, 2=cancelled)
# expires_at  :datetime
# created_at  :datetime
#
class Billing::Subscription < ApplicationRecord
  # ...
end
```

Custo: ~5 linhas. Benefício: elimina `db/schema.rb` do contexto.

---

## 4. Interface de Services — Padrão `.call`

Sem um contrato definido, agentes inventam interfaces diferentes a cada geração. Padronize:

```ruby
# app/domains/billing/services/activate_subscription_service.rb
module Billing
  class ActivateSubscriptionService
    Result = Data.define(:success, :subscription, :error)

    def self.call(...) = new(...).call

    def initialize(user:, plan:, payment_method:)
      @user           = user
      @plan           = plan
      @payment_method = payment_method
    end

    def call
      subscription = create_subscription
      charge_first_invoice(subscription)
      notify_user(subscription)

      Result.new(success: true, subscription: subscription, error: nil)
    rescue PaymentError => e
      Result.new(success: false, subscription: nil, error: e.message)
    end

    def success? = success  # convenience predicate

    private

    def create_subscription  = ...
    def charge_first_invoice = ...
    def notify_user          = ...
  end
end

# Uso sempre igual, independente do agente que escreveu
result = Billing::ActivateSubscriptionService.call(
  user: current_user,
  plan: plan,
  payment_method: payment_method
)

if result.success?
  redirect_to dashboard_path
else
  flash[:error] = result.error
end
```

**Regras do padrão:**
- `.call` sempre como entry point
- Retorna um `Result` com `success`, dado e erro — nunca levanta exceção para fluxo de negócio
- `Data.define` não aceita `?` no nome do campo — use `success` e adicione `success?` como predicate method no Result se necessário
- `initialize` apenas recebe dependências, sem executar lógica
- Métodos privados com nomes de intenção, não de implementação

---

## 5. Error Handling

Sem convenção, cada agente inventa um padrão diferente de rescue/raise.

```markdown
## Regras de Erros
- Erros de negócio: retorne no Result, nunca raise
- Erros de infra (timeout, conexão): raise e deixe o controller rescue
- ApplicationController tem rescue_from para erros comuns
- Nunca rescue StandardError ou Exception
```

```ruby
# ApplicationController
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found
    respond_to do |format|
      format.html { render "errors/not_found", status: :not_found }
      format.turbo_stream { head :not_found }
    end
  end

  def bad_request
    head :bad_request
  end
end
```

---

## 6. Query Objects — N+1 Zero por Convenção

Agentes geram N+1 queries constantemente. A defesa mais eficaz é tornar o eager loading parte do contrato do QueryObject, combinada com strict loading no framework.

### Strict Loading (enforcement real)

```ruby
# config/environments/development.rb
config.active_record.strict_loading_by_default = true

# Agora qualquer lazy load levanta ActiveRecord::StrictLoadingViolationError
# O agente é forçado a declarar includes explicitamente

# Para relaxar em casos específicos:
user = User.strict_loading(false).find(id)
```

### QueryObject Pattern

```ruby
# app/domains/billing/queries/overdue_subscriptions_query.rb
module Billing
  class OverdueSubscriptionsQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call
      @relation
        .includes(:account, :plan, :invoices)  # eager loading explícito aqui
        .where(status: :active)
        .where("expires_at < ?", Time.current)
        .order(expires_at: :asc)
    end
  end
end
```

**Regras:**
- `includes` sempre no QueryObject, nunca no controller
- Recebe uma `relation` como argumento (facilita composição e testes)
- Retorna um scope, não um array — permite encadeamento

---

## 7. Organização por Domínio (não por tipo)

```
# ❌ Horizontal — agente precisa navegar 4 diretórios para entender uma feature
app/controllers/billing/
app/models/subscription.rb
app/services/billing/
app/views/billing/

# ✅ Vertical — tudo do domínio junto
app/domains/billing/
  controllers/
  models/
  concerns/
  services/
  queries/
  jobs/
  mailers/
  views/
  README.md
```

### Autoload (obrigatório)

Sem isso o agente cria a estrutura e quebra no boot.

```ruby
# config/application.rb
config.autoload_paths += Dir[Rails.root.join("app/domains/*/")]
```

---

## 8. README por Domínio

~300 tokens que eliminam exploração desnecessária a cada sessão.

```markdown
# Billing Domain

## Responsabilidade
Gerencia assinaturas, cobranças e faturas.

## Entry points principais
- `ActivateSubscriptionService.call` — ativa nova assinatura
- `BillingCycleJob` — processa cobranças mensais (Sidekiq)

## Modelos
- `Subscription` — vínculo conta/plano, status e validade
- `Invoice` — fatura gerada por ciclo
- `PaymentMethod` — cartão ou boleto

## NÃO pertence aqui
- Cadastro de usuário → Identity domain
- Exibição de preços → Catalog domain

## Dependências externas
- Stripe API via `app/lib/stripe_gateway.rb`
```

---

## 9. Concerns — Padrão DHH de Extração de Comportamento

Concerns são o mecanismo primário de extração de comportamento no Rails Way. Sem essa instrução o agente cria services para tudo, inclusive lógica que pertence ao model.

```ruby
# app/domains/billing/models/concerns/subscription/expirable.rb
module Subscription::Expirable
  extend ActiveSupport::Concern

  included do
    scope :expired, -> { where("expires_at < ?", Time.current) }
    scope :expiring_soon, -> { where(expires_at: Time.current..3.days.from_now) }
  end

  def expired? = expires_at < Time.current
  def days_until_expiry = (expires_at.to_date - Date.current).to_i
end
```

**Quando usar o quê:**
- **Concern** = comportamento do próprio model (queries, predicados, cálculos sobre `self`)
- **Service** = orquestração entre objetos ou side effects externos
- Se o método só acessa `self`, provavelmente é concern
- Se o método coordena 2+ objetos, é service

---

## 10. Model Authority

```ruby
# ❌ Atravessa associações — frágil, agente pode quebrar silenciosamente
user.subscription.plan.features.include?(:export)

# ✅ O model responde pela própria lógica
user.can_export?

# No model:
def can_export?
  subscription&.active? && subscription.plan.feature?(:export)
end
```

### Delegations — Tell, Don't Ask

```ruby
# ❌ Law of Demeter violation (agentes fazem isso o tempo todo)
subscription.account.name
subscription.plan.price

# ✅ Delegate
class Subscription < ApplicationRecord
  delegate :name, to: :account, prefix: true   # subscription.account_name
  delegate :price, to: :plan, prefix: true      # subscription.plan_price
end
```

---

## 11. Controllers — Padrão DHH Multi-Controller

Apenas 7 actions REST. Se precisa de mais, crie um sub-resource controller.

```ruby
# ❌ Action customizada (8ª action — fora do padrão)
class SubscriptionsController
  def cancel
  end
end

# ✅ Novo controller com recurso derivado
class Subscriptions::CancellationsController < ApplicationController
  def create  # POST /subscriptions/:id/cancellation
    result = Billing::CancelSubscriptionService.call(subscription: @subscription)
    # ...
  end
end
```

### Controller Template

```ruby
class Billing::SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :update, :destroy]

  def index
    @subscriptions = Billing::ActiveSubscriptionsQuery.new.call
  end

  def create
    result = Billing::ActivateSubscriptionService.call(**subscription_params)

    if result.success?
      redirect_to billing_subscription_path(result.subscription)
    else
      flash.now[:error] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_subscription
    @subscription = Current.account.subscriptions.find(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(:plan_id, :payment_method_id)
  end
end
```

---

## 12. Routing — Nested Resources com Limites

```ruby
# ❌ Nunca mais que 1 nível de nesting
resources :accounts do
  resources :subscriptions do
    resources :invoices  # 3 níveis — URLs ilegíveis, agente se perde
  end
end

# ✅ Shallow nesting
resources :accounts do
  resources :subscriptions, shallow: true
end
resources :subscriptions do
  resources :invoices, shallow: true
end

# Resultado: /subscriptions/:id (não /accounts/:account_id/subscriptions/:id)
```

---

## 13. Current Attributes — Contexto de Request sem Passar Parâmetros

Agentes tendem a passar `current_user` por 4 camadas de profundidade. O `Current` resolve isso no Rails Way.

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :account, :request_id
end

# Setado no ApplicationController
class ApplicationController < ActionController::Base
  before_action :set_current

  private

  def set_current
    Current.user    = current_user
    Current.account = current_user&.account
    Current.request_id = request.request_id
  end
end

# Usado em qualquer camada sem injeção
class Billing::ActivateSubscriptionService
  def call
    subscription = Current.account.subscriptions.create!(plan: @plan)
    # ...
  end
end
```

**⚠️ NÃO usar em Jobs** — rodam fora do request cycle. Em Jobs, passe IDs explicitamente.

---

## 14. Callbacks: Regra Clara

Callbacks ocultos são o principal gerador de bugs por agentes — efeitos colaterais invisíveis.

```ruby
# ✅ Aceitável: invariante do próprio modelo
before_validation :normalize_email
before_save       :compute_expires_at

# ❌ Proibido: efeito em outro domínio ou side effect externo
after_create :send_welcome_email    # → mover para Service
after_save   :update_billing_status # → mover para Named Orchestration
after_commit :sync_to_crm           # → mover para Observer ou Event
```

Coordenação entre domínios → sempre em um Service explícito e nomeado.

---

## 15. Enums com Prefixo

```ruby
# ❌ Agente gera enum simples — colide com outros enums ou métodos
enum status: [:active, :inactive]  # gera .active que pode colidir

# ✅ Com prefix
enum :status, { active: 0, suspended: 1, cancelled: 2 }, prefix: true
# gera: .status_active, .status_active?, .status_suspended!

# Regras:
# - Sempre integer-backed (não string) — performance e storage
# - Sempre com prefix: true
# - Valores novos sempre no final — nunca reordene
# - Documente os valores no schema comment do model
```

---

## 16. Scopes com Nomes Completos

```ruby
# ❌ Genérico — agente não sabe o que "recent" significa neste domínio
scope :recent, -> { where("created_at > ?", 30.days.ago) }
scope :active, -> { where(active: true) }

# ✅ Explícito e composável
scope :created_within, ->(period) { where(created_at: period) }
scope :with_status, ->(status) { where(status:) }
scope :billable, -> { status_active.where("expires_at > ?", Time.current) }

# Regra: scope retorna relation (nunca `.first`, `.count`, `.pluck`)
# Se precisa de valor escalar → class method
```

---

## 17. Cross-Domain Communication

O guia proíbe acesso direto entre domínios. Aqui está o que usar no lugar:

```ruby
# Opção 1: Domain Event (preferida — desacoplamento real)
# Publicar no service do domínio origem:
Billing::SubscriptionActivated.publish(subscription_id: subscription.id)

# Consumir no domínio destino:
class Notifications::OnSubscriptionActivated
  def call(event)
    subscription = Billing::Subscription.find(event[:subscription_id])
    NotificationMailer.subscription_activated(subscription).deliver_later
  end
end

# Opção 2: Orchestration Service (quando precisa de resposta síncrona)
# Vive no domínio que orquestra:
class Onboarding::ActivateNewUserService
  def call
    identity_result = Identity::CreateUserService.call(...)
    billing_result  = Billing::ActivateSubscriptionService.call(...)
    # combina resultados
  end
end

# ❌ Nunca: acesso direto entre domínios
Billing::Subscription.find_by(account: Identity::User.find(...))
```

---

## 18. Background Jobs

```ruby
# Regra: Job = orquestrador. Chama um Service, não contém lógica.
# Idempotente sempre (pode rodar 2x sem efeito duplicado).

# ✅
class Billing::ProcessOverdueInvoicesJob < ApplicationJob
  queue_as :billing

  def perform(invoice_id)
    invoice = Billing::Invoice.find(invoice_id)
    Billing::ProcessOverdueInvoiceService.call(invoice:)
  end
end

# ❌ Lógica no job
class Billing::ProcessOverdueInvoicesJob < ApplicationJob
  def perform(invoice_id)
    invoice = Billing::Invoice.find(invoice_id)
    invoice.update!(status: :overdue)
    StripeGateway.charge(invoice)  # lógica que pertence a um Service
    BillingMailer.overdue(invoice).deliver_later
  end
end

# ⚠️ Nunca use Current Attributes em Jobs — passe IDs explicitamente
# ⚠️ Receba IDs, não objetos (serialização do ActiveJob)
```

---

## 19. Mailer Convention

```ruby
# Mailer = template. Quem decide quando enviar é o Service.
# ❌ after_create :send_welcome_email (callback no model)

# ✅ No service:
def notify_user(subscription)
  Billing::SubscriptionMailer.activated(subscription).deliver_later
end

# Mailer naming: DomainMailer + action como verbo passivo
# Billing::SubscriptionMailer.activated
# Identity::UserMailer.password_reset_requested
```

---

## 20. Hotwire — Frontend Rails Way

Sem instrução explícita, o agente vai gerar JSON APIs ou React.

```ruby
# Stack: Turbo Frames + Turbo Streams + Stimulus
# O agente NÃO deve gerar:
# - endpoints JSON para consumo frontend
# - JavaScript manipulando DOM diretamente
# - Fetch/axios calls para atualizar UI
```

### Turbo Frame — navegação parcial

```erb
<%= turbo_frame_tag "subscription_#{subscription.id}" do %>
  <%= render partial: "subscription", locals: { subscription: } %>
<% end %>
```

### Turbo Stream — updates em tempo real

```ruby
# No controller:
respond_to do |format|
  format.turbo_stream
  format.html { redirect_to subscriptions_path }
end
```

### Stimulus — JS mínimo e declarativo

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  toggle() { this.contentTarget.classList.toggle("hidden") }
}
```

```erb
<!-- Na view -->
<div data-controller="toggle">
  <button data-action="click->toggle#toggle">Toggle</button>
  <div data-toggle-target="content">Conteúdo</div>
</div>
```

---

## 21. Database Conventions

```ruby
# Sempre adicione em migrations:
# - Foreign keys explícitas (não confie só em _id)
# - Índices em toda FK e coluna de busca
# - NOT NULL em tudo que não é genuinamente opcional
# - default values quando aplicável

add_reference :subscriptions, :account, null: false, foreign_key: true, index: true
add_column :subscriptions, :status, :integer, null: false, default: 0

# Nomes de migration como intenção:
# ✅ AddExpirationTrackingToSubscriptions
# ❌ ChangeSubscriptionsTable
```

---

## 22. Credentials — Nunca Hardcode

```ruby
# ❌ Agente coloca chave no código
Stripe.api_key = "sk_live_..."

# ✅ Credentials
Stripe.api_key = Rails.application.credentials.dig(:stripe, :api_key)

# Agente nunca deve:
# - Criar/editar credentials (precisa de master key)
# - Hardcodar tokens, chaves, URLs de API
# - Usar ENV[] sem fallback documentado
```

---

## 23. Value Objects com `composed_of`

Para atributos com lógica própria (dinheiro, endereço, período):

```ruby
class Money
  attr_reader :amount_cents, :currency

  def initialize(amount_cents:, currency: "BRL")
    @amount_cents = amount_cents
    @currency = currency
  end

  def to_s = "#{currency} #{'%.2f' % (amount_cents / 100.0)}"
  def +(other) = self.class.new(amount_cents: amount_cents + other.amount_cents)
end

# No model:
composed_of :price, class_name: "Money",
  mapping: [%w[price_cents amount_cents], %w[currency currency]]
```

---

## 24. Modern Rails (7.1+)

```ruby
# Normalizes — substitui before_validation para transformações simples
normalizes :email, with: ->(e) { e.strip.downcase }

# generates_token_for — substitui gems de token
generates_token_for :email_confirmation, expires_in: 24.hours do
  email
end

# Query constraints em associations
has_many :active_subscriptions, -> { status_active },
  class_name: "Subscription", inverse_of: :account

# Async queries (Rails 7.1+)
promise = Subscription.where(status: :active).async_count
# ... faz outras coisas ...
count = promise.value  # espera resultado
```

---

## 25. Metaprogramação — Evitar

Agentes têm dificuldade de raciocinar sobre código que gera código.

```ruby
# ❌ Opaco para agentes
method_missing(:find_by_*)
define_method(attr) { ... }
send(:"process_#{type}")
const_get("#{domain}::#{klass}")

# ✅ Explícito e navegável
def find_by_email(email) = where(email: email)
def process_subscription  = ...
def process_payment       = ...
Billing::ActivateSubscriptionService
```

---

## 26. Testing Conventions

Sem convenção de testes, agentes geram specs fracas que testam implementação, não comportamento.

```ruby
# Regras:
# - Teste o Service pelo Result: expect(result.success).to be true
# - Teste o QueryObject pelo SQL gerado, não por fixtures complexas
# - Nomeie com intenção: it "suspends subscription when payment fails"
# - Sem `let!` em cascata — setup explícito no `it`
# - Factory por domínio: spec/domains/billing/factories/
# - Nunca mocke o Service internamente — mocke apenas dependências externas

# Exemplo de spec de Service:
RSpec.describe Billing::ActivateSubscriptionService do
  describe ".call" do
    it "activates subscription with valid payment" do
      user = create(:user)
      plan = create(:plan, :monthly)
      payment_method = create(:payment_method, user:)

      result = described_class.call(
        user:,
        plan:,
        payment_method:
      )

      expect(result.success).to be true
      expect(result.subscription).to be_persisted
      expect(result.subscription.status).to eq("active")
    end

    it "returns error when payment fails" do
      user = create(:user)
      plan = create(:plan, :monthly)
      payment_method = create(:payment_method, :expired, user:)

      result = described_class.call(
        user:,
        plan:,
        payment_method:
      )

      expect(result.success).to be false
      expect(result.error).to include("payment")
    end
  end
end

# Exemplo de spec de QueryObject:
RSpec.describe Billing::OverdueSubscriptionsQuery do
  describe "#call" do
    it "returns only active subscriptions past expiration" do
      overdue = create(:subscription, :active, expires_at: 1.day.ago)
      _current = create(:subscription, :active, expires_at: 1.day.from_now)
      _cancelled = create(:subscription, :cancelled, expires_at: 1.day.ago)

      result = described_class.new.call

      expect(result).to contain_exactly(overdue)
    end
  end
end
```

---

## 27. Workflow com Agentes

### Prompt Template (Claude Code)

```
"Leia CLAUDE.md e app/domains/billing/README.md.
 Implemente [X] seguindo o padrão .call + Result.
 Arquivos permitidos: app/domains/billing/** e spec/domains/billing/**
 Rode bundle exec rspec spec/domains/billing/ ao final.
 Se falhar, corrija antes de concluir."
```

O "arquivos permitidos" é o guardrail mais eficaz — limita o blast radius.

### Adicionando feature

```
"Adicionar [X] no domínio Billing.
 Contexto: app/domains/billing/README.md e CLAUDE.md
 Padrões: Service com .call + Result, QueryObject para queries, Concern para lógica do model
 Crie a spec junto: spec/domains/billing/x_spec.rb
 Modifique apenas app/domains/billing/
 Rode bundle exec rspec spec/domains/billing/ ao final"
```

### Debugando

Forneça stack trace + apenas o arquivo com problema. Não cole arquivos inteiros.

### Refatorando código legado

Avance um passo por vez:

```
fat_controller → extraia concerns → multi-controllers → services → query objects
```

Nunca pule etapas. Cada passo é um PR separado.

---

## Anti-patterns — Referência Rápida

| Sinal | Problema | Solução |
|---|---|---|
| Controller > 80 linhas | Alto token overhead | Multi-controllers + services |
| Service sem interface padrão | Inconsistência cross-agente | Padrão `.call` + Result |
| `includes` no controller | N+1 invisível | Mover para QueryObject |
| `app/services/` flat com 50+ arquivos | Agente navega tudo | Organizar por domínio |
| Callbacks com side effects externos | Bugs invisíveis | Named Services |
| `method_missing` / `send` dinâmico | Agente não consegue rastrear | Métodos explícitos |
| Sem CLAUDE.md | 5–10 tool calls de exploração | Criar agora |
| Schema só em `db/schema.rb` | Agente lê arquivo inteiro | `annotate` gem + comment no model |
| `rescue StandardError` | Engole erros de infra | rescue apenas exceções específicas |
| `current_user` passado por 4 camadas | Poluição de interface | `Current` attributes |
| Enum sem prefix | Colisão de nomes | `prefix: true` sempre |
| Nesting > 1 nível nas rotas | URLs ilegíveis | `shallow: true` |
| Lógica de model em service | Service desnecessário | Concern |
| Lógica pesada no Job | Job não testável isoladamente | Job chama Service |
| `Data.define(:success?)` | Campo inválido com `?` | Use `:success` + predicate method |
| Acesso direto entre domínios | Acoplamento | Domain Events ou Orchestration Service |
| JSON API com Hotwire stack | Duplicação de interface | Turbo Frames + Streams |
| `let!` em cascata nos testes | Setup incompreensível | Setup explícito no `it` |
