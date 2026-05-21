# Plano de melhoria — pílulas v1.1 (pre-imagem)

Saída esperada: catálogo limpo, distratores fortes, hints visuais puros, PREFIX otimizado.
Tudo pronto antes da geração real das ilustrações (Phase 6 do change `add-pill-illustrations`).

## Princípios

1. **Mexer o mínimo no que já está ótimo** — Top 5 (`habito-2-minutos`, `celular-difícil-parar`, `dinheiro-vira-dinheiro`, `notificacoes-custam-23-min`, `memoria-falsa`) ficam intocados.
2. **Decisão editorial fica com o humano**; reescrita mecânica fica com IA.
3. **Cada mudança deixa rastro** — todo arquivo deletado/movido vira commit isolado com motivo no título.
4. **PREFIX bumpa pra `duolingo@v2`** se ajustarmos contrato visual (força regeneração consistente).
5. **Nenhuma imagem rola até a Fase D passar** (validação completa).

## Convenção de marcadores

- 👤 = decisão humana (taste editorial; só você fecha)
- 🤖 = execução determinística (eu faço sem ambiguidade)
- 🤝 = proposta minha + 1 review seu

---

## Fase A — Limpeza de catálogo (curadoria)

Resolve **dup#1-8** e **mismatch#1-4** do audit. Reduz de 42 para ~37 pílulas únicas, custo de imagem cai de $0.017 pra $0.015 (irrelevante) mas a coerência do caderno sobe muito.

### A.1 — Duplicatas: decisões por par 👤

| # | Par | Proposta | Justificativa |
|---|---|---|---|
| dup#1 | `5-porques.json` × `cinco-porques-resolve.json` | **Deletar** `cinco-porques-resolve` | `5-porques` tem exemplo de carro/alternador (industrial, memorável). `cinco-porques-resolve` usa vaso quebrado (genérico). |
| dup#2 | `vies-confirmacao.json` × `primeira-impressao-erra.json` | **Deletar** `primeira-impressao-erra` | Ambas usam a metáfora "detetive com lupa". `vies-confirmacao` tem distrator de bug-no-jogo (forte). |
| dup#3 | `algoritmo-conhece-voces-1milhao.json` × `como-internet-conhece-voce.json` | **Diferenciar e renomear** | Manter `algoritmo-conhece-voces-1milhao` (foco em **votos + pesos**). Renomear `como-internet-conhece-voce` → `algoritmo-tem-limites.json` e re-escrever pra falar de **safeguards** (idade, horário, filtros) — ângulo realmente distinto. |
| dup#4 | `quebrar-problema.json` × `pensar-em-voz-alta.json` | **Deletar** `pensar-em-voz-alta` | Filename mente: conteúdo é decomposição. `quebrar-problema` tem exemplo de quarto (concreto). |
| dup#5 | `custo-oportunidade-real.json` × `querer-precisar.json` | **Deletar** `querer-precisar` | Ambas usam balança/gangorra. `custo-oportunidade-real` tem distrator forte (R$ 10, sorvete + livro). |
| dup#6 | `calar-quando-falar-fofoca.json` × `mentiras-pequenas-custam.json` | **Diferenciar** | Reescrever `calar-quando-falar-fofoca` pra focar especificamente em **fofoca** (custo social, alianças falsas), não em honestidade-consigo. Mantém `mentiras-pequenas-custam` como "contrato consigo". |
| dup#7 | `silencio-constroi-confianca.json` × `escutar-de-verdade.json` | **Manter ambas** com reescrita leve | Complementares: silencio = **3 segundos de pausa externa**; escutar-de-verdade = **freio interno da Broca**. Reforçar essa distinção no headline e no rationale de cada uma. |
| dup#8 | `scroll-infinito-mente.json` × `celular-difícil-parar.json` | **Manter ambas** com diferenciação clara | `scroll-infinito` = **prêmio variável**; `celular-difícil-parar` = **velocidade do sinal (80ms)**. Já são razoavelmente distintas; só reforçar nos headlines. |

**Saldo**: 4 deleções + 2 renomeações + 4 diferenciações leves.

### A.2 — Mismatches filename ↔ conteúdo 👤🤝

| # | Arquivo atual | Conteúdo real | Proposta |
|---|---|---|---|
| mis#1 | `como-ia-decide.json` | Probabilidade do dado | Renomear → `probabilidade-do-dado.json`. Escrever pílula **nova** `como-ia-decide.json` sobre como modelos atuais decidem (chute baseado em padrão estatístico de bilhões de textos). |
| mis#2 | `ia-nao-e-magica.json` | Probabilidade do dado (outra ângulo) | **Deletar** — duplica `como-ia-decide` atual (`probabilidade-do-dado` após rename). |
| mis#3 | `como-app-funciona.json` | Loop genérico de feedback | Renomear → `loop-feedback.json` (loop control é conceito legítimo, não mascara). |
| mis#4 | `pensar-em-voz-alta.json` | Decomposição (duplica `quebrar-problema`) | **Já tratado em dup#4** — deletar. |

**Saldo**: 2 renames + 1 deleção + 1 pílula nova.

### A.3 — Pílulas finais 🤖

```
42 originais
–  4 deleções dup (cinco-porques-resolve, primeira-impressao-erra, querer-precisar, pensar-em-voz-alta)
–  1 deleção mis (ia-nao-e-magica)
+  1 nova (como-ia-decide v2 — IA real)
+  2 renames (como-internet-conhece-voce → algoritmo-tem-limites; como-ia-decide → probabilidade-do-dado; como-app-funciona → loop-feedback)
= 38 pílulas únicas no catálogo final
```

### A.4 — Atualizar seed loader / referências 🤖

- Verificar se algum código referencia os slugs deletados (`grep -rn`).
- Atualizar `db/seeds/*.rb` que carregam payloads.
- Migration de cleanup pra `academy_lens_cache` rows órfãs em dev/test.

---

## Fase B — Polimento de conteúdo (pílulas individuais)

### B.1 — Reescrita de illustration_hints com texto literal 🤖

Research confirmou: Gemini renderiza strings entre aspas como tipografia. **Não dá pra compensar no PREFIX** — tem que limpar na fonte. 12 casos identificados:

| Slug | Texto literal a remover | Substituição visual |
|---|---|---|
| `notificacoes-custam-23-min` | "cronômetro mostrando 23:00" | "ampulheta semi-vazia ao lado de peças de quebra-cabeça sendo recolhidas do chão" |
| `habito-2-minutos` | "'EU LEIO'", "'cérebro conta votos, não horas'" | "urna esquerda transbordando com pontinhos brilhantes vs urna direita vazia" |
| `foco-profundo-25min` | "'mesmo neurônio. 6 meses de foco profundo de diferença.'" | (apenas o close do neurônio com mielina, sem legenda) |
| `manipulacao-marcas` | "cartaz 'foi ideia minha'" | "fantasma carregando um símbolo de coroa/troféu" |
| `como-ia-decide` (after rename → probabilidade-do-dado) | "'1/6 não é previsão, é promessa de longo prazo'" | (apenas tabela com palitos contando 6s) |
| `vies-confirmacao` | "'ACHADOS: 1 prova'", "'coisas que não quero ver'" | "lupa iluminando uma única foto, prateleira de fotos viradas atrás" |
| `5-porques` | "'checklist incompleto'" | "engrenagem com peça faltando" |
| `calar-quando-falar-fofoca` | "contrato escrito 'Eu, comigo mesmo'", "selo de 'confiável'" | "pergaminho com símbolo de aperto-de-mão + selo de cera dourado" |
| `mentiras-pequenas-custam` | "placa 'CONTA'", "placa 'ESCONDE'", "balão 'foi ideia minha'" | "duas portas — uma com símbolo de coração brilhante, outra com símbolo de coração trincado" |
| `silencio-constroi-confianca` | "bolha de pensamento 'ele tá me ouvindo de verdade'", "cronômetro marca 3 segundos" | "ampulheta pequena entre dois personagens; uma das figuras com expressão de alívio" |
| `criador-vs-consumidor` | "'check' preguiçoso" (palavra) | "carimbo simples vs cérebro com luzes acendendo" |
| `quebrar-problema` | "caixa rotulada 'feito'" | "caixa com checkmark verde" |

Outras 3 pílulas têm menções leves a texto (ex: "letreiro sutil") — fazer pass completo no batch B.1. Estimativa: 15 ajustes totais.

**Restrição**: novo hint precisa caber no schema (50-320 chars). Hint reescrito não pode quebrar o schema validation.

### B.2 — Distratores fracos → plausíveis 🤝

Aplicando os critérios Haladyna do research (concepção equivocada real + paralelismo + ±20% comprimento + vocabulário homogêneo + zero absurdo):

| Slug | Distrator a corrigir | Proposta nova |
|---|---|---|
| `coragem-nao-ausencia-medo` | "A amígdala desligou sozinha e ele ficou calmo" | "A amígdala diminuiu o alarme antes dele decidir, então ficou mais fácil" *(concepção equivocada: "coragem é desligar o medo")* |
| `gratidao-muda-vista` | "Ele vai esquecer que o recreio existe" | "Ele vai começar a contar o tempo exato do recreio pra cobrar da escola" *(concepção equivocada: "gratidão = otimismo + checar fatos")* |
| `dinheiro-vira-dinheiro` | "Enterrar é mais seguro e o dinheiro não some" | "Os dois ficam com o mesmo, porque enterrar protege da inflação igual à conta" *(concepção equivocada: "guardar fora do banco também rende")* |
| `vies-confirmacao` | "Faz {{learner_name}} odiar o amigo por mostrar o vídeo" | "Faz {{learner_name}} reconhecer que o jogo tem problemas mas escolher continuar jogando" *(concepção equivocada: "reconhecer prova contra = aceitar")* |
| `impulso-perigoso` | "Porque a mãe não explicou direito" | "Porque o cérebro calcula 'jogar mais amanhã' como ganho maior, mas o cansaço futuro reduz" *(concepção equivocada: "racionalização compete com dopamina")* |
| `feedback-que-serve` | "'Arrume isso agora, senão vai ficar de castigo'" | "'Olha como a sua irmã sempre arruma rapidinho, viu?'" *(concepção equivocada: "comparação social = feedback construtivo")* |
| `acucar-engana-cerebro` | (revisar — opção C/D do micro_check estão muito fracas; checar arquivo) | (proposta no batch) |
| `tela-pre-sono` | "O cérebro entende que é dia e para de funcionar até amanhecer" | "A luz azul aquece a retina e faz o olho ficar cansado de uma forma diferente" *(concepção equivocada: "fadiga ocular = problema do sono")* |

**Saldo**: ~8 distratores reescritos. Pode haver mais quando ler tudo de novo com lente Haladyna — orçamento de até 12 ajustes.

### B.3 — Mechanism_steps muito longos (>180 chars) 🤖

Auditar com script:

```bash
ruby -e 'require "json"; Dir["db/seeds/academy_lens_payloads/scientific/*.json"].each { |f| j = JSON.parse(File.read(f)); j["mechanism_steps"].each_with_index { |s, i| puts "#{File.basename(f)} step#{i}: #{s.length} chars" if s.length > 180 } }'
```

Encurtar mantendo verbo + mecanismo. Schema permite 30-200, mas alvo é ~140 chars por leitura mobile.

### B.4 — Jargão empilhado → analogia primária 🤝

Casos do audit:
- `escutar-de-verdade`: "área de produção de fala (Broca)" → "central da fala no cérebro" + manter "memória de trabalho" (já é boa imagem mental).
- `foco-profundo-25min`: deixar BDNF/oligodendrócitos/mielina mas adicionar 1 linha de tradução no headline: "Gordura cerebral medível em ressonância — não é metáfora." → "Foco repetido engrossa a 'capa isolante' dos seus neurônios — sinal voa mais rápido."
- `acucar-engana-cerebro`: manter glicose/insulina/pâncreas (são vocabulário básico de educação alimentar; 10+ deveria saber); só adicionar uma analogia visual no primeiro step ("açúcar é um foguete pro sangue, insulina é o caminhão que limpa").

### B.5 — Headlines pequenas correções 🤖

- `criador-vs-consumidor`: "Ensinar alguém fixa o dobro do que só estudar sozinho" → "Ensinar alguém fixa muito mais que estudar sozinho — o cérebro tem que reorganizar tudo." (remove número falso-preciso "dobro", adiciona o porquê).
- `10-min-movimento`: "Regularidade vence intensidade em quase tudo do corpo" → "Pra aprender movimento, regularidade vence intensidade." (escopo correto).

---

## Fase C — PREFIX otimizado (aplicar research de imagem)

### C.1 — Novo PREFIX `duolingo@v2` 🤖

Substituir `PromptComposer::PREFIX` por versão com framing **positivo** (research mostrou que "no text" vaza tokens):

```ruby
STYLE_VERSION = "duolingo@v2"

PREFIX = <<~PROMPT.strip.freeze
  Flat vector illustration in the style of a wordless children's
  picture book. Communication is purely visual — symbols, icons,
  gestures, and facial expressions only. All surfaces (signs, screens,
  papers, walls, thought bubbles) are intentionally blank or contain
  only simple pictograms.

  Duolingo aesthetic: rounded geometric shapes, vibrant Duolingo green
  (#58CC02) as the primary accent over a soft pastel palette of peach,
  sky blue, and butter yellow. Thick clean outlines, friendly mascot
  energy, cheerful and curious mood. White background, square 1:1
  composition, child-friendly tone.

  Final check: every sign, page, screen, and bubble in this image is
  intentionally blank or shows only a simple pictogram — no letters,
  no numbers, no words anywhere.
PROMPT
```

Mudanças vs v1:
- Abre com "wordless children's picture book" (re-ancora estado-alvo).
- "Communication is purely visual" é positivo, não negativo.
- "Final check" no final reforça o estado-alvo sem introduzir o token "text" cru.

### C.2 — Atualizar PromptComposer + spec 🤖

- Bumpar `STYLE_VERSION = "duolingo@v2"`.
- Atualizar `prompt_composer_spec.rb` (asserções textuais sobre o prefix).
- Bump força regeneração automática de quaisquer rows existentes (já tratado no `Generate#up_to_date?`).

### C.3 — Doc 🤖

Adicionar nota em `docs/academy-v2.md` §15: por que `v2`, o que mudou, link pro research.

---

## Fase D — Validação (gate antes da Fase E)

Nada de imagem real até tudo aqui passar.

### D.1 — Schema 🤖

```bash
ruby -e '... validar todos os 38 payloads contra scientific.json'
```

Garantir que reescritas mantêm os limites (`headline 20-120`, `mechanism_steps 3 items × 30-200`, `illustration_hint 50-320`, `micro_check.options 3-4 items × 5-120`).

### D.2 — make rspec 🤖

Suíte completa verde (incluindo specs novas do PromptComposer atualizado).

### D.3 — make lint + brakeman 🤖

Limpos.

### D.4 — Smoke real de imagem (3 pílulas representativas) 🤖

Antes de gerar 38, gerar 3 com `--only=foco-profundo-25min,memoria-falsa,custo-oportunidade-real` e auditar visualmente:

- ✓ Zero texto/letras na imagem?
- ✓ Paleta Duolingo respeitada?
- ✓ Estilo flat vector consistente?
- ✓ Cena reflete o hint?

Custo: ~$0.0012. Se vazar texto em alguma, ajustar PREFIX e re-rolar antes de ir pras 38.

### D.5 — openspec validate strict 🤖

```bash
openspec validate add-pill-illustrations --strict
```

---

## Fase E — Geração full + commit

(É a Phase 6 atual do change `add-pill-illustrations`.)

- `make academy-illustrations DRY_RUN=1` confirma 38 rows (não 42).
- `make academy-illustrations` gera os 38 reais.
- Revisão humana visual; re-roll de outliers via `FORCE=1 ONLY=...`.
- Commit isolado dos `.webp` (mensagem: `"seed: academy pill illustrations (gemini-2.5-flash-image, duolingo@v2, 38 pills)"`).

---

## Resumo numérico

```
Pílulas:           42 → 38  (4 deletadas, 2 renomeadas, 1 nova)
Distratores fix:   ~8-12
Hints reescritos:  ~15
Steps encurtados:  ~6
PREFIX:            v1 → v2 (positive framing)
Custo imagem:      $0.017 → $0.015  (irrelevante)
Coerência:         caderno limpo, zero duplicatas, zero mismatches
```

## Ordem de execução

```
1. Você revisa este plano (especialmente A.1, A.2, B.2)
2. Você aprova decisões editoriais 👤
3. Eu executo Fase A em commits separados (deleções, renames, diferenciações)
4. Eu executo Fase B em commits separados (hints, distratores, steps, jargão)
5. Eu executo Fase C (PREFIX + spec + doc)
6. Eu executo Fase D (validação completa, smoke de 3 imagens)
7. Você revisa as 3 imagens smoke 👤
8. Após OK, executamos Fase E (batch full)
```

## Itens que precisam decisão sua antes de eu começar 👤

1. **Concorda com as decisões de duplicata** (deletar `cinco-porques-resolve`, `primeira-impressao-erra`, `querer-precisar`, `pensar-em-voz-alta`, `ia-nao-e-magica`)? Algum par que prefere mesclar em vez de deletar?
2. **A nova pílula `como-ia-decide` v2** sobre IA real — quer que eu rascunhe e você revisa, ou prefere escrever você (essa é editorial-pesada)?
3. **`mentiras-pequenas-custam` × `calar-quando-falar-fofoca` diferenciação** — sua família é cristã (memória do projeto); quer que `calar-quando-falar-fofoca` puxe explicitamente da tradição (Tiago 3:5-6, Provérbios 16:28)? Ou só ângulo psicológico/social?
4. **Distratores reescritos em B.2** — vou submeter um diff por arquivo pra você aprovar, ou prefere que eu execute em lote e você revisa o conjunto?
