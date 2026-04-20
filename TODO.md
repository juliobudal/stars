# LittleStars — Master TODO 🌟

> **Referências:** [PRD](./PRD_LittleStars.md) · [Tech Spec](./TECHSPEC.md)
> **Regra:** Cada task é atômica — ao completá-la, algo funciona ou é verificável.
> 🚨 **Atenção (Ambiente Isolado):** Todos os comandos de CLI (ex: `rails`, `bundle`, `rspec`, `yarn`) devem ser sempre executados **DENTRO** do container Docker (seja via `docker compose exec web ...` ou preferencialmente usando o terminal do VS Code conectado ao **Devcontainer**).

---

## Fase 0: Infraestrutura e Setup

> **Meta:** `docker compose up` roda Rails com PostgreSQL. Acessar `localhost:3000` mostra a página padrão do Rails.

- [x] **0.1** Criar `Dockerfile` (Ruby 3.3, Node, Yarn, pacotes necessários)
- [x] **0.2** Criar `docker-compose.yml` (services: `web` + `db` PostgreSQL 16)
- [x] **0.3** Configurar `.devcontainer/devcontainer.json` (apontando pro `docker-compose.yml` para integração nativa com IDEs)
- [x] **0.4** Subir o devcontainer e abrir a pasta internamente no VS Code/Cursor.
- [x] **0.5** Gerar o projeto Rails 8 **dentro do devcontainer** (`rails new . --database=postgresql --css=tailwind --skip-jbuilder --skip-action-text --force`) e depois adicionar o Vite (`bundle add vite_rails` -> `bundle exec vite install`)
- [x] **0.6** Configurar `config/database.yml` para apontar ao host `db` e mapear usuário/senha do compose
- [x] **0.7** Levantar o server (`bin/dev` ou `rails s`) e confirmar que `localhost:3000` responde
- [x] **0.8** Instalar JetRockets UI (copiar ViewComponents base e configurar Tailwind 4.0 conforme docs)
- [x] **0.8.1** Adicionar ViewComponent base de Flash Message aos layouts principais (`parent` e `kid`)
- [x] **0.9** Instalar gems de teste: `rspec-rails`, `factory_bot_rails`, `faker`, `shoulda-matchers`
- [x] **0.10** Rodar `rails generate rspec:install` e confirmar que `bundle exec rspec` passa (0 examples)
- [x] **0.11** Criar `.rubocop.yml` ou `standardrb` básico para lint

---

## Fase 1: Modelagem de Dados

> **Meta:** Todas as tabelas existem no banco. `rails console` permite criar registros manualmente.

### 1A — Migrations

- [x] **1.1** Criar migration `CreateFamilies` (name:string)
- [x] **1.2** Criar migration `CreateProfiles` (family:references, name, avatar, role:integer, points:integer default:0)
- [x] **1.3** Criar migration `CreateGlobalTasks` (family:references, title, category:integer, points:integer, frequency:integer, days_of_week:integer[])
- [x] **1.4** Criar migration `CreateProfileTasks` (profile:references, global_task:references, status:integer default:0, completed_at:datetime, assigned_date:date)
- [x] **1.5** Criar migration `CreateRewards` (family:references, title, cost:integer, icon)
- [x] **1.6** Criar migration `CreateActivityLogs` (profile:references, log_type:integer, title, points:integer)
- [x] **1.7** Rodar `rails db:migrate` e confirmar schema sem erros
- [x] **1.8** Adicionar índices: `profile_tasks(profile_id, assigned_date)`, `profile_tasks(profile_id, status)`, `activity_logs(profile_id, created_at)`

### 1B — Models e Validações

- [x] **1.9** Criar model `Family` (has_many :profiles, :global_tasks, :rewards, dependent: :destroy)
- [x] **1.10** Criar model `Profile` (belongs_to :family, enum :role, validates :name, :points >= 0)
- [x] **1.11** Criar model `GlobalTask` (belongs_to :family, enums category/frequency, validates :title, :points > 0)
- [x] **1.12** Criar model `ProfileTask` (belongs_to :profile, :global_task, enum :status, scopes: for_today, actionable, delegate :title/:points/:category)
- [x] **1.13** Criar model `Reward` (belongs_to :family, validates :title, :cost > 0)
- [x] **1.14** Criar model `ActivityLog` (belongs_to :profile, enum :log_type, scope :recent)

### 1C — Factories e Model Specs

- [x] **1.15** Criar factory `family`
- [x] **1.16** Criar factory `profile` (traits: `:parent`, `:child`)
- [x] **1.17** Criar factory `global_task` (traits: `:daily`, `:weekly`)
- [x] **1.18** Criar factory `profile_task` (traits por status: `:pending`, `:awaiting_approval`, `:approved`)
- [x] **1.19** Criar factory `reward`
- [x] **1.20** Criar factory `activity_log` (traits: `:earn`, `:redeem`)
- [x] **1.21** Escrever model specs para validações de `Profile` (name presente, points >= 0)
- [x] **1.22** Escrever model specs para validações de `GlobalTask` (points > 0)
- [x] **1.23** Escrever model specs para validações de `Reward` (cost > 0)
- [x] **1.24** Escrever model specs para scopes de `ProfileTask` (for_today, actionable)
- [x] **1.25** Rodar `bundle exec rspec` — tudo verde

### 1D — Seed Data

- [x] **1.26** Criar `db/seeds.rb` com família demo: 2 pais, 2 filhos, 5 tarefas globais, 3 recompensas
- [x] **1.27** Rodar `rails db:seed` e confirmar dados no console

---

## Fase 2: Sessão e Seleção de Perfil

> **Meta:** Tela inicial mostra avatares da família. Clicar em um perfil seta a sessão e redireciona para o painel correto.

- [x] **2.1** Criar `SessionsController` com action `index` (listar perfis da família)
- [x] **2.2** Criar `SessionsController#create` (recebe `profile_id`, seta `session[:profile_id]`, redireciona por role)
- [x] **2.3** Criar `SessionsController#destroy` (limpa sessão, volta para seleção)
- [x] **2.4** Criar helper `current_profile` no `ApplicationController`
- [x] **2.5** Criar concern `Authenticatable` com `require_parent!` e `require_child!`
- [x] **2.6** Configurar `root` route para `sessions#index`
- [x] **2.7** Criar view `sessions/index.html.erb` usando JetRockets `Avatar` + `Card` (grid de perfis)
- [x] **2.8** Estilizar: pais com badge "👑", filhos com borda colorida, hover scale
- [x] **2.9** Escrever request spec: POST `/session` com perfil pai → redirect para `/parent`
- [x] **2.10** Escrever request spec: POST `/session` com perfil filho → redirect para `/kid`
- [x] **2.11** Escrever request spec: acessar `/parent` sem sessão → redirect para root

---

## Fase 3: Parent View — Dashboard e CRUD

> **Meta:** Pai loga e vê o dashboard. Pode gerenciar filhos, tarefas globais e recompensas.

### 3A — Layout e Dashboard

- [x] **3.1** Criar layout `layouts/parent.html.erb` (sidebar/navbar clean, JetRockets `Sidebar` ou `Navbar`)
- [x] **3.2** Criar `Parent::DashboardController#index`
- [x] **3.3** Criar view `parent/dashboard/index.html.erb` com JetRockets `Stat` cards (total filhos, tarefas pendentes, aprovações pendentes, total estrelinhas distribuídas)
- [x] **3.4** Configurar rotas `namespace :parent` com `root` apontando para dashboard

### 3B — CRUD de Filhos (Profiles)

- [x] **3.5** Criar `Parent::ProfilesController` (new, create, edit, update, destroy)
- [x] **3.6** Criar view `parent/profiles/new.html.erb` — form com JetRockets Form Builder (TextField nome, Select avatar/emoji)
- [x] **3.7** Criar view `parent/profiles/edit.html.erb` — mesmo form, preenchido
- [x] **3.8** Listar filhos no dashboard com JetRockets `Card` + `Avatar` + botões editar/excluir
- [x] **3.9** Excluir filho com JetRockets `Turbo Confirm` modal ("Tem certeza? Isso remove tudo.")
- [x] **3.10** Escrever request specs: CRUD completo de profiles (create, update, destroy com cascade)

### 3C — CRUD de Tarefas Globais (GlobalTasks)

- [x] **3.11** Criar `Parent::GlobalTasksController` (index, new, create, destroy)
- [x] **3.12** Criar view `parent/global_tasks/index.html.erb` — JetRockets `Table` com título, categoria (Badge), pontos, frequência
- [x] **3.13** Criar view `parent/global_tasks/new.html.erb` — Form Builder (TextField título, TextField pontos, Select categoria, Select frequência, Checkbox[] dias da semana)
- [x] **3.14** Usar JetRockets `Empty` component quando não há tarefas cadastradas
- [x] **3.15** Excluir tarefa global com Turbo Confirm
- [x] **3.16** Escrever request specs: criar tarefa global, listar, excluir

### 3D — CRUD de Recompensas (Rewards)

- [x] **3.17** Criar `Parent::RewardsController` (index, new, create, destroy)
- [x] **3.18** Criar view `parent/rewards/index.html.erb` — JetRockets `Table` com título, custo (⭐), ícone
- [x] **3.19** Criar view `parent/rewards/new.html.erb` — Form Builder (TextField título, TextField custo, Select ícone/emoji)
- [x] **3.20** JetRockets `Empty` quando loja vazia
- [x] **3.21** Excluir recompensa com Turbo Confirm
- [x] **3.22** Escrever request specs: CRUD completo de rewards

---

## Fase 4: Service Objects (Lógica de Negócio)

> **Meta:** Toda lógica transacional testada isoladamente, antes de conectar nas views.

### 4A — Aprovação e Rejeição de Tarefas

- [x] **4.1** Criar `Tasks::ApproveService` (transação: muda status → incrementa points → cria ActivityLog)
- [x] **4.2** Criar `Tasks::RejectService` (muda status de volta para pending)
- [x] **4.3** Escrever spec: aprovação credita pontos corretamente
- [x] **4.4** Escrever spec: aprovação cria entry no ActivityLog (type: earn)
- [x] **4.5** Escrever spec: rejeição volta status para pending, sem alterar pontos
- [x] **4.6** Escrever spec: aprovar tarefa que não está em `awaiting_approval` → erro
- [x] **4.7** Escrever spec: filho tentando aprovar → erro

### 4B — Resgate de Recompensas

- [x] **4.8** Criar `Rewards::RedeemService` (transação: valida saldo → decrementa points → cria ActivityLog)
- [x] **4.9** Escrever spec: resgate com saldo suficiente deduz pontos corretamente
- [x] **4.10** Escrever spec: resgate cria entry no ActivityLog (type: redeem)
- [x] **4.11** Escrever spec: resgate com saldo insuficiente → erro, nenhuma alteração
- [x] **4.12** Escrever spec: saldo não fica negativo em cenário de race condition

### 4C — Reset Diário de Tarefas

- [x] **4.13** Criar `Tasks::DailyResetService` (instancia ProfileTasks do dia para cada filho)
- [x] **4.14** Escrever spec: tarefas diárias são instanciadas para todos os filhos
- [x] **4.15** Escrever spec: tarefas semanais são instanciadas apenas nos dias corretos
- [x] **4.16** Escrever spec: não duplica se a task já existe para aquele dia
- [x] **4.17** Rodar `bundle exec rspec spec/services/` — tudo verde

---

## Fase 5: Parent View — Fila de Aprovações

> **Meta:** Pai vê tarefas pendentes, clica em aprovar/rejeitar, pontos são creditados/devolvidos.

- [x] **5.1** Criar `Parent::ApprovalsController#index` (lista ProfileTasks com status `awaiting_approval`, agrupadas por filho)
- [x] **5.2** Criar `Parent::ApprovalsController#approve` (chama `Tasks::ApproveService`)
- [x] **5.3** Criar `Parent::ApprovalsController#reject` (chama `Tasks::RejectService`)
- [x] **5.4** Criar view `parent/approvals/index.html.erb` — lista segmentada por filho com JetRockets `Card` + `Badge` (status) + botões Aprovar (verde) / Rejeitar (vermelho)
- [x] **5.5** Usar `turbo_frame_tag "approvals_list"` para atualizar lista sem reload
- [x] **5.6** Flash message de sucesso com JetRockets `Flash Message` (aprovado/rejeitado)
- [x] **5.7** Adicionar contador de aprovações pendentes no dashboard (JetRockets `Badge` no menu)
- [x] **5.8** Escrever request specs: approve → pontos creditados, reject → status volta

---

## Fase 6: Kid View — Missões

> **Meta:** Criança loga, vê missões do dia separadas por status, submete tarefa para aprovação.

### 6A — Layout e Navegação Kid

- [x] **6.1** Criar layout `layouts/kid.html.erb` (visual lúdico: bordas arredondadas 32px, cores vibrantes, sem sidebar complexo)
- [x] **6.2** Criar navegação kid: 4 botões grandes no topo/bottom (🎯 Missões, 💰 Carteira, 🏪 Loja, 📜 Extrato)
- [x] **6.3** Estilizar: fundo gradiente suave, fontes maiores, espaçamento generoso

### 6B — Lista de Missões

- [x] **6.4** Criar `Kid::MissionsController#index` (ProfileTasks do dia, separadas: pendentes vs awaiting_approval)
- [x] **6.5** Criar ViewComponent `Kid::MissionCardComponent` (card grande com: ícone categoria, título, pontos em Badge, botão "Fazer Missão")
- [x] **6.6** Criar view `kid/missions/index.html.erb` — JetRockets `Tabs` ("Para Fazer" / "Aguardando")
- [x] **6.7** Tab "Para Fazer": lista de `MissionCardComponent` com botão ativo
- [x] **6.8** Tab "Aguardando": lista de cards com estado visual diferente (opacidade, sem botão, badge "⏳ Aguardando papai/mamãe")
- [x] **6.9** JetRockets `Empty` component quando não há missões no dia

### 6C — Submissão de Missão

- [x] **6.10** Criar `Kid::MissionsController#show` (detalhes da missão)
- [x] **6.11** Criar `Kid::MissionsController#submit` (muda status para `awaiting_approval`)
- [x] **6.12** Criar JetRockets `Modal` de confirmação ("Tem certeza que terminou? Papai/Mamãe vai conferir!")
- [x] **6.13** Após submit: card se move da tab "Para Fazer" para "Aguardando" via Turbo Frame
- [x] **6.14** Escrever request specs: submit muda status, não credita pontos

---

## Fase 7: Kid View — Carteira (Saldo)

> **Meta:** Criança vê seu saldo de estrelinhas com visual impactante.

- [x] **7.1** Criar `Kid::WalletsController#show`
- [x] **7.2** Criar ViewComponent `Kid::WalletCardComponent` (saldo central grande, ícone de estrela/baú, cor dourada/laranja)
- [x] **7.3** Criar view `kid/wallets/show.html.erb` — card de saldo com JetRockets `Stat`
- [x] **7.4** Criar Stimulus controller `animated_counter_controller.js` (anima de 0 ao valor real no mount)
- [x] **7.5** Wrappear saldo em `turbo_frame_tag "wallet_balance"` para atualização real-time
- [x] **7.6** Estilizar: fundo gradiente laranja→dourado, número grande, ícone ⭐ pulsando

---

## Fase 8: Kid View — Loja e Resgate

> **Meta:** Criança navega a loja, vê preços, resgata recompensa se tiver saldo.

- [x] **8.1** Criar `Kid::StoreController#index` (lista rewards da família)
- [x] **8.2** Criar `Kid::StoreController#redeem` (chama `Rewards::RedeemService`)
- [x] **8.3** Criar ViewComponent `Kid::StoreItemComponent` (card with icon, title, cost, button "Redeem")
- [x] **8.4** Criar view `kid/store/index.html.erb` — grid de cards da loja
- [x] **8.5** Botão "Resgatar" desabilitado (cinza) se `profile.points < reward.cost`
- [x] **8.6** JetRockets `Modal` de confirmação do resgate ("Trocar 200⭐ por Sorvete?")
- [x] **8.7** Criar Stimulus controller `idle_wobble_controller.js` (rotação ±5° + shadow pulse nos cards)
- [x] **8.8** Escrever request specs: resgate com saldo OK, resgate com saldo insuficiente → 422

---

## Fase 9: Extrato de Atividades

> **Meta:** Ambos os perfis veem histórico de transações, filtrado por role.

- [x] **9.1** Criar `Parent::ActivityLogsController#index` (logs de todos os filhos, com nome do filho)
- [x] **9.2** Criar `Kid::ActivityLogsController#index` (logs apenas do próprio perfil)
- [x] **9.3** Criar view `parent/activity_logs/index.html.erb` — JetRockets `Timeline` + `Badge` por tipo (earn: verde, redeem: rosa)
- [x] **9.4** Criar view `kid/activity_logs/index.html.erb` — Timeline simplificada (+50⭐ Louça, -200⭐ Sorvete)
- [x] **9.5** Ordenação: mais recente primeiro
- [x] **9.6** JetRockets `Empty` quando não há atividades

---

## Fase 10: Turbo Streams (Real-Time)

> **Meta:** Ações do pai refletem automaticamente na tela do filho (e vice-versa), sem reload.

- [x] **10.1** Configurar ActionCable no Docker Compose (adapter: async para dev)
- [x] **10.2** No `Tasks::ApproveService`: broadcast `turbo_stream` atualizando `wallet_balance` do kid
- [x] **10.3** No `Tasks::ApproveService`: broadcast atualizando a tab "Aguardando" do kid (remover card aprovado)
- [x] **10.4** No `Kid::MissionsController#submit`: broadcast atualizando contador de aprovações do parent
- [x] **10.5** No `Rewards::RedeemService`: broadcast atualizando saldo na wallet
- [x] **10.6** Adicionar `turbo_stream_from "kid_#{current_profile.id}"` no layout kid
- [x] **10.7** Adicionar `turbo_stream_from "parent_#{current_profile.family_id}"` no layout parent
- [x] **10.8** Testar manualmente: abrir 2 abas (pai + filho), aprovar tarefa, verificar saldo atualiza

---

## Fase 11: Animações e Micro-Interações

> **Meta:** A experiência da criança é viva e recompensadora.

- [x] **11.1** Criar Stimulus controller `celebration_controller.js` (confetes + glow radial no resgate)
- [x] **11.2** Criar Stimulus controller `approval_animation_controller.js` (flash verde na aprovação, flash vermelho na rejeição)
- [x] **11.3** Integrar `celebration_controller` no modal de resgate (trigger após resposta 200)
- [x] **11.4** Integrar `approval_animation_controller` nos botões de approve/reject
- [x] **11.5** Adicionar CSS transition nos cards de missão (hover: scale 1.02, shadow lift)
- [x] **11.6** Adicionar animação de entrada nos cards (fade-in + slide-up com stagger)
- [x] **11.7** Animar troca de número no saldo (count up/down suave no `animated_counter_controller`)

---

## Fase 12: Reset Diário (Scheduled Job)

> **Meta:** Todo dia à meia-noite, as tarefas do dia são instanciadas automaticamente para cada filho.

- [x] **12.1** Criar rake task `tasks:daily_reset` que chama `Tasks::DailyResetService`
- [x] **12.2** Testar rake task manualmente: `rails tasks:daily_reset`
- [x] **12.3** Configurar `Solid Queue` (nativo do Rails 8) para recurring jobs (executar o job à 00:00)
- [x] **12.4** Configurar o Worker do Solid Queue no Docker Compose (`bin/jobs`)
- [x] **12.5** Escrever spec: após rodar o job, ProfileTasks do dia existem para todos as crianças

---

## Fase 13: Polish e Edge Cases

> **Meta:** Tudo funciona suavemente. Sem estados quebrados.

- [x] **13.1** Proteger rotas: filho não acessa `/parent/*`, pai não acessa `/kid/*`
- [x] **13.2** Tratar caso: família sem filhos (dashboard mostra CTA para criar primeiro filho)
- [x] **13.3** Tratar caso: família sem tarefas (dashboard mostra CTA para criar primeira tarefa)
- [x] **13.4** Tratar caso: família sem recompensas (loja mostra mensagem amigável)
- [x] **13.5** Tratar caso: criança sem missões no dia (Kid View mostra "Dia livre! 🎉")
- [x] **13.6** Validar que excluir GlobalTask não quebra ProfileTasks históricas (foreign key com `nullify` ou preservar dados)
- [x] **13.7** Adicionar flash messages consistentes em todas as ações CRUD
- [x] **13.8** Responsive: testar layouts em mobile (kid view priority) e tablet

---

## Fase 14: Testes de Integração (System Specs)

> **Meta:** Fluxos end-to-end automatizados com Capybara.

- [x] **14.1** System spec: Pai cria filho → filho aparece na seleção de perfil
- [x] **14.2** System spec: Pai cria tarefa global → tarefa aparece no Banco
- [x] **14.3** System spec: Pai cria recompensa → recompensa aparece na loja da criança
- [x] **14.4** System spec: Fluxo completo — Criar tarefa → Reset gera ProfileTask → Filho submete → Pai aprova → Saldo credita → Filho resgata recompensa → Saldo debita → Ambos veem no extrato
- [x] **14.5** System spec: Tentativa de resgate com saldo insuficiente → bloqueado
- [x] **14.6** Rodar `bundle exec rspec` — TUDO verde

---

## Fase 15: Manutenção e Estabilização 🛠️

- [x] **15.1** Configurar `web-console` para acesso remoto via Docker (`0.0.0.0/0`)
- [x] **15.2** Corrigir rotas de assets do Tailwind CSS v4 expansion em desenvolvimento
- [x] **15.3** Configurar `Procfile.dev` com binding `0.0.0.0` e portas fixas para Docker
- [x] **15.4** Sincronizar entrypoints de CSS (`tailwind.css` vs `application.css`)
- [x] **15.5** Verificar acessibilidade cross-container (Vite + Rails)

---

## Resumo de Progresso

| Fase | Tasks | Status |
|---|---|---|
| 0 — Infraestrutura | 9 | ✅ |
| 1 — Modelagem de Dados | 27 | ✅ |
| 2 — Sessão e Perfil | 11 | ✅ |
| 3 — Parent View CRUD | 22 | ✅ |
| 4 — Service Objects | 17 | ✅ |
| 5 — Aprovações | 8 | ✅ |
| 6 — Kid Missões | 14 | ✅ |
| 7 — Kid Carteira | 6 | ✅ |
| 8 — Kid Loja | 8 | ✅ |
| 9 — Extrato | 6 | ✅ |
| 10 — Turbo Streams | 8 | ✅ |
| 11 — Animações | 7 | ✅ |
| 12 — Reset Diário | 5 | ✅ |
| 13 — Polish | 8 | ✅ |
| 14 — Testes E2E | 6 | ✅ |
| 15 — Estabilização | 5 | ✅ |
| **TOTAL** | **167** | 100% |
