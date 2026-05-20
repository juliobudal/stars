# frozen_string_literal: true

# Academy v3 — currículo de curiosidade-do-mundo.
# Adds 3 new Subjects + ~30 new Concepts focused on factual curiosity
# (mundo natural, palavras/origens, corpo, matemática-espetáculo) so the
# pílulas Academy delivers feel like "discovery" instead of pure
# meta-skill/self-analysis content.
#
# Idempotent. Loaded from db/seeds/academy.rb AFTER academy_concepts.rb +
# pokedex_keys.rb (so the existing 53 concepts are intact and we can patch
# pokedex_color_key for the new ones in the same pass).
#
# Concepts here are seeded with active=true; lens payloads (closure +
# scientific + narrative) for these come from plans B/C of
# .planning/designs/academy-pills-improvements/. Until any payload exists
# the concepts still render in the parent dashboard catalog (0/N missions).

CURIOSIDADE_SUBJECTS = [
  {
    slug: "como-o-mundo-funciona",
    name: "Como o Mundo Funciona",
    tagline: "Mecanismos invisíveis do dia a dia",
    angle: "Investigador (mecanismo > rótulo). Cada pílula revela COMO algo do mundo físico funciona — o tipo de fato que faz a criança gritar 'sério?!' e contar pra alguém em menos de 1 hora.",
    color: "var(--c-academy-mundo)",
    icon: "atom",
    position: 8
  },
  {
    slug: "curiosidades-do-corpo",
    name: "Curiosidades do Corpo",
    tagline: "O que o teu corpo faz sem te contar",
    angle: "Naturalista (corpo como sistema vivo). O corpo é a primeira máquina que a criança opera — entender o que ele faz por baixo do pano é poder.",
    color: "var(--c-academy-corpo)",
    icon: "heart-pulse",
    position: 9
  },
  {
    slug: "palavras-origens",
    name: "Palavras & Origens",
    tagline: "De onde vêm as ideias e os nomes",
    angle: "Etimologista (a palavra esconde história). Toda palavra é um fóssil de uma ideia antiga — saber a origem destrava conexões entre línguas, culturas e tempo.",
    color: "var(--c-academy-palavras)",
    icon: "book-open",
    position: 10
  }
].freeze

# 30 new concepts (10 per subject). Each has: slug, name, definition,
# category (uses extended Concept::CATEGORIES), pokedex_color_key.
# Definitions are 1-2 lines, child-readable, no moralization.
CURIOSIDADE_CONCEPTS = {
  "como-o-mundo-funciona" => [
    {
      slug: "por-que-o-ceu-e-azul",
      name: "Por que o céu é azul",
      category: "mundo_natural",
      definition: "Luz do sol bate nas moléculas do ar e o azul se espalha mais que as outras cores — por isso o céu pinta de azul, mesmo a luz sendo branca."
    },
    {
      slug: "gelo-flutua-na-agua",
      name: "Por que o gelo flutua",
      category: "mundo_natural",
      definition: "A água é o raríssimo líquido que fica MENOS denso quando vira sólido — por isso o gelo boia em vez de afundar."
    },
    {
      slug: "como-funciona-o-arco-iris",
      name: "Como nasce um arco-íris",
      category: "mundo_natural",
      definition: "Cada gota de chuva é um prisminha: separa a luz branca em cores e devolve pra você no ângulo certo — sempre 42°."
    },
    {
      slug: "como-um-aviao-voa",
      name: "Como um avião voa",
      category: "mundo_natural",
      definition: "A asa empurra o ar pra baixo, e o ar empurra a asa pra cima — voar é uma briga organizada com o ar."
    },
    {
      slug: "por-que-mar-e-salgado",
      name: "Por que o mar é salgado",
      category: "mundo_natural",
      definition: "Chuva rala a pedra dos continentes há bilhões de anos e leva sal pro mar — o oceano é a tigela onde tudo isso se junta."
    },
    {
      slug: "trovao-vem-depois-do-raio",
      name: "Por que trovão vem depois do raio",
      category: "mundo_natural",
      definition: "A luz é quase um milhão de vezes mais rápida que o som — você vê o raio agora e ouve o trovão segundos depois."
    },
    {
      slug: "paradoxo-do-aniversario",
      name: "Paradoxo do aniversário",
      category: "matematica",
      definition: "Numa sala com 23 pessoas, é mais provável que duas façam aniversário no mesmo dia do que NÃO façam. A matemática contradiz a intuição."
    },
    {
      slug: "pizza-grande-e-mais-barata",
      name: "A matemática da pizza",
      category: "matematica",
      definition: "A área de uma pizza cresce com o QUADRADO do raio — pizza dobro do tamanho rende quatro vezes mais. Por isso a grande vale mais a pena."
    },
    {
      slug: "como-funciona-uma-pilha",
      name: "Como uma pilha funciona",
      category: "mundo_natural",
      definition: "Dentro da pilha, uma reação química empurra elétrons pra fora por um lado e puxa pelo outro — eletricidade é gente passando em fila."
    },
    {
      slug: "agua-quebra-pedra",
      name: "Por que cubo de gelo racha pedra",
      category: "mundo_natural",
      definition: "Água que congela expande — entra na fresta da pedra, congela à noite, e empurra a fresta cada vez mais. Em décadas, racha montanha."
    }
  ],
  "curiosidades-do-corpo" => [
    {
      slug: "por-que-engasgo-bocejando",
      name: "Por que se engasga bocejando",
      category: "saude",
      definition: "O tubo pra respirar e o tubo pra engolir cruzam na garganta — bocejar abre tudo ao mesmo tempo e a saliva pega o caminho errado."
    },
    {
      slug: "como-cicatrizacao-funciona",
      name: "Como a pele se conserta",
      category: "saude",
      definition: "Quando você corta a pele, células chamadas plaquetas tampam o buraco, depois colágeno costura — cicatriz é a costura ficando à mostra."
    },
    {
      slug: "por-que-temos-impressao-digital",
      name: "Por que a digital é única",
      category: "saude",
      definition: "Os dedos enrugam ainda dentro da barriga da mãe, e cada criança aperta em ângulo diferente — por isso nenhuma digital se repete no mundo."
    },
    {
      slug: "como-cerebro-ve-cor",
      name: "Como o cérebro vê cores",
      category: "saude",
      definition: "O olho só capta três cores (vermelho, verde, azul). O cérebro mistura essas três e INVENTA todas as outras — cor é uma decisão do cérebro."
    },
    {
      slug: "por-que-doi-bater-cotovelo",
      name: "Por que dói tanto bater o cotovelo",
      category: "saude",
      definition: "Tem um nervo passando bem rente ao osso do cotovelo, quase sem proteção — bater nele é avisar o cérebro com choque elétrico de verdade."
    },
    {
      slug: "como-osso-quebrado-se-cola",
      name: "Como osso quebrado se cola sozinho",
      category: "saude",
      definition: "Células-construtoras chamadas osteoblastos fabricam osso novo sobre a fratura — em 6 semanas o pedaço quebrado fica mais forte que o ao redor."
    },
    {
      slug: "por-que-temos-sonhos",
      name: "Para que servem os sonhos",
      category: "saude",
      definition: "Dormindo, o cérebro ensaia o que viveu de dia e arquiva o que importa — sonho é o que sobra do ensaio passando na sua frente."
    },
    {
      slug: "como-tomate-vira-coco",
      name: "Como o tomate vira cocô",
      category: "saude",
      definition: "O intestino aperta a comida em ondas (chama peristalse) enquanto enzimas quebram tudo em pedacinhos minúsculos — o que o corpo não usa, sai."
    },
    {
      slug: "por-que-bocejo-e-contagioso",
      name: "Por que bocejo pega",
      category: "saude",
      definition: "Quando você vê alguém bocejar, neurônios-espelho no seu cérebro 'copiam' o gesto antes do pensamento — empatia em forma de músculo."
    },
    {
      slug: "como-pele-fica-bronzeada",
      name: "Por que pele bronzeia no sol",
      category: "saude",
      definition: "A pele produz melanina (escurinho) pra absorver os raios do sol antes que machuquem dentro — bronzeado é uniforme de defesa do corpo."
    }
  ],
  "palavras-origens" => [
    {
      slug: "de-onde-vem-salario",
      name: "Salário vem de sal",
      category: "linguagem",
      definition: "Soldados romanos eram pagos em sal — produto raríssimo na época. 'Salário' é literalmente 'a quantidade de sal' do mês."
    },
    {
      slug: "por-que-domingo-e-domingo",
      name: "Por que domingo se chama domingo",
      category: "linguagem",
      definition: "Em latim era Dies Dominica — 'dia do Senhor'. O resto da semana virou número (segunda, terça…), mas domingo guardou o nome antigo."
    },
    {
      slug: "de-onde-veio-o-zero",
      name: "Quem inventou o zero",
      category: "historia",
      definition: "O zero nasceu na Índia, viajou pra Bagdá com mercadores árabes, e só chegou na Europa quase 800 anos depois — antes disso, simplesmente não havia 'nada'."
    },
    {
      slug: "quem-inventou-o-emoji",
      name: "Quem inventou os emojis",
      category: "linguagem",
      definition: "Shigetaka Kurita, engenheiro japonês, desenhou 176 figurinhas em 1999 pra mensagens de celular caberem em uma tela minúscula."
    },
    {
      slug: "por-que-livros-tem-paginas",
      name: "Por que livro tem páginas",
      category: "historia",
      definition: "Antes os textos eram rolos — pra achar algo, desenrolava metro a metro. Alguém empilhou folhas, costurou de um lado e inventou a invenção mais útil de 2 mil anos: a página."
    },
    {
      slug: "de-onde-vem-vacina",
      name: "Vacina vem de vaca",
      category: "linguagem",
      definition: "Edward Jenner percebeu que ordenhadoras pegavam uma doença leve de vaca (vaccinia) e ficavam imunes à varíola humana. 'Vacina' = 'da vaca'."
    },
    {
      slug: "como-romanos-contavam",
      name: "Como romanos contavam (sem zero)",
      category: "historia",
      definition: "Romanos somavam letras: I=1, V=5, X=10, L=50, C=100. Sem zero, multiplicar 358 × 47 era praticamente impossível — por isso a matemática parou."
    },
    {
      slug: "alfabeto-veio-de-onde",
      name: "De onde veio o alfabeto",
      category: "historia",
      definition: "Os fenícios, povo de mercadores, viraram desenhos egípcios em sons (alef = boi). Gregos pegaram e adaptaram. Quase todo alfabeto do mundo vem desses 22 símbolos."
    },
    {
      slug: "numeros-arabes-nao-sao-arabes",
      name: "Números arábicos não são árabes",
      category: "historia",
      definition: "Os algarismos 0-9 nasceram na Índia (séc. VI). Os árabes só foram os carteiros que levaram pra Europa — mas o nome 'arábico' grudou."
    },
    {
      slug: "quem-inventou-a-escrita",
      name: "Quem inventou a escrita",
      category: "historia",
      definition: "Os sumérios, na Mesopotâmia (3200 a.C.), riscavam contagem de cabras em tabuletas de barro — daí evoluiu cuneiforme, e daí toda escrita do planeta."
    }
  ]
}.freeze

# Pokédex color_key per slug — uses the new tokens added in theme.css.
# Matches concept.category for the new ones (1:1) but kept explicit so a
# future palette decoupling is easy.
CURIOSIDADE_POKEDEX_KEYS = CURIOSIDADE_CONCEPTS.values.flatten.to_h do |c|
  [ c[:slug], c[:category] ]
end.freeze

# Subject-spanning edges for the obvious "ponte" cases. Keep small — these
# are creative reading prompts for the Atlas, not exhaustive ontology.
CURIOSIDADE_EDGES = [
  [ "pizza-grande-e-mais-barata", "tradeoff",          :echoes ],
  [ "paradoxo-do-aniversario",    "ceticismo",         :echoes ],
  [ "como-cerebro-ve-cor",        "memoria-reconstrutiva", :echoes ],
  [ "por-que-bocejo-e-contagioso", "empatia",          :echoes ],
  [ "agua-quebra-pedra",          "consistencia",      :echoes ],
  [ "quem-inventou-a-escrita",    "aprendizado-ativo", :echoes ],
  [ "numeros-arabes-nao-sao-arabes", "vies-confirmacao", :echoes ],
  [ "de-onde-veio-o-zero",        "decomposicao",      :echoes ]
].freeze

ActiveRecord::Base.transaction do
  # 1. Subjects
  CURIOSIDADE_SUBJECTS.each do |attrs|
    subject = ::Academy::Subject.find_or_initialize_by(slug: attrs[:slug])
    subject.assign_attributes(attrs.merge(active: true))
    subject.save!
  end

  # 2. Concepts. We append to the position sequence (continuing from the
  #    last existing position), so the Atlas order stays deterministic.
  base_position = ::Academy::Concept.maximum(:position).to_i
  offset = 0

  CURIOSIDADE_CONCEPTS.each_value do |group|
    group.each do |attrs|
      offset += 1
      record = ::Academy::Concept.find_or_initialize_by(slug: attrs[:slug])
      record.assign_attributes(
        name: attrs[:name],
        definition: attrs[:definition],
        category: attrs[:category],
        position: base_position + offset,
        active: true,
        pokedex_color_key: CURIOSIDADE_POKEDEX_KEYS[attrs[:slug]],
        pokedex_silhouette_key: nil
      )
      record.save!
    end
  end

  # 3. Cross-subject edges (only when both endpoints exist).
  concepts_by_slug = ::Academy::Concept.where(
    slug: CURIOSIDADE_EDGES.flatten.uniq
  ).index_by(&:slug)

  CURIOSIDADE_EDGES.each do |from_slug, to_slug, kind|
    from = concepts_by_slug[from_slug]
    to   = concepts_by_slug[to_slug]
    next unless from && to

    ::Academy::ConceptEdge.find_or_create_by!(
      from_concept_id: from.id,
      to_concept_id: to.id,
      kind: ::Academy::ConceptEdge.kinds.fetch(kind.to_s)
    )
  end
end

puts "✓ Academy curiosidade seeded: " \
     "#{::Academy::Subject.where(slug: CURIOSIDADE_SUBJECTS.map { |s| s[:slug] }).count} novas áreas · " \
     "#{::Academy::Concept.where(slug: CURIOSIDADE_CONCEPTS.values.flatten.map { |c| c[:slug] }).count} conceitos novos."
