# Academy — didactic moves dos bestsellers, aplicados por lente

> Data: 2026-05-18 (revisada — versão anterior leu "bestseller" como estrutura;
> esta lê como **qualidade de conteúdo / didactic moves**)
> Antecedentes: refactor de tom Lens v5 (2026-05-18)

## Premissa correta

Best-sellers de auto-ajuda contemporâneos não são uma estrutura a ser copiada — são **livros que fazem moves didáticos específicos muito bem**. Cada livro tem UM forte:

- **Carnegie** — *ilustra com anedotas de gente nomeada*
- **Clear** — *transforma comportamento em sistema causal nomeado*
- **Elrod** — *prescreve micro-ação executável agora*
- **Vieira** — *imperativo curto, ação antes do estado*
- **Eker** — *contraste de mindsets, dois lados defendidos por dentro*
- **Burchard** — *identity-first ("você já é X, só ainda não sabe")*

O que aprendemos: **cada lente do nosso catálogo tem afinidade natural com 1-2 desses moves**. Quando o template nomeia o move concretamente, o LLM gera conteúdo mais sharp. Sem migration, sem schema. Só prompt.

## Princípio-guia

> **Curioso, nunca infantilizado.** Diversão vem do mistério e da concretude — nunca de palhaçada, gíria forçada, ou tom "vamos brincar aprendendo". A criança fareja condescendência. O bestseller acerta esse equilíbrio: trata o leitor como capaz, mas é divertido porque entrega cápsula concreta com payoff imediato.

## Mapeamento didactic-move → lente

| Lente | Move | Inspiração concreta | O que isso muda no template |
|---|---|---|---|
| `scientific` | Mecanismo nomeado, causal | Clear: 4 leis (cue→craving→response→reward) — sistema com peças nomeadas | Cada passo tem verbo causal forte; mecanismo vira nameable system |
| `narrative` | Anedota com nome próprio antes do princípio | Carnegie: sempre Lincoln/Roosevelt/Andrew, nunca conceito abstrato primeiro | Personagem concreto brasileiro, idade, situação. Princípio NUNCA nomeado |
| `ethical` | Dois lados defendidos por dentro | Eker: rich-file vs poor-file, ambos articulados sem ironia | `case_b` mantém convicção interna; reveal ilumina, não decide |
| `statistical` | Predict → reveal calibrando intuição | Freakonomics-style; Eker quando cita números de "wealthy mindset" | Número específico com fonte honesta; surpresa em direção à sacada |
| `engineering` | Design do ambiente como variável | Clear cap. "Design your environment" — mudar as peças muda o resultado | Restrições nomeadas, custos concretos, outcomes com consequência observável |
| `historical` | Mesmo padrão atravessando eras | Documentário Diamond/Pinker (não bestseller direto mas mesma família) | 3 cenas em 3 séculos, detalhe sensorial por cena, padrão invariante revelado pela própria criança |
| `first_person` | Ação precede estado | Vieira (Poder da Ação): "para, faz, repara" · Elrod (SAVERS): 30s executáveis agora | Imperativa curta · sem cerimônia · reveal DEPOIS da sensação |
| `analogy_bridge` | Lattice de modelos mentais | Munger: biologia ↔ finanças, mesma engrenagem entre campos distantes | Domínios genuinamente distantes; mapeamento estrutural ≥ 3 pares |

## O que cada move proíbe (não-negociável)

| Move | Anti-padrão que mata |
|---|---|
| Mecanismo nomeado (scientific) | Definição abstrata em vez de causa→efeito |
| Anedota com nome próprio (narrative) | "Sofia, a curiosa" — nome+epíteto-cartilha |
| Dois lados defendidos (ethical) | `case_b` que já moraliza contra si |
| Predict→reveal (statistical) | Número da média esperada — não surpreende |
| Design do ambiente (engineering) | Opção obviamente certa vs obviamente errada |
| Padrão através de eras (historical) | 3 décadas grudadas (2010-2015-2020) |
| Ação precede estado (first_person) | "Feche os olhos e imagine" — não é encarnado |
| Lattice de modelos (analogy_bridge) | Domínios grudados (futebol/vôlei) |

## O que NÃO copiamos dos bestsellers

| Bestseller faz | Academy não faz | Por quê |
|---|---|---|
| Moraliza ("be sincere, period") | Convida descoberta | Criança fareja sermão |
| Prescreve afirmações repetidas | Convida ação observável | Autoridade sobre criança ≠ autoridade sobre leitor adulto |
| Tom motivacional (Eker, Burchard) | Tom Sagan-Manual-do-Mundo | Motivacional cansa criança; fascínio sustenta |
| Repete a mesma frase 50× | Reapresenta via lente diferente (rotação) | Mesma sacada, novos ângulos — recall via variedade |
| Vende plataforma/identidade | Vende curiosidade | Burchard não cabe |

## Implementação

Já feita (2026-05-18) — cada `# ENERGIA DESTA LENTE` no template foi atualizado pra nomear o didactic move concreto + a inspiração. VOICE em `base.rb` reforça "curioso, nunca infantilizado".

Sem migration. Sem schema novo. Sem schedule de rotação de lente. Sem campo `sticky_label` ou `thesis` curado. **Mudança ocorre 100% via prompt.** Cache invalida lazy via `prompt_digest`.

## Verificação

Próximas gerações de aula vão ter (esperado):
- `scientific` mais "sistema causal" (Clear-style) menos "definição"
- `narrative` mais "nome próprio + situação concreta" (Carnegie-style) menos "personagem genérico"
- `ethical` mais "dois lados defendidos" (Eker-style) menos "um certo + um errado"
- `first_person` mais "para, faz, repara" (Vieira/Elrod-style) menos "feche os olhos e reflita"

Se output continuar morno depois disso: o problema está em few-shot pool (`Lens::ExamplePicker`) ou no Judge — não nos templates.

## Camada 2 — As 4 disciplinas do micro-formato (2026-05-18, adendo)

Conversa subsequente trouxe constraint que muda a leitura dos templates: **kid escolhe diariamente, lê no celular, em ≤ 3 min, pílula de conhecimento útil**. Adicionado em `Base::VOICE`:

### Princípios novos (sistema)

1. **PÍLULA EM 3 MIN** — densidade > volume. Cada campo paga seu próprio espaço; "frase morna que só completa o JSON" é proibida.

2. **TESTE DE ÚTIL** — meta-critério: a aula é útil quando dá ao kid um NOME pra fenômeno que ele já meio-percebia ("recompensa variável", "dopamina antecipatória"). Sem o "olha-é-isso" apontando pra cenas do dia, é decoração. (Pesquisa: Perkins & Salomon 1992; Hattie 2009 — transferência depende de framing nomeado.)

3. **TESTE DO TEASER** — primeira frase tem que funcionar standalone. Se cortarmos tudo depois dela, ela já criou curiosity gap. (Pesquisa: Loewenstein 1994 — gap só funciona com peça-faltando sugerida, não mistério total.)

4. **PROMESSA AO KID** (por lente) — o kid escolheu uma label do catálogo (`🔬 Como funciona`, `📖 Conta a história`, etc.). A aula precisa entregar exatamente isso. Quebra de contrato com criança = bounce imediato.

### Mapa promessa→entrega

| Label | Promessa implícita | Falha se… |
|---|---|---|
| 🔬 Como funciona | Ver mecanismo desmontado | entrega fato/definição em vez de causa→efeito |
| 📖 Conta a história | Cair numa cena com gente real | abre com "era uma vez" ou narrador explicando |
| ⚖️ Você decide | Agência real no presente | dilema hipotético "imagine que…" |
| 📈 Adivinha | Palpitar antes do número | pergunta retórica em vez de irrecusável |
| 🛠 Você que constrói | Ser engenheiro/designer | challenge soa como exercício de prova |
| 🕰 Atravessando o tempo | Viagem no tempo sensorial | cenas grudadas/vagas "nos anos 1900…" |
| 👁 Faz isso agora | Parar de ler e EXECUTAR | kid lê o reveal sem ter feito a ação |
| 🔭 Em outro lugar | Sentir o "ah, mesma engrenagem!" | analogia decorativa sem clique estrutural |

### Generation effect — subutilizado por enquanto

Pesquisa (Slamecka & Graf 1978 + replicações): conhecimento gerado pelo aprendiz é retido ~50% melhor. Hoje só `statistical` e `historical` exploram a fundo. Próximas iterações dos templates podem incluir pequenos "preview-before-reveal" em `scientific`/`engineering`/`narrative` sem mudar schema. Não forçado nesta rodada — só se vier natural.

## Camada 3 — 3 gaps silenciosos que podem morder depois (2026-05-18, adendo)

Análise pós-implementação. Levantar agora porque um deles é silent killer e dois são oportunidades de cleanup com custo baixo.

### Gap A — `the_essence` / `mission.essence` pode driftar entre sessões da mesma missão

**Risco.** A `essence` é o que TODAS as 8 lentes pivotam ("a sacada central"). Se ela é LLM-gerada por turno em vez de vir de campo curado no DB, a 1ª aula e a 3ª aula da MESMA missão podem reforçar **sacadas levemente diferentes**. Spaced repetition (`Recall`) opera assumindo "mesma ideia, ângulos diferentes" — se a ideia muda silenciosamente, a repetição não consolida.

**Verificação.** Ler `Lens::InterpolatePayload` + `mission.essence` flow. A sacada vem de coluna no DB curada por humano, ou é re-gerada a cada chamada do LLM?

**Se for re-gerada:** mudança load-bearing. Move `essence` pra campo curado por missão (não por geração). Pode ser onde o `sticky_label`/`thesis` da v1 deste doc faria sentido — mas em escopo bem menor: só `mission.essence` virar curado, sem migration nova grande.

**Severidade:** alta. Silencioso. Quanto mais aulas geradas sob drift, mais o Atlas/Pokédex perde coerência cognitiva.

### Gap B — Few-shot pool nasce vazio sob o regime v5+judge-v4

**Diagnóstico.** `Lens::ExamplePicker` filtra por `judge_overall_score >= 85` (escala 0-100 do judge v4). Rows do cache antigo são escala 0-12 — automaticamente excluídos. **A primeira geração nova roda só com o exemplo hardcoded do template.**

**Boa notícia:** templates JÁ TÊM exemplo hardcoded por lente (bloco `# EXEMPLO DE REFERÊNCIA`). Cold-start é coberto. Não há crise.

**Gap real:** esses 8 exemplos hardcoded foram escritos sob disciplinas antigas (pre-PROMESSA-AO-KID, pre-didactic-move, pre-TESTE-DE-ÚTIL). Eles **não foram auditados contra a régua nova**.

**Auditoria atual:**

| Lente | Status | Diagnóstico |
|---|---|---|
| scientific | ⚠️ médio | Headline Sagan-style, mecanismo causal ok, mas "fotossíntese" não passa TESTE DE ÚTIL — kid não aponta pra ela no dia |
| narrative | ✅ forte | Theo + palavra dada — Carnegie puro, mantém |
| ethical | ⚠️ médio | Caso ok, mas `reveal` tem cheirinho de moralização |
| statistical | ✅ forte | 96 unlocks/dia — teaser irrecusável e útil, mantém |
| engineering | ✅ forte | TikTok mechanics — trade-offs reais, mantém |
| historical | ✅ forte | 1898 → 1971 → 2012 — mantém |
| first_person | ✅ forte | "Lista 5 detalhes" — Vieira/Elrod, mantém |
| analogy_bridge | ⚠️ médio | Mapeamento estrutural ok, mas "senso crítico" é abstrato pra 8-14 |

**Solução proposta — duas opções:**

- **A (leve):** auditar e sharpear os 3 fracos inline nos `.md.erb`. Custo baixo. Risco zero.
- **B (estruturada):** extrair os 8 exemplos canônicos pra `app/services/academy/lens/canonical_examples/{lens_type}.json` — dados, não prosa ERB. Template inclui via partial. Benefícios:
  - Auditável como data (spec valida shape contra `schemas/{lens_type}.json`)
  - Swappable sem editar prompt
  - Versionável independente do template
  - Espaço pra múltiplos exemplos por lente no futuro (rotação de few-shot pra evitar over-fitting)
  - Curador (você) atualiza JSON, não toca ERB

**Recomendação:** A agora (1 sessão), B documentada como next step quando os 8 exemplos forem estáveis e quiser-se múltiplos por tipo.

**Severidade:** média. Não-bloqueante. Mas a régua nova precisa estar refletida nos exemplos pra disciplina funcionar em escala — LLM imita o que vê.

### Gap C — Audit de "úteis" nos ~45 conceitos

**Risco.** Acabamos de adicionar TESTE DE ÚTIL como meta-critério ("a aula nomeia fenômeno que kid já meio-percebia"). Alguns conceitos no `academy_concepts` podem ser academicamente válidos mas falham nesse teste — "mitose", "tipos de relevo", "fotossíntese" classicamente. Por mais bem-feita a aula, conceito acadêmico não passa o teste.

**Solução proposta.** Audit rápido — 1 chat com Claude, lista dos 45 conceitos, prompt: "para cada conceito, ele nomeia fenômeno que criança 8-14 já meio-percebe no dia? Ranque ÚTIL / MORNO / ACADÊMICO". Output: lista priorizada de quais deletar/substituir.

**Severidade:** média. Não-bloqueante. Mas se 30% dos conceitos forem ACADÊMICO, 30% das missões geradas vão ser inúteis independente da qualidade da lente. Vale fazer antes do produto ir pra muitos kids.

## Histórico

- 2026-05-18 v1: bestseller como metáfora estrutural — proposta de `sticky_label` + `thesis` + rotação de lente. **Descartada** (não virou código).
- 2026-05-18 v2: reframe pra didactic moves por lente. Cada `# ENERGIA DESTA LENTE` ganhou nome de move + inspiração concreta de bestseller.
- 2026-05-18 v3 (Camada 2): adicionada constraint micro-formato + 4 disciplinas (pílula 3 min, teste de útil, teste do teaser, promessa ao kid) + tabela promessa→entrega.
- 2026-05-18 v4 (Camada 3): 3 gaps silenciosos pós-implementação (essence drift · few-shot canonical audit · concept utility audit). Bootstrapping de few-shot via codebase JÁ existe (`# EXEMPLO DE REFERÊNCIA` hardcoded); cleanup é auditar/sharpear esses 8 exemplos.
