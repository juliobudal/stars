# D — "Pílula do Dia" no kid home

> **Objetivo.** Criar a menor unidade possível de Academy — **uma lente
> avulsa de 60-90s**, ofertada diariamente no kid home, sem fricção de
> missão/trail. É a peça que entrega literalmente a promessa "pílula
> diária que deixa mais inteligente, de forma divertida".

## Motivação

Hoje a menor surface da Academy é uma **missão** (3-7 lentes encadeadas,
5-15 minutos com loading overlay, completion screen, atlas card mint).
Isso é ótimo pra aprendizado profundo — mas é fricção *alta* pra hábito
diário.

A linguagem do produto fala "pílula" o tempo todo (vide
`config/academy_wisdom_pills.yml` e o overlay), mas o **kid não recebe
pílula** — recebe **aula**.

Pílula como modo de uso:
- Aparece no kid home, **acima** do botão "Lojinha".
- 1 lente, 60-90s, sem necessidade de finalizar missão.
- Botão "Conta pro pai" → cria notificação parent-side.
- Acumula em "Caderno de pílulas" (read-only, separado do Atlas que é
  jogo de coleção).

## Escopo

**Entra:**
- Service `Academy::Pills::PickDailyForLearner` — escolhe 1 lente curada
  diferente por dia (24h cooldown por learner+pill).
- Component `Kid::HomePillCard` — exibe a pílula em ~120px de altura.
- Controller action `Kid::Academy::PillsController#consume` — marca como
  vista, opcionalmente registra micro-check.
- Action "Conta pro pai" — cria `ActivityLog` tipo `pill_shared` e
  notifica parent via Turbo Stream no parent dashboard.
- View `kid/academy/pills/index` — caderno (histórico).

**NÃO entra:**
- Algoritmo de spaced repetition aqui (esse é o item G).
- Gerar pílulas via LLM — só usa lentes já curadas.
- Mexer no Atlas (que continua sendo o museu de cards das missões).

## Trabalho

### Passo 1 — Modelagem (1h)

Nova tabela:
```ruby
create_table :academy_pill_views do |t|
  t.references :learner, null: false                # FK to Academy::Learner adapter
  t.references :lens_cache, null: false             # which lens was served
  t.string :status, null: false, default: "served"  # served|viewed|shared|checked
  t.integer :micro_check_choice                     # null se não respondeu
  t.boolean :micro_check_correct                    # null se não respondeu
  t.boolean :shared_with_parent, default: false
  t.timestamps
  t.index [:learner_id, :created_at]
  t.index [:learner_id, :lens_cache_id], unique: true # 1 vez por kid+pílula
end
```

### Passo 2 — Service de escolha (2h)

`app/services/academy/pills/pick_daily_for_learner.rb`:
- Input: `learner`.
- Lógica:
  1. Se já houve um `PillView` criado nas últimas 24h → retorna o
     mesmo `lens_cache` (idempotente por dia).
  2. Senão, escolhe um `LensCache(source: 'curated', age_band: 'kid')`
     que: (a) ainda não foi servido como pílula para esse learner; (b)
     pertence a uma das categorias de "curiosidade-do-mundo" preferidas
     (`mundo_natural`, `linguagem`, `historia`, `cientifico`) — privilegia
     o conteúdo factual sobre meta-skills aqui.
  3. Cria `PillView(status: 'served')`.
  4. Retorna `ok(lens_cache: ..., pill_view: ...)`.
- Fallback: se learner já viu todas, reciclar em ordem `created_at ASC`.

### Passo 3 — UI (3h)

`app/components/kid/home_pill_card.rb` + `.html.erb`:
- ~120px de altura, position-1 no kid home (acima de Lojinha).
- Mostra: emoji do lens_type, `kid_action_label` ("🔬 Como funciona"),
  título curto derivado do `concept.name`, gancho (1ª frase do payload).
- CTA primary: "Tomar a pílula" (verde Duolingo).
- Estado vazio (caso falhe): card minúsculo "O Guia está de folga hoje".

`app/views/kid/academy/pills/show.html.erb`:
- Layout em modal full-screen (não muda layout do home).
- Renderiza a lente usando o partial existente
  (`kid/academy/missions/_lens_<type>.html.erb` — reaproveitar!).
- Botão "Conta pro pai" abaixo + botão "Voltar".
- Marca `PillView.status = 'viewed'` no `show`.

### Passo 4 — Compartilhamento parent (1h)

`Kid::Academy::PillsController#share`:
- Atualiza `PillView.shared_with_parent = true`.
- Cria `ActivityLog(log_type: 'pill_shared', ...)` no nível do `Family`.
- Broadcast Turbo Stream pro canal `family_#{family_id}` que mostra
  card no parent home: "Lia tomou a pílula 'Por que o céu é azul' hoje
  — pergunta pra ela contar!".

### Passo 5 — Caderno (1h)

`app/views/kid/academy/pills/index.html.erb`:
- Lista paginada (10/page) das pílulas tomadas.
- Cada card mostra: data, lens_type, headline, e link para reabrir.
- Diferencia visualmente "compartilhada com pai" (checkmark dourado).

## Critérios de aceite

1. Kid logado no home vê card "Pílula do Dia" no topo todo dia
   (idempotente intra-day).
2. Tomar pílula completa em <90s (timer no UX).
3. Botão "Conta pro pai" cria notificação visível no parent dashboard
   em <1s (Turbo Stream).
4. Caderno em `/kid/academy/pills` lista o histórico.
5. Specs:
   - `spec/services/academy/pills/pick_daily_for_learner_spec.rb` —
     idempotência intra-day, exclusão de já-vistas.
   - `spec/system/kid/academy/pill_of_the_day_spec.rb` — fluxo full.

## Riscos

- **Conflito com missões em andamento**: kid abandonar missão pra tomar
  pílula. Mitigação: pílula só aparece no home, não no `/kid/academy`.
- **Acúmulo de "shared" no parent home** poluindo dashboard. Mitigação:
  agrupar por dia ("hoje a Lia tomou 1 pílula").
- **Algoritmo de escolha cansando o kid** (sempre o mesmo tipo). Mitigação:
  rodar com 4 categorias rotacionando + spec.

## Estimativa

- Total: **~10h** (modelagem 1h, service 2h, UI 3h, share 1h, caderno
  1h, testes 2h).

## Dependências

- **Bloqueia em A** — sem ~30 conceitos novos de curiosidade-do-mundo,
  a pílula é uma versão pequena de aula meta-skill, o que **não muda a
  percepção**. Esperar A entregar pelo menos 80 conceitos curados.
- **Independe de B/C** — pode rodar sem closure lens (pílula nunca é
  closure).
- **Sinerge com F** (interesses): se F existir, pílula filtra por
  interesse declarado.
