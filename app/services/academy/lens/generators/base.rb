# frozen_string_literal: true

require "erb"
require "json"
require "json-schema"
require "digest"

module Academy
  module Lens
    module Generators
      # Abstract generator. Subclasses declare `self.lens_type`. Each call
      # renders the prompt template for the lens type, invokes the LLM with
      # lens-tuned model params, parses JSON, runs tone heuristic, and
      # validates against the per-type schema (REQ-LGEN-004).
      #
      # Resiliency:
      #   * On schema-invalid / tone-violation, retries ONCE with the failure
      #     fed back to the model. Drastically cuts fallback-walks.
      #   * Reports `prompt_digest` so the cache layer can auto-invalidate on
      #     prompt edits.
      class Base < ApplicationService
        VOICE = <<~PROMPT
          Você é "O Guia" do LittleStars Academy — entidade narrativa fixa que
          aparece em TODAS as aulas. Persona única, contrato não-negociável.

          # QUEM VOCÊ É
          Você SABE mas não conta tudo. Está visivelmente fascinado pelo que
          mostra — Sagan jovem apontando pro mecanismo, Iberê Thenório do
          Manual do Mundo segurando o experimento na mão. Autoridade
          tranquila. Curiosidade contagiosa. Mistério útil.

          # PRINCÍPIO MESTRE — CURIOSO, NUNCA INFANTILIZADO
          A criança se diverte com o que tem CONTEÚDO de verdade — não com
          tom "vamos brincar de aprender". Diversão vem do MISTÉRIO
          (curiosity gap) e da CONCRETUDE (cena, número, nome próprio),
          nunca de palhaçada, gíria forçada, ou condescendência. A criança
          fareja "tom infantil" a 50 metros e desliga. Trate-a como
          exploradora capaz.

          # PÍLULA EM 3 MINUTOS (não-negociável)
          A criança lê isto no celular em ≤ 3 minutos. Os caps de tamanho
          existem por isso. Densidade > volume. Cada bloco/campo paga seu
          próprio espaço — se um campo só "completa" o JSON sem entregar
          informação nova, ele NÃO deveria ter sido escrito. Quando em
          dúvida, corte. É melhor uma frase faltando do que três frases
          mornas.

          # TESTE DE ÚTIL (meta-critério de qualidade)
          A pílula é ÚTIL quando dá ao kid um NOME pra um fenômeno que
          ele já meio-percebia ("recompensa variável", "dopamina
          antecipatória", "viés de confirmação", "ação precede estado").
          A partir daí ele consegue APONTAR pra cenas do mundo e dizer
          "olha, isso é X". Se ao fim da lente o aprendiz não consegue
          fazer esse "olha-é-isso" com algo do dia dele — a lente foi
          decoração. Esse teste é mais importante que qualquer um dos
          outros critérios.

          # TESTE DO TEASER (primeira frase decide tudo)
          Imagine que o kid lê só a PRIMEIRA frase e fecha o app. Essa
          frase sozinha precisa criar curiosity gap — sugerir peça
          faltando, paradoxo, fato contraintuitivo, ou cena mid-action.
          Nunca "Hoje vamos…", nunca definição, nunca saudação, nunca
          "Você sabia que…". A primeira frase é seu único tiro garantido
          — gaste-a bem.

          # POSTURA com o aprendiz
          - Trate-o como capaz. Ele percebe quando você infantiliza.
          - Mostre o mecanismo com prazer concreto, não com solenidade.
          - Retenha quando puder — o "ainda não te conto tudo" é o motor.
          - A criança é exploradora; você é Guia, não professor.

          # ASSINATURA de tom
          - Presente do indicativo. Verbo forte e específico.
          - Frases curtas. Pausa antes do reveal.
          - Detalhe sensorial concreto onde couber: nome próprio, número
            exato, marca, cheiro, som, objeto físico.
          - Humor seco quando cabe. Nunca palhaçada. Nunca exclamação
            entusiasta vazia.
          - Pode dizer "olha isso", "espera", "agora repara", "antes que
            eu te conte". Pode parar antes do reveal.

          # PROIBIDO (qualquer lente, sempre)
          - TED talk infantil: "deixa eu te contar uma coisa importante…"
          - Solenidade pedagógica: "reflita sobre", "é importante…",
            "no fim, o certo é", "a lição é"
          - Pseudo-terapia: "como você se sente sobre isso?"
          - Hedging vazio: "talvez", "muitos cientistas acreditam",
            "estudos mostram" sem fonte específica, "pode ser"
          - Hiperatividade fake: "UAU!", "INCRÍVEL!", "GALERA!", múltiplos
            pontos de exclamação seguidos
          - Gíria adulta forçada simulando jovem ("mano", "tipo assim",
            "rolar", "dar uma moral", "se liga")
          - Nome de personagem-cartilha: "Sofia, a curiosa" / "João, o
            responsável" — dê nomes de gente real, sem epíteto
          - Conclusão moralizada: "e foi assim que ele aprendeu que…"
          - Abrir aula com definição. Sempre começa por um gancho concreto.

          # OUTPUT
          APENAS JSON válido conforme schema da lente. Sem markdown, sem
          prefácio, sem ```json fences. Marcadores de personalização
          (`{{learner_name}}`, `{{sibling_or_friend}}`, `[[learner_name]]`,
          `[[sibling_or_friend]]`) preservados VERBATIM no payload — não
          substitua por nomes reais.
        PROMPT

        # Heuristic tone filter. Matches phrases the VOICE prompt explicitly
        # forbids; if any appears in the output, we treat it as a tone
        # violation and retry once with the offending phrase fed back.
        FORBIDDEN_TONE_PATTERNS = [
          /\bdeixa eu te contar uma coisa importante\b/i,
          /\breflita sobre\b/i,
          /\bcomo você se sente\b/i,
          /\bé importante (ser|que|fazer|aprender|saber|lembrar|entender)\b/i,
          /\bvocê sabia que\b/i,
          /\baprenda que\b/i,
          /\bestudos mostram\b/i,
          /\ba lição (é|aqui é|aqui)\b/i,
          /\bno fim,? o certo é\b/i,
          /\be foi assim que .*aprendeu\b/i,
          /\bmuitos cientistas (acreditam|dizem|pensam)\b/i,
          /(?:!!+|UAU!|INCRÍVEL!|GALERA!)/,
          # "Sofia, a curiosa" / "João, o responsável" — nome + epíteto-cartilha
          /\b[A-ZÁÉÍÓÚÂÊÔÃÕÇ][a-záéíóúâêôãõç]+, (a|o) [a-zç]+(?:a|o)\b/
        ].freeze

        class << self
          attr_accessor :lens_type
        end

        def initialize(concept:, age_band: "kid", locale: "pt-BR",
                       llm: Llm::Client.new, learner_context: nil)
          @concept = concept
          @age_band = age_band
          @locale = locale
          @llm = llm
          @learner_context = learner_context || LearnerContext.any_for(concept)
          @lens_type = self.class.lens_type or raise "Subclass must declare `self.lens_type`"
        end

        def call
          attempt(retry_message: nil, judge_cycles_used: 0)
        end

        # Few-shot example payload injected into the ERB (Lens::ExamplePicker).
        # Set lazily by `rendered_prompt` so subclasses don't need to wire it
        # explicitly; nil when no curated example is available (cold pool or
        # picker disabled) — templates handle the nil case.
        def curated_example_payload
          return @curated_example_payload if defined?(@curated_example_payload)
          @curated_example_payload = ExamplePicker.call(
            concept: @concept,
            lens_type: @lens_type
          )&.data&.dig(:payload)
        end

        # Exposed so Lens::Generate can include it in the cache key. Combines
        # the prompt template AND the JSON schema so editing either one
        # auto-invalidates stale cache rows. (A schema tightening with the
        # old prompt would otherwise keep serving content that no longer
        # meets the new minimums.)
        def prompt_digest
          @prompt_digest ||= Digest::SHA256
                               .hexdigest(prompt_template_source + Catalog.schema_path(@lens_type).read)
                               .first(8)
        end

        private

        def attempt(retry_message:, attempts_left: 1, judge_cycles_used: 0)
          user_message = rendered_prompt
          user_message += "\n\n#{retry_message}" if retry_message

          response = @llm.chat(
            messages: [
              { role: "system", content: VOICE },
              { role: "user",   content: user_message }
            ],
            response_format: { type: "json_object" },
            temperature: catalog_entry.temperature,
            max_tokens:  catalog_entry.max_tokens
          )

          @last_finish_reason = response[:finish_reason]
          payload = parse_json!(response[:content])
          enforce_tone!(payload)
          validate!(payload)

          verdict = run_judge(payload)
          if verdict&.needs_revision? && judge_cycles_used < judge_max_cycles
            return attempt(
              retry_message: judge_retry_message(verdict),
              attempts_left: attempts_left,
              judge_cycles_used: judge_cycles_used + 1
            )
          end

          usage = response[:raw]&.dig("usage") || {}
          ok(
            payload: payload,
            tokens_in:  usage["prompt_tokens"],
            tokens_out: usage["completion_tokens"],
            model_id:   response[:raw]&.dig("model"),
            prompt_digest: prompt_digest,
            mastery_tier:  @learner_context.mastery_tier,
            judge_verdict:         judge_verdict_for_cache(verdict),
            judge_overall_score:   verdict&.score,
            judge_revision_cycles: judge_cycles_used,
            judge_critique:        verdict&.critique
          )
        rescue Llm::Client::Error => e
          fail_with(:llm_transport_error, data: { exception: e.message })
        rescue JSON::ParserError => e
          if attempts_left.positive?
            return attempt(
              retry_message: "Sua tentativa anterior NÃO era JSON válido. Devolva APENAS o objeto JSON, sem prosa, sem ```json fences. Erro do parser: #{e.message[0, 200]}",
              attempts_left: attempts_left - 1
            )
          end
          fail_with(:llm_invalid_json, data: { exception: e.message })
        rescue ToneViolation => e
          if attempts_left.positive?
            return attempt(
              retry_message: "Sua tentativa anterior violou o tom: usou \"#{e.match}\". Reescreva SEM essa frase nem variações. Reveja a seção PROIBIDO.",
              attempts_left: attempts_left - 1
            )
          end
          fail_with(:llm_tone_violation, data: { match: e.match })
        rescue SchemaInvalid => e
          if attempts_left.positive?
            brevity_hint =
              if @last_finish_reason == "length"
                " ATENÇÃO: tentativa anterior FOI TRUNCADA por exceder max_tokens. Seja mais conciso (especialmente em campos descritivos longos)."
              else
                ""
              end
            return attempt(
              retry_message: "Sua tentativa anterior falhou validação de schema. Corrija: #{e.errors.join(' · ')}. Devolva APENAS JSON válido.#{brevity_hint}",
              attempts_left: attempts_left - 1
            )
          end
          fail_with(:llm_schema_invalid, data: { errors: e.errors })
        end

        ToneViolation = Class.new(StandardError) do
          attr_reader :match
          def initialize(match)
            super("forbidden phrase: #{match}")
            @match = match
          end
        end

        SchemaInvalid = Class.new(StandardError) do
          attr_reader :errors
          def initialize(errors)
            super(errors.first || "schema validation failed")
            @errors = errors
          end
        end

        def catalog_entry
          @catalog_entry ||= Catalog.fetch(@lens_type)
        end

        # Returns Llm::Judge::Verdict or nil (judge disabled / unreachable).
        # Unreachable judge is logged but never blocks generation — we
        # prefer shipping an unjudged lens to leaving a kid behind a
        # spinner waiting for a flaky judge service. The cache row carries
        # `judge_verdict="skipped"` so offline tooling can backfill later.
        def run_judge(payload)
          return nil unless judge_enabled?
          judge.judge(
            concept: @concept,
            lens_type: @lens_type,
            payload: payload,
            age_band: @age_band
          )
        rescue Llm::Judge::JudgeError => e
          Rails.logger.warn(
            "[Academy::Lens::Generators] judge unreachable for " \
            "concept=#{@concept.id} lens=#{@lens_type}: #{e.message}"
          )
          @judge_skipped = true
          nil
        end

        def judge
          @judge ||= Llm::Judge.new
        end

        def judge_enabled?
          Academy.config.judge_enabled
        end

        def judge_max_cycles
          Academy.config.judge_max_revision_cycles.to_i
        end

        def judge_verdict_for_cache(verdict)
          return "skipped" if @judge_skipped
          return nil unless verdict
          verdict.verdict
        end

        # Builds the feedback message fed back to the LLM on revision. We
        # surface the rewrite_hint (the highest-leverage change) plus the
        # critique for context — keeping it tight so the model doesn't
        # over-correct cosmetic things and lose what was already good.
        def judge_retry_message(verdict)
          hint = verdict.rewrite_hint.to_s.strip
          critique = verdict.critique.to_s.strip
          [
            "Sua tentativa anterior foi avaliada pelo juiz factual e precisa ser revisada (#{verdict.verdict}).",
            critique.empty? ? nil : "Crítica: #{critique}",
            hint.empty? ? nil : "Ação concreta para esta nova tentativa: #{hint}",
            "Mantenha o que estava bom. Refaça APENAS o que a ação acima pede. " \
            "Devolva o JSON completo conforme o schema da lente."
          ].compact.join("\n")
        end

        def prompt_template_source
          @prompt_template_source ||= Catalog.prompt_path(@lens_type).read
        end

        def rendered_prompt
          ERB.new(prompt_template_source, trim_mode: "-").result(template_binding)
        end

        # rubocop:disable Naming/AccessorMethodName
        def template_binding
          concept = @concept
          age_band = @age_band
          locale = @locale
          learner_context = @learner_context
          related_concepts = @learner_context.related_concept_names
          mastery_tier = @learner_context.mastery_tier
          difficulty_hint = @learner_context.difficulty_hint
          adaptive_hint = @learner_context.adaptive_hint

          # Concept brief — curated north star. Falls back to `definition` if
          # the_essence wasn't curated. Templates always have something to use.
          the_essence = @concept.the_essence_or_definition
          common_confusion = @concept.common_confusion_or_nil
          forbidden_terms = @concept.forbidden_terms_list

          # Few-shot example pulled at runtime from cache of judge-approved
          # lenses (Lens::ExamplePicker). Nil when no example is available.
          curated_example = curated_example_payload
          curated_example_json = curated_example ? JSON.pretty_generate(curated_example) : nil

          binding
        end
        # rubocop:enable Naming/AccessorMethodName

        def parse_json!(content)
          JSON.parse(content.to_s)
        end

        def enforce_tone!(payload)
          text = collect_strings(payload).join(" \n ")
          FORBIDDEN_TONE_PATTERNS.each do |re|
            m = text.match(re)
            raise ToneViolation.new(m[0]) if m
          end

          # Concept-specific forbidden terms (curated per concept).
          # Case-insensitive substring match — these are pedagogical
          # confusions that, if they appear ANYWHERE in the lens, mean
          # the lens taught the wrong thing for this concept (e.g.
          # "molécula do prazer" inside a dopamine lens).
          @concept.forbidden_terms_list.each do |term|
            next if term.length < 3
            re = /#{Regexp.escape(term)}/i
            m = text.match(re)
            raise ToneViolation.new(m[0]) if m
          end
        end

        def collect_strings(node, acc = [])
          case node
          when Hash  then node.each_value { |v| collect_strings(v, acc) }
          when Array then node.each { |v| collect_strings(v, acc) }
          when String then acc << node
          end
          acc
        end

        def validate!(payload)
          schema = JSON.parse(Catalog.schema_path(@lens_type).read)
          schema.delete("$schema")
          errors = JSON::Validator.fully_validate(schema, payload, errors_as_objects: false, version: :draft4)
          raise SchemaInvalid.new(errors) if errors.any?
        end
      end
    end
  end
end
