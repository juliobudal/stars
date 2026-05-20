# J — Suavizar `FORBIDDEN_TONE_PATTERNS` pra liberar wonder-hook

> **Objetivo.** Recuperar uma classe de ganchos que o produto baniu por
> medo justo de cair em TED-talk infantil, mas que são **a estrutura
> clássica do espanto** ("Espera. Olha isso.", "Tem uma coisa estranha
> aqui."). Liberá-los com cuidado e sob critério, sem reabrir a
> moralização que motivou o ban.

## Motivação

`FORBIDDEN_TONE_PATTERNS` (em `db/seeds/academy_lens_payloads.rb:28` e
em `app/services/academy/lens/generators/base.rb` quando o LLM roda)
banem:

```ruby
/\bdeixa eu te contar uma coisa importante\b/i,
/\breflita sobre\b/i,
/\bcomo você se sente\b/i,
/\bé importante (ser|que|fazer|aprender|saber|lembrar|entender)\b/i,
/\bvocê sabia que\b/i,    # ← polêmico
/\baprenda que\b/i,
/\bestudos mostram\b/i,
...
```

O ban faz sentido contra moralização e TED-talk genérico. Mas
**`"você sabia que"`** é a construção *standard* do wonder-hook,
usada por todo bom divulgador científico (Sagan, Cosmos, Manual do
Mundo, Kurzgesagt). Ao bani-la, o produto perdeu o **gancho clássico
da curiosidade** sem trocar por substituto.

Resultado prático: várias lentes `scientific` curadas começam com a
sentença-mecanismo direto ("O doce ou suco chega no intestino, arranca
a glicose para o sangue em minutos…"), pulando o gancho-espanto. Sem
o convite de espanto, a leitura entra como aula, não como pílula.

## Escopo

**Entra:**
- Reduzir `FORBIDDEN_TONE_PATTERNS` para o **mínimo necessário** —
  remover regex sobre wonder-hook.
- Adicionar **WHITELIST** explícita de openers permitidos.
- Adicionar **anti-padrão substituto**: bloquear ganchos *vazios*
  ("Hoje vou te contar algo legal!") sem bloquear ganchos *concretos*
  ("O coração bate 100.000 vezes por dia. Repara nisso.").
- Atualizar prompt ERB (camada 3, quando reativada) com exemplo de
  wonder-hook bom × ruim.

**NÃO entra:**
- Reabrir `\breflita sobre\b` ou `\bé importante\b` (moralização).
- Mudar o `JudgePersona` (juiz continua julgando "Gancho" como pilar).

## Trabalho

### Passo 1 — Auditoria do bloqueio atual (1h)

Rodar nas 192 lentes curadas:
```ruby
patterns = [
  /\bvocê sabia que\b/i,
  /\bdeixa eu te contar\b/i,
  ...
]
Academy::LensCache.where(source: "curated").find_each do |c|
  texts = collect_strings(c.payload)
  hits = patterns.flat_map { |re| texts.select { |t| t =~ re } }
  puts "#{c.id} #{c.lens_type} #{c.concept.slug}: #{hits.size} hits" if hits.any?
end
```

Resultado serve para **calibrar quais patterns retirar**: se nenhum
payload curado hoje bate em `"você sabia que"` (esperado, já que o
seed-time bloqueia), o ban é eficaz **a montante** mas vazio
**a jusante** — pode soltar.

### Passo 2 — Reescrever o conjunto (1h)

Nova lista mínima em `db/seeds/academy_lens_payloads.rb`:

```ruby
# Patterns que indicam tom de TED-talk, moralização, ou enchimento.
# NÃO ban wonder-hook puro — o juiz decide se o gancho é vazio ou
# concreto.
FORBIDDEN_TONE_PATTERNS = [
  # moralização direta
  /\breflita sobre\b/i,
  /\bcomo você se sente\b/i,
  /\bé importante (ser|que|fazer|aprender|saber|lembrar|entender)\b/i,
  /\baprenda que\b/i,
  /\ba lição (é|aqui é|aqui)\b/i,
  /\bno fim,? o certo é\b/i,
  /\be foi assim que .*aprendeu\b/i,

  # enchimento vazio
  /\bdeixa eu te contar uma coisa importante\b/i,
  /\bestudos mostram\b/i,
  /\bmuitos cientistas (acreditam|dizem|pensam)\b/i,

  # excesso de animação
  /(?:!!+|UAU!|INCRÍVEL!|GALERA!)/,

  # vocativo desnecessário
  /\b[A-ZÁÉÍÓÚÂÊÔÃÕÇ][a-záéíóúâêôãõç]+, (a|o) [a-zç]+(?:a|o)\b/

  # REMOVIDO: /\bvocê sabia que\b/i (era anti-wonder-hook)
  # REMOVIDO: /\bdeixa eu te contar\b/i amplo (mantém só a versão "uma coisa importante")
].freeze
```

### Passo 3 — Adicionar gate positivo (2h)

Em vez de só blacklist, adicionar **expected_opener_kinds** no schema
opcional ou validar no curator-time:

```ruby
module Academy
  module Lens
    module OpenerCheck
      WONDER_OPENERS_OK = [
        /\bvocê sabia que\b/i,
        /\brepara isso\b/i,
        /\bolha (so|isso|essa|esse)\b/i,
        /\bespera\b/i,
        /\btem uma coisa estranha\b/i,
        /\bse alguém te perguntar/i,
        /^[A-Z].{0,80}[.!?]/   # primeira frase concreta e curta
      ]

      def self.has_hook?(text)
        first_sentence = text.split(/(?<=[.!?])\s/).first.to_s
        WONDER_OPENERS_OK.any? { |re| first_sentence =~ re } ||
          first_sentence.split.size <= 12  # frase curta = hook implícito
      end
    end
  end
end
```

E no seeder/juiz adicionar warning se o **primeiro campo descritivo**
(`headline`, `dilemma`, `pattern_label`…) não passa por `has_hook?`.

### Passo 4 — Atualizar few-shot exemplares (2h)

Cada `*.md.erb` (camada 3) tem 1 few-shot. Substituir os atuais por
exemplares que **começam com wonder-hook concreto**, por exemplo:

`scientific.md.erb`:
```
Exemplo bom:
"Você sabia que seu coração bombeia 7000 litros de sangue por dia?
Isso é uma piscina inflável a cada 24 horas, sem você notar..."

Exemplo ruim:
"O coração é um órgão muscular que tem 4 câmaras. Ele bombeia
sangue para o corpo todo..."
```

### Passo 5 — Doc da decisão (30 min)

Adicionar seção em `docs/academy-lesson-structure.md`:
> "Anti-padrões: o que muda em 2026-05-2X — wonder-hook liberado;
> moralização e enchimento continuam banidos."

## Critérios de aceite

1. Curar payload começando com "Você sabia que [fato concreto]?" **passa**
   no seed-time.
2. Curar payload começando com "Reflita sobre a importância da
   gratidão" **falha** no seed-time.
3. Curar payload começando com "Hoje vou te contar algo legal sobre…"
   (genérico/vazio) **dispara warning** mas não bloqueia.
4. Specs:
   - `spec/services/academy/lens/opener_check_spec.rb` — 10 casos.
5. Documentação atualizada.

## Riscos

- **Wonder-hook degenerando em clickbait**: "Você sabia que comer
  brócolis te transforma em superherói?". Mitigação: pilar "Gancho" do
  juiz (já existe) reprova hook não-factual; spec coverage.
- **Liberação aparente de moralização** se o gate for malcalibrado.
  Mitigação: blacklist mantida (não foi removida — só reduzida).

## Estimativa

- Total: **~5h**.

## Dependências

- Independente. Pode rodar a qualquer momento.
- **Habilita melhor B/C** — curadores ganham um padrão expressivo a
  mais.
