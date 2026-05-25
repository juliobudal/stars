## 0. Pré-requisitos

- [x] 0.1 Confirmar que o container `web` está rodando (`make dev-detached` se preciso) — todas as etapas abaixo rodam dentro dele.

## 1. Migration & Profile

- [x] 1.1 Gerar migration `add_onboarded_at_to_profiles` adicionando `datetime :onboarded_at, null: true`.
- [x] 1.2 No `up`, fazer backfill `Profile.where(role: :child).update_all(onboarded_at: Time.current)` para não interromper kids existentes.
- [x] 1.3 Rodar `make migrate`.
- [x] 1.4 Atualizar anotação Schema Information no topo de `app/models/profile.rb` (rodando `bundle exec annotate` ou editando manualmente).
- [x] 1.5 Sanity check: `Profile.column_names.include?("onboarded_at")` no console.

## 2. ProgressSteps component

- [x] 2.1 Criar `app/components/ui/progress_steps/component.rb` com `initialize(current:, total:)` e `def call`.
- [x] 2.2 Renderizar `total` segmentos finos (height 8px), os primeiros `current` segmentos em `var(--primary)` com `0 2px 0 var(--primary-2)`, restantes em `var(--surface-2)`.
- [x] 2.3 Spec leve: `app/components/ui/progress_steps/component_spec.rb` cobrindo "renders N segmentos" e "marca current como verdes".

## 3. Concern KidOnboardingGuard

- [x] 3.1 Criar `app/controllers/concerns/kid_onboarding_guard.rb` com `included do; before_action :gate_kid_onboarding!; end` e o método privado redirecionando se `child?` && `onboarded_at.nil?`.
- [x] 3.2 Helper de redirect deve usar `kid_welcome_path` (a rota que vamos criar em §5).

## 4. Kid::BaseController

- [x] 4.1 Criar `app/controllers/kid/base_controller.rb`:
  - `include Authenticatable`
  - `include KidOnboardingGuard`
  - `before_action :require_child!`
  - `layout "kid"`
- [x] 4.2 Migrar `Kid::DashboardController` para `< Kid::BaseController` removendo includes/before_action/layout duplicados.
- [x] 4.3 Migrar `Kid::MissionsController`.
- [x] 4.4 Migrar `Kid::RewardsController`.
- [x] 4.5 Migrar `Kid::WalletController`.
- [x] 4.6 Migrar `Kid::WishlistController`.
- [x] 4.7 Migrar `Kid::InterestsController`.
- [x] 4.8 Para o módulo Academy: criar `app/controllers/kid/academy/base_controller.rb` herdando de `Kid::BaseController` e migrar todos os `Kid::Academy::*Controller`. Se algum estiver com lógica custom de auth, manter override explícito.

## 5. Rotas

- [x] 5.1 Em `config/routes.rb` dentro de `namespace :kid`, antes das outras rotas, declarar:
  ```ruby
  get  "welcome",            to: "onboarding#welcome",        as: :welcome
  get  "welcome/interests",  to: "onboarding#interests",      as: :welcome_interests
  patch "welcome/interests", to: "onboarding#update_interests"
  get  "welcome/how",        to: "onboarding#how_it_works",   as: :welcome_how
  get  "welcome/ready",      to: "onboarding#ready",          as: :welcome_ready
  post "welcome/finish",     to: "onboarding#finish",         as: :welcome_finish
  ```
- [x] 5.2 Verificar `make routes | grep welcome` mostra todas as 6 rotas.

## 6. Kid::OnboardingController

- [x] 6.1 Criar `app/controllers/kid/onboarding_controller.rb < Kid::BaseController` com `skip_before_action :gate_kid_onboarding!`.
- [x] 6.2 Action `welcome` — define `@step = 1`, renderiza.
- [x] 6.3 Action `interests` — define `@step = 2`, `@catalog = ProfileInterest::Catalog.all`, `@selected = current_profile.interest_keys(5)`, `@min = 3`, `@max = 5`.
- [x] 6.4 Action `update_interests` — replica lógica do `Kid::InterestsController#update`: valida 3..5 keys do catálogo, `transaction { profile_interests.delete_all; create_each_with_rank }`, redireciona para `kid_welcome_how_path`. Em falha, re-renderiza `interests` com `flash.now[:alert]`.
- [x] 6.5 Action `how_it_works` — define `@step = 3`, renderiza.
- [x] 6.6 Action `ready` — define `@step = 4`, renderiza.
- [x] 6.7 Action `finish` — `current_profile.update!(onboarded_at: Time.current)`, `flash[:notice] = "Tudo pronto, #{current_profile.name}! ✨"`, redireciona `kid_root_path`. Idempotente — re-stamping o mesmo valor é OK.

## 7. Layout

- [x] 7.1 Criar `app/views/layouts/kid_onboarding.html.erb` espelhando `kid.html.erb` mas:
  - sem `shared/kid_nav`
  - sem `KidTopBar`
  - `main` com `max-w-[430px] mx-auto pt-8 pb-12 px-5`
  - mantém `data-palette`, `fx_stage`, `Ui::Flash`, `Ui::Celebration`, `pwa_shell`
- [x] 7.2 Em `Kid::OnboardingController`, fazer `layout "kid_onboarding"`.

## 8. Views

- [x] 8.1 `app/views/kid/onboarding/welcome.html.erb` — mascote (`SmileyAvatar 120`), saudação personalizada com `current_profile.name`, 3 linhas de copy, botão primary "Bora!" → `kid_welcome_interests_path`.
- [x] 8.2 `app/views/kid/onboarding/interests.html.erb` — reusa estrutura do `kid/interests/show.html.erb` mas com URL `kid_welcome_interests_path` (PATCH) e cópia "Escolhe de 3 a 5 — vamos usar pra deixar as missões com a sua cara".
- [x] 8.3 `app/views/kid/onboarding/how_it_works.html.erb` — 3 cards stack (missões, estrelinhas, recompensas), cada um com emoji + título + body curto. Cards diferenciados visualmente: missão = `--primary-soft`, estrelinhas = `--star-soft`, recompensas = `--c-peach-soft`.
- [x] 8.4 `app/views/kid/onboarding/ready.html.erb` — mascote bouncing + confetti gatilho (`data-controller="celebration" data-celebration-auto-value="true"` se o Stimulus celebration controller suportar isso; senão simplesmente apresentamos com `Ui::Celebration` + um data-attribute que dispara no `connect`). Botão = form POST para `kid_welcome_finish_path` (não link, pra exigir CSRF token).
- [x] 8.5 Cada view começa com `<%= render Ui::ProgressSteps::Component.new(current: @step, total: 4) %>`.

## 9. Confetti trigger

- [x] 9.1 Investigar `app/assets/controllers/celebration_controller.js` — se já tem auto-fire, ótimo. Senão, adicionar value `auto: Boolean` com `connect() { if (this.autoValue) this.fire() }`.
- [x] 9.2 Garantir que `Ui::Celebration::Component` aceita uma flag `auto:` que injeta `data-celebration-auto-value="true"`. Se não aceitar, ajustar o componente (mínimo: aceitar `**options` e propagar para data attrs).

## 10. Parent hint

- [x] 10.1 Em `app/views/parent/profiles/_form.html.erb`, logo após o campo PIN (linha ~77), adicionar quando `profile.child? && profile.new_record?`:
  ```erb
  <div class="text-[12px] font-bold mt-1.5" style="color: var(--text-muted);">
    Na primeira vez que entrar, a criança vai ser recebida com um tour rápido.
  </div>
  ```

## 11. Specs — request

- [x] 11.1 `spec/requests/kid/onboarding_spec.rb`:
  - Kid sem `onboarded_at` GET /kid → redirect /kid/welcome.
  - Kid com `onboarded_at` GET /kid → 200.
  - Parent GET /kid/welcome → redirect / (require_child!).
  - GET welcome/interests/how/ready respondem 200 para kid.
  - PATCH /kid/welcome/interests com 3 keys válidas → redirect to `kid_welcome_how_path` + cria 3 `profile_interests`.
  - PATCH com 2 keys → 422 + re-render interests com flash alert.
  - POST /kid/welcome/finish → stampa `onboarded_at`, redirect /kid, flash[:notice] presente.
  - POST finish idempotente (chamar 2×: segunda vez também redirect, sem erro).
- [x] 11.2 `spec/requests/kid/dashboard_spec.rb` (existente) — adicionar teste que kid sem onboarded_at é redirecionado.

## 12. Spec — system

- [x] 12.1 `spec/system/kid_onboarding_flow_spec.rb` (Capybara):
  - Criar família + perfil child sem onboarded_at via factory.
  - Login family + selecionar perfil + entrar com PIN.
  - Esperar redirect para `/kid/welcome`.
  - Clicar "Bora!".
  - Selecionar 3 chips de interesse.
  - Clicar "Próximo".
  - Ver os 3 cards de "Aqui é assim".
  - Clicar "Entendi".
  - Na tela "ready", clicar "Começar".
  - Estar em `/kid` com notice "Tudo pronto" e card "Eu curto" populado.

## 13. Lint + run

- [x] 13.1 `make rspec` — todos verdes.
- [x] 13.2 `make lint` — sem warnings novos. Corrigir se aparecer.
- [x] 13.3 (opcional) `make brakeman` — sem novos findings.

## 14. Playwright smoke

- [x] 14.1 Levantar a app (`make dev-detached`) e seedar uma família + kid sem onboarded_at via `bin/rails runner` (one-liner).
- [x] 14.2 Via Playwright MCP: navegar pra `http://localhost:3000`, logar, selecionar perfil kid, digitar PIN, verificar redirect, percorrer as 4 telas, capturar screenshot de cada.
- [x] 14.3 Confirmar `onboarded_at` foi stampado e que reload em `/kid/welcome` re-renderiza (não bloqueia, idempotente).
