# frozen_string_literal: true

module Academy
  module Content
    # Valida os cinco padrões de arco narrativo sobre a estrutura de conteúdo
    # curado (ACADEMY_CONTENT), sem tocar no banco. Reaproveitado pelo seed
    # (db/seeds/academy.rb) como gate de build e pela suíte de testes
    # (spec/seeds/academy_content_spec.rb) como gate de CI.
    #
    # Uso:
    #   violations = Academy::Content::ArcValidator.call(ACADEMY_CONTENT)
    #   raise violations.join("\n") if violations.any?
    #
    # Cada trilha deve declarar os metadados de arco:
    #   refrao, callback_anchor, arc_payload_marker, cliffhanger_to (slug | nil)
    module ArcValidator
      # Lista negra anti-clichê (FR-005). Comparada de forma normalizada
      # (minúsculas, sem acento). Mantida curta e específica de propósito —
      # pega o óbvio; o resto é revisão humana.
      BANNED_PHRASES = [
        "reflita sobre",
        "moral da historia",
        "nunca desista",
        "acredite em voce",
        "acredite nos seus sonhos",
        "siga seus sonhos",
        "o importante e",
        "licao de vida",
        "sempre acredite",
        "o ceu e o limite"
      ].freeze

      module_function

      # Retorna um array de strings de violação. Vazio = conteúdo válido.
      def call(content)
        trails = Array(content)
        slugs  = trails.map { |t| t[:slug] }
        active = trails.to_h { |t| [ t[:slug], t.fetch(:active, true) ] }
        titles = trails.to_h { |t| [ t[:slug], t[:title].to_s ] }

        trails.flat_map { |trail| validate_trail(trail, slugs:, active:, titles:) }
      end

      def validate_trail(trail, slugs:, active:, titles:)
        name    = trail[:slug]
        lessons = Array(trail[:lessons])
        return [ "[#{name}] trilha sem aulas" ] if lessons.empty?

        first = lessons.first
        last  = lessons.last
        out   = []

        # FR-002 — refrão presente na revelação de TODAS as aulas.
        refrao = trail[:refrao].to_s
        if refrao.strip.empty?
          out << "[#{name}] refrao não declarado (FR-002)"
        else
          lessons.each do |l|
            unless includes_norm?(revelation_of(l), refrao)
              out << "[#{name}/#{l[:slug]}] refrão ausente na revelação: #{refrao.inspect} (FR-002)"
            end
          end
        end

        # FR-003 — callback: âncora aparece na 1ª aula E na última.
        anchor = trail[:callback_anchor].to_s
        if anchor.strip.empty?
          out << "[#{name}] callback_anchor não declarado (FR-003)"
        else
          out << "[#{name}] callback ausente na 1ª aula: #{anchor.inspect} (FR-003)" unless includes_norm?(lesson_text(first), anchor)
          out << "[#{name}] callback ausente na última aula: #{anchor.inspect} (FR-003)" unless includes_norm?(lesson_text(last), anchor)
        end

        # FR-001 — pagamento de arco: marcador do gancho de abertura reaparece
        # na última aula (e existe no próprio gancho da trilha).
        marker = trail[:arc_payload_marker].to_s
        if marker.strip.empty?
          out << "[#{name}] arc_payload_marker não declarado (FR-001)"
        else
          out << "[#{name}] marcador de arco ausente no gancho da trilha: #{marker.inspect} (FR-001)" unless includes_norm?(trail[:hook].to_s, marker)
          out << "[#{name}] pagamento de arco ausente na última aula: #{marker.inspect} (FR-001)" unless includes_norm?(lesson_text(last), marker)
        end

        # FR-004 — cliffhanger cruzado nominal.
        dest = trail[:cliffhanger_to]
        if dest.nil?
          # Última do conjunto: fisgada é gancho aberto (sem destino a referenciar).
        elsif !slugs.include?(dest)
          out << "[#{name}] cliffhanger_to aponta para trilha inexistente: #{dest.inspect} (FR-004)"
        elsif !active[dest]
          out << "[#{name}] cliffhanger_to aponta para trilha inativa: #{dest.inspect} (FR-004)"
        elsif !includes_norm?(last.dig(:payload, :hook).to_s, titles[dest])
          out << "[#{name}] fisgada final não nomeia a trilha-destino #{titles[dest].inspect} (FR-004)"
        end

        # FR-005 — anti-clichê (lista negra) em qualquer texto da trilha.
        banned_hits(trail).each { |hit| out << "[#{name}] frase clichê proibida: #{hit.inspect} (FR-005)" }

        out
      end

      # --- helpers ---

      def revelation_of(lesson) = lesson.dig(:payload, :revelation).to_s

      def lesson_text(lesson)
        p = lesson[:payload] || {}
        check = p[:check] || {}
        [
          lesson[:title], lesson[:enigma],
          *Array(p[:clues]), p[:revelation], p[:hook],
          check[:prompt], *Array(check[:options]), check[:explanation]
        ].compact.join(" ")
      end

      def trail_all_text(trail)
        ([ trail[:title], trail[:hook] ] + Array(trail[:lessons]).map { |l| lesson_text(l) }).compact.join(" ")
      end

      def banned_hits(trail)
        hay = normalize(trail_all_text(trail))
        BANNED_PHRASES.select { |phrase| hay.include?(phrase) }
      end

      # Word-start match (not bare substring): the anchor must begin at a word
      # boundary so a short anchor like "sol" matches "sol"/"solzinho" but not
      # "consolo" or "girassol". A trailing word part is allowed so plurals and
      # inflections still match (e.g. "cócega" → "cócegas").
      def includes_norm?(haystack, needle)
        n = normalize(needle)
        return false if n.empty?

        normalize(haystack).match?(/\b#{Regexp.escape(n)}/)
      end

      # minúsculas + remoção de acentos (NFKD) para casamento robusto.
      def normalize(str)
        str.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.strip
      end
    end
  end
end
