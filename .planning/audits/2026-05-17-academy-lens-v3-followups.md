# Academy Lens v3 — QA Follow-ups (2026-05-17)

Pós-implementação dos 4 itens de refinamento (concept brief estruturado,
few-shot rotation, contra-exemplo nomeado, forbidden_terms) + QA Playwright
com a Laura (11y) percorrendo a missão **"Por que mexer no celular é tão
difícil de parar?"** (conceito Dopamina, 5 lentes cold-path geradas com
`template_version: *.v3`).

**3 itens identificados pra próxima sessão**, ordenados por impacto:

```
┌─────────────────────────────────────────────────────────────────┐
│  Prioridade   Item                                  Tipo        │
├─────────────────────────────────────────────────────────────────┤
│  ALTA         #1 Clonagem do few-shot hardcoded     Pedagógico  │
│  MÉDIA        #2 Nav fixa intercepta "Continuar"    UX/UI       │
│  BAIXA        #3 Drift textual no analogy_bridge    LLM/Schema  │
└─────────────────────────────────────────────────────────────────┘
```

---

## #1 — Clonagem do few-shot quando concept-alvo coincide com concept-exemplo

**Prioridade:** ALTA — afeta diretamente a qualidade pedagógica do conceito
mais visitado (Dopamina é a missão "destacada" no `Búsola do Explorador`).

### Sumário

Quando o conceito-alvo da geração coincide com o conceito usado no
`# EXEMPLO DE REFERÊNCIA` hardcoded do prompt ERB, o LLM produz uma cópia
**quase literal** do exemplo. O `LLM-as-judge` aprova (verdict=PASS, score
11-12) porque julga apenas a lente isolada, sem visibilidade do prompt.

### Evidência concreta

QA com Laura na missão de Dopamina, 6 lentes geradas com `*.v3`:

| Tipo            | Eco da sacada | Clonou few-shot?      | Score  |
|-----------------|---------------|-----------------------|--------|
| `scientific`    | ✅            | ✅ **cópia literal**  | 12/12  |
| `narrative`     | ❌            | ✅ **cópia literal**  | 11/12  |
| `historical`    | ✅            | ❌ (cenas originais)  |  9/12  |
| `first_person`  | ✅            | ❌ (ação original)    |  8/12  |
| `analogy_bridge`| ✅            | ❌ (domínios novos)   | 10/12  |
| `statistical`   | ❌            | (n/a) REVISE          |  7/12  |

Os 2 que clonaram são exatamente aqueles cujo prompt usa **dopamina** como
conceito do exemplo hardcoded:
- `prompts/scientific.md.erb` — exemplo "Dopamina não é prazer…" (linhas 67-90)
- `prompts/narrative.md.erb` — exemplo "Léo, 12, joga handebol…" (linhas 76-95)

Lente real gerada para `scientific` (row 472 do `academy_lens_cache`):

```
headline:        "Dopamina não é prazer — é o sinal de 'vai atrás disso'"
mechanism_steps: idêntico ao exemplo, palavra por palavra
illustration:    "Um cachorro farejando, com uma seta..." (idem)
micro_check:     pergunta idêntica, só {{learner_name}} → "Laura"
```

### Hipótese de causa

O LLM, ao ver no prompt:
1. **"Gere lente para o conceito Dopamina"**
2. **"# EXEMPLO DE REFERÊNCIA (conceito: 'dopamina') [payload completo]"**

…interpreta o exemplo como **resposta canônica do mesmo problema** e
copia. Esse padrão é conhecido em prompt engineering: few-shots usando o
**mesmo objeto** que a query bias o modelo pra reuso literal.

O `the_essence` (curado) e o `# CONTRA-EXEMPLO` que adicionamos
**mitigam pra outros conceitos** (`historical`, `first_person`,
`analogy_bridge` geraram conteúdo original mesmo sendo Dopamina), mas
**não vencem o atrator do exemplo + conceito iguais**.

### Opções de fix (escolher 1 ou combinar 1+3)

**1. Trocar o concept-exemplo dos 8 ERBs por algo "neutro"**
   Para cada `prompts/*.md.erb`, escolher um conceito de exemplo que
   **provavelmente não vai ser o concept-alvo** com frequência. Candidatos:
   - `scientific`: trocar "dopamina" → "fotossíntese" ou "homeostase"
   - `narrative`: trocar "dopamina" → "gratificação tardia" ou "palavra dada"
   - `ethical`: já usa "honestidade radical" (concept-alvo plausível) — talvez trocar pra "tradeoff"
   - `statistical`: trocar "dopamina" → "ultraprocessados" ou "switch-cost"
   - `engineering`: trocar "dopamina" → "algoritmo-recomendacao"
   - `historical`: já usa "recompensa variável" — concept-alvo bem raro, OK
   - `first_person`: já usa "atenção plena" — OK
   - `analogy_bridge`: já usa "senso crítico" — OK
   **Custo:** ~30min curadoria + bump de `template_version` (v3 → v4).
   **Risco:** os exemplos novos precisam ser PASS do juiz primeiro, ou
   ficamos com âncora pior que a atual. Estratégia: rodar `Lens::Generate`
   manualmente pros conceitos candidatos, pegar payloads PASS, usar como
   novo hardcoded.

**2. Detectar colisão concept-alvo == concept-exemplo no Generators::Base**
   Marcar cada prompt ERB com um cabeçalho `EXAMPLE_CONCEPT_SLUG`, e no
   `template_binding` setar `suppress_hardcoded_example = (concept.slug ==
   example_concept_slug)`. Quando true, esconder o bloco `# EXEMPLO DE
   REFERÊNCIA` e confiar apenas no `curated_example_json` (item 2) +
   contra-exemplo + `the_essence`.
   **Custo:** ~1h código + ajuste nos 8 ERBs.
   **Risco:** cold-start fica sem few-shot positivo nesse caso específico.
   Mitigação: o `the_essence` curado + contra-exemplo nomeado + auto-crítica
   já dão muito ancoramento.

**3. Forçar variação no prompt do scientific/narrative quando colisão**
   Adicionar uma instrução condicional no Base, injetada quando colisão
   detectada: *"ATENÇÃO: o exemplo abaixo é sobre o MESMO conceito que você
   está sendo pedido a gerar. NÃO copie literal. Mude personagem, cena,
   números, headline. Use o exemplo apenas pra calibrar SHAPE e VOZ."*
   **Custo:** ~30min.
   **Risco:** o LLM pode ignorar a instrução (é o padrão clássico de "don't
   do X" anti-instrução).

**Recomendação combinada:** começar por **#1** (mais robusto, sem código
novo). Quando o `ExamplePicker` (item 2 já implementado) acumular pool
PASS≥11 de outros conceitos, ele substituirá automaticamente o hardcoded
via `curated_example_json` — então o problema desaparece em prod
naturalmente, mas o hardcoded continua sendo o fallback de cold-start.
Por isso o fix vale.

### Como validar o fix

```ruby
# Em sessão futura, após aplicar o fix:
# 1) rebump template_version (*.v4) pra invalidar cache
# 2) seed dopamina + 1 outro concept curado
# 3) rodar pra dopamina e checar se NÃO clonou:
docker compose exec web bin/rails runner '
  Academy::Lens::Generate.call(
    concept: Academy::Concept.find_by(slug: "dopamina"),
    lens_type: :scientific, learner: <stub>
  )
  # Inspecionar payload — headline + mechanism_steps NÃO devem ser idênticos
  # ao hardcoded.
'
```

---

## #2 — Nav fixa inferior intercepta clicks no botão "Continuar"

**Prioridade:** MÉDIA — não bloqueia conclusão (form pode ser submetido
via Enter ou JS), mas trava a interação natural de toque.

### Sumário

O `<nav>` flutuante de navegação principal (`fixed left-1/2 -translate-x-1/2`)
no kid layout sobrepõe verticalmente o botão `<input type="submit"
value="Continuar →">` quando a lente termina. Resultado: o tap no botão
"Continuar" cai no link "Academia" da nav (ou em outro item), gerando
navegação errada ou nenhuma ação.

### Evidência concreta

Erro do Playwright durante o QA:

```
<input type="submit" value="Continuar →">
  → element is visible, enabled and stable
  → scrolling into view if needed
  → <nav aria-label="Navegação principal" class="fixed left-1/2 ...">
    intercepts pointer events
  → retrying click action
  [fail after 5s]
```

Reproduzido em **todas as 5 lentes da missão de Dopamina**. Workaround
no QA: submit via JS (`form.submit()`).

### Hipótese de causa

Provavelmente um conflito de:
- nav com `position: fixed` + `bottom-X`
- botão `Continuar` com `w-full` no fim da página, sem `margin-bottom` ou
  `padding-bottom` suficiente pra escapar do safe-area da nav

### Onde investigar

- `app/views/layouts/kid.html.erb` — nav fixa
- `app/views/kid/academy/missions/` — partial que renderiza o footer da
  lente com o botão Continuar
- `app/components/ui/` — se houver componente "stage actions" ou similar

### Opções de fix

**1. `padding-bottom` no `<main>` >= altura da nav + gap (recomendado)**
   Garante que qualquer conteúdo no fim da página tenha respiro. Único
   ajuste em 1 lugar (`layouts/kid.html.erb` ou tailwind theme).

**2. Renderizar o "Continuar" como bottom-sheet acima da nav**
   Componente "stage actions" com `position: sticky bottom-X` *acima* do
   z-index da nav. Mais robusto pra outros lugares (forms longos), mas
   mexe em componente.

**3. Aumentar z-index do form de ação acima do z-index da nav**
   Hack barato — pode quebrar outros overlays. Evitar.

### Como validar

Reabrir Playwright na missão e tentar tap normal no "Continuar" — deve
funcionar sem fallback JS.

---

## #3 — Drift textual no `analogy_bridge` entre `elements` e `mapping`

**Prioridade:** BAIXA — cosmético, não afeta sacada principal. Mas é
sinal de que o schema permite incongruência.

### Sumário

Na lente `analogy_bridge` gerada pra Dopamina (visit 1197), o LLM
produziu **2 versões** ligeiramente diferentes do mesmo elemento:

| Local                            | Texto produzido                                                          |
|----------------------------------|--------------------------------------------------------------------------|
| `target_domain.elements[3]`      | "criança que perde o interesse depois de **conseguir o** brincar demais no videogame" |
| `mapping[3].to`                  | "criança que perde o interesse depois de brincar demais no videogame"    |

O `mapping[3].to` deveria ser **exatamente igual** a um item de
`target_domain.elements` (regra explícita no prompt ERB linha 22:
*"Cada `to` está em `target_domain.elements`"*).

### Evidência concreta

Snapshot da página de Laura (visit 1197), seções "Destino" vs "Pontes":

```
Destino → "...depois de conseguir o brincar demais no videogame"
Pontes →  "...depois de brincar demais no videogame"
                                                  ^^^^^^^^^^^^
```

### Hipótese de causa

O `schemas/analogy_bridge.json` não tem validação cruzada entre
`mapping[*].from/to` e `source_domain.elements / target_domain.elements`.
O prompt PEDE consistência ("NÃO valide no JSON, mas obedeça"), mas o
LLM falhou.

### Opções de fix

**1. Validar runtime no `Generators::AnalogyBridge` (pós-schema)**
   Hook próprio no subclass: depois do `validate!`, checar que todo
   `mapping[i].from ∈ source_domain.elements` e idem `to`. Em caso de
   mismatch, retry com `retry_message` específico:
   *"O mapping[3].to ('...brincar demais...') não bate com nenhum item de
   target_domain.elements ('...conseguir o brincar demais...'). Corrija
   um dos dois pra ficarem idênticos."*
   **Custo:** ~30min código + 1 spec.
   **Risco:** zero. Aumenta latência em 1 retry quando ocorre.

**2. Adicionar `if/then` no JSON Schema (draft-07 suporta limitado)**
   Mais frágil — draft-07 não tem `containsExactly` nem referência
   cruzada confortável. Evitar.

**3. Normalizar no view (silencioso)**
   View do `analogy_bridge` lê só `mapping[].from/to` e ignora `elements`.
   Hack — perde a estrutura pedagógica visual de "Origem"/"Destino" como
   listas separadas. Evitar.

**Recomendação:** opção **1**.

### Como validar

Gerar 5 lentes `analogy_bridge` (diferentes conceitos) com a validação
ativa. Conferir que mismatches disparam retry e que o output final é
consistente entre `elements` e `mapping`.

---

## Anexos

- Screenshots do QA: `qa-01-narrative-dopamina.png` … `qa-08-mission-complete.png`
  (raiz do repo)
- Rows de DB analisados: `academy_lens_cache` `template_version LIKE '%.v3'`
  AND `concept_id = (slug=dopamina)` — 6 rows.
- Specs novos cobrindo a base v3: `spec/services/academy/lens/example_picker_spec.rb`,
  `spec/services/academy/lens/generators/base_spec.rb` (forbidden_terms),
  `spec/models/academy/concept_spec.rb` (brief accessors).
- Migration: `db/migrate/20260518000001_add_brief_fields_to_academy_concepts.rb`
- Seed curado (11 conceitos com brief): `db/seeds/academy_concepts.rb`,
  constante `CONCEPT_BRIEFS`.
