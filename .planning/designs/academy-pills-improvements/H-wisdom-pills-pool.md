# H — Expandir WisdomPills (40 → 120 + autoria real)

> **Objetivo.** Triplicar o pool de pílulas de sabedoria exibidas no
> loading overlay, e baixar a fração atribuída a "O Guia" (autoria
> sintética) de 25% para <10%, ampliando a presença de vozes reais
> (Sagan, Feynman, Montessori, Da Vinci, Saint-Exupéry, Camões…).

## Motivação

`config/academy_wisdom_pills.yml` hoje (2026-05-20):
- **40 entries** no total.
- **10/40 = 25%** assinadas por "O Guia" (autoria sintética).
- 12 versículos bíblicos (Provérbios/Eclesiastes/Tiago) ✓ alinhado com
  family values.
- ~15 filósofos/educadores. Repete: Sócrates (×2), Confúcio (×2), Paulo
  Freire (×2), Rubem Alves (×3), Einstein (×3), Cortella (×2).
- **Faltam ausências gritantes**: Carl Sagan, Richard Feynman, Maria
  Montessori, Leonardo da Vinci, Aristóteles, Marie Curie, Saint-Exupéry,
  Tolkien, C.S. Lewis, Camões, Cecília Meireles, Drummond, Clarice
  Lispector, Mandela, Gandhi.
- Pool de 40 com mostra aleatória: kid em uso diário (15 segundos no
  overlay × 1-2 missões/dia) **vê a mesma pílula em ~1 semana**.

Cresce o pool → renova a experiência e reduz vibe "sempre os mesmos".

## Escopo

**Entra:**
- ~80 pílulas novas, atingindo total de ~120.
- Reduzir "O Guia" para no máximo 12/120 (10%).
- Adicionar ~20 vozes novas, com 2-4 pílulas cada.
- Categorias temáticas opcionais (curiosidade, perseverança, escuta,
  humor, coragem) para se um dia o overlay quiser filtrar por contexto.

**NÃO entra:**
- Mudança no `Academy::WisdomPills` service (estrutura mantida).
- Tradução pra outros idiomas.
- Pull dinâmico (LLM gerando pílulas em runtime).

## Trabalho

### Passo 1 — Curadoria (4h)

Estabelecer **target mix**:

| Categoria                  | Atual | Alvo  | Δ    |
|----------------------------|-------|-------|------|
| Bíblia (Provérbios+)       | 12    | 25    | +13  |
| Filósofos clássicos        | 7     | 18    | +11  |
| Educadores brasileiros     | 7     | 14    | +7   |
| Cientistas (Sagan etc)     | 0     | 14    | +14  |
| Escritores/poetas          | 0     | 18    | +18  |
| Pensadores cristãos        | 1     | 9     | +8   |
| Anônimos / O Guia          | 10    | 12    | +2   |
| Outras culturas (Confúcio, Lao Tse, Rumi…) | 2 | 10 | +8 |
| **TOTAL**                  | **40**| **120**| **+80** |

Sugestões iniciais (revisar com o user):

**Cientistas a adicionar (4 cada):**
- Carl Sagan ("Somos todos feitos de poeira de estrelas"…)
- Richard Feynman ("Não é incrível? Eu tenho o direito de não saber".)
- Marie Curie ("Nada na vida deve ser temido — só compreendido".)
- Leonardo da Vinci ("Simplicidade é a sofisticação suprema".)

**Escritores brasileiros (3 cada):**
- Cecília Meireles, Drummond, Clarice Lispector, Manoel de Barros,
  Monteiro Lobato.

**Pensadores cristãos (1-2 cada):**
- C.S. Lewis, Tolkien, Madre Teresa, Santo Agostinho.

**Outras culturas (1-2 cada):**
- Rumi, Lao Tse, Marco Aurélio, Epicteto.

**Educadores brasileiros (mais):**
- Mario Sergio Cortella, Leandro Karnal, Augusto Cury, Içami Tiba.

### Passo 2 — Critérios editoriais (escritos no topo do YAML)

Cada pílula precisa:
1. **Ser uma frase só**, até ~14 palavras.
2. **Atribuição real** (livro ou referência conhecida; rejeitar
   "atribuído a X" sem fonte).
3. **Linguagem acessível**: PT-BR moderno; se o original era em outra
   língua, tradução fluente, não literal.
4. **Tom permitido**: curiosidade, perseverança, humildade, escuta,
   coragem, escolha, esforço.
5. **Tom proibido**: medo, fim dos tempos, julgamento moral direto,
   politização, melancolia adulta.

### Passo 3 — Adicionar categorias opcionais (1h)

Expandir o schema do YAML:
```yaml
pills:
  - text: "..."
    source: "..."
    theme: curiosidade  # opcional: curiosidade | escuta | perseveranca | humor | coragem | sabedoria
```

`Academy::WisdomPills` ganha:
- `WisdomPills.sample(theme: :curiosidade)` — filtra por tema.
- Mantém `.sample` (random uniforme) como default.

### Passo 4 — Tornar contextualidade possível no overlay (2h)

Hoje `app/views/kid/academy/missions/_loading_overlay.html.erb` chama
`Academy::WisdomPills.sample`. Mudança opcional: passar o `lens_type`
sendo gerado e mapear:

```
scientific → theme: curiosidade
narrative  → theme: escuta
ethical    → theme: coragem
first_person → theme: perseveranca
historical → theme: sabedoria
analogy_bridge → theme: curiosidade
```

Sample com fallback: se o tema não tem 5+ pílulas, cai pra random
uniforme.

### Passo 5 — Specs (1h)

`spec/services/academy/wisdom_pills_spec.rb`:
- `.all.size >= 120`.
- "O Guia" representa ≤ 12% do pool.
- Cada pílula tem `text` (≤120 chars) e `source` non-empty.
- `sample(theme: :curiosidade)` retorna pílula com theme correto.

## Critérios de aceite

1. `config/academy_wisdom_pills.yml` tem >= 120 entries.
2. `Academy::WisdomPills.all.count { |p| p.source == "O Guia" } <= 12`.
3. Overlay durante loading mostra variedade visível em 5 reloads
   consecutivos (manual smoke).
4. Specs verdes.

## Riscos

- **Atribuição falsa** (citações da internet são notoriamente
  espúrias). Mitigação: cada pílula nova precisa de fonte primária ou
  link Wikiquote com referência ao livro/discurso original.
- **Tom melancólico** infiltrando (Drummond/Clarice têm potencial).
  Mitigação: critério #5 do passo 2 — curar com olho de criança.

## Estimativa

- Curadoria das ~80 pílulas: **~6h** (~4-5 min cada com checagem de
  fonte).
- Themes + tests: **~3h**.
- **Total: ~9h**.

## Dependências

- Independente. Pode rodar em qualquer ponto.
