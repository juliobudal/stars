## 1. Filosofia

Mantemos o onboarding curto, gamificado e bem integrado:

- **4 telas, ~60-90 segundos**. Uma ação por tela. Nunito 800, 3D shadows, mascote presente, sem texto longo.
- **Foco**: zero distração — `kid_onboarding.html.erb` esconde a bottom-nav e a top-bar habituais, mostra só conteúdo + progresso + um botão.
- **Reaproveita**: o picker de interesses é o mesmo `interest-picker` Stimulus controller que já existe (`/kid/interests`). O `Ui::Celebration` é o mesmo confetti das missões. `Ui::SmileyAvatar` com `data-palette` do kid mantém identidade visual.
- **Salva ao final, não a cada passo**: estado intermediário fica em `session[:kid_onboarding]` (hash leve) — só quando POST finish vier é que `onboarded_at` é stampado e interesses persistidos. Isso evita kid abandonar no meio e ficar com estado parcial.
- **Backfill amigável**: na migration, profiles existentes (role child) recebem `onboarded_at = Time.current` para que nenhum kid em produção seja interrompido pelo deploy.

## 2. Fluxo

```
profile_sessions#create
        │  profile.child? + auth ok
        ▼
   /kid (any surface)
        │
        ▼
 ┌─────────────────────────────────┐
 │ before_action :gate_onboarding! │  ← novo concern, em todos Kid::*
 │ if onboarded_at.nil?            │
 │   redirect /kid/welcome         │
 └─────────────────────────────────┘
        │
        ▼ (only Kid::OnboardingController skips guard)
 ┌──────────────┐
 │ #welcome     │  GET /kid/welcome
 │  Próximo →   │
 ├──────────────┤
 │ #interests   │  GET /kid/welcome/interests
 │  (form PATCH)│
 │  Salvar →    │  PATCH /kid/welcome/interests
 ├──────────────┤
 │ #how_it_works│  GET /kid/welcome/how
 │  Entendi →   │
 ├──────────────┤
 │ #finish      │  POST /kid/welcome/finish
 │  ↓                                       │
 │  • profile.update!(onboarded_at: now)    │
 │  • flash[:notice] + celebration trigger  │
 │  • redirect /kid                         │
 └──────────────┘
```

Estado intermediário em `session[:kid_onboarding] = { interests: [keys], step: "..." }`. Limpamos em `finish` ou via TTL natural da sessão. Se kid fecha navegador no passo 2, próximo login o concern manda pra `/kid/welcome` de novo — fluxo é replayable, não amassa o que ele tinha selecionado (a sessão pode até persistir o array por algumas horas, mas é nice-to-have, não bloqueante).

## 3. Telas

### Tela 1: Welcome

```
┌──────────────────────────────────────────────┐
│  •••• progress · passo 1/4                   │
│                                              │
│                                              │
│              ╭───────╮                       │
│              │ kid   │  ← SmileyAvatar 120px │
│              │ smile │     ls-mascot-bounce  │
│              ╰───────╯                       │
│                                              │
│    Oi, Lila!                                 │
│    Bem-vindo ao LittleStars                  │
│                                              │
│    Aqui você vira super-aluno:               │
│    faz missões, ganha estrelinhas            │
│    e troca por recompensas legais.           │
│                                              │
│              ┌──────────────┐                │
│              │ Bora!  →     │   primary btn  │
│              └──────────────┘                │
└──────────────────────────────────────────────┘
```

Detalhes:
- Mascote = `SmileyAvatar` do kid em 120px, com `ls-mascot-bounce`.
- Estrela amarela `--star` orbitando.
- Headline H1 26px 800.
- Body 14px 700, max 3 linhas.
- Botão primary com `0 4px 0 var(--primary-2)`.

### Tela 2: Interests

```
┌──────────────────────────────────────────────┐
│  ███████░░ progress · passo 2/4              │
│                                              │
│  O que você curte?                           │
│  Escolhe de 3 a 5 — vamos usar pra deixar    │
│  as missões com a sua cara.                  │
│                                              │
│  ┌────┐ ┌────┐ ┌────┐                        │
│  │🦖  │ │🐱  │ │⚽  │  ...                   │
│  │Dino│ │Gato│ │Fute│                        │
│  └────┘ └────┘ └────┘                        │
│  ┌────┐ ┌────┐ ┌────┐                        │
│  │🪐  │ │🎨  │ │🍕  │                        │
│  └────┘ └────┘ └────┘                        │
│                                              │
│  2 de 5 escolhidas (mínimo 3)                │
│              ┌──────────────┐                │
│              │ Próximo  →   │  (disabled <3) │
│              └──────────────┘                │
└──────────────────────────────────────────────┘
```

Reusa `interest-picker` Stimulus controller existente. Diferença vs `Kid::InterestsController#show`:
- POST vai pra `/kid/welcome/interests` (PATCH) — mesma estrutura do form, controller diferente.
- Botão "Próximo" desabilita se selecionados < 3 (mesma lógica do controller existente).
- Visual idêntico — não criamos chip novo.

### Tela 3: How It Works

```
┌──────────────────────────────────────────────┐
│  █████████░ progress · passo 3/4             │
│                                              │
│  Aqui é assim:                               │
│                                              │
│  ┌──────────────────────────────────────┐    │
│  │ 🎯  Missões                          │    │
│  │     Tarefas pra você cumprir         │    │
│  └──────────────────────────────────────┘    │
│                                              │
│  ┌──────────────────────────────────────┐    │
│  │ ⭐  Estrelinhas                      │    │
│  │     Você ganha completando missões   │    │
│  └──────────────────────────────────────┘    │
│                                              │
│  ┌──────────────────────────────────────┐    │
│  │ 🎁  Recompensas                      │    │
│  │     Troca suas estrelinhas por elas  │    │
│  └──────────────────────────────────────┘    │
│                                              │
│              ┌──────────────┐                │
│              │ Entendi  →   │                │
│              └──────────────┘                │
└──────────────────────────────────────────────┘
```

3 cards stack vertical, cada um com emoji grande (`32px`), label H3 18px 800, descrição 13px 700. Card base = `ls-card-3d` existente em `app/views/kid/dashboard/index.html.erb` (gradient `--primary-soft → --surface`, border `--primary`, shadow `0 4px 0 var(--primary-2)`). Mas variantes por tema: o card de estrelinhas usa `--star-soft → --surface` + border `--star`, e o card de recompensas usa `--c-peach-soft → --surface` + border `--c-peach`. Isso quebra a monotonia sem inventar componente novo.

### Tela 4: Finish (POST não tem view — vai pra `/kid` com flash + confetti)

O `finish` action faz `profile.update!(onboarded_at: Time.current)`, dispara `flash[:notice] = "Tudo pronto, Lila! 🎉"` e redireciona `/kid`. No `_celebration.html.erb` ou via flash hook, o Stimulus `celebration` controller é acionado por um attribute `data-celebration-fire="true"` no body do dashboard quando vier de finish — opcional, mas é o ponto de polish que diferencia "feature genérica" de "experiência refinada".

Decisão: para manter simples, **não** vamos modificar o dashboard layout pra escutar a flag de celebration. Em vez disso, renderizamos uma única "all set" view real (tela 4) com confetti embed, e oferecemos um botão "Começar". Custa 1 view a mais, ganha controle visual total.

Revisado:

```
┌──────────────────────────────────────────────┐
│  ██████████ progress · passo 4/4 ✓           │
│                                              │
│         ╭────────╮                           │
│         │ 🎉🎊✨│      confetti layer        │
│         │mascote │      ls-mascot-bounce     │
│         ╰────────╯                           │
│                                              │
│       Tudo pronto, Lila!                     │
│                                              │
│   Suas missões já estão te esperando.        │
│                                              │
│              ┌──────────────┐                │
│              │ Começar  ⭐  │  POST /finish  │
│              └──────────────┘                │
└──────────────────────────────────────────────┘
```

O "Começar" é um form POST que stampa o `onboarded_at` e redireciona. Confetti dispara já em `connect()` do controller. Limpeza fina: o "Começar" é o único botão real, mas a tela já carregou antes do POST — o stamp acontece só ao clicar (evita marcar como onboardeado se a criança fecha a aba na tela final).

## 4. Concern: gate

`app/controllers/concerns/kid_onboarding_guard.rb`:

```ruby
module KidOnboardingGuard
  extend ActiveSupport::Concern

  included do
    before_action :gate_kid_onboarding!
  end

  private

  def gate_kid_onboarding!
    return unless current_profile&.child?
    return if current_profile.onboarded_at.present?
    redirect_to kid_welcome_path
  end
end
```

Incluído em `Kid::DashboardController`, `Kid::MissionsController`, `Kid::RewardsController`, `Kid::WalletController`, `Kid::WishlistController`, `Kid::InterestsController`, e em todos os `Kid::Academy::*`. Pra evitar repetição: criamos `Kid::BaseController < ApplicationController` que já inclui `Authenticatable + KidOnboardingGuard + require_child!`, e migramos os controllers existentes pra herdar dele. Isso é um pequeno refactor mas é higiênico e evita esquecimento futuro.

Decisão: **fazer o refactor**. Os controllers `Kid::*` hoje fazem `include Authenticatable + before_action :require_child! + layout "kid"` repetidos. Centralizar é ganho duplo (DRY + impossível esquecer o guard num controller novo).

Exclusão: o próprio `Kid::OnboardingController` herda de `Kid::BaseController` mas faz `skip_before_action :gate_kid_onboarding!` para não loopar.

## 5. Migration

```ruby
class AddOnboardedAtToProfiles < ActiveRecord::Migration[8.1]
  def up
    add_column :profiles, :onboarded_at, :datetime, null: true

    # Existing children should not see the onboarding after deploy.
    Profile.reset_column_information
    Profile.where(role: :child).update_all(onboarded_at: Time.current)
  end

  def down
    remove_column :profiles, :onboarded_at
  end
end
```

Sem índice — query é `WHERE id = ? AND onboarded_at IS NULL` no caminho do `current_profile`, batendo na PK. Sem necessidade.

## 6. Rotas

```ruby
namespace :kid do
  resource :onboarding, only: [], controller: "onboarding", path: "welcome" do
    get :welcome,      on: :collection, path: ""
    get :interests,    on: :collection
    patch :interests,  on: :collection, action: :update_interests
    get :how_it_works, on: :collection, path: "how"
    get :ready,        on: :collection, path: "ready"
    post :finish,      on: :collection
  end
  # ... rest of kid routes
end
```

Resultados:
- `GET  /kid/welcome`           → `welcome`
- `GET  /kid/welcome/interests` → `interests`
- `PATCH /kid/welcome/interests` → `update_interests`
- `GET  /kid/welcome/how`       → `how_it_works`
- `GET  /kid/welcome/ready`     → `ready`
- `POST /kid/welcome/finish`    → `finish`

## 7. Persistência intermediária

`session[:kid_onboarding] = { interests: ["dinossauros", "espaco"] }` — minimalista. Persiste só os interesses entre `update_interests` (que valida 3..5 e salva no array) e `how_it_works` (que apenas avança) e `ready` (que monta o form de finish) e `finish` (que aplica).

Decisão: **na verdade, é melhor salvar interesses imediatamente em `update_interests`** (mesma forma do `Kid::InterestsController`). Razões:
- Se kid fecha o app entre tela 2 e tela 4, na próxima vez ele cai no welcome de novo, mas os interesses já estão lá. Próximo PATCH só substitui (delete_all + recreate, mesma lógica existente).
- Evita ter que dar suporte a session storage volátil em testes.
- Simplifica: `update_interests` faz exatamente o que `Kid::InterestsController#update` faz, mas redireciona pra `how_it_works`.

Estado salvo:
- Interesses: tabela `profile_interests` (já existe)
- Onboarded flag: `profiles.onboarded_at`

Sessão só usada pra: nada. Removemos o `session[:kid_onboarding]` por completo. KISS.

## 8. Layout

`app/views/layouts/kid_onboarding.html.erb`:

- Sem `kid_nav` (escapa do bottom nav).
- Sem `KidTopBar` (sem streak/stars exibidos).
- Mantém `data-palette` do kid (palette permanece).
- Container `max-w-[430px] mx-auto pt-8 pb-12 px-5`.
- Mantém `Ui::Flash`, `fx_stage`, `Ui::Celebration` (escondido até gatilho).
- Inclui o componente `Ui::ProgressSteps` no topo.

## 9. ProgressSteps component

`app/components/ui/progress_steps/component.rb`:

```ruby
class Ui::ProgressSteps::Component < ApplicationComponent
  def initialize(current:, total:)
    @current = current.to_i
    @total = total.to_i
  end

  def call
    content_tag :div, class: "flex items-center gap-2 mb-7" do
      safe_join(
        @total.times.map do |i|
          done = (i + 1) <= @current
          content_tag :div, "",
            class: "flex-1 h-2 rounded-full",
            style: "background: #{done ? 'var(--primary)' : 'var(--surface-2)'}; #{done ? 'box-shadow: 0 2px 0 var(--primary-2);' : ''}"
        end
      )
    end
  end
end
```

Bem fininho. Sem template ERB — só `call`. Match com DESIGN.md: cores via vars, depth shadow 3D nos passos completos.

## 10. Edge cases

| Caso | Comportamento |
|---|---|
| Parent acessa `/kid/welcome` direto | `require_child!` redireciona pra `root_path` com alert |
| Kid já onboardeado entra em `/kid/welcome` | Tela carrega normalmente (não bloqueamos — é não-destrutivo). Se ele clicar "Começar" no final, re-stampa `onboarded_at` com `now` e re-salva interesses se quiser. Tudo idempotente. |
| Kid sem família | `require_family!` redireciona pra login |
| Kid pula direto pra `/kid/welcome/how` antes de selecionar interesses | Renderiza normal — não bloqueamos navegação direta. Se ele clicar "Começar" no `ready` sem ter passado por `interests`, finish ainda funciona (interesses vazios são válidos do ponto de vista do schema; só ficamos sem personalização). Decisão consciente: simplicidade > rigidez. O `Academy::Learner` já tolera zero interests. |
| Kid em produção (deploy) | Migration stampou `onboarded_at`, então não vê o tour. Pode acessar `/kid/welcome` manualmente se quiser revisar. |
| Multi-tab abuse (kid abre 5 tabs do finish) | `update!` no `onboarded_at` é idempotente; só re-grava o mesmo valor. Sem risco. |
| Kid clica "Voltar" no browser entre telas | Cada tela é GET stateless — funciona perfeitamente. |

## 11. Testes

Request specs:
- Redirect `/kid` → `/kid/welcome` quando `onboarded_at.nil?`
- Não redireciona quando onboardeado
- Não redireciona profile parent (parent não passa pelo concern)
- Welcome / interests / how_it_works / ready respondem 200
- update_interests persiste `profile_interests` em ordem; rejeita < 3
- finish stampa `onboarded_at` e redireciona pra `/kid`
- finish é idempotente (chamar 2× não dá erro)

System spec (Capybara + chrome headless):
- Kid recém-criado loga, é redirecionado pra welcome, clica "Bora!", seleciona 3 interesses, avança, vê o tour, finaliza, cai no dashboard com flash de notice e os interesses aparecendo no card "Eu curto".

Playwright (manual após apply):
- Mesma jornada, mas verificando visual real no navegador (confetti, transições, palette).

## 12. Out of scope (não fazemos agora)

- Onboarding pro pai/parent: já existe (`/parent/profiles/new?onboarding=true`).
- Tour interativo dentro do dashboard (estilo product-tour com tooltips). Mais complexo, baixo ROI agora.
- Personalização do mascote durante o onboarding (kid escolhendo cor/avatar). O pai já fez isso na criação. Adicionar mais um passo aqui seria fricção.
- "Skip" button no welcome — uma criança pequena não deve poder pular. Quem pode pular é o pai, *já* tendo configurado o perfil sem o tour, e isso não é necessário.
- A/B test do fluxo. Sem infra; deixa pra depois.
- i18n. Tudo em pt-BR direto (consistente com o resto do app).
