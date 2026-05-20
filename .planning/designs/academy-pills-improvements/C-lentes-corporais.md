# C — Lentes corporais e temporais (`first_person`, `historical`, `engineering`)

> **Objetivo.** Quebrar o trio expositivo dominante
> (narrative → scientific → statistical) que aparece em 80% das missões,
> curando 30-40 payloads dos 3 lens types subutilizados, para que cada
> missão possa oferecer pelo menos um modo *fazer com o corpo*, *atravessar
> o tempo* ou *projetar* — não só *ler e responder*.

## Motivação

Distribuição atual de payloads curados (2026-05-20):
```
scientific      42
narrative       42
statistical     42
analogy_bridge  38
ethical         23
engineering      4   ← os MESMOS 4 conceitos
first_person     4   ← os MESMOS 4 conceitos
historical       1   ← UM único conceito
```

Os 4 concepts que têm `engineering` e `first_person` são todos do mesmo
cluster ("habito-2-minutos", "celular-difícil-parar", "foco-profundo",
"notificacoes-custam-23min") — formação humana. Toda a `historical`
existente é uma única lente sobre hábitos.

Resultado: o kid pratica praticamente só leitura + múltipla escolha. A
v4 desenhou 8 modos pedagógicos diferentes (catálogo em
`app/services/academy/lens/catalog.rb`), mas só 5 estão em uso real.

Os 3 modos faltantes são os mais "divertidos" justamente porque tiram o
kid da tela:
- `first_person` — **fazer com o corpo agora** (`ui_primitive: embodied_action`).
- `historical` — **atravessar o tempo** (`ui_primitive: timeline`).
- `engineering` — **projetar / arrastar elementos** (`ui_primitive: drag_list`).

## Escopo

**Entra:**
- 10 novos payloads `first_person` em concepts variados (não só formação
  humana).
- 10 novos payloads `historical` (idem).
- 10 novos payloads `engineering` (idem).
- Inclusão dessas lentes na `Lens::ChooseNext` para que de fato apareçam
  no journey do kid (revisar heurística atual).

**NÃO entra:**
- Schemas novos (os 3 já existem).
- UI primitives novos (já existem no catálogo).
- LLM generation pros 3 tipos (mantém curated-static pivot).

## Trabalho

### Passo 1 — Selecionar concepts candidatos (1h)

Critério de seleção:
- Concepts que **se beneficiam** do modo. Não forçar `first_person` num
  concept abstrato; não forçar `historical` num concept sem precedente
  histórico claro.

Lista preliminar (ajustar):

**`first_person` — embodied** (10 concepts onde o kid pode FAZER agora)
1. `escutar-de-verdade` — fica em silêncio 60s ouvindo o ambiente.
2. `respiracao-acalma` (criar se não existe) — 4-7-8 e mede ritmo cardíaco.
3. `cinco-porques-resolve` — aplica num problema real (e.g. "por que
   meu quarto sempre fica bagunçado").
4. `compromisso-cumprido` — escolhe 1 micro-compromisso pra cumprir hoje.
5. `por-que-doi-bater-cotovelo` (de A) — bate de leve, sente o nervo.
6. `como-cerebro-ve-cor` (de A) — ilusão de cor com retângulo cinza em
   fundo colorido.
7. `gelo-flutua-na-agua` (de A) — coloca cubo de gelo num copo, observa.
8. `por-que-ceu-e-azul` (de A) — usa lanterna + copo com água + leite.
9. `paradoxo-do-aniversario` (de A) — pergunta data nascimento de 5
   amigos, conta colisões.
10. `coragem-nao-ausencia-medo` — escolhe 1 coisa que te dá medo e faz
    versão minúscula dela.

**`historical` — pattern across time** (10 concepts com 3+ marcos)
1. `juros-compostos` — Babilônia (sumérios) → Fibonacci (1202) → Einstein.
2. `vacina` — Jenner (1796) → Pasteur (1885) → COVID mRNA (2020).
3. `escrita` — Suméria 3200 a.C. → Gutenberg → Internet.
4. `zero` — Índia (~458) → Bagdá (820) → Europa (1202).
5. `tempo-padronizado` — relógio mecânico (1300s) → fuso horário (1884)
   → NTP (1985).
6. `democracia` — Atenas → Magna Carta → constituição.
7. `mapa` — Babilônia → Mercator → GPS.
8. `dinheiro` — escambo → moeda metálica → cartão → Pix.
9. `medicina-baseada-em-evidencia` — Hipócrates → Semmelweis → RCT moderno.
10. `algoritmo` — Al-Khwarizmi (820) → Ada Lovelace → ChatGPT.

**`engineering` — design under constraint** (10 concepts com tradeoff)
1. `prioridade` — 5 tarefas, 1h de tempo, escolhe ordem.
2. `economizar-vs-gastar` — orçamento de R$ 50, lista de 8 desejos.
3. `dieta-balanceada` (de A?) — monta prato com proteína/carb/fibra.
4. `mochila-do-escolar` — 5 itens, peso máx, escolhe e justifica.
5. `interface-de-app` — projeta tela de "tarefas da semana" pra irmão.
6. `como-aviao-voa` (de A) — projeta avião de papel com restrição (1
   folha, sem cola).
7. `por-que-pizza-grande-mais-barata` (de A) — escolhe pizza que rende
   mais por R$ entre 3 tamanhos.
8. `algoritmo-de-busca` — ordena 10 livros com 3 regras dadas.
9. `como-criar-habito` — projeta o próprio gancho de hábito em 4 campos.
10. `senha-segura` — projeta senha com 5 restrições obrigatórias.

### Passo 2 — Curar payloads (per type)

Mesmo workflow do plano B:
1. Ler schema (`app/services/academy/lens/schemas/<type>.json`).
2. Escrever payload contra schema.
3. Salvar em `db/seeds/academy_lens_payloads/<type>/<concept-slug>.json`.
4. Rodar `make seed` parcial.

Atenção especial:
- `first_person.json` exige `action_prompt`, `sensory_anchor`,
  `expected_time_seconds`, `reveal`. **`expected_time_seconds` deve ser
  realista** (60-180s) — não vale "15 minutos de meditação".
- `historical.json` exige `scenes` com `year` + `headline` +
  `structural_element`, mínimo 3 cenas em séculos diferentes (não vale
  "2018, 2019, 2020").
- `engineering.json` exige `constraint`, `options[]` arrastáveis, e
  `reveal` com o **tradeoff** explícito.

### Passo 3 — Atualizar `Lens::ChooseNext`

Hoje a heurística (em `app/services/academy/lens/choose_next.rb`) tende
a escolher os 4 tipos mais populados. Revisar para garantir que quando
um concept tem `first_person`/`historical`/`engineering` curado, esses
têm chance >= 1/N de serem escolhidos numa missão de 4 stages.

Possível regra simples: se a missão exige 3 stages e o concept tem
qualquer um dos 3 modos raros curado, **forçar 1 desses no meio** (entre
o `narrative` e o closure).

## Critérios de aceite

1. `Academy::LensCache.curated.where(lens_type: %i[first_person
   historical engineering]).distinct.pluck(:concept_id).size` >= 25.
2. Replay aleatório de 10 missões: **pelo menos 4 delas** apresentam
   uma das 3 lentes raras.
3. Spec `spec/services/academy/lens/choose_next_spec.rb` cobrindo o
   caso "concept com first_person → ChooseNext eventually picks it".

## Riscos

- **Realismo de `first_person`** — ações que pedem objetos físicos que o
  kid não tem (lanterna, leite, balança). Mitigação: priorizar ações
  com material zero (silêncio, respiração, observação corporal).
- **`historical` factualmente errado** — datas, atribuições. Mitigação:
  curador checa pelo menos 1 fonte por marco (Wikipedia EN + 1 livro/site
  acadêmico).
- **`engineering` virar "leitura disfarçada de arrasto"** — Mitigação:
  cada payload precisa de tradeoff *real*, não escolha óbvia.

## Estimativa

- 20 min × 30 payloads = **~10h**.
- Engineering toma mais tempo (lógica de tradeoff). Estimar 12h no total.

## Dependências

- **A** habilita ~10 dos 30 candidatos. Sem A, lista cai pra ~20.
- Roda em paralelo com **B**.
