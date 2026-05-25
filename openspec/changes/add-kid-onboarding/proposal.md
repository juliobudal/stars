## Why

Quando o pai cria o perfil da criança em `/parent/profiles/new`, a criança imediatamente cai em `/kid` ao logar com PIN — sem nenhuma boas-vindas, sem entender o produto, e sem ter declarado seus interesses. O card "Eu curto" do dashboard tenta resolver isso depois, mas:

1. A criança não sabe ainda o que são missões, estrelinhas, recompensas ou a Academy — o dashboard é cheio (greeting + Pílula + Lightning + Eu curto + tasks) e some o senso de "onde começar".
2. Sem interesses, o `Academy::Learner` opera sem personalização (top key = nil → currículo genérico). Os pills e lens types ficam menos relevantes pra criança.
3. A criança nunca foi *recebida* — o produto é gamificado/playful em todo lugar exceto na porta de entrada.

A infraestrutura para resolver isso já existe: `ProfileInterest::Catalog` está pronto, `Ui::Celebration` confetti idem, `Ui::SmileyAvatar` per-kid idem, palette via `data-palette`. Falta apenas o fluxo guiado de primeira sessão.

## What Changes

- Nova migração `add_onboarded_at_to_profiles` adicionando coluna `datetime null: true` em `profiles`. Stamping em `now` marca onboarding completo. Backfill ⇒ existing profiles ficam considerados "já onboardeados" (não interrompemos sessões em produção).
- Novo `Kid::OnboardingController` com 4 actions GET + uma POST de finalização:
  - `welcome` (GET `/kid/welcome`) — boas-vindas com mascote
  - `interests` (GET `/kid/welcome/interests`) — picker reaproveitando `ProfileInterest::Catalog` (min 3, max 5)
  - `update_interests` (PATCH) — persiste e avança
  - `how_it_works` (GET `/kid/welcome/how`) — tour curto (missões → estrelinhas → recompensas)
  - `finish` (POST `/kid/welcome/finish`) — stampa `onboarded_at`, dispara `Ui::Celebration`, redireciona `/kid`
- Novo concern `KidOnboardingGuard` (em `app/controllers/concerns/`) incluído por todos os controllers `Kid::*` exceto o próprio onboarding. Redireciona `Profile#child? && onboarded_at.nil?` para `/kid/welcome`. Mantém kid em sessão mas força o fluxo.
- Novo layout `layouts/kid_onboarding.html.erb` focado (sem `kid_nav`, sem topbar, com progress bar de 4 passos e background suave da palette do kid).
- 4 partials novos em `app/views/kid/onboarding/` + 1 progress-step component em `app/components/ui/progress_steps/`.
- Atualização do `_form.html.erb` do Parent::Profiles para mostrar mensagem "A criança será recebida com um tour rápido na primeira vez que entrar" — sinal pro pai que onboarding é automático.
- Specs cobrindo: redirect quando onboarded_at nil; 4 telas se carregam; persistência de interesses; idempotência (kid já onboardeado não é redirecionado); replay protection (POST finish exige token CSRF padrão).

## Capabilities

### New Capabilities

- `kid-onboarding`: fluxo de boas-vindas guiado para criança em primeira sessão; cobre gating de surface, persistência de marca de conclusão, persistência de interesses do catálogo canônico, integração com `Ui::Celebration` na finalização, e fallback para skip seguro (concern excluído do próprio fluxo evita loop).

### Modified Capabilities

<!-- Nenhuma capability spec existente; nada a modificar. -->

## Impact

- **Código novo**: 1 migration, 1 controller, 1 concern, 4 view partials, 1 layout, 1 ViewComponent (progress steps). Specs request + system. Sem service novo — controller é fino, persistência delegada a `current_profile.update!` e `ProfileInterest.create!` (mesma forma que `Kid::InterestsController` já usa).
- **Código tocado**: `app/controllers/kid/dashboard_controller.rb` e demais `Kid::*` recebem o concern via base controller (ou via include explícito); `_form.html.erb` do parent ganha 1 linha de hint; `config/routes.rb` ganha 5 linhas dentro de `namespace :kid`.
- **Infra reaproveitada**: `ProfileInterest::Catalog`, `Ui::SmileyAvatar`, `Ui::Btn`, `Ui::Celebration`, `Ui::IconPicker`, `Ui::Flash`, `Authenticatable#require_child!`, palette tokens. Stimulus controllers existentes (`interest-picker`, `celebration`) cobrem interação — não precisa de Stimulus novo.
- **Risco baixo**:
  - Backfill marcando todos os existentes como `onboarded_at = Time.current` evita que kids em produção vejam o tour de repente.
  - Concern excluído do próprio `Kid::OnboardingController` evita loop de redirect.
  - Kid pode pular/voltar com botão "voltar" e re-encontrar o fluxo no próximo login (estado é só `onboarded_at`).
  - Não toca em Academy, parent, services de tasks/rewards, ou em qualquer fluxo de auth — escopo cirúrgico.
- **Migration safety**: coluna nullable com default `nil` para novos perfis, backfill em `up` com `Profile.where(role: :child).update_all(onboarded_at: Time.current)` para profiles existentes. Cabe num único deploy.
- **Sem deps novas**: nenhuma gem, nenhuma env var.
