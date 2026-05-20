# A — Currículo de curiosidade-do-mundo

> **Objetivo.** Reequilibrar o currículo da Academia, hoje 70% "meta-skills
> de formação humana", adicionando ~30 conceitos de **curiosidade factual
> útil** (ciência, mundo natural, matemática-espetáculo, palavras, história
> curiosa) para que a promessa "pílulas que deixam mais inteligente" passe a
> ser estruturalmente verdadeira, não só caso particular.

## Motivação

Dump real (2026-05-20):
```
academy_concepts — 53 ativos
 ├ cognitivo  17  ← 32% (foco, atenção, anchoring, 5-porques, etc)
 ├ social      9
 ├ cientifico  7
 ├ saude       7
 ├ tecnologia  5
 ├ financeiro  4
 └ virtude     4
```
- A categoria `cientifico` tem apenas 7 conceitos — e quase todos são
  *meta-científicos* (ceticismo, método, "erro como dado") em vez de
  fatos-do-mundo (eletricidade, luz, células, raios, marés…).
- Não há categoria `mundo_natural`, `linguagem`, `matematica`, `historia`
  enquanto eixos próprios — geografia, biologia, astronomia simplesmente
  não existem como dimensão.

Crianças querem `Wow!` (fato surpreendente, mecanismo invisível) + utilidade
("agora eu sei algo que a maioria não sabe"). O currículo atual entrega
sobretudo *autoanálise*. Pílulas precisam ter sabor de **descoberta**.

## Escopo

**Entra:**
- 3 novas `Academy::Subject`s (com `angle`, `tagline`, `color`, `icon`,
  posição relativa).
- ~30 novos `Academy::Concept`s distribuídos entre as 3 (10 cada).
- 3 novas categorias no enum `Concept::CATEGORIES`: `mundo_natural`,
  `linguagem`, `historia` (e `matematica` se ainda couber).
- Migration para acomodar as categorias.
- Seed file `db/seeds/academy_curiosidade_concepts.rb` com `slug`, `name`,
  `definition`, `category`, `subject_id`, `pokedex_color_key`,
  `pokedex_silhouette_key`.

**NÃO entra:**
- Payloads de lentes pros novos conceitos (esses ficam para iteração junto
  com itens B e C — esse plano só popula o currículo).
- UI nova de Subject card no kid-side (reaproveita o que já existe).
- Renomeio de subjects existentes.

## Trabalho

### Passo 1 — Migração de categorias
Adicionar `mundo_natural`, `linguagem`, `historia`, `matematica` ao enum:

- `db/migrate/<ts>_extend_academy_concept_categories.rb` — apenas comentário
  + atualizar check constraint se houver. Hoje a validação é Ruby-side em
  `app/models/academy/concept.rb:33` (`CATEGORIES = %w[...].freeze`), então
  alterar a constante.
- Atualizar `db/migrate/<ts>_add_pokedex_columns_to_academy_concepts.rb`?
  Não — `pokedex_color_key` é texto livre. Apenas criar 3-4 tokens novos
  no CSS (ver Passo 4).

### Passo 2 — Definir as 3 novas Subjects

Sugestão (revisar nomes com o user antes de seedar):

```ruby
[
  {
    slug:    "como-o-mundo-funciona",
    name:    "Como o Mundo Funciona",
    tagline: "Mecanismos invisíveis do dia a dia",
    angle:   "Investigador (mecanismo > rótulo)",
    color:   "var(--c-academy-mundo)",      # novo token, ~#3B82F6 azul
    icon:    "atom",                          # ou "telescope"
    position: 8
  },
  {
    slug:    "curiosidades-do-corpo",
    name:    "Curiosidades do Corpo",
    tagline: "O que o teu corpo faz sem te contar",
    angle:   "Naturalista (corpo como sistema vivo)",
    color:   "var(--c-academy-corpo)",      # ~#F97316 laranja
    icon:    "heart-pulse",
    position: 9
  },
  {
    slug:    "palavras-origens",
    name:    "Palavras & Origens",
    tagline: "De onde vêm as ideias e os nomes",
    angle:   "Etimologista (a palavra esconde história)",
    color:   "var(--c-academy-palavras)",   # ~#A855F7 roxo
    icon:    "book-open",
    position: 10
  }
]
```

### Passo 3 — Lista dos ~30 conceitos

10 por Subject. Cada um é uma "pílula" — uma sacada que cabe em 1
`scientific` + 1 `narrative` + 1 closure. Lista a curar (preliminar; revisar
no kickoff):

**Como o Mundo Funciona (10)**
1. `por-que-o-ceu-e-azul` (cientifico) — espalhamento Rayleigh.
2. `gelo-flutua-na-agua` (cientifico) — anomalia da densidade.
3. `como-funciona-o-arco-iris` (cientifico) — refração + reflexão.
4. `como-um-aviao-voa` (cientifico) — Bernoulli + ângulo de ataque.
5. `por-que-mar-e-salgado` (cientifico) — erosão milenar.
6. `como-trovao-vem-depois-do-raio` (cientifico) — velocidade som vs luz.
7. `paradoxo-do-aniversario` (matematica) — combinatória contraintuitiva.
8. `por-que-pizza-grande-e-mais-barata` (matematica) — área = πr².
9. `como-funciona-uma-pilha` (cientifico) — reação química → elétrons.
10. `por-que-cubos-de-gelo-rachalham` (cientifico) — expansão térmica.

**Curiosidades do Corpo (10)**
1. `por-que-engasgo-bocejando` (saude) — anatomia compartilhada.
2. `como-cicatrizacao-funciona` (saude) — fibrina → colágeno.
3. `por-que-temos-impressao-digital` (saude) — atrito + identidade.
4. `como-cerebro-ve-cor` (saude) — cones + interpretação.
5. `por-que-doi-bater-cotovelo` (saude) — nervo ulnar exposto.
6. `como-corpo-cura-osso-quebrado` (saude) — osteoblastos.
7. `por-que-temos-sonhos` (saude) — consolidação de memória.
8. `como-tomate-vira-cocô` (saude) — peristalse + enzimas (humor).
9. `por-que-bocejo-e-contagioso` (social/saude) — neurônios-espelho.
10. `como-pele-fica-bronzeada` (saude) — melanina como protetor solar.

**Palavras & Origens (10)**
1. `de-onde-vem-a-palavra-salario` (linguagem) — sal romano.
2. `por-que-domingo-se-chama-domingo` (linguagem/historia) — Dies Dominica.
3. `de-onde-veio-o-zero` (matematica/historia) — Índia → Bagdá → Europa.
4. `quem-inventou-o-emoji` (linguagem/tecnologia) — Shigetaka Kurita 1999.
5. `por-que-livros-tem-paginas` (historia) — códex vs rolo.
6. `de-onde-vem-a-palavra-vacina` (linguagem/saude) — vacca/Jenner.
7. `como-romanos-contavam` (matematica/historia) — sistema aditivo.
8. `por-que-r-de-rua-e-igual-r-de-rato` (linguagem) — alfabeto fenício.
9. `por-que-numeros-arabes-nao-sao-arabes` (matematica/historia) — Índia.
10. `quem-inventou-a-escrita` (historia/linguagem) — Suméria 3200 a.C.

### Passo 4 — Tokens visuais

Adicionar 3 cores em `app/assets/stylesheets/tailwind/theme.css`:
```css
--c-academy-mundo:    #3B82F6; /* azul investigador */
--c-academy-corpo:    #F97316; /* laranja vital */
--c-academy-palavras: #A855F7; /* roxo histórico */
```
+ 3 `pokedex_color_key` correspondentes (`pokedex-mundo`, `pokedex-corpo`,
`pokedex-palavras`) com silhuetas SVG novas em
`app/assets/images/academy/pokedex/` (pode reusar 3 das existentes como
placeholder inicial e iterar depois).

### Passo 5 — Seed

`db/seeds/academy_curiosidade_concepts.rb`:
- Idempotente (`find_or_create_by(slug:)`).
- Cria Subjects + Concepts + edges óbvios (`concept_edges` para "ponte"
  óbvia: `por-que-pizza-grande-e-mais-barata` ↔ `custo-oportunidade-real`).
- Incluir em `db/seeds/academy.rb` no final.

### Passo 6 — Validação

- `make seed` roda limpo, sem mexer nos 53 conceitos existentes.
- `Academy::Concept.where(category: %w[mundo_natural linguagem historia
  matematica]).count` retorna ~30.
- Parent dashboard mostra as 3 novas Subjects com missões 0/10.

## Critérios de aceite

1. `Academy::Subject.count` == 10 (7 atuais + 3 novas).
2. `Academy::Concept.count` >= 83 (53 + 30 novos).
3. Todas as novas Subjects têm `angle`, `tagline`, `color`, `icon`
   populados.
4. Categorias novas no `CATEGORIES` aprovam o `validates :category,
   inclusion:`.
5. `make seed` é idempotente (rodar 2x dá mesmo resultado).
6. `bin/rails routes | grep academy` continua igual (nada quebra).
7. Smoke manual: `/parent/academy` mostra os 3 novos cards de Subject com
   "0/10 missões".

## Riscos

- **Categorias novas vazam para o LLM** que se baseia em `category` no
  prompt. Mitigação: revisar prompts `*.md.erb` (camada 3 do
  `academy-lesson-structure.md`) — se referenciam `category` literalmente,
  garantir que os 4 valores novos não destoam (`matematica` vs `cientifico`
  semelhantes).
- **Conceitos órfãos** se este plano for shipped sem B/C (sem payloads).
  Mitigação: criar `Concept`s com `active: false`. Só ativar quando houver
  ≥1 payload curado.
- **Drift de nomes** em PT-BR vs estrangeirismo: revisar com o user antes
  de seedar — "pizza grande é mais barata" vs "matemática da pizza", etc.

## Estimativa

- Migração + tokens + seed-skeleton: **2h**
- Escrever 30 `definition`s polidos (1-2 linhas cada): **4h**
- Revisar nomenclatura + edges + cores: **2h**
- **Total: ~8h** (1 sessão focada)

## Dependências

- Nenhuma técnica.
- **Bloqueia D** (Pílula do Dia) — D só faz sentido com massa crítica.
- **Habilita C/G** (sem novos conceitos, esses planos têm pouco substrato
  novo).
