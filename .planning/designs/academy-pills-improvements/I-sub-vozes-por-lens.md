# I — Sub-vozes por lens_type (Naturalista, Historiador, Engenheiro…)

> **Objetivo.** Substituir o narrador único "O Guia" por **um elenco
> reconhecível** de 4-5 sub-vozes, uma associada a cada modo pedagógico,
> para que o kid sinta variedade ("é o Naturalista de novo!") e cada
> lens_type ganhe **identidade própria** — não só formato.

## Motivação

Hoje o sistema usa uma única persona, "O Guia", definida em
`app/services/academy/lens/generators/base.rb::VOICE` (autoritativo +
misterioso + fascinado). Resultado: as 8 lentes têm **forma diferente**
mas **soam iguais**.

Crianças se conectam com personagens. Bill Nye e Mythbusters não eram
só "estilo" — eram **rostos com tics**. Mr. Beast, Felipe Castanhari,
Pirulla — todo edutainment infantil bem-sucedido tem um avatar
reconhecível.

O catálogo (`app/services/academy/lens/catalog.rb`) já diferencia
visualmente cada lens_type (emoji + ação). Mas o **conteúdo** é
narrado pela mesma voz. Falta o segundo nível de identidade.

## Escopo

**Entra:**
- Definir 4-5 sub-vozes com **tics**, vocabulário, hooks recorrentes.
- Mapear cada sub-voz a um (ou mais) lens_types.
- Atualizar prompts ERB (camada 3) com header "VOCÊ É [sub-voz]" no
  topo, antes do `VOICE` geral d'O Guia.
- Atualizar UI no kid (header da lente com nome + ícone da sub-voz).
- Manter "O Guia" como guarda-chuva narrativo (eles "vivem na Academia
  do Guia") — não destrona a persona-mãe.

**NÃO entra:**
- Áudio narration, ilustrações ou animações da sub-voz (futuro).
- Sub-vozes em chats do `GuideConversation` (mantém Guia neutro).

## Trabalho

### Passo 1 — Definir o elenco (1h)

Proposta de elenco (revisar com o user):

**🦋 A Naturalista**
- Lens types: `scientific`, `first_person`.
- Voz: tom de quem está com lupa na mão, paciente, susurro de
  descoberta. "Olha só…" / "Repara isso…".
- Tic: começa frase com observação concreta ("A formiga carrega 50× o
  próprio peso e nunca tropeça em rampa…").

**🏛 O Historiador**
- Lens types: `historical`.
- Voz: contador de história à beira da lareira; cita datas precisas.
- Tic: pula entre épocas mantendo o fio ("Em 1452, em Mainz… e dois
  séculos depois, no Rio…").

**🛠 A Engenheira**
- Lens types: `engineering`.
- Voz: pragmática, ama tradeoff, fala de constraint como cinto de
  segurança da criatividade.
- Tic: nomeia os limites ("Você só tem 1 folha. Sem cola. Pronto, aí
  começa o desafio…").

**🌉 O Tradutor**
- Lens types: `analogy_bridge`.
- Voz: o que vê padrão escondido entre dois mundos.
- Tic: começa com pergunta-ponte ("E se isso aqui fosse igual àquilo
  ali?").

**⚖️ O Juiz** (ou "A Conselheira")
- Lens types: `ethical`.
- Voz: nunca decide pelo kid — pergunta, mostra os dois lados.
- Tic: "Os dois caminhos têm peso. Mas peso é o que pesa pra você?".

**📖 A Contadora** *(opcional, p/ `narrative`)*
- Lens types: `narrative`.
- Voz: narrativa em terceira pessoa, ritmo de literatura juvenil.
- Tic: cenas com hora exata ("Quarta, 10h15…").

**📈 O Estatístico** *(opcional, p/ `statistical`)*
- Lens types: `statistical`.
- Voz: ama número específico, predição testável.
- Tic: "Aposta? Eu chuto X. Faz a sua aposta agora.".

Total: 5 vozes (sem opcionais) ou 7 (com).

### Passo 2 — Constants + adapter (1h)

`app/services/academy/lens/voices.rb`:
```ruby
module Academy
  module Lens
    module Voices
      Voice = Data.define(:key, :name, :emoji, :tagline, :tics, :system_extra)

      ROSTER = {
        naturalist:    Voice.new(key: :naturalist, ..., system_extra: "..."),
        historian:     Voice.new(...),
        engineer:      Voice.new(...),
        translator:    Voice.new(...),
        judge:         Voice.new(...)
      }.freeze

      LENS_TO_VOICE = {
        scientific:     :naturalist,
        first_person:   :naturalist,
        historical:     :historian,
        engineering:    :engineer,
        analogy_bridge: :translator,
        ethical:        :judge,
        narrative:      :naturalist,    # ou :storyteller se ativar
        statistical:    :naturalist     # ou :statistician se ativar
      }.freeze

      module_function

      def for_lens(type) = ROSTER[LENS_TO_VOICE.fetch(type.to_sym)]
    end
  end
end
```

### Passo 3 — Inject no prompt (1h)

Em `Generators::Base#system_prompt` (ou wherever o `VOICE` é montado):
```ruby
voice = Academy::Lens::Voices.for_lens(lens_type)
[
  "Você é #{voice.name}, #{voice.tagline}.",
  voice.system_extra,
  "",
  "Você faz parte da Academia d'O Guia — mantém o tom autoritativo,",
  "misterioso e fascinado d'O Guia, mas com a sua marca pessoal:",
  voice.tics.map { |t| "- #{t}" }.join("\n"),
  "",
  VOICE.original_body
].join("\n")
```

Para o pivot curated-static (onde prompts não rodam), garantir que o
**curador** sabe qual sub-voz usar — adicionar nota no schema/template
do payload (campo opcional `voice_hint`) e mostrar no parent dashboard.

### Passo 4 — UI da lente (1h)

`app/views/kid/academy/missions/_lens_<type>.html.erb`:
- Header com emoji + nome da sub-voz.
- Tooltip "Quem é a Naturalista?" → modal curto.

### Passo 5 — Galeria de sub-vozes (1h)

Tela `kid/academy/cast/index.html.erb`:
- Lista as 5-7 sub-vozes com lema, lente associada, e contagem de
  "quantas vezes você viu essa voz".
- Pequena gamificação: "Conheça todo o elenco" → badge quando viu
  ao menos 1 lente de cada sub-voz.

## Critérios de aceite

1. Cada lens_type tem uma sub-voz associada via
   `Academy::Lens::Voices::LENS_TO_VOICE`.
2. UI da lente mostra nome + emoji da sub-voz no header.
3. Quando prompt LLM voltar a rodar (post-pivot), o system prompt inclui
   o `voice.system_extra` no topo.
4. Galeria `/kid/academy/cast` lista todas as vozes.
5. Badge "Conheceu todo elenco" desbloqueia quando o `LearnerLensVisit`
   tem entries de todas as 8 lentes.

## Riscos

- **Sub-vozes destoando d'O Guia** → confusão narrativa. Mitigação: o
  prompt explicita "você é parte da Academia d'O Guia"; o tom-base
  permanece o de Generator::Base::VOICE; cada sub-voz só adiciona tics.
- **Curador esquecer de respeitar a sub-voz** no pivot curated-static.
  Mitigação: ferramenta de revisão em `/parent/academy/library` mostra
  a sub-voz esperada ao lado do payload.
- **Mais um onboarding cognitivo** pro kid (5 personagens novos).
  Mitigação: introduzir gradualmente (1 sub-voz por semana via missão).

## Estimativa

- Definição + roster + injection: **~4h**.
- UI da lente + galeria + badge: **~3h**.
- **Total: ~7h**.

## Dependências

- Independente.
- **Sinerge com H** — wisdom pills podiam ser atribuídas à sub-voz
  quando "O Guia" se torna apenas o "guarda-chuva". Mas H já está
  definida; basta cross-reference.
