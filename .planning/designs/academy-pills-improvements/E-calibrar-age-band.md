# E — Calibrar age band + leiturabilidade

> **Objetivo.** Alinhar a faixa etária declarada nas 4 camadas (prompt,
> juiz, schema, UI) e baixar o teto de vocabulário para que o conteúdo de
> fato sirva uma criança de **7-10 anos** — e não, na prática,
> adolescente-final-do-fundamental-2 que é onde várias lentes hoje
> aterrissam.

## Motivação

Discrepância detectada (2026-05-20):

```
docs/academy-lesson-structure.md (camada 3):
  "aprendiz pt-BR de 8-14 anos"

JudgePersona (camada 5, judge):
  pilar 3 "Encaixe 7-12 anos"

Prompt VOICE (camada 3):
  sem range explícito
```

E na evidência dos payloads curados:
- `db/seeds/academy_lens_payloads/historical/habito-2-minutos.json` cita
  "atos automatizados embrulhados de consciência" (William James) —
  inacessível pra 8 anos.
- `db/seeds/academy_lens_payloads/ethical/calar-quando-falar-fofoca.json`
  usa "coautoria silenciosa" — termo jurídico, ~12+ anos.
- Várias `scientific` usam parágrafos com cláusulas subordinadas longas
  (>20 palavras) que comprometem leitura por kid mais novo.

A promessa "pílulas que deixam mais inteligente, de forma divertida"
exige que **a criança consiga ler sozinha**. Hoje, parte do conteúdo
exige um adulto ao lado pra traduzir.

## Escopo

**Entra:**
- Unificar "kid age band" em **7-12 anos** em todas as camadas.
- Adicionar validação automática de leiturabilidade (Flesch-PT) no
  seeder e no juiz.
- Baixar `maxLength` em campos descritivos dos schemas para forçar
  concisão (sentenças mais curtas tendem a baixar Flesch automaticamente).
- Job (`rake academy:audit_readability`) que gera relatório das 200+
  lentes hoje curadas, listando as fora do range.

**NÃO entra:**
- Reescrever todos os payloads existentes nesta task — apenas relatar.
- Mudar prompt LLM (curated-static pivot mantém prompts congelados).

## Trabalho

### Passo 1 — Pesquisar Flesch-PT (1h)

Adotar **Flesch Reading Ease adaptado para português** (Martins, 1996).
Fórmula:
```
FRE_pt = 248.835 − 1.015 × (palavras / sentenças) − 84.6 × (sílabas / palavras)
```

Mapeamento de faixa:
- 75-100 → "muito fácil" (1º-2º ano, ~7 anos)
- 60-75 → "fácil" (3º-4º, ~8-9)
- 50-60 → "razoável" (5º-6º, ~10-11)
- 30-50 → "difícil" (12+)
- <30 → "muito difícil" (adulto)

**Alvo** para Academy kid: **FRE_pt >= 60** (até "fácil"). Hard floor: 50.

Gem candidata: `textstat` (existe via FFI) ou implementação Ruby pura
em ~80 linhas (contagem de sílabas em pt-BR via regex de vogais com
overrides para hiatos comuns). Preferir Ruby puro (zero deps).

### Passo 2 — Module `Academy::Llm::Readability` (2h)

`app/services/academy/llm/readability.rb`:
```ruby
module Academy
  module Llm
    module Readability
      module_function

      def score(text)
        words      = text.split(/\s+/).reject(&:empty?)
        sentences  = text.split(/[.!?]+/).reject { |s| s.strip.empty? }.size
        syllables  = words.sum { |w| count_syllables(w) }
        return 0.0 if words.empty? || sentences.zero?

        248.835 - 1.015 * (words.size.to_f / sentences) -
                  84.6 * (syllables.to_f / words.size)
      end

      def kid_friendly?(text, floor: 60.0)
        score(text) >= floor
      end

      private_class_method def self.count_syllables(word)
        # Conta grupos de vogais (aproximação razoável p/ pt-BR).
        word.downcase.scan(/[aeiouáéíóúâêôãõ]+/).size.clamp(1, Float::INFINITY)
      end
    end
  end
end
```
+ spec com 10-15 sentenças conhecidas (uma da Bíblia infantil, uma do
Camões — extremos esperados).

### Passo 3 — Integrar no seeder (1h)

Em `db/seeds/academy_lens_payloads.rb`:
- Após validar tone e schema, rodar `Readability.kid_friendly?` em todos
  os campos coletados por `collect_strings`.
- Se score < 50 → **abortar seed** desse payload com mensagem clara.
- Se 50 <= score < 60 → **warning** (mas segue).

### Passo 4 — Pilar novo no juiz (2h)

Em `app/services/academy/llm/judge_persona.rb`, ou substituindo um
pilar fraco:
- Adicionar **pilar 7 "Leiturabilidade"**, ou refinar pilar 3 "Encaixe
  7-12 anos" para incluir score Flesch como evidência.
- Se score < 50 → pilar 3 = 0 → REVISE automático.

### Passo 5 — Audit batch (1h)

`lib/tasks/academy.rake`:
```ruby
namespace :academy do
  desc "Audit readability of all curated payloads"
  task audit_readability: :environment do
    Academy::LensCache.where(source: "curated").find_each do |cache|
      texts = collect_strings(cache.payload)
      score = texts.sum { |t| Academy::Llm::Readability.score(t) } / texts.size
      tier  = score >= 60 ? :ok : (score >= 50 ? :warn : :fail)
      puts "[#{tier}] #{cache.lens_type}/#{cache.concept.slug} → #{score.round(1)}"
    end
  end
end
```

### Passo 6 — Apertar schemas (1h)

Para campos descritivos longos, baixar `maxLength`:
- `scientific.mechanism_steps[].text` — hoje sem `maxLength` explícito.
  Adicionar `maxLength: 120` por step → força frases curtas.
- `narrative.scenes[].text` — verificar limite atual.
- `ethical.case_a.body` / `case_b.body` — atualmente generosos.
- Bump de `template_version` em
  `app/services/academy/lens/catalog.rb` para invalidar cache LLM
  (mesmo que não seja usado no momento — disciplina).

### Passo 7 — Unificar age band (30 min)

- `docs/academy-lesson-structure.md` — trocar "8-14" → "7-12".
- `app/services/academy/llm/judge_persona.rb` — confirmar "7-12".
- README do portfólio.

## Critérios de aceite

1. `Academy::Llm::Readability.score("Frase simples curta. Tudo aqui é
   fácil.")` >= 80.
2. `Academy::Llm::Readability.score("A heurística de disponibilidade
   constitui um viés cognitivo que enviesa decisões em direção à
   evidência mais facilmente recuperada.")` < 30.
3. `rake academy:audit_readability` roda em <60s para o pool atual.
4. Relatório de audit lista quantos payloads precisam reescrita
   (esperado 20-40 hoje).
5. Seed novo de payload com tom adulto **é bloqueado** com mensagem
   clara apontando o campo problemático.

## Riscos

- **False positives** — score baixo pode vir de palavras compostas ou
  nomes próprios ("Eclesiastes", "Alexander"). Mitigação: warning, não
  fail abaixo de 50.
- **Pressão pra simplificar demais** podendo perder força do conceito.
  Mitigação: alvo é 60, não 80 — espaço pra densidade pedagógica.
- **Quebrar conteúdo existente** se forçarmos reescrita de tudo. Mitigação:
  primeiro relatar (passo 5), depois decidir lote a lote.

## Estimativa

- Implementação: **~7h** (Readability module + integração + audit).
- Reescrita dos payloads identificados: **separate effort**, escopo do
  curador depois.

## Dependências

- Independente; pode rodar a qualquer momento.
- **Habilita B/C** (curador ganha feedback automático sobre leiturabilidade
  durante a curadoria).
