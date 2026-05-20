# frozen_string_literal: true

# Academy v3 — missions for the curiosidade-do-mundo curriculum.
#
# 30 missions, 1:1 with the concepts seeded by
# db/seeds/academy_curiosidade_concepts.rb. Three Subjects already exist
# (como-o-mundo-funciona, curiosidades-do-corpo, palavras-origens); this
# file also creates the Trails that group these missions thematically
# (2 trails per subject, 5 missions each).
#
# Idempotent: every Subject/Trail/Mission lookup is find_or_initialize_by.
# Wrapped in a single transaction so a mid-load failure rolls everything
# back. Loaded from db/seeds/academy.rb AFTER lens payloads (so the
# curated-payload audit can pass) and BEFORE the final audit block.

CURIOSIDADE_MISSIONS = [
  # ───────────────────────────────────────────────────────────────────
  # 🌍 Como o Mundo Funciona  (10 concepts → 2 trails × 5)
  # ───────────────────────────────────────────────────────────────────
  {
    subject_slug: "como-o-mundo-funciona",
    trail_slug:   "ceu-terra-agua",
    trail_title:  "Céu, Terra e Água",
    trail_arc_hook: "Olhar pro chão, pro mar e pro céu com a pergunta certa muda o que se vê.",
    trail_position: 1,
    missions: [
      {
        concept_slug: "por-que-o-ceu-e-azul",
        title: "Por que o céu é azul (e não roxo)?",
        hook: "A luz do sol é branca — então quem pintou o céu?",
        angle: "A atmosfera espalha cada cor da luz em ritmo diferente. O azul se espalha muito mais que o vermelho, e a sobra chega aos olhos de todo lugar do céu.",
        central_insight: "Se o ar espalha mais o azul que o vermelho, o céu fica azul de dia e laranja no pôr do sol — quando a luz atravessa mais ar.",
        curiosity_facts: [
          "O azul se espalha cerca de 10 vezes mais que o vermelho — chamam isso de espalhamento de Rayleigh.",
          "No pôr do sol a luz atravessa muito mais atmosfera, o azul já se gastou no caminho e sobra o laranja.",
          "Na lua não tem atmosfera, então o céu lá é preto até de dia — mesmo com sol forte."
        ],
        challenge_prompt: "Olhe o céu hoje em 3 momentos: manhã, meio-dia, pôr do sol. Repare como a cor muda.",
        challenge_when: "hoje",
        challenge_observable: "Em qual horário o céu fica mais alaranjado e por quê.",
        learning_objective: "Relacionar a quantidade de ar atravessada pela luz com a cor do céu em 3 momentos do dia.",
        source: "Lord Rayleigh",
        framework: "explanation",
        illustration_key: "atom",
        points_reward: 25
      },
      {
        concept_slug: "gelo-flutua-na-agua",
        title: "Por que o gelo flutua, se quase tudo afunda quando endurece?",
        hook: "Coloque uma pedra na água: afunda. Coloque um cubo de gelo: bóia. Estranho.",
        angle: "Quase todos os líquidos ficam mais densos ao virar sólido. A água é a exceção rara — a forma do cristal de gelo deixa espaço vazio entre as moléculas, então pesa menos por volume.",
        central_insight: "Se o gelo afundasse, os lagos congelariam do fundo pra cima e os peixes morreriam todo inverno. Por isso a vida nos lagos depende dessa exceção.",
        curiosity_facts: [
          "O cristal de gelo ocupa cerca de 9% mais volume que a mesma quantidade de água líquida.",
          "Cerca de 90% de um iceberg fica embaixo d'água — só os 10% restantes aparecem.",
          "Sob pressão extrema (mais de 200 atmosferas) o gelo passa a afundar — perto da exceção, outra exceção."
        ],
        challenge_prompt: "Encha um copo até a boca com água e gelo. Acompanhe o derretimento — transborda ou não?",
        challenge_when: "hoje",
        challenge_observable: "Se a água transborda quando o gelo derrete (e tente prever antes).",
        learning_objective: "Prever e observar se a água transborda ao derreter o gelo no copo cheio.",
        source: "Linus Pauling",
        framework: "paradox",
        illustration_key: "atom",
        points_reward: 25
      },
      {
        concept_slug: "como-funciona-o-arco-iris",
        title: "Como uma gota de chuva fabrica um arco-íris?",
        hook: "Sempre 42°. Sempre. Os arco-íris têm um ângulo fixo no céu.",
        angle: "Cada gota de chuva funciona como um prisminha esférico: a luz branca entra, se separa em cores dentro da gota e sai num ângulo de 42° em relação ao sol.",
        central_insight: "Se o ângulo entre o sol, você e as gotas não é 42°, não tem arco-íris pra esses olhos — duas pessoas lado a lado veem arcos ligeiramente diferentes.",
        curiosity_facts: [
          "Cada gota de chuva separa as cores no mesmo ângulo: 42° pro vermelho, 40° pro azul.",
          "Arco-íris duplo acontece quando a luz reflete duas vezes dentro da gota — a ordem das cores no segundo arco inverte.",
          "De avião dá pra ver o arco-íris fechar um círculo completo — do chão a terra esconde a metade de baixo."
        ],
        challenge_prompt: "Com a mangueira no jardim, fique de costas pro sol e faça spray fino — encontre o arco-íris caseiro.",
        challenge_when: "hoje",
        challenge_observable: "O ângulo em que ele aparece em relação ao seu corpo e ao sol.",
        learning_objective: "Provocar um arco-íris com mangueira e identificar o ângulo entre sol, água e olhos.",
        source: "Isaac Newton",
        framework: "explanation",
        illustration_key: "atom",
        points_reward: 25
      },
      {
        concept_slug: "por-que-mar-e-salgado",
        title: "Por que o mar é salgado, mas a chuva não é?",
        hook: "A chuva vem do mar — e mesmo assim cai doce.",
        angle: "A chuva rala lentamente os continentes e leva sal dissolvido pros rios e daí pro oceano. Quando a água do mar evapora, o sal fica pra trás — por isso só a água sobe pras nuvens.",
        central_insight: "Se o sal sempre entra no oceano e quase nunca sai, ele se acumula há bilhões de anos — daí o mar ser cada vez um pouquinho mais salgado.",
        curiosity_facts: [
          "Em cada litro de mar tem em média 35 gramas de sal — quase 3 colheres de sopa.",
          "Os rios despejam cerca de 4 bilhões de toneladas de sal no mar por ano.",
          "O Mar Morto tem quase 10 vezes mais sal que o oceano comum — por isso ninguém afunda lá."
        ],
        challenge_prompt: "Coloque água com sal num pires e deixe ao sol o dia todo. Volte à noite.",
        challenge_when: "hoje",
        challenge_observable: "O que sobrou no pires depois que a água evaporou.",
        learning_objective: "Demonstrar evaporação seletiva colocando água salgada ao sol e identificando o resíduo.",
        source: "Edmond Halley",
        framework: "explanation",
        illustration_key: "atom",
        points_reward: 25
      },
      {
        concept_slug: "agua-quebra-pedra",
        title: "Como um cubo de gelo derrota uma montanha?",
        hook: "A água é mole. A pedra é dura. A água ganha — basta tempo.",
        angle: "Quando a água entra numa fresta da rocha e congela, ela expande cerca de 9%. Empurra a fresta um pouquinho. Derrete, entra mais fundo, congela de novo. Em décadas, racha a pedra.",
        central_insight: "Se uma força pequena age sempre no mesmo ponto, ela vence qualquer coisa — paciência é alavanca da física, não só de pessoa.",
        curiosity_facts: [
          "Uma fresta de 1mm aberta em dia gelado vira fresta de 1,1mm em uma noite só.",
          "A maior parte do solo do planeta nasceu de pedra que a água rachou durante milhões de anos.",
          "Os romanos racharam pedreiras gigantes batendo cunhas de madeira seca e jogando água — a madeira inchava e quebrava o granito."
        ],
        challenge_prompt: "Encha uma garrafinha de plástico até a boca e deixe no congelador a noite toda. Cuidado com o estouro.",
        challenge_when: "hoje",
        challenge_observable: "Se a garrafa estoura, racha ou só estufa quando a água vira gelo.",
        learning_objective: "Demonstrar a expansão da água ao congelar usando uma garrafa fechada no congelador.",
        source: "James Hutton",
        framework: "metaphor",
        illustration_key: "atom",
        points_reward: 25
      }
    ]
  },
  {
    subject_slug: "como-o-mundo-funciona",
    trail_slug:   "forcas-invisiveis",
    trail_title:  "Forças Invisíveis",
    trail_arc_hook: "Quase tudo que decide o dia a dia não tem cor, nem cheiro, nem peso — e mesmo assim manda.",
    trail_position: 2,
    missions: [
      {
        concept_slug: "como-um-aviao-voa",
        title: "Como um pedaço de metal de 300 toneladas voa?",
        hook: "Empurre o ar pra baixo com força, e o ar te empurra pra cima na mesma medida.",
        angle: "O formato curvo da asa faz o ar passar mais rápido em cima do que em baixo. Diferença de velocidade vira diferença de pressão, e a pressão maior embaixo empurra a asa pra cima.",
        central_insight: "Se você empurra o ar pra baixo, o ar te empurra pra cima — voar não é mágica, é o ar reagindo a uma pancada feita com elegância.",
        curiosity_facts: [
          "Um Boeing 747 só sai do chão depois de uns 280 km/h — abaixo disso o ar ainda não empurra bastante.",
          "A força que sustenta o avião é descrita pela terceira lei de Newton: ação e reação.",
          "Aviões viram subindo uma asa porque a asa de cima passa a empurrar menos ar — e o avião desce daquele lado."
        ],
        challenge_prompt: "Segure uma folha de papel pela borda perto do lábio inferior e sopre forte por cima.",
        challenge_when: "hoje",
        challenge_observable: "Pra onde a folha vai — pra cima ou pra baixo — e por quê.",
        learning_objective: "Demonstrar a sustentação soprando por cima de uma folha de papel e prevendo seu movimento.",
        source: "Daniel Bernoulli + Isaac Newton",
        framework: "explanation",
        illustration_key: "atom",
        points_reward: 25
      },
      {
        concept_slug: "trovao-vem-depois-do-raio",
        title: "Por que o trovão sempre chega depois do raio?",
        hook: "O raio e o trovão saem juntos. Mas só um chega primeiro.",
        angle: "A luz viaja a 300.000 km por segundo. O som, a 340 metros por segundo. Os dois nascem no mesmo instante, mas a luz chega quase imediata e o som demora.",
        central_insight: "Se você contar os segundos entre o raio e o trovão e dividir por 3, dá quase a distância da tempestade em quilômetros.",
        curiosity_facts: [
          "A luz é cerca de 900 mil vezes mais rápida que o som no ar.",
          "Cada 3 segundos entre raio e trovão equivalem a aproximadamente 1 km de distância.",
          "Um raio aquece o ar em volta a cerca de 30.000°C — cinco vezes mais quente que a superfície do sol."
        ],
        challenge_prompt: "Na próxima tempestade, conte segundos entre o raio e o trovão. Divida por 3.",
        challenge_when: "esta-semana",
        challenge_observable: "Se a tempestade está chegando, se afastando ou parada.",
        learning_objective: "Estimar a distância de uma tempestade contando segundos entre raio e trovão.",
        source: "Benjamin Franklin",
        framework: "explanation",
        illustration_key: "atom",
        points_reward: 25
      },
      {
        concept_slug: "paradoxo-do-aniversario",
        title: "Numa sala com 23 pessoas, dois fazem aniversário no mesmo dia?",
        hook: "Parece pouca gente. A matemática discorda.",
        angle: "Com 23 pessoas dá pra formar 253 pares diferentes. A chance de cada par NÃO coincidir é alta, mas multiplicada 253 vezes vira baixa — a chance de PELO MENOS um par coincidir passa de 50%.",
        central_insight: "Se a intuição diz 'precisaria de 183 pessoas pra coincidência' e a matemática diz '23 já basta', a intuição estima mal — calcular pares muda tudo.",
        curiosity_facts: [
          "Com 23 pessoas a chance de duas coincidirem em aniversário passa de 50%.",
          "Com 50 pessoas a chance vira 97%; com 70, vira 99,9%.",
          "O número de pares cresce com o quadrado da quantidade de pessoas: 23 pessoas formam 253 pares, não 23."
        ],
        challenge_prompt: "Pergunte o dia do aniversário pra 20 pessoas hoje (família, turma, time). Anote.",
        challenge_when: "esta-semana",
        challenge_observable: "Se dois aniversariantes caem no mesmo dia.",
        learning_objective: "Conduzir uma amostra de 20 aniversários e comparar com a previsão estatística.",
        source: "Richard von Mises",
        framework: "paradox",
        illustration_key: "atom",
        points_reward: 25
      },
      {
        concept_slug: "pizza-grande-e-mais-barata",
        title: "Por que pizza grande quase sempre vale mais a pena?",
        hook: "Pizza dobro do raio não rende dobro. Rende quatro vezes.",
        angle: "A área de um círculo cresce com o quadrado do raio (πr²). Dobrar o raio quadruplica a área. Por isso a pizza grande costuma sair MUITO mais barata por pedaço.",
        central_insight: "Se algo cresce em duas dimensões e o preço cresce em uma, o grande quase sempre vence o pequeno por unidade — pizza, casa, terreno, tudo.",
        curiosity_facts: [
          "Pizza de 30cm tem cerca de 707cm². Pizza de 40cm tem 1257cm² — quase o dobro, não 33% a mais.",
          "Duas pizzas média (30cm) somam 1414cm² — quase a mesma área de uma grande de 40cm, mas custam mais.",
          "Essa lei do quadrado vale pra tudo plano: tapete, parede pra pintar, terreno."
        ],
        challenge_prompt: "Pegue o menu da próxima pizzaria. Calcule o preço por cm² de cada tamanho. Compare.",
        challenge_when: "esta-semana",
        challenge_observable: "Qual tamanho rende mais comida por real.",
        learning_objective: "Calcular preço por cm² em duas pizzas e identificar qual rende mais por real.",
        source: "Arquimedes",
        framework: "paradox",
        illustration_key: "atom",
        points_reward: 25
      },
      {
        concept_slug: "como-funciona-uma-pilha",
        title: "Como uma pilha guarda energia no escuro?",
        hook: "Por fora, plástico e metal parado. Por dentro, química esperando o gatilho.",
        angle: "Dentro da pilha, dois metais diferentes ficam em contato com um líquido (eletrólito). Quando o circuito fecha, elétrons saem por um lado e voltam pelo outro — esse rio de elétrons é a corrente elétrica.",
        central_insight: "Se a corrente é só elétrons em fila, a pilha morre quando a química acaba de empurrar — eletricidade portátil é química disfarçada.",
        curiosity_facts: [
          "A primeira pilha (de Alessandro Volta, em 1800) era uma pilha mesmo: discos de zinco e cobre empilhados com pano molhado entre eles.",
          "Numa pilha AA passam cerca de 6 quintilhões de elétrons por segundo durante o uso.",
          "Pilha recarregável é a mesma reação química acontecendo de trás pra frente quando você carrega."
        ],
        challenge_prompt: "Espete uma lâmpada de LED pequena (ou um relógio de pilha) num limão com prego de zinco e moeda de cobre.",
        challenge_when: "esta-semana",
        challenge_observable: "Se o limão dá voltagem (use multímetro ou um LED de baixa tensão).",
        learning_objective: "Montar a pilha de limão e medir corrente entre eletrodos de zinco e cobre.",
        source: "Alessandro Volta",
        framework: "explanation",
        illustration_key: "atom",
        points_reward: 25
      }
    ]
  },

  # ───────────────────────────────────────────────────────────────────
  # 💪 Curiosidades do Corpo  (10 concepts → 2 trails × 5)
  # ───────────────────────────────────────────────────────────────────
  {
    subject_slug: "curiosidades-do-corpo",
    trail_slug:   "pele-ossos-e-cor",
    trail_title:  "Pele, Ossos e Cor",
    trail_arc_hook: "Tudo que se vê do corpo por fora tem uma engenharia escondida por dentro.",
    trail_position: 1,
    missions: [
      {
        concept_slug: "como-cicatrizacao-funciona",
        title: "Como a pele se conserta sozinha?",
        hook: "Você corta o dedo. Em 1 semana, o corte some. Quem fechou?",
        angle: "Em segundos as plaquetas tampam o buraco como cimento. Em dias, fibroblastos fabricam colágeno por baixo. Em semanas, a pele nova substitui a velha — e a cicatriz é a costura ficando à mostra.",
        central_insight: "Se o corte é fino, o conserto fica invisível; se é grosso, sobra cicatriz — a marca depende do tamanho da costura, não do machucado.",
        curiosity_facts: [
          "Uma plaqueta vive em média 8 a 10 dias — o corpo fabrica 100 bilhões de plaquetas novas por dia.",
          "O fígado é o único órgão do corpo que regenera pedaços inteiros sozinho — pode perder até 70% e voltar a crescer.",
          "Tatuagem dura a vida toda porque a tinta entra na camada que NÃO se renova (derme) — a camada de cima troca toda em ~30 dias."
        ],
        challenge_prompt: "Veja um machucado antigo seu. Compare com a pele ao redor — lisa, brilhante, mais clara?",
        challenge_when: "hoje",
        challenge_observable: "Qual a textura e a cor da cicatriz comparada com a pele em volta.",
        learning_objective: "Comparar textura e cor de uma cicatriz com a pele ao redor e identificar a marca da costura.",
        source: "Marc Donald",
        framework: "explanation",
        illustration_key: "heart-pulse",
        points_reward: 25
      },
      {
        concept_slug: "por-que-temos-impressao-digital",
        title: "Por que não existem duas digitais iguais no mundo?",
        hook: "Nem mesmo gêmeos idênticos têm a mesma digital. Por quê?",
        angle: "Os dedos formam os sulcos ainda na barriga da mãe, por volta da 13ª semana. A pele encosta no líquido em ângulos micro-diferentes em cada bebê — e os sulcos guardam essas curvas pra sempre.",
        central_insight: "Se nem gêmeos idênticos têm a mesma digital, então o desenho da pele não vem só do DNA — vem também do empurrão exato do líquido na barriga.",
        curiosity_facts: [
          "Cada dedo da mesma pessoa tem desenho diferente — a mão direita não copia a esquerda.",
          "Os coalas são quase os únicos animais não-primatas com impressão digital — e a deles é tão parecida com a humana que confunde até polícia científica.",
          "A digital se forma por volta da 13ª semana de gestação e não muda mais até a morte."
        ],
        challenge_prompt: "Faça sua digital com lápis 6B no papel e fita adesiva. Compare com a de alguém da família.",
        challenge_when: "hoje",
        challenge_observable: "Quantos padrões diferentes você vê entre você e seu parente próximo.",
        learning_objective: "Coletar duas digitais diferentes em casa e identificar o padrão (laço, espiral, arco).",
        source: "Francis Galton",
        framework: "explanation",
        illustration_key: "heart-pulse",
        points_reward: 25
      },
      {
        concept_slug: "como-cerebro-ve-cor",
        title: "O olho enxerga só 3 cores. Como você vê milhões?",
        hook: "Não tem azul-piscina dentro do olho. O cérebro inventa.",
        angle: "Na retina só existem 3 tipos de células sensíveis a cor (cones): vermelho, verde, azul. O cérebro mistura essas três e fabrica todas as outras — turquesa, lilás, marrom são receitas do cérebro.",
        central_insight: "Se duas pessoas olham a mesma maçã, cada cérebro reconstrói a cor por dentro — não dá pra provar que o vermelho que você vê é igual ao vermelho do outro.",
        curiosity_facts: [
          "A retina humana tem cerca de 6 milhões de cones e 120 milhões de bastonetes (pra preto e branco).",
          "Cachorros enxergam mais ou menos como humanos daltônicos — só duas cores, sem o vermelho-verde.",
          "Camarão-mantis tem 16 tipos de cones — provavelmente vê cores que humanos nunca vão imaginar."
        ],
        challenge_prompt: "Olhe uma mancha vermelha por 30 segundos. Depois olhe pra parede branca.",
        challenge_when: "hoje",
        challenge_observable: "Qual cor aparece de fantasma na parede (e por quê o cérebro inventa o oposto).",
        learning_objective: "Provocar pós-imagem cromática fixando uma cor e descrevendo a cor fantasma.",
        source: "Hermann von Helmholtz",
        framework: "paradox",
        illustration_key: "heart-pulse",
        points_reward: 25
      },
      {
        concept_slug: "como-osso-quebrado-se-cola",
        title: "Como osso quebrado se cola sozinho?",
        hook: "Bateu, rachou. Em 6 semanas, voltou inteiro — e mais forte que era.",
        angle: "Quando o osso quebra, o sangue forma um casulo em volta. Células chamadas osteoblastos chegam e fabricam osso novo na fratura — primeiro mole, depois duro. O ponto da fratura fica mais grosso que o resto.",
        central_insight: "Se o osso quebrado vira mais forte ali do que era antes, o corpo aprendeu com o erro — reconstruiu reforçado no exato ponto que falhou.",
        curiosity_facts: [
          "Um osso humano fraturado leva em média 6 a 8 semanas pra se colar completo.",
          "Crianças cicatrizam osso em metade do tempo dos adultos — o osso delas ainda tem cartilagem ativa.",
          "Pra um osso ficar grosso e forte, ele precisa de carga — astronautas perdem cerca de 1% de massa óssea por mês sem gravidade."
        ],
        challenge_prompt: "Pergunte pra alguém que já quebrou um osso: depois que colou, ficou mais grosso naquele ponto?",
        challenge_when: "esta-semana",
        challenge_observable: "O que a pessoa lembra do conserto (tempo, gesso, força ao voltar).",
        learning_objective: "Coletar 1 relato real de fratura curada e mapear tempo, sintomas e resultado final.",
        source: "Julius Wolff",
        framework: "case",
        illustration_key: "heart-pulse",
        points_reward: 25
      },
      {
        concept_slug: "como-pele-fica-bronzeada",
        title: "Por que a pele bronzeia ao sol?",
        hook: "O bronzeado não é só cor — é uniforme de defesa.",
        angle: "A luz ultravioleta do sol pode danificar o DNA das células da pele. Pra se proteger, células chamadas melanócitos produzem melanina (escurinho) que absorve o UV antes dele chegar fundo.",
        central_insight: "Se o bronzeado é o corpo fabricando proteção contra o sol, ele é sinal de que a pele JÁ está em alerta — não de saúde gratuita.",
        curiosity_facts: [
          "A melanina absorve cerca de 99,9% dos raios ultravioleta que chegam na pele.",
          "Pessoas de pele clara têm a mesma quantidade de melanócitos — só fabricam menos melanina por célula.",
          "O bronzeado começa a aparecer 2 a 3 dias depois da exposição porque a melanina demora pra subir até a superfície."
        ],
        challenge_prompt: "Coloque um adesivo numa parte da pele exposta ao sol e deixe 3 dias.",
        challenge_when: "esta-semana",
        challenge_observable: "Qual a diferença de tom entre a pele coberta pelo adesivo e a do lado.",
        learning_objective: "Demonstrar produção de melanina cobrindo um pedaço da pele e comparando o contraste em 3 dias.",
        source: "Thomas Fitzpatrick",
        framework: "explanation",
        illustration_key: "heart-pulse",
        points_reward: 25
      }
    ]
  },
  {
    subject_slug: "curiosidades-do-corpo",
    trail_slug:   "sono-ar-digestao",
    trail_title:  "Sono, Ar e Digestão",
    trail_arc_hook: "O corpo trabalha mais quando você dorme do que quando está acordado.",
    trail_position: 2,
    missions: [
      {
        concept_slug: "por-que-engasgo-bocejando",
        title: "Por que dá pra engasgar bocejando?",
        hook: "Dois tubos cruzam na sua garganta. A natureza fez gambiarra.",
        angle: "Pelo mesmo buraco da garganta passam o ar (pra os pulmões) e a comida (pro estômago). Uma tampinha chamada epiglote escolhe um por vez. Quando boceja, tudo abre ao mesmo tempo — e a saliva pode descer pelo cano errado.",
        central_insight: "Se o sistema de ar e o sistema de comida usam o mesmo tubo, engasgar não é defeito seu — é gambiarra antiga da evolução.",
        curiosity_facts: [
          "Cada pessoa adulta engasga em média 1 a 2 vezes por mês sem se ferir — quase nunca conta a alguém.",
          "Bebês têm a laringe alta, próxima ao nariz — por isso mamam e respiram ao mesmo tempo sem engasgar.",
          "Por volta dos 2 anos a laringe desce, abrindo espaço pra fala — e o risco de engasgo aumenta."
        ],
        challenge_prompt: "Boceje devagar e preste atenção: sente o ouvido estalar? A garganta se abrindo?",
        challenge_when: "hoje",
        challenge_observable: "Quantas coisas se mexem juntas durante um bocejo (mandíbula, ouvido, garganta).",
        learning_objective: "Mapear 3 partes do corpo que se mexem juntas durante 1 bocejo.",
        source: "Anatomia comparada",
        framework: "explanation",
        illustration_key: "heart-pulse",
        points_reward: 25
      },
      {
        concept_slug: "por-que-doi-bater-cotovelo",
        title: "Por que bater o cotovelo dói tanto pra uma coisa tão pequena?",
        hook: "Não é o osso. É um nervo descansando do lado de fora.",
        angle: "O nervo ulnar passa quase na superfície, encostado no osso do cotovelo, sem músculo nem gordura cobrindo. Quando bate, o nervo é prensado direto contra o osso — e manda choque elétrico pro cérebro.",
        central_insight: "Se um nervo passa sem proteção bem no canto de um osso, qualquer batidinha vira choque — não é dor à toa, é o aviso máximo do cérebro.",
        curiosity_facts: [
          "O nervo ulnar atravessa o corpo do pescoço até a ponta do dedo mindinho.",
          "O apelido 'osso engraçado' (funny bone) é trocadilho com húmero — mas a dor não vem do osso, vem do nervo encostado nele.",
          "Quem dorme com o braço dobrado por horas comprime o nervo ulnar — e acorda com o mindinho dormente."
        ],
        challenge_prompt: "Toque devagar a parte de trás do cotovelo até achar o ponto que dispara o formigamento.",
        challenge_when: "hoje",
        challenge_observable: "Pra onde o formigamento desce no braço (dedos específicos).",
        learning_objective: "Localizar o ponto do nervo ulnar e mapear até que dedo o formigamento chega.",
        source: "Henry Gray",
        framework: "explanation",
        illustration_key: "heart-pulse",
        points_reward: 25
      },
      {
        concept_slug: "por-que-temos-sonhos",
        title: "Pra que servem os sonhos?",
        hook: "Acordou e esqueceu. Mas o cérebro guardou o ensaio.",
        angle: "Durante o sono REM o cérebro reorganiza o que viveu, ensaia situações e arquiva o que importa. O sonho é o sobra do ensaio passando na sua frente como vídeo bagunçado.",
        central_insight: "Se quem dorme mal aprende menos no dia seguinte, então sonho não é desperdício de tempo — é o cérebro salvando o arquivo do dia.",
        curiosity_facts: [
          "Cada pessoa sonha em média 4 a 6 vezes por noite, mas só lembra do último sonho (e às vezes nem dele).",
          "Pesquisas de Matthew Walker mostram que noites sem REM reduzem a capacidade de aprender em até 40%.",
          "Cachorros e gatos têm REM — quem já viu o bicho mexendo as patinhas dormindo viu sonho de cachorro acontecendo."
        ],
        challenge_prompt: "Acordou hoje? Tente lembrar 1 detalhe do sonho ANTES de pegar o celular. Anota.",
        challenge_when: "hoje",
        challenge_observable: "Quanto do sonho some assim que olha pra tela.",
        learning_objective: "Anotar 1 detalhe de sonho antes de ver tela e comparar a memória com a do dia seguinte.",
        source: "Matthew Walker",
        framework: "explanation",
        illustration_key: "heart-pulse",
        points_reward: 25
      },
      {
        concept_slug: "como-tomate-vira-coco",
        title: "Como um pedaço de tomate vira cocô?",
        hook: "30 horas de viagem, 9 metros de tubo, 3 químicas trabalhando juntas.",
        angle: "A comida desce pelo esôfago em ondas (peristalse), passa pelo estômago que mistura com ácido, vai pro intestino delgado onde enzimas quebram tudo em pedacinhos. O que serve é absorvido pra dentro do sangue. O resto continua o caminho até a saída.",
        central_insight: "Se o intestino tem 9 metros, então o tomate viaja 30 horas pelo seu corpo antes de virar cocô — o estômago é só o começo da fábrica.",
        curiosity_facts: [
          "O intestino delgado de um adulto tem cerca de 6 a 7 metros — enrolado dentro da barriga.",
          "O ácido do estômago é tão forte (pH 1-2) que dissolveria metal — mas o estômago renova suas próprias paredes a cada 3 a 5 dias.",
          "A digestão completa de uma refeição leva entre 24 e 72 horas, dependendo do que foi comido."
        ],
        challenge_prompt: "Coma uma colher de milho cozido inteiro hoje. Repare quando aparece de novo.",
        challenge_when: "esta-semana",
        challenge_observable: "Quantas horas levou pro milho fazer a viagem completa.",
        learning_objective: "Medir o tempo de trânsito intestinal usando milho como marcador visível.",
        source: "William Beaumont",
        framework: "explanation",
        illustration_key: "heart-pulse",
        points_reward: 25
      },
      {
        concept_slug: "por-que-bocejo-e-contagioso",
        title: "Por que bocejo pega de uma pessoa pra outra?",
        hook: "Você viu alguém bocejar. Agora você bocejou. Quem comandou?",
        angle: "Quando você vê alguém bocejar, neurônios chamados neurônios-espelho copiam o gesto antes do pensamento racional acordar. Bocejo contagioso é empatia em forma de músculo.",
        central_insight: "Se quanto mais próximo emocionalmente, mais fácil pega bocejo, então 'pegar bocejo' é um indicador de empatia — não de sono.",
        curiosity_facts: [
          "Estudos mostram que bocejo pega mais entre família e amigos próximos do que entre estranhos.",
          "Cachorros pegam bocejo dos donos — e quase só dos donos, não de qualquer pessoa.",
          "Crianças com menos de 4 anos quase não pegam bocejo dos outros — os neurônios-espelho ainda estão amadurecendo."
        ],
        challenge_prompt: "Boceje propositalmente perto de 3 pessoas hoje. Conte quantas bocejaram em até 1 minuto.",
        challenge_when: "hoje",
        challenge_observable: "Quem pegou primeiro — e quem nem ligou.",
        learning_objective: "Conduzir teste informal de contágio do bocejo com 3 pessoas próximas.",
        source: "Giacomo Rizzolatti",
        framework: "case",
        illustration_key: "heart-pulse",
        points_reward: 25
      }
    ]
  },

  # ───────────────────────────────────────────────────────────────────
  # 📚 Palavras & Origens  (10 concepts → 2 trails × 5)
  # ───────────────────────────────────────────────────────────────────
  {
    subject_slug: "palavras-origens",
    trail_slug:   "palavras-que-nos-rodeiam",
    trail_title:  "Palavras que nos Rodeiam",
    trail_arc_hook: "Toda palavra do dia a dia esconde um pedaço de história que ninguém te contou.",
    trail_position: 1,
    missions: [
      {
        concept_slug: "de-onde-vem-salario",
        title: "De onde vem a palavra 'salário'?",
        hook: "Salário vem de sal. Sério.",
        angle: "Em Roma antiga, o sal era raríssimo — usado pra preservar carne sem geladeira. Soldados recebiam parte do pagamento em sal. 'Salarium' era literalmente 'a parte do sal' — virou 'salário'.",
        central_insight: "Se a palavra do nosso pagamento mensal nasceu do nome de um tempero, então o que parece 'normal' hoje foi luxo extremo em outra época.",
        curiosity_facts: [
          "Em Roma, o sal era tão valioso que existiam estradas dedicadas só pro transporte dele — a Via Salaria é uma delas.",
          "A palavra 'soldado' vem de 'soldo', que era o pagamento em moeda — antes era em sal mesmo.",
          "Quem 'não vale o sal que come' é uma expressão romana que sobreviveu 2.000 anos quase intacta."
        ],
        challenge_prompt: "Pegue 3 palavras do seu dia (escola, comida, casa) e pergunte ao adulto: 'de onde será que veio?'",
        challenge_when: "hoje",
        challenge_observable: "Quantas histórias inesperadas aparecem por trás das palavras comuns.",
        learning_objective: "Investigar a origem de 3 palavras cotidianas e descobrir 1 história surpresa.",
        source: "Plínio o Velho",
        framework: "historical_scene",
        illustration_key: "book-open",
        points_reward: 25
      },
      {
        concept_slug: "por-que-domingo-e-domingo",
        title: "Por que segunda, terça, quarta são números — mas domingo tem nome?",
        hook: "Os outros dias são contagem. O domingo guardou nome próprio.",
        angle: "Em latim cristão, o domingo era 'Dies Dominica' — 'dia do Senhor'. O resto da semana ficou conhecido por números ('feria secunda', 'feria tertia'). Em português os números viraram 'segunda', 'terça' etc. Domingo guardou o nome antigo.",
        central_insight: "Se a maioria dos idiomas latinos chama os dias por planetas (lunes, martes, miércoles) e o português chama por número, então a língua guardou um pedaço da história religiosa que outras esqueceram.",
        curiosity_facts: [
          "Em espanhol, francês e italiano, os dias da semana são nomes de planetas (lunes = lua, martes = Marte etc.).",
          "Em inglês, os dias vêm de deuses nórdicos: Thursday = dia de Thor, Wednesday = dia de Odin.",
          "O português é uma das poucas línguas latinas que numerou os dias — herança de um costume da igreja cristã primitiva."
        ],
        challenge_prompt: "Pergunte pra alguém que fale espanhol ou inglês o nome dos dias na língua dele.",
        challenge_when: "hoje",
        challenge_observable: "Quais dias têm nome 'estranho' em comparação ao português.",
        learning_objective: "Comparar os nomes dos dias da semana em 2 línguas e identificar a origem de cada um.",
        source: "São Martinho de Dume",
        framework: "historical_scene",
        illustration_key: "book-open",
        points_reward: 25
      },
      {
        concept_slug: "quem-inventou-o-emoji",
        title: "Quem inventou os emojis (e por que tão pequenos)?",
        hook: "Em 1999, um engenheiro japonês desenhou 176 figuras. Hoje são mais de 3.700.",
        angle: "Shigetaka Kurita trabalhava numa empresa de celular no Japão. As mensagens cabiam em poucos caracteres, e o povo queria mostrar emoção. Ele desenhou 176 ícones de 12×12 pixels — tinha que ser MINÚSCULO pra caber.",
        central_insight: "Se os primeiros emojis foram criados pra resolver uma limitação técnica, então criatividade nasce do limite — não do espaço aberto.",
        curiosity_facts: [
          "Os primeiros 176 emojis foram desenhados em apenas 1 mês.",
          "O emoji é mantido pela Unicode — um comitê internacional decide quais novos emojis entram a cada ano.",
          "Em 2014, os 176 emojis originais foram doados pro acervo permanente do MoMA, em Nova York."
        ],
        challenge_prompt: "Tente desenhar 3 emojis novos que você acha que faltam — cada um em quadrado de 1cm.",
        challenge_when: "hoje",
        challenge_observable: "Quantos detalhes cabem no quadradinho — e quantos você teve que cortar.",
        learning_objective: "Criar 3 emojis novos em 1cm² e identificar 1 detalhe que precisou ser cortado.",
        source: "Shigetaka Kurita",
        framework: "historical_scene",
        illustration_key: "book-open",
        points_reward: 25
      },
      {
        concept_slug: "de-onde-vem-vacina",
        title: "Por que vacina se chama vacina?",
        hook: "Vacina vem de vaca. E quase ninguém sabe.",
        angle: "Em 1796, Edward Jenner reparou que as ordenhadoras pegavam uma doença leve das vacas (chamada 'vaccinia') e ficavam imunes à varíola — doença que matava muito gente. Ele inoculou o líquido da vaccinia em uma criança e funcionou. 'Vacina' veio de 'vaca'.",
        central_insight: "Se a palavra 'vacina' guarda a vaca na origem, então cada vez que alguém é vacinado, está se invocando uma observação feita olhando ordenhadora trabalhar.",
        curiosity_facts: [
          "Edward Jenner inoculou pela primeira vez o filho de 8 anos do seu jardineiro — funcionou.",
          "A varíola foi a primeira doença humana erradicada pelo mundo, em 1980 — só por causa da vacina.",
          "Antes de Jenner, a chineses e turcos já tentavam algo parecido — chamavam de 'variolação', mas o risco era maior."
        ],
        challenge_prompt: "Pergunte pra alguém da família qual a vacina mais recente que tomou — e do que protege.",
        challenge_when: "esta-semana",
        challenge_observable: "Quantas doenças diferentes a família junta já tem proteção contra.",
        learning_objective: "Mapear as vacinas tomadas por 3 pessoas da família e contra que doenças protegem.",
        source: "Edward Jenner",
        framework: "historical_scene",
        illustration_key: "book-open",
        points_reward: 25
      },
      {
        concept_slug: "alfabeto-veio-de-onde",
        title: "De onde vieram as letras do alfabeto?",
        hook: "A letra A começou virada de ponta-cabeça — era um boi.",
        angle: "Há cerca de 3.800 anos, os fenícios — povo de mercadores — adaptaram desenhos de bois, casas e portas (do egípcio) em sons. 'Alef' (boi) virou 'A', 'beth' (casa) virou 'B'. Gregos giraram as letras e pegaram emprestado. Quase todo alfabeto do mundo hoje desce desses 22 símbolos.",
        central_insight: "Se a letra A começou como desenho de boi de cabeça pra baixo, então toda escrita do mundo carrega um boi disfarçado — o passado mora na forma das letras.",
        curiosity_facts: [
          "Os fenícios tinham 22 símbolos — sem vogais. Os gregos adicionaram as vogais depois.",
          "A palavra 'alfabeto' vem de 'alef-beth' — as duas primeiras letras fenícias.",
          "O alfabeto hebraico, árabe, latino e cirílico — todos descem direto do alfabeto fenício."
        ],
        challenge_prompt: "Vire a letra A de ponta-cabeça num papel. Tente enxergar uma cabeça de boi (chifres pra cima).",
        challenge_when: "hoje",
        challenge_observable: "Se você consegue ver o boi escondido na letra.",
        learning_objective: "Identificar visualmente a origem pictográfica do A girando a letra de ponta-cabeça.",
        source: "Sir Alan Gardiner",
        framework: "historical_scene",
        illustration_key: "book-open",
        points_reward: 25
      }
    ]
  },
  {
    subject_slug: "palavras-origens",
    trail_slug:   "invencoes-que-ficaram",
    trail_title:  "Invenções que Ficaram",
    trail_arc_hook: "Algumas pessoas inventaram coisas tão úteis que o mundo virou um antes e um depois.",
    trail_position: 2,
    missions: [
      {
        concept_slug: "de-onde-veio-o-zero",
        title: "Quem inventou o zero?",
        hook: "Por mais de 30 mil anos a humanidade contou sem 'nada'. Aí alguém pensou no nada.",
        angle: "O zero como número (não só como vazio) nasceu na Índia, por volta do século VI. Brahmagupta foi o primeiro a tratá-lo como número com regras próprias. Mercadores árabes levaram a ideia pra Bagdá, e dali chegou na Europa quase 800 anos depois.",
        central_insight: "Se o zero levou 800 anos pra atravessar do leste pro oeste, então uma ideia simples pode mudar o mundo — mas só se chegar nas pessoas certas.",
        curiosity_facts: [
          "Os romanos faziam matemática SEM zero — por isso multiplicar 358 × 47 em algarismos romanos era praticamente impossível.",
          "Brahmagupta, em 628 d.C., escreveu as primeiras regras: 'qualquer número mais zero é o número' — parece óbvio hoje.",
          "Nos primeiros séculos na Europa, o zero foi proibido em algumas cidades — comerciantes preferiam o sistema romano."
        ],
        challenge_prompt: "Tente escrever o ano em que você nasceu usando só algarismos romanos. Sem zero.",
        challenge_when: "hoje",
        challenge_observable: "Quanto mais comprido fica o número — e como fica difícil somar dois anos.",
        learning_objective: "Escrever 1 número de 4 dígitos em algarismos romanos e comparar com a versão indo-arábica.",
        source: "Brahmagupta",
        framework: "historical_scene",
        illustration_key: "book-open",
        points_reward: 25
      },
      {
        concept_slug: "por-que-livros-tem-paginas",
        title: "Por que livro tem páginas?",
        hook: "Antes do livro, o texto era rolo. Achar um trecho dava aula de paciência.",
        angle: "Por séculos os textos eram rolos de papiro — pra ler um pedaço lá no meio, desenrolava metro a metro. Por volta do século I, alguém empilhou folhas, costurou de um lado, e inventou o códice — o livro como conhecemos. Mudou tudo.",
        central_insight: "Se a página parece banal, ela só é banal porque alguém resolveu um problema que demorou 3.000 anos pra ser resolvido — a invenção da página foi tão revolucionária quanto a da escrita.",
        curiosity_facts: [
          "Os primeiros códices apareceram no século I — adotados primeiro por cristãos pra carregar os evangelhos.",
          "Em um rolo de papiro só se escrevia de um lado; o códice usa os dois — caiu o custo do livro pela metade.",
          "O Codex Sinaiticus (séc. IV) é um dos livros mais antigos do mundo — está em Londres, no Museu Britânico."
        ],
        challenge_prompt: "Tente achar a página 50 de um livro qualquer. Depois imagine achar 'o pedaço da metade' num rolo de 10 metros.",
        challenge_when: "hoje",
        challenge_observable: "Quanto tempo se ganha por ter número de página.",
        learning_objective: "Comparar tempo de acesso a um trecho num livro vs. num rolo simulado de papel.",
        source: "Suetônio",
        framework: "historical_scene",
        illustration_key: "book-open",
        points_reward: 25
      },
      {
        concept_slug: "como-romanos-contavam",
        title: "Como os romanos faziam contas (sem zero)?",
        hook: "I, V, X, L, C, D, M. Tente multiplicar XII × XVII.",
        angle: "Os romanos somavam letras: I=1, V=5, X=10, L=50, C=100, D=500, M=1000. Pra calcular usavam um tabuleiro chamado ábaco — letras eram só pra escrever, não pra calcular.",
        central_insight: "Se os romanos construíram aquedutos sem o zero, então a matemática deles era genial dentro do limite — mas multiplicar números grandes era lento demais pra avançar mais.",
        curiosity_facts: [
          "Pra fazer contas pesadas, romanos usavam o ábaco — não as letras (essas eram só pra contabilidade).",
          "O sistema indo-arábico se espalhou na Europa só por volta de 1200 — antes disso, romanos dominavam.",
          "Você ainda vê algarismos romanos em capítulos de livro, mostradores de relógio antigos e nomes de papas e reis."
        ],
        challenge_prompt: "Some XII + XVII no papel SEM converter pra número moderno. Depois confira.",
        challenge_when: "hoje",
        challenge_observable: "Quanto tempo levou — e se você desistiu antes do fim.",
        learning_objective: "Resolver 1 soma em algarismos romanos sem conversão intermediária.",
        source: "Edward Hatton",
        framework: "thought_experiment",
        illustration_key: "book-open",
        points_reward: 25
      },
      {
        concept_slug: "numeros-arabes-nao-sao-arabes",
        title: "Por que se chamam 'números arábicos' se nasceram na Índia?",
        hook: "Os algarismos do seu celular não nasceram onde o nome diz.",
        angle: "Os números 0-9 nasceram na Índia, no século VI. Mercadores árabes pegaram a invenção, levaram pra Bagdá, e dali pra Europa. Os europeus chamavam de 'arábicos' porque foi por eles que chegaram — esqueceram do verdadeiro autor.",
        central_insight: "Se o crédito da invenção foi pro carteiro e não pro inventor, então quem entrega a ideia muitas vezes leva o nome — mesmo sem ter inventado nada.",
        curiosity_facts: [
          "Os matemáticos árabes Al-Khwarizmi e Al-Kindi traduziram a matemática indiana e a difundiram em Bagdá — a palavra 'álgebra' vem do título do livro de Al-Khwarizmi.",
          "Os 'algarismos' levam o nome de Al-Khwarizmi (latinizado: Algoritmi) — daí também 'algoritmo'.",
          "Pra desenhar a forma atual dos números 0-9, vários povos contribuíram ao longo de mais de 700 anos."
        ],
        challenge_prompt: "Pegue um celular qualquer e olhe os 10 algarismos. Compare com algarismos romanos no Google.",
        challenge_when: "hoje",
        challenge_observable: "Qual sistema permite escrever 'um milhão' em menos espaço.",
        learning_objective: "Escrever 1 milhão em algarismos romanos e em indo-arábicos para comparar espaço usado.",
        source: "Al-Khwarizmi",
        framework: "historical_scene",
        illustration_key: "book-open",
        points_reward: 25
      },
      {
        concept_slug: "quem-inventou-a-escrita",
        title: "Quem inventou a escrita?",
        hook: "Os primeiros textos do mundo são contagem de cabras em barro.",
        angle: "Os sumérios, na Mesopotâmia (atual Iraque), por volta de 3200 a.C., riscavam contagem de gado e grãos em tabuletas de barro com um espeto. Esses risquinhos viraram cuneiforme, e dali nasceu a escrita do mundo — primeiro pra contar gado, depois pra contar histórias.",
        central_insight: "Se a escrita começou pra controlar estoque de cabras, então a literatura veio depois — primeiro a humanidade inventou o jeito, e só séculos depois inventou o que poderia ser dito com ele.",
        curiosity_facts: [
          "As tabuletas mais antigas do mundo, com cerca de 5.200 anos, foram encontradas em Uruk (atual Iraque).",
          "Os primeiros textos não são poesia nem lei — são listas de cabras, ovelhas e cevada.",
          "A epopeia de Gilgamesh, o texto literário mais antigo conhecido, é cerca de 1.000 anos mais nova que as primeiras contagens."
        ],
        challenge_prompt: "Escreva o seu nome riscando em uma bolinha de massinha — sem caneta, sem papel.",
        challenge_when: "hoje",
        challenge_observable: "Como o barro guarda o risco — e quanto tempo levou pra escrever.",
        learning_objective: "Reproduzir escrita em barro com 1 nome próprio e descrever a textura do registro.",
        source: "Denise Schmandt-Besserat",
        framework: "historical_scene",
        illustration_key: "book-open",
        points_reward: 25
      }
    ]
  }
].freeze

ActiveRecord::Base.transaction do
  CURIOSIDADE_MISSIONS.each do |trail_block|
    subject = ::Academy::Subject.find_by!(slug: trail_block[:subject_slug])

    trail = ::Academy::Trail.find_or_initialize_by(
      subject_id: subject.id,
      slug: trail_block[:trail_slug]
    )
    trail.assign_attributes(
      title: trail_block[:trail_title],
      arc_hook: trail_block[:trail_arc_hook],
      position: trail_block[:trail_position],
      active: true
    )
    trail.save!

    trail_block[:missions].each_with_index do |m, idx|
      concept = ::Academy::Concept.find_by!(slug: m[:concept_slug])

      mission = subject.missions.find_or_initialize_by(slug: m[:concept_slug])
      mission.assign_attributes(
        trail_id: trail.id,
        concept_id: concept.id,
        title: m[:title],
        hook: m[:hook],
        angle: m[:angle].to_s.strip,
        source: m[:source],
        framework: m[:framework],
        sacada: m[:central_insight], # back-compat with legacy `sacada`
        central_insight: m[:central_insight],
        challenge_prompt: m[:challenge_prompt],
        challenge_when: m[:challenge_when],
        challenge_observable: m[:challenge_observable],
        curiosity_facts: m[:curiosity_facts] || [],
        illustration_key: m[:illustration_key],
        learning_objective: m[:learning_objective],
        position_in_trail: idx,
        order_in_subject: trail.position * 100 + idx,
        points_reward: m[:points_reward] || 25,
        active: true
      )
      mission.save!
    end
  end
end

mission_count = ::Academy::Mission
  .joins(:subject)
  .where(academy_subjects: { slug: %w[como-o-mundo-funciona curiosidades-do-corpo palavras-origens] })
  .where(active: true)
  .count

trail_count = ::Academy::Trail
  .joins(:subject)
  .where(academy_subjects: { slug: %w[como-o-mundo-funciona curiosidades-do-corpo palavras-origens] })
  .where(active: true)
  .count

puts "✓ Academy curiosidade missions seeded: #{mission_count} missões / #{trail_count} trilhas"
