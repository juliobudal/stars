# frozen_string_literal: true

# Academy v4 — calibration of all discovery missions to the v4 quality bar.
#
# Two operations, idempotent, both keyed by mission slug:
#
#   1. UPGRADES — find each existing v2 mission by slug and rewrite the
#      `challenge_prompt`, `challenge_observable`, and (when applicable) the
#      `hook`/`curiosity_facts`. The shape of the challenge is the numeric
#      wager mandated by Beat 6 of Persona v4:
#        "Aposto que você [X] [N] vezes [contexto]. Conta amanhã."
#
#   2. NEW MISSIONS — add ~9 new discovery missions to round out the 5 thin
#      areas (Dinheiro, Caráter, Tech, Resolver, Sociedade), in v4 voice.
#
# Quality filter (from .planning/designs/academy-v3.1-adventure.md):
#   - "um menino de 9 anos contaria isso pro amigo na escola?"
#   - 70% descoberta divertida · 30% reflexão leve
#   - tom Bill Nye + Mythbusters + Kurzgesagt
#   - Beat 6 SEMPRE numeric aposta em discovery
#   - sem moralização, sem tom TED-talk infantil

# ── 1. UPGRADES ──────────────────────────────────────────────────────────
upgrades = {
  # ── MENTE FORTE ────────────────────────────────────────────────────────
  "celular-difícil-parar" => {
    challenge_prompt: "Aposto que você pega o celular sem motivo 12 vezes hoje. Conta amanhã. Quem chega mais perto da real ganha.",
    challenge_observable: "Quantas vezes pegou o celular sem motivo claro."
  },
  "notificacoes-custam-23-min" => {
    challenge_prompt: "Aposto que você muda de aba/app 28 vezes hoje quando ia focar. Conta amanhã.",
    challenge_observable: "Quantas vezes trocou de aba/app sem terminar o que começou."
  },
  "foco-profundo-25min" => {
    challenge_prompt: "Aposto que você dura 18 minutos antes de quebrar o foco. Cronometre 1 sessão de estudo hoje.",
    challenge_observable: "Minutos reais de foco contínuo antes da primeira distração."
  },
  "habito-2-minutos" => {
    challenge_prompt: "Aposto que você cumpre o hábito de 2 min em 4 dias seguidos esta semana. Marque cada dia.",
    challenge_observable: "Dias seguidos que repetiu a versão de 2 min sem falhar."
  },
  "vies-confirmacao" => {
    challenge_prompt: "Aposto que você acha 5 confirmações da sua opinião antes de achar 1 contra hoje. Conte.",
    challenge_observable: "Quantas vezes notou alguém repetindo algo que você já achava."
  },
  "memoria-falsa" => {
    challenge_prompt: "Aposto que sua lembrança da última briga difere da do outro em 3 detalhes. Confira hoje, sem brigar de novo.",
    challenge_observable: "Quantos detalhes não bateram entre as duas versões."
  },
  "pensar-devagar" => {
    challenge_prompt: "Aposto que você responde Sistema 1 em 4 de 5 perguntas surpresa hoje. Anote as 5.",
    challenge_observable: "Quantas das 5 respostas você deu sem pensar 3 segundos antes."
  },

  # ── CORPO & SAÚDE ──────────────────────────────────────────────────────
  "acucar-engana-cerebro" => {
    challenge_prompt: "Aposto que você sente cansaço falso 2 vezes hoje, ~30 min depois de doce. Marque.",
    challenge_observable: "Quantas vezes bateu sono/desânimo logo depois de algo doce."
  },
  "noite-ruim-apaga-semana" => {
    challenge_prompt: "Aposto que você lembra de 3 momentos do dia mal dormido vs. 7 do dia bem dormido. Compare amanhã.",
    challenge_observable: "Quantos momentos consegue listar de cada dia."
  },
  "agua-confunde-fome" => {
    challenge_prompt: "Aposto que 6 de 10 'fomes' fora de hora somem com 1 copo d'água. Teste hoje.",
    challenge_observable: "Quantas 'fomes' viraram nada depois da água."
  },
  "tela-pre-sono" => {
    challenge_prompt: "Aposto que você dorme 18 min mais rápido se largar a tela 1h antes. Cronometre 3 noites.",
    challenge_observable: "Minutos entre 'deitei' e 'apaguei' com e sem tela."
  },
  "scroll-infinito-mente" => {
    challenge_prompt: "Aposto que você passa 22 minutos no scroll sem perceber. Cronometre 1 sessão hoje, sem cortar.",
    challenge_observable: "Minutos reais cronometrados na sessão de scroll."
  },
  "atencao-sem-tela" => {
    challenge_prompt: "Aposto que você fica entediado em 7 minutos sem tela. Cronometre hoje. Aguente o tédio.",
    challenge_observable: "Minutos até bater vontade forte de pegar a tela."
  },

  # ── DINHEIRO & VIDA ────────────────────────────────────────────────────
  "impulso-perigoso" => {
    challenge_prompt: "Aposto que 7 em 10 vontades de comprar passam em 24h. Liste 3 vontades hoje, decida amanhã.",
    challenge_observable: "Quantas vontades sobreviveram um dia."
  },
  "querer-precisar" => {
    challenge_prompt: "Aposto que 4 das suas próximas 5 'precisos' são 'queros'. Liste 5 hoje, marque cada um.",
    challenge_observable: "Quantos eram 'querer' disfarçado de 'precisar'."
  },
  "guardar-mais-que-gastar" => {
    challenge_prompt: "Aposto que você guarda R$10 esta semana se cortar 1 coisa pequena. Diga qual hoje.",
    challenge_observable: "Real guardado vs. apostado, ao fim da semana."
  },
  "dinheiro-vira-dinheiro" => {
    challenge_prompt: "Aposto que R$10/mês a 10% vira R$1.000 em ~24 anos. Confira na calculadora hoje, se duvidar.",
    challenge_observable: "O quão perto sua intuição estava antes de calcular."
  },

  # ── CARÁTER & VIRTUDES ─────────────────────────────────────────────────
  "mentiras-pequenas-custam" => {
    challenge_prompt: "Aposto que você esconde 2 verdades pequenas hoje. Conte para você mesmo, depois conte 1 inteira.",
    challenge_observable: "Quantas vezes engoliu uma verdade pequena e o que mudou ao soltar uma."
  },
  "compromisso-cumprido" => {
    challenge_prompt: "Aposto que você esquece 1 das 3 promessas que faz hoje. Anote as 3 de manhã, confira à noite.",
    challenge_observable: "Quantas das 3 cumpriu sem precisar lembrar."
  },
  "gratidao-muda-vista" => {
    challenge_prompt: "Aposto que sua manhã muda se você listar 3 coisas a agradecer antes do café. Teste 3 dias.",
    challenge_observable: "Como você descreveria seu humor da manhã nesses 3 dias."
  },
  "coragem-nao-ausencia-medo" => {
    challenge_prompt: "Aposto que você adia 2 conversas difíceis esta semana. Anote, e tenha 1 delas.",
    challenge_observable: "Quantas você adiou e o que aconteceu na que você teve."
  },

  # ── TECNOLOGIA & CRIAÇÃO ───────────────────────────────────────────────
  "como-app-funciona" => {
    challenge_prompt: "Aposto que você descobre 5 truques de fisgar no app que mais usa. Caça hoje.",
    challenge_observable: "Quantos truques você reconheceu (notif vermelha, scroll infinito, swipe pull, badge, …)."
  },
  "como-ia-decide" => {
    challenge_prompt: "Aposto que 8 de 10 sugestões no seu feed hoje são feitas pra você ficar mais tempo. Conte.",
    challenge_observable: "Quantas sugestões pareciam 'só pra te prender' vs. 'realmente úteis'."
  },
  "como-internet-conhece-voce" => {
    challenge_prompt: "Aposto que aparece 3 anúncios sobre algo que você só FALOU em voz alta hoje. Repare.",
    challenge_observable: "Quantos anúncios bateram com conversas faladas (sem busca)."
  },
  "criador-vs-consumidor" => {
    challenge_prompt: "Aposto que você consome 90 min e cria 0 hoje. Cronometre — depois inverta 10 min.",
    challenge_observable: "Minutos consumindo vs. minutos criando algo."
  },

  # ── RESOLVER PROBLEMAS ─────────────────────────────────────────────────
  "quebrar-problema" => {
    challenge_prompt: "Aposto que qualquer 'problemão' seu vira 4 problemas pequenos resolvíveis. Pegue 1 hoje, quebre.",
    challenge_observable: "Em quantos pedaços o problemão se quebrou quando você listou."
  },
  "erro-dado" => {
    challenge_prompt: "Aposto que 3 dos seus últimos 'fracassos' ensinaram algo que ninguém te ensinou na escola. Liste 3 hoje.",
    challenge_observable: "Quantos viraram dado útil quando você nomeou a lição."
  },
  "priorizar-pareto" => {
    challenge_prompt: "Aposto que 2 das suas 10 próximas tarefas trazem 80% do resultado. Marque hoje.",
    challenge_observable: "Quais 2 mereciam o tempo, quais 8 podiam esperar."
  },

  # ── VIDA & SOCIEDADE ───────────────────────────────────────────────────
  "escutar-de-verdade" => {
    challenge_prompt: "Aposto que você interrompe 4 vezes em 1 conversa de 5 min. Conte hoje, sem se justificar.",
    challenge_observable: "Quantas interrupções e quantas vezes a pessoa terminou a frase."
  },
  "manipulacao-marcas" => {
    challenge_prompt: "Aposto que você vê 7 propagandas escondidas como 'conteúdo' hoje. Procure hashtags pequenas e #publi.",
    challenge_observable: "Quantos 'conteúdos' eram anúncio mal-disfarçado."
  },
  "silencio-constroi-confianca" => {
    challenge_prompt: "Aposto que ficar 3 segundos calado antes de responder muda 2 conversas hoje. Teste e conte.",
    challenge_observable: "Em quantas conversas o silêncio fez a outra pessoa falar mais ou diferente."
  },
  "feedback-que-serve" => {
    challenge_prompt: "Aposto que 4 de 5 feedbacks que você recebe hoje vêm sem 'situação + comportamento + impacto'. Conte.",
    challenge_observable: "Quantos feedbacks tinham os 3 elementos vs. eram só elogio/crítica genérica."
  },

  # ── 2 missões originais que faltaram passar pela calibração v4 ──────────
  "10-min-movimento" => {
    challenge_prompt: "Aposto que você acha 10 min pra se mexer 3 dias seguidos esta semana. Marque cada dia.",
    challenge_observable: "Dias consecutivos com pelo menos 10 min de movimento real."
  },
  "5-porques" => {
    challenge_prompt: "Aposto que 4 dos seus últimos 5 'problemas chatos' têm a mesma raiz quando você pergunta 5 vezes 'por quê'. Faça hoje em 1 deles.",
    challenge_observable: "Quantos 'porquês' apareceram antes de chegar na causa real."
  }
}

upgrade_count = 0
upgrades.each do |slug, attrs|
  mission = ::Academy::Mission.find_by(slug: slug)
  next unless mission

  mission.update!(attrs)
  upgrade_count += 1
end
puts "✓ Academy v4 discovery upgrades: #{upgrade_count}/#{upgrades.size} missions calibrated to numeric wager"

# ── 2. NEW MISSIONS ──────────────────────────────────────────────────────
# Format mirrors academy.rb. Subject + trail are referenced by slug.
new_missions = [
  # ── CARÁTER (+2) ───────────────────────────────────────────────────────
  {
    slug: "desculpa-que-conserta",
    subject: "carater", trail: "palavra-dada",
    title: "Por que a desculpa de 'mas eu...' não funciona?",
    hook: "Pedir desculpa direito conserta. Pedir mal piora — e quase ninguém pede direito.",
    angle: "Anatomia da desculpa: explicar o erro + reconhecer impacto + dizer o que fará diferente. Sem 'mas...'.",
    central_insight: "Se sua desculpa começa com 'mas', você não está pedindo desculpa — está se defendendo.",
    curiosity_facts: [
      "Estudo Harvard: 'desculpa com mas' baixa confiança mais do que 'sem desculpa nenhuma'.",
      "O cérebro do outro registra a parte ANTES do 'mas' e ignora o resto.",
      "Pesquisadores de relações chamam isso de 'fauxpology' — desculpa-fingida."
    ],
    challenge_prompt: "Aposto que você pede desculpa mal 2x esta semana (tipo 'foi mal, mas...'). Conte, e repita 1 direito.",
    challenge_when: "esta-semana",
    challenge_observable: "Quantas 'fauxpologies' você soltou e qual reação rolou ao soltar uma de verdade.",
    learning_objective: "Distinguir desculpa real de defesa disfarçada e pedir 1 desculpa direito.",
    illustration_key: "users",
    source: "Aaron Lazare, On Apology",
    framework: "anatomia + caso",
    concept_slug: "palavra-dada"
  },
  {
    slug: "calar-quando-falar-fofoca",
    subject: "carater", trail: "palavra-dada",
    title: "Falar mal de quem não tá presente vicia. Por quê?",
    hook: "Fofoca dá prazer parecido com salgadinho — e custa parecido com salgadinho.",
    angle: "Cérebro libera dopamina ao 'estar do lado certo'. Custo: confiança aos poucos some sem ninguém perceber.",
    central_insight: "Se a frase só faria sentido com a pessoa presente, é fofoca. Se faria sentido melhor sem ela, é tóxico.",
    curiosity_facts: [
      "Robin Dunbar: ~65% das conversas humanas são sobre pessoas ausentes. Não somos imunes.",
      "Quem fofoca com você sobre os outros vai fofocar com os outros sobre você — em 8 de 10 casos.",
      "O cérebro registra 'fofoqueiro' como 'pouco confiável' inconscientemente — mesmo ouvindo."
    ],
    challenge_prompt: "Aposto que você ouve fofoca 5 vezes hoje na escola. Conte. Em 1 delas, mude de assunto.",
    challenge_when: "hoje",
    challenge_observable: "Quantas vezes ouviu, e o que aconteceu na vez que mudou de assunto.",
    learning_objective: "Reconhecer fofoca + cortar 1 vez sem moralizar a outra pessoa.",
    illustration_key: "users",
    source: "Robin Dunbar / antropologia evolutiva",
    framework: "fato + dado",
    concept_slug: "honestidade"
  },

  # ── DINHEIRO (+2) ──────────────────────────────────────────────────────
  {
    slug: "anchoring-no-preco",
    subject: "dinheiro-vida", trail: "impulso-vs-planejamento",
    title: "Por que 'de R$200 por R$150' parece barato?",
    hook: "O primeiro preço que você vê desfigura tudo o que vem depois.",
    angle: "Anchoring (Tversky-Kahneman). O cérebro usa o primeiro número como âncora — mesmo sabendo que é truque.",
    central_insight: "Se uma loja te mostra R$200 antes de R$150, você acha barato. Sem o R$200, você acharia caro.",
    curiosity_facts: [
      "Kahneman ganhou Nobel mostrando isso: até pessoas avisadas do truque caem nele.",
      "Lojas testam 4-5 'preços âncora' antes de escolher o que mais vende.",
      "Sites de viagem mostram o quarto mais caro primeiro DE PROPÓSITO."
    ],
    challenge_prompt: "Aposto que você vê 4 produtos com 'preço cortado' hoje em algum app. Conte e suspeite de cada um.",
    challenge_when: "hoje",
    challenge_observable: "Quantos preços âncora cabularam você e quantos você reconheceu como truque.",
    learning_objective: "Reconhecer anchoring em pelo menos 3 produtos do dia.",
    illustration_key: "coin",
    source: "Daniel Kahneman, Thinking Fast & Slow",
    framework: "experimento clássico",
    concept_slug: "escassez-percebida"
  },
  {
    slug: "custo-oportunidade-real",
    subject: "dinheiro-vida", trail: "impulso-vs-planejamento",
    title: "Cada 'sim' é mil 'nãos' invisíveis",
    hook: "Você não escolhe entre R$50 e o doce. Escolhe entre o doce e tudo que esse R$50 viraria.",
    angle: "Custo de oportunidade. Economista Bastiat: o que se vê (compra) vs. o que NÃO se vê (alternativa).",
    central_insight: "Se você gasta R$50 no doce, esses R$50 não viram livro, jogo, bike. É troca, não 'só um docinho'.",
    curiosity_facts: [
      "Economistas chamam de 'o invisível' — fica fora da consciência por padrão.",
      "Pessoas que listam 3 alternativas antes de comprar gastam ~30% menos.",
      "Buffett mantém uma lista mental de 'o que esse dinheiro viraria'. Calcula antes."
    ],
    challenge_prompt: "Aposto que você gasta R$X esta semana sem listar 5 outras coisas que esse dinheiro compraria. Liste antes da próxima compra acima de R$20.",
    challenge_when: "esta-semana",
    challenge_observable: "Quantas vezes parou antes de comprar e quantas listou alternativas.",
    learning_objective: "Visualizar o custo invisível em pelo menos 1 decisão de compra.",
    illustration_key: "coin",
    source: "Frédéric Bastiat / Charlie Munger",
    framework: "mental model",
    concept_slug: "tradeoff"
  },

  # ── TECNOLOGIA (+2) ────────────────────────────────────────────────────
  {
    slug: "algoritmo-conhece-voces-1milhao",
    subject: "tecnologia-criacao", trail: "como-tecnologia-funciona",
    title: "O algoritmo não te conhece. Conhece 1 milhão como você.",
    hook: "Você acha que TikTok te conhece. Conhece 1 milhão de você e aposta que você reage igual.",
    angle: "Sistemas de recomendação são clusters estatísticos. Não há 'eu único'; há perfil parecido com N outros.",
    central_insight: "Se 100 mil pessoas como você curtiram X, o algoritmo aposta que você curte também. Você é estatística.",
    curiosity_facts: [
      "Netflix tem ~2 mil 'micro-gêneros' baseados em padrões de quem assistiu o quê.",
      "Spotify Wrapped funciona porque seus dados encaixam em um de ~150 'perfis musicais'.",
      "Engenheiros de recomendação têm uma frase: 'predict the next click, win the war'."
    ],
    challenge_prompt: "Aposto que 9 de 10 vídeos que aparecem hoje no seu feed são feitos pra te prender. Procure o padrão.",
    challenge_when: "hoje",
    challenge_observable: "Quantos vídeos foram 'só pra te prender' vs. 'realmente úteis' / 'novos'.",
    learning_objective: "Ver o algoritmo como estatística, não como mágica nem como espionagem.",
    illustration_key: "phone",
    source: "Hannes Schulz / sistemas de recomendação",
    framework: "desmistificação",
    concept_slug: "algoritmo-recomendacao"
  },
  {
    slug: "ia-nao-e-magica",
    subject: "tecnologia-criacao", trail: "como-tecnologia-funciona",
    title: "ChatGPT não pensa. Conta palavras.",
    hook: "IA não 'sabe'. IA aposta a próxima palavra mais provável — e fala com confiança total mesmo errando.",
    angle: "LLMs são preditores estatísticos. Não há entendimento; há frequência. Por isso 'alucinam'.",
    central_insight: "Se você pergunta algo simples, IA acerta. Se você pergunta algo subjetivo, IA inventa com confiança.",
    curiosity_facts: [
      "ChatGPT erra ~15-25% de fatos simples e fala como se tivesse 100% de certeza.",
      "Pesquisadores chamam de 'hallucination': IA inventa fontes que não existem.",
      "Ela é um 'preditor de próxima palavra' treinado em ~10 trilhões de palavras humanas."
    ],
    challenge_prompt: "Aposto que você faz 3 perguntas hoje à IA e em 1 resposta tem erro factual escondido. Pesquise depois.",
    challenge_when: "hoje",
    challenge_observable: "Quantas respostas erraram quando você cruzou com 1 fonte externa.",
    learning_objective: "Tratar IA como ferramenta com erro, não como oráculo.",
    illustration_key: "lightbulb",
    source: "Emily Bender / 'stochastic parrots'",
    framework: "desmistificação",
    concept_slug: "probabilidade"
  },

  # ── RESOLVER (+2) ──────────────────────────────────────────────────────
  {
    slug: "cinco-porques-resolve",
    subject: "resolver-problemas", trail: "quando-trava",
    title: "Pergunte 'por quê?' 5 vezes seguidas. Aí você acha o problema real.",
    hook: "Toyota descobriu: se você pergunta 'por quê?' uma vez, conserta o sintoma. Se pergunta 5 vezes, conserta a causa.",
    angle: "Os 5 Porquês (Sakichi Toyoda). Cada 'porque' descasca uma camada do problema até a raiz.",
    central_insight: "Se você para no 1º 'por quê', resolve o sintoma. Se vai até o 5º, resolve o problema.",
    curiosity_facts: [
      "Toyota usa essa técnica em CHÃO DE FÁBRICA — economiza milhões/ano por erro encontrado.",
      "Pesquisas em UX: 80% dos problemas relatados pelo usuário não são o problema real.",
      "Funciona até pra brigas com irmão. Sério."
    ],
    challenge_prompt: "Aposto que 3 das suas 5 últimas 'discussões com a mãe' têm a mesma causa real. Pergunte 5 'por quê' na próxima briga.",
    challenge_when: "esta-semana",
    challenge_observable: "Em quantas brigas a 5ª pergunta mudou o que você ia dizer.",
    learning_objective: "Aplicar os 5 porquês a 1 conflito real esta semana.",
    illustration_key: "puzzle",
    source: "Sakichi Toyoda / Toyota Production System",
    framework: "ferramenta + caso",
    concept_slug: "5-porques"
  },
  {
    slug: "pensar-em-voz-alta",
    subject: "resolver-problemas", trail: "quando-trava",
    title: "Por que explicar o problema pra um pato resolve metade dos bugs?",
    hook: "Programadores falam com um pato de borracha. Sério. E em 50% dos casos, o pato resolve o problema sozinho.",
    angle: "Rubber duck debugging. Ato de explicar oraliza o que estava implícito — aí o erro aparece.",
    central_insight: "Pensar em voz alta encontra erro que pensar em silêncio esconde.",
    curiosity_facts: [
      "Origem: livro 'The Pragmatic Programmer' (1999). Hoje cada dev tem 1 pato.",
      "Funciona porque o cérebro força 'sequência' quando vc fala — silêncio permite atalhos.",
      "Pesquisa em educação: alunos que 'falam o problema antes de tentar' acertam ~30% mais."
    ],
    challenge_prompt: "Aposto que você acha 2 erros nas suas tarefas hoje só explicando em voz alta. Tente em 1 prova/dever.",
    challenge_when: "hoje",
    challenge_observable: "Quantos erros apareceram só falando, antes mesmo de procurar.",
    learning_objective: "Aplicar 'rubber duck' em pelo menos 1 problema travado.",
    illustration_key: "lightbulb",
    source: "Andy Hunt / The Pragmatic Programmer",
    framework: "técnica + experimento",
    concept_slug: "decomposicao"
  },

  # ── SOCIEDADE (+1) ─────────────────────────────────────────────────────
  {
    slug: "primeira-impressao-erra",
    subject: "vida-sociedade", trail: "ler-pessoas",
    title: "Você decide quem é a pessoa em 7 segundos. E erra 60% do tempo.",
    hook: "Seu cérebro fecha um veredito sobre alguém em 7 segundos — antes mesmo de você ouvir o nome.",
    angle: "Thin-slicing (Malcolm Gladwell + Nalini Ambady). Cérebro é rápido — também é tendencioso.",
    central_insight: "Se você confia nos 7 primeiros segundos, perde gente boa. Espere 3 conversas antes de decidir.",
    curiosity_facts: [
      "Estudo de Ambady: alunos avaliavam professores corretamente em 6 segundos de vídeo MUDO. Mas erravam 40% das pessoas em geral.",
      "Cérebro usa 'similaridade comigo' como atalho. Quem parece com você ganha pontos grátis.",
      "Pessoas que esperam '3 conversas antes de julgar' têm amizades mais duradouras (estudo Dunbar)."
    ],
    challenge_prompt: "Aposto que sua impressão sobre 2 colegas muda totalmente se você conversar 5 min com cada. Teste hoje.",
    challenge_when: "hoje",
    challenge_observable: "Em quantos casos sua 1ª impressão mudou e em quais ficou igual.",
    learning_objective: "Suspender julgamento de 1 colega que você tinha 'arquivado'.",
    illustration_key: "users",
    source: "Malcolm Gladwell, Blink / Nalini Ambady",
    framework: "dado científico + ação",
    concept_slug: "vies-confirmacao"
  }
]

SUBJECT_FALLBACK_CONCEPT_V4 = {
  "mente-forte"          => "atencao",
  "corpo-saude"          => "homeostase",
  "dinheiro-vida"        => "tradeoff",
  "carater"              => "virtude-habito",
  "tecnologia-criacao"   => "pensamento-computacional",
  "resolver-problemas"   => "decomposicao",
  "vida-sociedade"       => "comunicacao"
}.freeze

concept_id_by_slug_v4 = ::Academy::Concept.pluck(:slug, :id).to_h

new_count = 0
new_missions.each do |attrs|
  subject = ::Academy::Subject.find_by(slug: attrs[:subject])
  trail   = subject && ::Academy::Trail.find_by(subject_id: subject.id, slug: attrs[:trail])
  unless subject
    warn "  ⚠ v4_missions: subject '#{attrs[:subject]}' not found, skipping #{attrs[:slug]}"
    next
  end

  concept_id = concept_id_by_slug_v4[attrs[:concept_slug]] ||
               concept_id_by_slug_v4[SUBJECT_FALLBACK_CONCEPT_V4[attrs[:subject]]] ||
               concept_id_by_slug_v4.values.first

  mission = ::Academy::Mission.find_or_initialize_by(slug: attrs[:slug])
  mission.assign_attributes(
    subject_id: subject.id,
    trail_id: trail&.id,
    title: attrs[:title],
    hook: attrs[:hook],
    angle: attrs[:angle],
    central_insight: attrs[:central_insight],
    curiosity_facts: attrs[:curiosity_facts],
    challenge_prompt: attrs[:challenge_prompt],
    challenge_when: attrs[:challenge_when],
    challenge_observable: attrs[:challenge_observable],
    learning_objective: attrs[:learning_objective],
    illustration_key: attrs[:illustration_key],
    source: attrs[:source],
    framework: attrs[:framework],
    concept_id: mission.concept_id || concept_id,
    active: true,
    points_reward: mission.points_reward || 25,
    order_in_subject: mission.order_in_subject || 50
  )
  mission.save!
  new_count += 1
end
puts "✓ Academy v4 new discovery missions: #{new_count} added/refreshed"

# Soft-deactivate v2 duplicates whose v4 replacement is now present.
# Must run AFTER new_missions so the replacement actually exists.
duplicates = { "5-porques" => "cinco-porques-resolve" }
deactivated = 0
duplicates.each do |old_slug, replacement_slug|
  old = ::Academy::Mission.find_by(slug: old_slug)
  next unless old&.active?
  next unless ::Academy::Mission.find_by(slug: replacement_slug)

  old.update_columns(active: false)
  deactivated += 1
end
puts "✓ Academy v4 duplicates deactivated: #{deactivated} (replaced by v4-calibrated)" if deactivated.positive?
