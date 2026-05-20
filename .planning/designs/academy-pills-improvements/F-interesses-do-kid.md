# F — Sinal de interesses do kid → personalização

> **Objetivo.** Capturar 3-5 interesses por kid no onboarding e injetá-los
> no `LearnerContext` para que `narrative.character`,
> `analogy_bridge.source_domain` e exemplos em `scientific` falem **da
> paixão do kid**, não de cenas genéricas (mochila/recreio/brigadeiro).

## Motivação

Análise (2026-05-20):
- A única personalização hoje no payload é `{{learner_name}}` (substituído
  por `Lens::InterpolatePayload`).
- `LearnerContext` (`app/services/academy/lens/learner_context.rb`) calcula
  `mastery_tier`, `related_concepts`, hints adaptativos — mas o prompt
  ERB **pouco usa** isso, e nada captura "esse kid adora dinossauros".
- A consequência: a Lia que ama futebol e o Pedro que ama RPG recebem o
  mesmo `narrative` sobre Lia jogando RPG. Engajamento perdido.

Crianças engajam **brutalmente** quando o exemplo é da paixão delas. É
das alavancas mais subestimadas em produto edu pra criança.

## Escopo

**Entra:**
- Tabela `profile_interests` — interesses por profile (kid).
- Onboarding step novo "Conta pra gente o que você curte" (3-5 tags).
- Catálogo fixo de ~30 interesses (chips clicáveis).
- `LearnerContext` ganha `interests:` array.
- Prompts ERB (camada 3) ganham bloco "PERSONALIZAÇÃO POR INTERESSE"
  com instrução para o LLM puxar exemplo do interesse declarado (quando
  cabe — não forçar).
- Para payloads curados estáticos (pivot atual), criar variantes por
  interesse onde faz sentido **só nos slots críticos** (`narrative` +
  `analogy_bridge.source_domain`).

**NÃO entra:**
- Reescrever todos os payloads existentes para todos os interesses
  (combinação explode).
- Inferir interesses por uso (machine learning) — só auto-declarado.
- Atualizar interesses via parent (parent não escolhe pelo kid;
  é o kid quem clica nos chips).

## Trabalho

### Passo 1 — Modelagem (1h)

```ruby
# db/migrate/<ts>_create_profile_interests.rb
create_table :profile_interests do |t|
  t.references :profile, null: false, foreign_key: true
  t.string :interest_key, null: false   # slug do catálogo
  t.integer :rank, null: false, default: 0  # 1=top, 2, 3...
  t.timestamps
  t.index [:profile_id, :interest_key], unique: true
end
```

Catálogo em `config/profile_interests.yml`:
```yaml
interests:
  # Natureza & animais
  - { key: dinossauros, label: "Dinossauros", emoji: "🦖" }
  - { key: gatos,       label: "Gatos",       emoji: "🐱" }
  - { key: cachorros,   label: "Cachorros",   emoji: "🐶" }
  - { key: oceano,      label: "Oceano e peixes", emoji: "🐠" }
  - { key: insetos,     label: "Insetos",     emoji: "🐛" }
  - { key: passaros,    label: "Pássaros",    emoji: "🦜" }
  # Esportes
  - { key: futebol,     label: "Futebol",     emoji: "⚽" }
  - { key: skate,       label: "Skate",       emoji: "🛹" }
  - { key: dança,       label: "Dança",       emoji: "💃" }
  - { key: artes_marciais, label: "Artes marciais", emoji: "🥋" }
  # Espaço & ciência
  - { key: espaco,      label: "Espaço/planetas", emoji: "🪐" }
  - { key: dragoes,     label: "Dragões e mitos", emoji: "🐉" }
  - { key: robos,       label: "Robôs e IA",     emoji: "🤖" }
  - { key: experimentos, label: "Experimentos", emoji: "🧪" }
  # Arte & criação
  - { key: desenho,     label: "Desenho",     emoji: "🎨" }
  - { key: musica,      label: "Música",      emoji: "🎵" }
  - { key: leitura,     label: "Ler livros",  emoji: "📚" }
  - { key: lego,        label: "Lego/construir", emoji: "🧱" }
  # Jogos
  - { key: minecraft,   label: "Minecraft",   emoji: "⛏️" }
  - { key: roblox,      label: "Roblox",      emoji: "🎮" }
  - { key: rpg,         label: "RPG de mesa", emoji: "🎲" }
  - { key: tabuleiro,   label: "Jogos de tabuleiro", emoji: "🎯" }
  # Comida
  - { key: cozinhar,    label: "Cozinhar/doces", emoji: "🍰" }
  - { key: pizza,       label: "Pizza",       emoji: "🍕" }
  # Família
  - { key: irmaos,      label: "Brincar com irmãos", emoji: "👯" }
  - { key: avos,        label: "Hora com avós",   emoji: "👴" }
  # Outros
  - { key: carros,      label: "Carros",      emoji: "🚗" }
  - { key: avioes,      label: "Aviões",      emoji: "✈️" }
  - { key: viagens,     label: "Viajar",      emoji: "🗺️" }
  - { key: natureza,    label: "Acampar/natureza", emoji: "🏕️" }
```

### Passo 2 — UI onboarding (2h)

Adicionar step no onboarding kid:
- Tela: "Conta pra gente o que você mais curte! (escolhe 3-5)"
- Grid de chips clicáveis (3 colunas em mobile, 5 em desktop).
- Validação client-side: min 3, max 5.
- Salva via `Kid::OnboardingController#interests` → cria registros em
  `profile_interests` com `rank` na ordem de clique.

Permitir editar mais tarde via "Configurações > Eu curto" no kid home.

### Passo 3 — Modelo + adapter (1h)

`app/models/profile_interest.rb` (já dá pra adicionar `has_many` em
`Profile`).

Estender `Academy::Learner` (o adapter value object que é a ponte
módulo↔host) com `def interests` retornando array de keys ordenado por
rank.

### Passo 4 — `LearnerContext` ganha interests (1h)

`app/services/academy/lens/learner_context.rb`:
- Aceita `learner.interests` no `from(learner:, concept:)`.
- Adiciona método `interests_str` (top 3 keys + labels) pra uso no
  prompt: `"Lia gosta de: dinossauros, lego, gatos"`.

### Passo 5 — Prompts ERB (quando voltarem) (2h)

Quando o pivot curated-static for revertido para LLM-on-demand
parcialmente (fora deste plano), adicionar bloco aos prompts:

```erb
## INTERESSES DO APRENDIZ
<% if learner_context.interests.any? %>
Esta criança curte: <%= learner_context.interests_str %>.
Quando der pra usar SEM forçar (não cabe em todos os conceitos),
prefira ancorar exemplos nesses interesses. Não invente fatos sobre
o interesse — use só o conhecimento médio que uma criança da idade
tem do tema.
<% end %>
```

### Passo 6 — Variantes curadas críticas (3h)

Para o pivot curated-static, criar **subpasta de variantes por interesse**
**apenas em slots críticos** (não pra todo concept):

```
db/seeds/academy_lens_payloads/narrative/
  ├ escutar-de-verdade.json                  ← default (genérico)
  └ escutar-de-verdade.minecraft.json        ← variante p/ minecraftcer
```

Service `Lens::ResolveCuratedPayload`:
- Para um `learner` + `concept` + `lens_type`, tenta primeiro arquivo
  `<slug>.<top_interest>.json`; cai pra default se não existir.

Curar variantes só para os **10 conceitos mais-tocados** × **5
interesses mais comuns** (= 50 variantes). Não bloqueia o ship — vai
crescendo conforme curador escreve.

## Critérios de aceite

1. Kid novo passa pelo onboarding e seleciona 3+ interesses.
2. `Profile#interests.pluck(:interest_key)` retorna a lista ordenada.
3. `Academy::Learner.from_profile(profile).interests.first(3)` retorna
   3 keys.
4. `LearnerContext.from(learner: kid, concept: c).interests_str` retorna
   string formatada.
5. Quando o `Lens::ResolveCuratedPayload` encontra uma variante para o
   top interest, ela é servida.
6. Specs:
   - `spec/models/profile_interest_spec.rb`.
   - `spec/services/academy/lens/resolve_curated_payload_spec.rb`.

## Riscos

- **Catálogo enviesado** (jogos masculinos demais). Mitigação: revisar
  paridade de gênero/atividade ao montar `profile_interests.yml`.
- **Interesses mudando** rápido (kid muda paixão a cada mês). Mitigação:
  permitir edição fácil; mostrar "última atualização há X dias" pra
  lembrar.
- **Variantes explodindo** em manutenção. Mitigação: pivot é
  só-default; variantes opcionais por concept-chave.

## Estimativa

- Modelagem + onboarding + adapter: **~5h**.
- Variantes (50 payloads): **~10h** (separate effort do curador).
- **Total mínimo: 5h** para infra; variantes vão crescendo.

## Dependências

- Independe técnico.
- **Habilita D** (Pílula do Dia ganha personalização forte).
- **Habilita G** (Lightning Round pode escolher conceitos relacionados
  ao interesse pra surpreender).
