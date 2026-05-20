# frozen_string_literal: true

# Academy v2 Phase 2 — concept catalog + edges.
# v5: 1:1 mission↔concept. Loaded BEFORE the curriculum mission loop in
# seeds/academy.rb so concepts exist when missions are saved with concept_id.
# Idempotent. The MISSION_CONCEPTS constant remains exposed so the caller
# can look up the primary concept_slug per mission.

CONCEPTS_CATALOG = {
  "cognitivo" => [
    { slug: "dopamina",             name: "Dopamina",                   definition: "Neurotransmissor da expectativa de recompensa — não do prazer." },
    { slug: "recompensa-variavel",  name: "Recompensa variável",        definition: "Prêmio que pode vir ou não — vicia mais que prêmio certo." },
    { slug: "recompensa-imediata",  name: "Recompensa imediata",        definition: "Preferir pouco-agora a muito-depois." },
    { slug: "gratificacao-tardia",  name: "Gratificação tardia",        definition: "Esperar pra ganhar mais é músculo treinável." },
    { slug: "habito-loop",          name: "Loop do hábito",             definition: "Gatilho → rotina → recompensa, ciclo que automatiza." },
    { slug: "identidade",           name: "Identidade",                 definition: "Você é o que repete fazendo — não o que promete." },
    { slug: "atencao",              name: "Atenção",                    definition: "Recurso finito que você decide pra onde mandar." },
    { slug: "foco",                 name: "Foco",                       definition: "Manter atenção em um único objeto sem trocar." },
    { slug: "switch-cost",          name: "Custo da troca",             definition: "Cada interrupção custa minutos pra recuperar o foco." },
    { slug: "deep-work",            name: "Trabalho profundo",          definition: "Blocos longos de atenção total — rendimento multiplicado." },
    { slug: "sistema-1-vs-2",       name: "Pensar rápido vs devagar",   definition: "Sistema-1 (automático) decide quase tudo; sistema-2 (lento) raramente acorda." },
    { slug: "vies-confirmacao",     name: "Viés de confirmação",        definition: "Buscar provas só do que já se acredita." },
    { slug: "memoria-reconstrutiva", name: "Memória reconstrutiva",     definition: "Cada lembrança é reescrita — o cérebro inventa pra costurar buracos." },
    { slug: "ceticismo",            name: "Ceticismo saudável",         definition: "Duvidar antes de confiar, especialmente do próprio cérebro." },
    { slug: "neuroplasticidade",    name: "Neuroplasticidade",          definition: "Cérebro forma conexões novas DURANTE o erro." },
    { slug: "regra-dos-2-min",      name: "Regra dos 2 minutos",        definition: "Comece a versão minúscula do hábito — vontade morre em planos grandes." },
    { slug: "criatividade",         name: "Criatividade",               definition: "Tédio + tempo sem estímulo = ideias originais." }
  ],
  "saude" => [
    { slug: "sono-consolidacao",    name: "Sono consolida memória",     definition: "Dormir é quando o cérebro 'salva o arquivo' do dia." },
    { slug: "melatonina",           name: "Melatonina",                 definition: "Hormônio do sono — luz azul suprime por até 90 min." },
    { slug: "homeostase",           name: "Homeostase",                 definition: "O corpo busca equilíbrio constante; sinais externos atrapalham." },
    { slug: "glicose-pico",         name: "Pico de glicose",            definition: "Açúcar sobe rápido, cai rápido — a queda cobra com mais fome." },
    { slug: "ultraprocessados",     name: "Ultraprocessados",           definition: "Alimentos desenhados pra nunca saciar." },
    { slug: "consistencia",         name: "Consistência",               definition: "Regularidade vence intensidade em quase tudo do corpo." },
    { slug: "sinal-corporal",       name: "Sinais do corpo",            definition: "Fome, sede, cansaço — corpo fala em código fácil de confundir." }
  ],
  "social" => [
    { slug: "prova-social",         name: "Prova social",               definition: "Fazer o que outros fazem — gatilho universal de influência." },
    { slug: "escassez-percebida",   name: "Escassez percebida",         definition: "Raro parece mais valioso (mesmo quando não é)." },
    { slug: "empatia",              name: "Empatia",                    definition: "Sentir COM (presença), não sentir POR (pena ou solução)." },
    { slug: "escuta-ativa",         name: "Escuta ativa",               definition: "Ouvir pra entender, não pra responder." },
    { slug: "comunicacao",          name: "Comunicação",                definition: "Mensagem é o que o outro recebe, não o que você disse." },
    { slug: "palavra-dada",         name: "Palavra dada",               definition: "Compromisso cumprido constrói confiança invisível." },
    { slug: "confianca",            name: "Confiança",                  definition: "Saldo emocional construído por consistência repetida." },
    { slug: "pausa-estrategica",    name: "Pausa estratégica",          definition: "Silêncio curto após o outro falar — sinal de respeito e escuta." },
    { slug: "feedback-formativo",   name: "Feedback formativo",         definition: "Descreve comportamento + impacto, sem julgar pessoa." }
  ],
  "virtude" => [
    { slug: "virtude-habito",       name: "Virtude é hábito",           definition: "Caráter é o que você FAZ repetidamente — não o que sente." },
    { slug: "coragem",              name: "Coragem",                    definition: "Agir apesar do medo — não na ausência dele." },
    { slug: "honestidade",          name: "Honestidade",                definition: "Primeiro contrato consigo mesmo." },
    { slug: "gratidao",             name: "Gratidão",                   definition: "Filtro atencional treinável — você passa a notar o que estava lá." }
  ],
  "financeiro" => [
    { slug: "juros-compostos",      name: "Juros compostos",            definition: "Ganho que ganha ganho — o tempo é o ingrediente raro." },
    { slug: "tradeoff",             name: "Tradeoff",                   definition: "Tudo custa algo — escolher é renunciar." },
    { slug: "escassez",             name: "Escassez",                   definition: "Recurso limitado força escolha." },
    { slug: "pagar-se-primeiro",    name: "Pagar-se primeiro",          definition: "Guardar antes de gastar — o que sobra desaparece." }
  ],
  "tecnologia" => [
    { slug: "pensamento-computacional", name: "Pensamento computacional", definition: "Decompor + abstrair + iterar." },
    { slug: "probabilidade",        name: "Probabilidade",              definition: "Lidar com incerteza usando números." },
    { slug: "sistemas",             name: "Sistemas",                   definition: "Todo conjunto tem entrada, processo, saída — e feedback." },
    { slug: "algoritmo-recomendacao", name: "Algoritmo de recomendação", definition: "Cada toque vira voto — o feed é projetado a partir do seu comportamento." },
    { slug: "aprendizado-ativo",    name: "Aprendizado ativo",          definition: "Criar/ensinar fixa muito mais que consumir passivamente." }
  ],
  "cientifico" => [
    { slug: "decomposicao",         name: "Decomposição",               definition: "Problema gigante = soma de pequenos problemas resolvíveis." },
    { slug: "estrategia",           name: "Estratégia",                 definition: "Decidir antes de agir — escolher o caminho, não só correr." },
    { slug: "decisao-rapida",       name: "Decisão sob pressão",        definition: "Decidir bem com pouco tempo é treinável." },
    { slug: "feedback-loop",        name: "Loop de feedback",           definition: "Saída vira nova entrada — sistema se auto-ajusta." },
    { slug: "causa-e-efeito",       name: "Causa e efeito",             definition: "X provoca Y, mas Y às vezes volta pra X." },
    { slug: "pareto",               name: "Princípio de Pareto",        definition: "20% das causas geram 80% dos efeitos — escolha bem o 20%." },
    { slug: "5-porques",            name: "Cinco Porquês",              definition: "Cavar 5 níveis abaixo do sintoma pra encontrar a causa real." }
  ]
}.freeze

# Edges: [from_slug, to_slug, kind]. We seed `echoes` as the default; for
# asymmetric dependencies we use `depends_on` (from depends on to).
CONCEPT_EDGES = [
  # Atenção & dopamina cluster
  [ "dopamina", "recompensa-variavel", :echoes ],
  [ "dopamina", "recompensa-imediata", :echoes ],
  [ "recompensa-imediata", "gratificacao-tardia", :echoes ],
  [ "recompensa-variavel", "atencao", :leads_to ],
  [ "atencao", "foco", :echoes ],
  [ "atencao", "switch-cost", :echoes ],
  [ "foco", "deep-work", :leads_to ],
  [ "deep-work", "consistencia", :echoes ],

  # Hábito cluster
  [ "habito-loop", "identidade", :leads_to ],
  [ "habito-loop", "regra-dos-2-min", :echoes ],
  [ "habito-loop", "neuroplasticidade", :depends_on ],
  [ "virtude-habito", "habito-loop", :depends_on ],
  [ "virtude-habito", "identidade", :echoes ],
  [ "honestidade", "virtude-habito", :echoes ],

  # Cognitivo / cético
  [ "vies-confirmacao", "ceticismo", :echoes ],
  [ "memoria-reconstrutiva", "ceticismo", :echoes ],
  [ "sistema-1-vs-2", "ceticismo", :echoes ],
  [ "probabilidade", "ceticismo", :echoes ],

  # Sono e memória
  [ "sono-consolidacao", "memoria-reconstrutiva", :echoes ],
  [ "sono-consolidacao", "melatonina", :depends_on ],

  # Corpo
  [ "sinal-corporal", "homeostase", :echoes ],
  [ "glicose-pico", "dopamina", :echoes ],
  [ "ultraprocessados", "recompensa-imediata", :echoes ],
  [ "consistencia", "habito-loop", :echoes ],

  # Marketing / social cluster
  [ "prova-social", "escassez-percebida", :echoes ],
  [ "escassez-percebida", "escassez", :echoes ],
  [ "escassez-percebida", "recompensa-imediata", :leads_to ],

  # Relação / comunicação
  [ "empatia", "escuta-ativa", :echoes ],
  [ "escuta-ativa", "comunicacao", :echoes ],
  [ "palavra-dada", "confianca", :leads_to ],
  [ "confianca", "virtude-habito", :echoes ],

  # Finança
  [ "juros-compostos", "gratificacao-tardia", :echoes ],
  [ "tradeoff", "escassez", :echoes ],

  # Tecnologia / sistemas / problema
  [ "pensamento-computacional", "decomposicao", :echoes ],
  [ "pensamento-computacional", "sistemas", :echoes ],
  [ "decomposicao", "estrategia", :leads_to ],
  [ "feedback-loop", "sistemas", :echoes ],
  [ "causa-e-efeito", "sistemas", :echoes ],
  [ "feedback-loop", "habito-loop", :echoes ]
].freeze

# Mission slug → [primary_concept_slug, secondary…]. First slug is is_primary=true.
MISSION_CONCEPTS = {
  # Mente Forte / atencao
  "celular-difícil-parar"      => %w[dopamina recompensa-variavel atencao],
  "notificacoes-custam-23-min" => %w[switch-cost atencao foco],
  "foco-profundo-25min"        => %w[deep-work foco habito-loop],
  "habito-2-minutos"           => %w[regra-dos-2-min habito-loop identidade],
  # Mente Forte / vieses
  "vies-confirmacao"           => %w[vies-confirmacao ceticismo],
  "memoria-falsa"              => %w[memoria-reconstrutiva ceticismo],
  "pensar-devagar"             => %w[sistema-1-vs-2 ceticismo],
  # Corpo & Saúde / energia
  "acucar-engana-cerebro"      => %w[glicose-pico dopamina ultraprocessados],
  "noite-ruim-apaga-semana"    => %w[sono-consolidacao memoria-reconstrutiva],
  "10-min-movimento"           => %w[consistencia habito-loop neuroplasticidade],
  "agua-confunde-fome"         => %w[sinal-corporal homeostase],
  # Corpo & Saúde / telas
  "tela-pre-sono"              => %w[melatonina sono-consolidacao atencao],
  "scroll-infinito-mente"      => %w[recompensa-variavel dopamina atencao],
  "atencao-sem-tela"           => %w[criatividade foco atencao],
  # Dinheiro
  "impulso-perigoso"           => %w[recompensa-imediata gratificacao-tardia],
  "querer-precisar"            => %w[tradeoff escassez-percebida],
  "guardar-mais-que-gastar"    => %w[pagar-se-primeiro tradeoff habito-loop],
  "dinheiro-vira-dinheiro"     => %w[juros-compostos gratificacao-tardia consistencia],
  # Caráter
  "mentiras-pequenas-custam"   => %w[honestidade virtude-habito identidade],
  "compromisso-cumprido"       => %w[palavra-dada confianca habito-loop],
  "gratidao-muda-vista"        => %w[gratidao atencao virtude-habito],
  "coragem-nao-ausencia-medo"  => %w[coragem virtude-habito identidade],
  # Tecnologia & Criação
  "como-app-funciona"          => %w[sistemas pensamento-computacional],
  "como-ia-decide"             => %w[probabilidade ceticismo pensamento-computacional],
  "como-internet-conhece-voce" => %w[algoritmo-recomendacao feedback-loop vies-confirmacao],
  "criador-vs-consumidor"      => %w[aprendizado-ativo criatividade identidade],
  # Resolver Problemas
  "quebrar-problema"           => %w[decomposicao pensamento-computacional estrategia],
  "erro-dado"                  => %w[neuroplasticidade identidade ceticismo],
  "priorizar-pareto"           => %w[pareto estrategia tradeoff],
  "5-porques"                  => %w[5-porques causa-e-efeito ceticismo],
  # Vida & Sociedade
  "escutar-de-verdade"         => %w[escuta-ativa empatia comunicacao],
  "manipulacao-marcas"         => %w[prova-social escassez-percebida vies-confirmacao],
  "silencio-constroi-confianca" => %w[pausa-estrategica escuta-ativa confianca],
  "feedback-que-serve"         => %w[feedback-formativo comunicacao palavra-dada]
}.freeze

# Curated "concept brief" — only seeded for high-traffic concepts. Adding
# more here is the highest-leverage pedagogical edit available: every lens
# generated for a concept with a brief aligns to a single north star and
# uses the named confusion to seed micro_check distractors. Concepts not
# listed here fall back to `definition` transparently.
#
# Schema per slug:
#   the_essence:      single-sentence concept lock (≤ ~140 chars)
#   common_confusion: typical 7-12yo misread to seed micro_check distractors
#   forbidden_terms:  words the lens must never use for THIS concept
CONCEPT_BRIEFS = {
  "dopamina" => {
    the_essence: "Dopamina não é prazer — é o sinal de 'vai atrás disso'.",
    common_confusion: "Crianças acham que dopamina É o prazer; na verdade é a antecipação dele.",
    forbidden_terms: [ "dopamina é o prazer", "molécula do prazer", "hormônio do prazer" ]
  },
  "recompensa-variavel" => {
    the_essence: "Prêmio incerto vicia mais que prêmio garantido — o cérebro paga atenção pela CHANCE.",
    common_confusion: "Achar que vicia porque o prêmio é grande; vicia porque é INCERTO.",
    forbidden_terms: [ "sorte", "azar puro" ]
  },
  "habito-loop" => {
    the_essence: "Hábito não nasce de força de vontade — nasce do ciclo gatilho → rotina → recompensa, repetido.",
    common_confusion: "Pensar que basta 'querer muito' pra criar hábito; o que cria é repetir o ciclo.",
    forbidden_terms: [ "força de vontade resolve", "basta querer" ]
  },
  "atencao" => {
    the_essence: "Atenção é recurso finito — onde você manda, você vira.",
    common_confusion: "Confundir atenção com tempo; ficar 1h olhando algo distraído não é prestar atenção.",
    forbidden_terms: [ "multitarefa funciona" ]
  },
  "vies-confirmacao" => {
    the_essence: "O cérebro caça provas do que já acredita — e finge não ver as que contrariam.",
    common_confusion: "Confundir com preconceito; viés de confirmação age mesmo em ideias neutras.",
    forbidden_terms: [ "preconceito", "racismo", "burrice" ]
  },
  "gratificacao-tardia" => {
    the_essence: "Esperar pra ganhar mais é músculo — treina ou atrofia.",
    common_confusion: "Pensar que é dom inato; é hábito que cresce com cada espera bem-sucedida.",
    forbidden_terms: [ "nasceu paciente", "personalidade calma" ]
  },
  "juros-compostos" => {
    the_essence: "Ganho que ganha ganho — o tempo é o ingrediente raro, não o valor inicial.",
    common_confusion: "Achar que precisa de muito dinheiro pra começar; o multiplicador é o TEMPO.",
    forbidden_terms: [ "só pra rico", "precisa muito dinheiro" ]
  },
  "sono-consolidacao" => {
    the_essence: "Dormir é quando o cérebro salva o arquivo do dia — sem sono, o aprendizado se perde.",
    common_confusion: "Pensar que estudar até tarde rende mais; dormir é parte do estudo.",
    forbidden_terms: [ "preguiça dormir", "dormir é perder tempo" ]
  },
  "prova-social" => {
    the_essence: "Fazer o que outros fazem — gatilho universal que decide quase tudo sem você notar.",
    common_confusion: "Achar que não cai nessa; cai exatamente quando acha que não cai.",
    forbidden_terms: [ "pessoas espertas não caem" ]
  },
  "honestidade" => {
    the_essence: "Honestidade é primeiro contrato consigo mesmo — antes de qualquer pacto com outros.",
    common_confusion: "Achar que mentira pequena 'não conta'; o custo é a confiabilidade do próprio juízo.",
    forbidden_terms: [ "mentirinha branca não faz mal" ]
  },
  "neuroplasticidade" => {
    the_essence: "Cérebro forma conexões novas DURANTE o erro — errar é a oficina do aprendizado.",
    common_confusion: "Achar que errar é fracasso; é o único momento em que o cérebro reconecta.",
    forbidden_terms: [ "errar é fracasso" ]
  }
}.freeze

ActiveRecord::Base.transaction do
  position = 0

  CONCEPTS_CATALOG.each do |category, concepts|
    concepts.each do |attrs|
      position += 1
      record = ::Academy::Concept.find_or_initialize_by(slug: attrs[:slug])
      record.assign_attributes(
        name: attrs[:name],
        definition: attrs[:definition],
        category: category,
        position: position,
        active: true
      )

      if (brief = CONCEPT_BRIEFS[attrs[:slug]])
        record.assign_attributes(
          the_essence: brief[:the_essence],
          common_confusion: brief[:common_confusion],
          forbidden_terms: brief[:forbidden_terms]
        )
      end

      record.save!
    end
  end

  concepts_by_slug = ::Academy::Concept.all.index_by(&:slug)

  CONCEPT_EDGES.each do |from_slug, to_slug, kind|
    from = concepts_by_slug[from_slug]
    to   = concepts_by_slug[to_slug]
    next unless from && to

    ::Academy::ConceptEdge.find_or_create_by!(
      from_concept_id: from.id,
      to_concept_id: to.id,
      kind: ::Academy::ConceptEdge.kinds.fetch(kind.to_s)
    )
  end

  # v5: mission↔concept is 1:1. If the mission already exists (re-seed), patch
  # its concept_id to the primary concept. On the initial seed pass the
  # missions don't exist yet — the curriculum loop in academy.rb assigns
  # concept_id directly at create time via MISSION_CONCEPTS lookup.
  MISSION_CONCEPTS.each do |mission_slug, concept_slugs|
    mission = ::Academy::Mission.find_by(slug: mission_slug)
    next unless mission

    primary_slug = concept_slugs.first
    primary = concepts_by_slug[primary_slug]
    next unless primary
    next if mission.concept_id == primary.id

    mission.update_columns(concept_id: primary.id)
  end
end

puts "✓ Academy concepts seeded: " \
     "#{::Academy::Concept.active.count} conceitos · " \
     "#{::Academy::ConceptEdge.count} arestas (v5: mission↔concept 1:1, sem aula_concepts)."
