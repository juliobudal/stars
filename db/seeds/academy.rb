# frozen_string_literal: true

# Idempotent curriculum seeds for the Academy v2 module.
# Run on its own:  rails runner db/seeds/academy.rb
# Or chained from db/seeds.rb (already wired below).
#
# # v2 — Áreas de formação humana × Trilhas × Aulas (pílulas)
#
# 7 áreas duráveis de FORMAÇÃO HUMANA (não disciplinas escolares). Cada
# área tem TRILHAS — mini-jornadas narrativas. Cada trilha tem AULAS
# (pílulas), e cada aula entrega:
#   - 1 PERGUNTA poderosa (title)
#   - 2-3 CURIOSIDADES rápidas
#   - 1 INSIGHT CENTRAL ("se X, então Y") que sobra na cabeça
#   - 1 MINI-DESAFIO comportamental verificável
#
# Seed comportamento:
#   - Áreas v1 (slugs antigos: inteligencia / carater / relacionamentos /
#     dinheiro / saude / fe-sentido) ficam soft-deactivated. Progresso
#     histórico e medalhas preservadas.
#   - Áreas v2 com slug abaixo são criadas/atualizadas com active=true.
#   - Aulas v2 são criadas em trilhas. (v5: sessions_count retirado;
#     missions agora têm concept_id 1:1 e lens-type runtime.)

CURRICULUM_V2 = [
  # ───────────────────────────────────────────────────────────────────
  # 🧠 Mente Forte  (showcase fully populated)
  # ───────────────────────────────────────────────────────────────────
  {
    slug: "mente-forte",
    name: "Mente Forte",
    tagline: "Dominar a própria mente",
    color: "#7C3AED",
    icon: "brain",
    position: 1,
    angle: "Foco, autocontrole, hábitos, pensamento crítico. Cada aula entrega 1 capacidade prática. Esconde por dentro: neurociência básica, psicologia cognitiva, leitura de viés.",
    trails: [
      {
        slug: "atencao",
        title: "Quem Manda na Sua Atenção?",
        arc_hook: "Se você não programa sua atenção, alguém programa por você.",
        position: 1,
        missions: [
          {
            slug: "celular-difícil-parar",
            title: "Por que mexer no celular é tão difícil de parar?",
            hook: "Apps foram desenhados pra te prender — não é fraqueza.",
            angle: "Dopamina + recompensa variável. O kid está competindo contra mil engenheiros.",
            central_insight: "Se você não decide o que faz sua atenção, um algoritmo decide por você.",
            curiosity_facts: [
              "Apps de rede social usam recompensa variável, a mesma técnica de máquina de caça-níquel.",
              "Notificações ativam dopamina em ~80ms — antes do pensamento racional acordar.",
              "Times de 1000+ engenheiros trabalham pra você NÃO desligar o app."
            ],
            challenge_prompt: "Desligue 3 notificações desnecessárias hoje. Veja o que muda.",
            challenge_when: "hoje",
            challenge_observable: "Quantas vezes você pegou o celular sem precisar.",
            learning_objective: "Reconhecer que o design dos apps explora a atenção e tomar 1 ação concreta.",
            illustration_key: "phone",
            source: "Tristan Harris (ex-Google)",
            framework: "paradoxo + caso real"
          },
          {
            slug: "notificacoes-custam-23-min",
            title: "Quanto custa uma notificação?",
            hook: "Cada beep apaga 23 minutos do seu cérebro.",
            angle: "Custo do switch de contexto. Pesquisa de Gloria Mark, UC Irvine.",
            central_insight: "Cada interrupção tira 23 minutos pra voltar — então 5 notificações = 2 horas perdidas.",
            curiosity_facts: [
              "Pesquisa da UC Irvine: ~23 min para recuperar foco depois de cada interrupção.",
              "O cérebro não é multitarefa — ele alterna rápido e cobra pedágio em cada troca.",
              "Pessoas com notificações ligadas erram 50% mais em tarefas simples."
            ],
            challenge_prompt: "Coloque o celular em modo avião por 30 minutos enquanto faz 1 coisa só.",
            challenge_when: "hoje",
            challenge_observable: "Como você se sentiu — calmo, ansioso, distraído.",
            learning_objective: "Experimentar 30 min sem interrupção e perceber o efeito no próprio foco.",
            illustration_key: "bell",
            source: "Gloria Mark (UC Irvine)",
            framework: "dado contra-intuitivo"
          },
          {
            slug: "foco-profundo-25min",
            title: "Por que 25 minutos podem valer mais que 2 horas?",
            hook: "Foco profundo é o novo QI.",
            angle: "Deep work de Cal Newport. Bloco curto de atenção total > horas de meia-atenção.",
            central_insight: "Quem treina 25 minutos seguidos de foco real, em poucos meses, deixa para trás quem 'estuda 2 horas com celular do lado'.",
            curiosity_facts: [
              "Cal Newport (Georgetown): blocos de 25-50 min são o sweet spot do cérebro.",
              "Estudo da Universidade do Michigan: 1h focada ensina mais que 4h fragmentadas.",
              "Foco é músculo — fica mais forte cada vez que você o usa, e mais fraco cada vez que cede."
            ],
            challenge_prompt: "Faça 1 bloco de 25 minutos com celular fora da vista, fazendo uma coisa só.",
            challenge_when: "hoje",
            challenge_observable: "Quanto rendeu vs. um dia normal.",
            learning_objective: "Aplicar 1 bloco de Pomodoro de 25 min e comparar com sessão fragmentada.",
            illustration_key: "target",
            source: "Cal Newport",
            framework: "regra prática"
          },
          {
            slug: "habito-2-minutos",
            title: "Como criar um hábito novo sem sofrer?",
            hook: "Vontade morre em planos grandes. Vive em 2 minutos.",
            angle: "Lei 3 de James Clear (Hábitos Atômicos): faça o hábito de entrada ridiculamente pequeno.",
            central_insight: "Se o novo hábito cabe em 2 minutos, você começa. Se cabe em 1 hora, você desiste no terceiro dia.",
            curiosity_facts: [
              "James Clear: 'ler 1 página por dia' venceu 'ler 1 hora por dia' em 100% dos casos que ele acompanhou.",
              "O cérebro guarda a IDENTIDADE da repetição, não o tamanho — fez 1x = 'sou alguém que faz isso'.",
              "Hábito é voto de identidade: cada repetição é um voto em quem você quer ser."
            ],
            challenge_prompt: "Pegue 1 hábito que você quer ter e crie a versão de 2 minutos. Faça hoje.",
            challenge_when: "hoje",
            challenge_observable: "Se foi mais fácil do que o cérebro previa.",
            learning_objective: "Reduzir 1 desejo de hábito à sua versão de 2 min e cumprir 1x.",
            illustration_key: "spark",
            source: "James Clear",
            framework: "regra prática + paradoxo"
          }
        ]
      },
      {
        slug: "vies-cerebro",
        title: "Seu Cérebro Mente Pra Você",
        arc_hook: "Quem conhece os truques do próprio cérebro pensa melhor que 90% das pessoas.",
        position: 2,
        missions: [
          {
            slug: "vies-confirmacao",
            title: "Por que você acredita em coisas que confirmam o que já pensa?",
            hook: "O cérebro é advogado de defesa, não juiz.",
            angle: "Viés de confirmação. Procuramos provas a favor — e ignoramos contra.",
            central_insight: "Se você só procura provas do que já acha, você nunca aprende — só confirma.",
            curiosity_facts: [
              "Estudos clássicos mostram: damos 2x mais peso a evidência que confirma do que à que contradiz.",
              "Em discussões online, raramente mudamos de opinião — geralmente reforçamos a inicial.",
              "Cientistas treinam por anos pra ATIVAMENTE buscar refutar suas próprias hipóteses."
            ],
            challenge_prompt: "Escolha 1 opinião sua e procure 3 argumentos contra ela. Honestamente.",
            challenge_when: "esta-semana",
            challenge_observable: "Se algum argumento te fez vacilar de verdade.",
            learning_objective: "Aplicar busca ativa por contra-evidência em 1 opinião própria.",
            illustration_key: "search",
            source: "Daniel Kahneman",
            framework: "experimento mental"
          },
          {
            slug: "memoria-falsa",
            title: "Como o cérebro inventa lembranças?",
            hook: "Você lembra. Tem certeza?",
            angle: "Memória é reconstrução, não gravação. Cada vez que lembra, edita.",
            central_insight: "Quem confia 100% na própria memória paga caro — ela costura buracos com inventos sem te avisar.",
            curiosity_facts: [
              "Elizabeth Loftus (Univ. Califórnia) mostrou: dá pra implantar lembranças falsas inteiras com poucas frases.",
              "A cada vez que você 'recorda' algo, o cérebro reescreve a memória (e ela muda um pouquinho).",
              "Testemunhos oculares em tribunais são uma das principais causas de condenação errada."
            ],
            challenge_prompt: "Pergunte pra 2 pessoas um detalhe específico de uma lembrança comum. Compare.",
            challenge_when: "esta-semana",
            challenge_observable: "Quantas versões diferentes você ouviu.",
            learning_objective: "Comparar versões de um mesmo evento entre pessoas e notar divergências.",
            illustration_key: "book",
            source: "Elizabeth Loftus",
            framework: "paradoxo + caso real"
          },
          {
            slug: "pensar-devagar",
            title: "Quando o pensamento rápido te trai?",
            hook: "Você tem 2 cérebros — um pula, outro pensa.",
            angle: "Sistema 1 vs Sistema 2 de Kahneman. Rápido decide quase tudo automaticamente; raramente acordamos o lento.",
            central_insight: "Quem só usa o cérebro rápido vive de palpite. Quem treina o devagar, decide melhor sob pressão.",
            curiosity_facts: [
              "Kahneman ganhou Nobel mostrando: 95% das nossas decisões são automáticas, sistema-1.",
              "Sistema-2 (lento) só liga quando algo é difícil — senão, é palpite.",
              "Teste clássico: bastão + bola = R$1,10; bastão custa R$1 a mais. Quanto a bola? Quase todo mundo erra de cara."
            ],
            challenge_prompt: "Antes da próxima decisão importante hoje, espere 60 segundos antes de decidir.",
            challenge_when: "hoje",
            challenge_observable: "Se a resposta mudou.",
            learning_objective: "Inserir pausa de 60s entre estímulo e decisão em 1 caso real.",
            illustration_key: "clock",
            source: "Daniel Kahneman",
            framework: "dado científico"
          }
        ]
      }
    ]
  },

  # ───────────────────────────────────────────────────────────────────
  # 💪 Corpo & Saúde  (showcase fully populated)
  # ───────────────────────────────────────────────────────────────────
  {
    slug: "corpo-saude",
    name: "Corpo & Saúde",
    tagline: "Cuidar do corpo como ferramenta poderosa",
    color: "#F59E0B",
    icon: "muscle",
    position: 2,
    angle: "Sono, alimentação real, exercício, respiração, telas. Concreto, sem moralizar — sempre 1 ação aplicável hoje.",
    trails: [
      {
        slug: "energia-do-dia",
        title: "De Onde Vem a Energia Real?",
        arc_hook: "Pequenas decisões diárias multiplicam (ou roubam) sua energia.",
        position: 1,
        missions: [
          {
            slug: "acucar-engana-cerebro",
            title: "Por que açúcar engana seu cérebro?",
            hook: "O 'cansaço' das 3 da tarde quase nunca é cansaço.",
            angle: "Pico + queda de glicose. Cérebro confunde sede + queda de açúcar com fome.",
            central_insight: "Se você come doce pra ter energia, em 30 minutos você vai sentir MENOS energia — e querer mais doce.",
            curiosity_facts: [
              "Açúcar entra rápido na corrente e o corpo dispara insulina pra defesa — resultado: queda de energia em ~30 min.",
              "Ultraprocessados são desenhados pra você nunca sentir saciedade.",
              "A indústria estuda o 'bliss point' — combinação exata de açúcar/sal/gordura que vicia."
            ],
            challenge_prompt: "Troque 1 lanche ultraprocessado por fruta + água hoje. Marque como se sentiu 1h depois.",
            challenge_when: "hoje",
            challenge_observable: "Se a fome voltou rápido (doce) ou demorou (fruta).",
            learning_objective: "Substituir 1 lanche industrializado e comparar saciedade.",
            illustration_key: "apple",
            source: "Michael Pollan",
            framework: "paradoxo + caso"
          },
          {
            slug: "noite-ruim-apaga-semana",
            title: "O que acontece quando você dorme mal?",
            hook: "1 noite ruim apaga aprendizado de uma semana inteira.",
            angle: "Sono consolida memória. Sem ele, o dia 'não salva'.",
            central_insight: "Se você dorme menos de 7h, seu cérebro joga fora boa parte do que tentou aprender no dia.",
            curiosity_facts: [
              "Matthew Walker (Berkeley): privação de sono reduz capacidade de aprender em ~40%.",
              "Dormir é quando o cérebro 'salva o arquivo' do dia — sem salvar, perde.",
              "Tela 30 min antes de dormir bloqueia melatonina por até 90 min."
            ],
            challenge_prompt: "Hoje: nada de tela 30 minutos antes de dormir. Veja como acorda amanhã.",
            challenge_when: "hoje",
            challenge_observable: "Disposição ao acordar — pior, igual, melhor.",
            learning_objective: "Cumprir 1 noite com 30 min sem tela antes de dormir.",
            illustration_key: "moon",
            source: "Matthew Walker",
            framework: "dado contra-intuitivo"
          },
          {
            slug: "10-min-movimento",
            title: "Por que 10 minutos por dia vencem 1 hora no sábado?",
            hook: "Consistência derrota intensidade.",
            angle: "Hipócrates: 'caminhar é o melhor remédio'. O corpo recompensa regularidade.",
            central_insight: "Se você se mexe 10 min todo dia, em 1 mês está mais forte que quem 'maratona' 1 hora no sábado.",
            curiosity_facts: [
              "Walter Bortz (Stanford): regularidade vence intensidade em quase todo indicador de saúde.",
              "O corpo precisa do sinal DIÁRIO 'eu mexo' pra calibrar humor, sono, foco.",
              "Mesmo 5 min de movimento intenso melhoram humor pelas próximas 4 horas."
            ],
            challenge_prompt: "Faça 10 min de movimento HOJE: andar, dançar, pular corda, jogar bola. Conta.",
            challenge_when: "hoje",
            challenge_observable: "Humor + disposição depois.",
            learning_objective: "Cumprir 10 min de movimento real em 1 dia.",
            illustration_key: "muscle",
            source: "Hipócrates + Bortz",
            framework: "regra simples"
          },
          {
            slug: "agua-confunde-fome",
            title: "Quando você acha que está com fome, está com sede?",
            hook: "70% das 'fomes' das 16h somem com 1 copo d'água.",
            angle: "Corpo confunde sede + cansaço + fome. Hidratar primeiro é gratuito.",
            central_insight: "Se você não bebeu água há 3 horas e bate fome ou cansaço, beba água primeiro — 70% das vezes resolve.",
            curiosity_facts: [
              "2% de desidratação reduz humor, foco e energia perceptivelmente.",
              "Quase ninguém sente sede ANTES de já estar desidratado.",
              "Um copo de água pode acabar com a 'fome falsa' em 10 minutos."
            ],
            challenge_prompt: "Antes do próximo lanche, beba 1 copo de água e espere 10 min. Veja se ainda quer.",
            challenge_when: "hoje",
            challenge_observable: "Se a fome era real ou era sede.",
            learning_objective: "Aplicar o teste da água antes de 1 lanche.",
            illustration_key: "drop",
            source: "Univ. Connecticut",
            framework: "dado prático"
          }
        ]
      },
      {
        slug: "tempo-de-tela",
        title: "Você Comanda as Telas?",
        arc_hook: "Apps foram desenhados pra te prender. Você foi desenhado pra escolher.",
        position: 2,
        missions: [
          {
            slug: "tela-pre-sono",
            title: "Por que tela à noite te rouba o sono?",
            hook: "Luz azul engana seu cérebro pensando que é dia.",
            angle: "Melatonina suprimida por luz. Resultado: demora pra dormir + sono pior.",
            central_insight: "Se você usa tela na cama, o seu cérebro acha que é meio-dia — e seu sono paga o preço.",
            curiosity_facts: [
              "Luz azul de tela suprime melatonina por até 90 minutos.",
              "Quem deixa o celular fora do quarto dorme 1h a mais em média.",
              "Sono pré-meia-noite vale o dobro do sono pós (em consolidação de memória)."
            ],
            challenge_prompt: "Deixe o celular fora do quarto hoje. Acorde amanhã e marque como se sentiu.",
            challenge_when: "hoje",
            challenge_observable: "Qualidade do sono + humor ao acordar.",
            learning_objective: "Dormir 1 noite com celular fora do quarto.",
            illustration_key: "moon",
            source: "Andrew Huberman",
            framework: "dado + experimento"
          },
          {
            slug: "scroll-infinito-mente",
            title: "Por que scroll infinito vicia tanto?",
            hook: "Você desce a tela. E desce. E não para.",
            angle: "Recompensa variável de Skinner — mesmo mecanismo da máquina de cassino.",
            central_insight: "Se a próxima rolagem PODE trazer algo legal (mas pode não trazer), seu cérebro vai puxar por horas.",
            curiosity_facts: [
              "Scroll infinito foi inventado em 2006 — o engenheiro original já se arrependeu publicamente.",
              "B.F. Skinner mostrou: recompensa imprevisível prende mais que recompensa certa.",
              "Cassinos usam exatamente a mesma técnica das redes sociais."
            ],
            challenge_prompt: "Coloque um TIMER de 10 min antes de abrir rede social hoje. Pare quando tocar.",
            challenge_when: "hoje",
            challenge_observable: "Quão difícil foi parar quando tocou.",
            learning_objective: "Limitar 1 sessão de scroll a 10 min via timer.",
            illustration_key: "phone",
            source: "B.F. Skinner",
            framework: "paradoxo + caso"
          },
          {
            slug: "atencao-sem-tela",
            title: "Como recuperar sua atenção?",
            hook: "Tédio é o primeiro passo da criatividade.",
            angle: "Cal Newport — minimalismo digital. Reaprender a ficar sem estímulo.",
            central_insight: "Se você nunca fica entediado, você nunca tem ideias novas — o cérebro precisa de espaço vazio pra criar.",
            curiosity_facts: [
              "Estudos: 6 min de tédio antes de tarefa criativa AUMENTA originalidade em ~25%.",
              "Crianças que nunca ficam entediadas têm menos imaginação espontânea.",
              "Cal Newport: 'silêncio é o oxigênio do pensamento profundo'."
            ],
            challenge_prompt: "Caminhe 15 min HOJE sem celular, sem fone. Só andando.",
            challenge_when: "hoje",
            challenge_observable: "Ideias ou pensamentos que apareceram.",
            learning_objective: "Cumprir 15 min de movimento sem estímulo digital.",
            illustration_key: "walk",
            source: "Cal Newport",
            framework: "experimento"
          }
        ]
      }
    ]
  },

  # ───────────────────────────────────────────────────────────────────
  # 💰 Dinheiro & Vida Real
  # ───────────────────────────────────────────────────────────────────
  {
    slug: "dinheiro-vida",
    name: "Dinheiro & Vida Real",
    tagline: "Inteligência financeira e responsabilidade",
    color: "#10B981",
    icon: "coin",
    position: 3,
    angle: "Valor, troca, juros, impulso vs. planejamento, querer ≠ precisar. Sem assustar, sem materializar.",
    trails: [
      {
        slug: "impulso-vs-planejamento",
        title: "Quem manda no seu dinheiro?",
        arc_hook: "Quem não decide quando gasta, gasta sempre.",
        position: 1,
        missions: [
          {
            slug: "impulso-perigoso",
            title: "Por que comprar por impulso é uma armadilha?",
            hook: "Você quer agora — daqui a 1 dia, talvez nem queira mais.",
            angle: "Recompensa imediata vs. arrependimento posterior. Truque das 24h.",
            central_insight: "Se você espera 24 horas antes de comprar algo, mais da metade do desejo evapora — e revela o que era impulso.",
            curiosity_facts: [
              "Marketing é desenhado pra você comprar HOJE, não pra você comprar BEM.",
              "Estudo: ~60% dos itens comprados por impulso teriam sido recusados se houvesse 24h de espera.",
              "O cérebro distingue mal 'eu quero' de 'eu preciso'."
            ],
            challenge_prompt: "Identifique 1 coisa que está com vontade de comprar. Espere 24h antes de comprar.",
            challenge_when: "hoje",
            challenge_observable: "Se ainda quer amanhã na mesma intensidade.",
            learning_objective: "Aplicar a regra das 24h em 1 desejo de compra.",
            illustration_key: "coin",
            source: "Dave Ramsey",
            framework: "regra prática"
          },
          {
            slug: "querer-precisar",
            title: "Quase tudo que você 'precisa' é desejo?",
            hook: "Categoria errada = grana errada.",
            angle: "Necessidade (sobrevivência básica) vs. desejo (querer). Marketing borra a linha de propósito.",
            central_insight: "Quem aprende cedo a diferença entre N e D, em 30 anos junta 10× mais que quem não aprendeu.",
            curiosity_facts: [
              "Necessidades reais (comida básica, abrigo, saúde) são poucas. Quase tudo o resto é desejo.",
              "Marcas falam 'você PRECISA disso' justamente porque sabem que é desejo.",
              "Provérbio: 'rico não é quem tem mais — é quem precisa de menos'."
            ],
            challenge_prompt: "Liste seus últimos 10 gastos e marque cada um como N ou D. Sem se julgar.",
            challenge_when: "esta-semana",
            challenge_observable: "Quantos D você jurava que eram N.",
            learning_objective: "Classificar 10 gastos recentes como necessidade ou desejo.",
            illustration_key: "list",
            source: "Provérbios + Dave Ramsey",
            framework: "regra prática"
          },
          {
            slug: "guardar-mais-que-gastar",
            title: "Por que pessoas ricas guardam mais que gastam?",
            hook: "Saldo positivo cresce — saldo zero some.",
            angle: "Disciplina de poupar > tamanho do salário. Conceito de pagar-se-primeiro.",
            central_insight: "Se você guarda primeiro e gasta o resto, sobra dinheiro; se gasta primeiro e tenta guardar o resto, nunca sobra.",
            curiosity_facts: [
              "Pesquisa Stanford: pessoas que automatizam poupança guardam ~3× mais que as que tentam 'no fim do mês'.",
              "Provérbio: 'rico não é quem ganha muito — é quem guarda muito'.",
              "Bilionários como Buffett vivem com fração do que ganham. Pobreza mental ≠ saldo bancário."
            ],
            challenge_prompt: "Da sua próxima mesada/dinheiro, separe 10% pra guardar ANTES de qualquer gasto.",
            challenge_when: "esta-semana",
            challenge_observable: "Se sobra o mesmo no fim — ou se sobra mais.",
            learning_objective: "Reservar 10% de uma entrada antes de gastar.",
            illustration_key: "coin",
            source: "George Clason (Pai Rico) + Provérbios",
            framework: "regra prática"
          },
          {
            slug: "dinheiro-vira-dinheiro",
            title: "Como dinheiro vira mais dinheiro sozinho?",
            hook: "R$1 hoje vale R$10 daqui a 20 anos — sem você mexer.",
            angle: "Juros compostos. Tempo é o ingrediente raro.",
            central_insight: "Se você começa cedo e deixa o tempo trabalhar, juros pequenos viram montanha — porque o ganho começa a ganhar também.",
            curiosity_facts: [
              "Einstein chamou juros compostos de 'a 8ª maravilha do mundo' — quem entende, ganha; quem não, paga.",
              "R$100/mês a 10%/ano viram ~R$70 mil em 20 anos. R$760 mil em 40 anos. Tempo dobra dobra.",
              "Buffett ficou 99% rico DEPOIS dos 50 anos — não pelo gênio, pelo tempo composto."
            ],
            challenge_prompt: "Use uma calculadora de juros compostos. Simule R$50/mês por 30 anos a 10%.",
            challenge_when: "hoje",
            challenge_observable: "Quanto vira — e como você sente o número.",
            learning_objective: "Simular 1 cenário real de juros compostos.",
            illustration_key: "coin",
            source: "Morgan Housel + Albert Einstein",
            framework: "experimento numérico"
          }
        ]
      }
    ]
  },

  # ───────────────────────────────────────────────────────────────────
  # 🤝 Caráter & Virtudes
  # ───────────────────────────────────────────────────────────────────
  {
    slug: "carater",
    name: "Caráter & Virtudes",
    tagline: "Formar caráter forte",
    color: "#EF4444",
    icon: "target",
    position: 4,
    angle: "Honestidade, coragem, gratidão, perseverança, palavra. Sem sermão — através de cena, dilema, escolha.",
    trails: [
      {
        slug: "palavra-dada",
        title: "Sua palavra vale o que?",
        arc_hook: "Quem cumpre o que diz, em 10 anos vira raro.",
        position: 1,
        missions: [
          {
            slug: "mentiras-pequenas-custam",
            title: "Por que mentiras pequenas custam caro?",
            hook: "Mentir 1 vez é fácil. Mentir 100 vezes é prisão.",
            angle: "Cada mentira pequena exige 3 maiores pra sustentar.",
            central_insight: "Se você mente o pequeno, vai precisar mentir o grande — só pra a primeira mentira continuar de pé.",
            curiosity_facts: [
              "Aristóteles dizia: virtude é hábito — caráter é o que você FAZ repetidamente.",
              "Quem mente uma vez por dia entra num ciclo: precisa lembrar o que mentiu pra quem.",
              "Pessoas honestas são menos estressadas — não têm histórias múltiplas pra manter."
            ],
            challenge_prompt: "Identifique 1 mentira pequena que você se permitiu essa semana. Conserte.",
            challenge_when: "esta-semana",
            challenge_observable: "Como se sentiu depois de consertar.",
            learning_objective: "Identificar e corrigir 1 mentira recente.",
            illustration_key: "target",
            source: "Provérbios + Aristóteles",
            framework: "metáfora + experimento"
          },
          {
            slug: "compromisso-cumprido",
            title: "O que faz alguém confiável?",
            hook: "Confiança são depósitos. Quebra é saque.",
            angle: "Cada compromisso cumprido deposita; cada falha saca.",
            central_insight: "Quem cumpre o pequeno todo dia constrói algo invisível — e raríssimo: confiança.",
            curiosity_facts: [
              "Stephen Covey: relação tem 'conta bancária emocional' — deposite ou saque.",
              "1 falha grande pode anular 20 depósitos.",
              "Pessoas confiáveis ganham, em média, 30% mais ao longo da carreira."
            ],
            challenge_prompt: "Faça 1 compromisso pequeno hoje (ex: 'volto em 10 min'). Cumpra exato.",
            challenge_when: "hoje",
            challenge_observable: "Se a pessoa percebeu (geralmente percebe).",
            learning_objective: "Cumprir 1 compromisso exato em horário e palavra.",
            illustration_key: "check",
            source: "Stephen Covey",
            framework: "metáfora financeira"
          },
          {
            slug: "gratidao-muda-vista",
            title: "Por que gratidão muda o que você vê?",
            hook: "Sua cabeça é uma lente — gratidão muda o filtro.",
            angle: "Gratidão treinada vira ferramenta atencional: você passa a notar o que estava lá.",
            central_insight: "Se você lista 3 coisas boas todo dia, em 30 dias começa a NOTAR coisas boas sem listar — o filtro mudou.",
            curiosity_facts: [
              "Robert Emmons (UC Davis): 30 dias de diário de gratidão reduz sintomas depressivos em ~25%.",
              "Cérebro grato libera dopamina + serotonina ao MESMO tempo — combinação rara.",
              "Pessoas gratas dormem melhor, segundo 11 estudos diferentes — não é placebo."
            ],
            challenge_prompt: "Antes de dormir hoje, escreva 3 coisas específicas pelas quais você é grato. Pequenas valem.",
            challenge_when: "hoje",
            challenge_observable: "Se notou algo bom que normalmente passaria batido.",
            learning_objective: "Listar 3 gratidões específicas em 1 noite.",
            illustration_key: "sparkle",
            source: "Robert Emmons (Psicologia Positiva)",
            framework: "experimento + ciência"
          },
          {
            slug: "coragem-nao-ausencia-medo",
            title: "Coragem é a ausência do medo?",
            hook: "Quem age sem medo é cego — não corajoso.",
            angle: "Coragem = agir APESAR do medo. Medo é sinal, não inimigo.",
            central_insight: "Se você esperar o medo passar pra agir, nunca age — coragem é dar 1 passo enquanto o medo ainda fala.",
            curiosity_facts: [
              "Soldados condecorados, em entrevista, descrevem MAIS medo que a média — só agiram apesar.",
              "Aristóteles: coragem é a virtude MÃE — sem ela, nenhuma outra virtude resiste à pressão.",
              "Cérebro com medo libera adrenalina — mesma química que dá foco extremo."
            ],
            challenge_prompt: "Faça hoje 1 coisa pequena que você está adiando por medo (uma conversa, um pedido, um 'não').",
            challenge_when: "hoje",
            challenge_observable: "Como se sente DEPOIS — quase sempre alívio.",
            learning_objective: "Fazer 1 ação adiada por medo.",
            illustration_key: "bolt",
            source: "Marco Aurélio + Aristóteles",
            framework: "reframe + ação"
          }
        ]
      }
    ]
  },

  # ───────────────────────────────────────────────────────────────────
  # 💻 Tecnologia & Criação
  # ───────────────────────────────────────────────────────────────────
  {
    slug: "tecnologia-criacao",
    name: "Tecnologia & Criação",
    tagline: "Sair do consumir e entrar no criar",
    color: "#3B82F6",
    icon: "bolt",
    position: 5,
    angle: "Como apps, IA, internet, computadores tomam decisões. Foco em entender pra criar, não só consumir.",
    trails: [
      {
        slug: "como-tecnologia-funciona",
        title: "Como as máquinas pensam?",
        arc_hook: "Quem entende como a máquina decide, decide melhor sobre ela.",
        position: 1,
        missions: [
          {
            slug: "como-app-funciona",
            title: "Como um app realmente funciona?",
            hook: "Cada toque é uma conversa entre você e milhões de linhas de código.",
            angle: "Frontend × backend × banco — explicado com a metáfora do restaurante.",
            central_insight: "Se você entende que app é 'pedido → cozinha → entrega', você nunca mais olha um botão como 'mágica'.",
            curiosity_facts: [
              "App = interface (cardápio) + servidor (cozinha) + banco de dados (estoque). Sempre.",
              "Cada toque vira uma requisição de rede que viaja a milhões de km/segundo.",
              "Quase todo app que você usa hoje foi escrito por alguém que aprendeu sozinho."
            ],
            challenge_prompt: "Abra 1 app e tente identificar onde o 'pedido' vai (banco? servidor? local?).",
            challenge_when: "hoje",
            challenge_observable: "Quanto da 'mágica' deixa de ser mágica.",
            learning_objective: "Identificar componentes (UI/servidor/dados) em 1 app conhecido.",
            illustration_key: "phone",
            source: "Pensamento computacional",
            framework: "metáfora"
          },
          {
            slug: "como-ia-decide",
            title: "Como uma IA toma decisão?",
            hook: "IA não pensa — ela conta.",
            angle: "Modelos não 'entendem' — calculam probabilidade de próximo token.",
            central_insight: "Se você acha que IA pensa, vai confiar demais. Se entende que IA estima probabilidade, sabe quando duvidar.",
            curiosity_facts: [
              "ChatGPT prevê literalmente 'qual palavra vem a seguir' com base em padrões de texto.",
              "Uma IA não 'sabe' — ela acerta com alta probabilidade no que parece resposta certa.",
              "Por isso IA 'alucina' — quando o padrão favorece resposta fluente, mesmo que errada."
            ],
            challenge_prompt: "Pergunte algo MUITO específico a uma IA. Cheque a resposta numa fonte real.",
            challenge_when: "hoje",
            challenge_observable: "Se a IA inventou ou acertou.",
            learning_objective: "Detectar 1 caso de alucinação ou imprecisão de IA.",
            illustration_key: "spark",
            source: "Fundamentos de ML",
            framework: "experimento"
          },
          {
            slug: "como-internet-conhece-voce",
            title: "Como a internet sabe o que você gosta?",
            hook: "Você assistiu 2 vídeos de cachorro — e o feed virou cachorros.",
            angle: "Algoritmos de recomendação: cada toque é um voto silencioso.",
            central_insight: "Se você entende que cada toque vira voto pro algoritmo, você passa a escolher o que vê — em vez de ser escolhido por ele.",
            curiosity_facts: [
              "Algoritmo de recomendação assiste VOCÊ assistindo: tempo, pausas, repetições, scroll.",
              "TikTok identifica padrão em ~40 minutos — Netflix leva ~2 horas.",
              "'Personalização' soa amigável — é o termo elegante pra 'previsão de comportamento'."
            ],
            challenge_prompt: "Abra seu feed favorito. Note os 5 primeiros itens. Eles confirmam o que você JÁ pensa?",
            challenge_when: "hoje",
            challenge_observable: "Quantos abrem horizonte vs. fecham bolha.",
            learning_objective: "Reconhecer bolha algorítmica em 1 feed real.",
            illustration_key: "search",
            source: "Tristan Harris + Cathy O'Neil",
            framework: "experimento + cena"
          },
          {
            slug: "criador-vs-consumidor",
            title: "Criar muda você mais que consumir?",
            hook: "Mil horas assistindo ≠ uma hora criando.",
            angle: "Aprendizado ativo (criar) bate consumo passivo em retenção.",
            central_insight: "Se você só consome, você aprende sobre o que outros fizeram; se você cria, descobre o que VOCÊ pensa.",
            curiosity_facts: [
              "Cone de Edgar Dale: retemos ~10% do que lemos, ~90% do que ensinamos ou criamos.",
              "Toda figura de criatividade adulta (cientista, artista, engenheiro) começou criando coisas ruins na adolescência.",
              "Plataformas tornam consumir gratuito e infinito — criar segue exigindo esforço e fricção."
            ],
            challenge_prompt: "Pegue 30 minutos hoje pra CRIAR algo (um desenho, um texto, um pequeno código, uma melodia). Pode ser ruim.",
            challenge_when: "hoje",
            challenge_observable: "Como se sente DEPOIS de criar vs. depois de scrollar.",
            learning_objective: "Criar 1 artefato em 30 minutos.",
            illustration_key: "magic",
            source: "Edgar Dale + Austin Kleon",
            framework: "experimento"
          }
        ]
      }
    ]
  },

  # ───────────────────────────────────────────────────────────────────
  # 🛠️ Resolver Problemas
  # ───────────────────────────────────────────────────────────────────
  {
    slug: "resolver-problemas",
    name: "Resolver Problemas",
    tagline: "Autonomia intelectual",
    color: "#0EA5E9",
    icon: "puzzle",
    position: 6,
    angle: "Estratégia, decomposição, decisão sob incerteza, criatividade. Erro como dado, não drama.",
    trails: [
      {
        slug: "quando-trava",
        title: "Quando trava — o que fazer?",
        arc_hook: "Estratégia vence força.",
        position: 1,
        missions: [
          {
            slug: "quebrar-problema",
            title: "Como quebrar um problema grande?",
            hook: "Problema gigante se rende a 4 perguntas.",
            angle: "Método Polya — 4 passos pra destravar qualquer problema.",
            central_insight: "Se você não consegue resolver, é porque o problema ainda está grande demais — quebre em pedaços menores.",
            curiosity_facts: [
              "Polya (Princeton, 1945): 4 perguntas — sei o quê? quero o quê? já vi parecido? dá pra dividir?",
              "Programadores chamam isso de 'decomposição' — habilidade #1 do pensamento computacional.",
              "Engenheiros da NASA usam o mesmo método pra mandar foguetes pra Marte."
            ],
            challenge_prompt: "Pegue 1 problema atual seu (escola, conflito, projeto) e aplique as 4 perguntas no caderno.",
            challenge_when: "hoje",
            challenge_observable: "Se destravou.",
            learning_objective: "Aplicar as 4 perguntas de Polya em 1 problema real.",
            illustration_key: "puzzle",
            source: "George Polya",
            framework: "método em 4 passos"
          },
          {
            slug: "erro-dado",
            title: "Por que errar te ajuda?",
            hook: "Cérebro só cresce quando dá errado.",
            angle: "Neuroplasticidade dispara no erro — não no acerto.",
            central_insight: "Se você só faz o que sabe, você não aprende — o aprendizado mora exatamente onde dói errar.",
            curiosity_facts: [
              "Estudos de neuroplasticidade: o cérebro forma conexões novas DURANTE o erro, não durante o acerto.",
              "Carol Dweck: quem trata erro como 'sou ruim' fica travado. Quem trata como 'dado pra próxima' avança.",
              "Os melhores jogadores de xadrez do mundo perdem mais partidas do que ganham — eles só perdem MELHOR."
            ],
            challenge_prompt: "Liste 3 erros recentes seus. Escreva o que cada um te ENSINOU (em 1 frase cada).",
            challenge_when: "esta-semana",
            challenge_observable: "Se o erro virou conhecimento ou ficou só dor.",
            learning_objective: "Reinterpretar 3 erros recentes como aprendizado concreto.",
            illustration_key: "bolt",
            source: "Carol Dweck",
            framework: "reframe + caso"
          },
          {
            slug: "priorizar-pareto",
            title: "Como saber qual problema atacar primeiro?",
            hook: "20% das tarefas dão 80% do resultado.",
            angle: "Princípio de Pareto aplicado a decisão prática.",
            central_insight: "Se você ataca tudo na ordem que apareceu, perde tempo; se identifica o 1 problema que move 80%, o resto encolhe sozinho.",
            curiosity_facts: [
              "Vilfredo Pareto (1896): 80% da terra italiana pertencia a 20% das pessoas. Padrão repete em quase tudo.",
              "Sua nota da escola: 20% das matérias decidem 80% da média.",
              "Steve Jobs voltou à Apple e CORTOU 70% dos produtos — focou só nos 20% que importavam."
            ],
            challenge_prompt: "Liste 5 problemas atuais seus. Marque o 1 que, se resolvido, deixaria os outros menores.",
            challenge_when: "hoje",
            challenge_observable: "Quanto os outros 4 encolhem mentalmente quando você foca naquele.",
            learning_objective: "Identificar 1 problema-alavanca entre 5.",
            illustration_key: "target",
            source: "Vilfredo Pareto + Tim Ferriss",
            framework: "regra prática"
          },
          {
            slug: "5-porques",
            title: "Por que perguntar 'por quê' 5 vezes resolve quase tudo?",
            hook: "Causa real mora 5 'por quês' abaixo do sintoma.",
            angle: "Método dos 5 Porquês (Toyota): cavar até a raiz.",
            central_insight: "Se você só resolve o sintoma, ele volta; se você pergunta 'por que' até a quinta vez, encontra a causa real — e o sintoma desaparece.",
            curiosity_facts: [
              "Sakichi Toyoda (fundador da Toyota) usava 5 perguntas pra achar a raiz de qualquer defeito de fábrica.",
              "Estudos de gestão: ~80% dos problemas crônicos se resolvem ao chegar no 3-5º 'por quê'.",
              "Funciona pra problema técnico, emocional, de relação — mesma estrutura."
            ],
            challenge_prompt: "Pegue 1 frustração recente. Pergunte 'por quê?' 5 vezes seguidas. Anote o que aparece no 5º.",
            challenge_when: "hoje",
            challenge_observable: "Se a causa real é diferente do sintoma.",
            learning_objective: "Aplicar 5 'por quês' em 1 frustração real.",
            illustration_key: "search",
            source: "Sakichi Toyoda (Toyota Production System)",
            framework: "método em cadeia"
          }
        ]
      }
    ]
  },

  # ───────────────────────────────────────────────────────────────────
  # 🌎 Vida & Sociedade
  # ───────────────────────────────────────────────────────────────────
  {
    slug: "vida-sociedade",
    name: "Vida & Sociedade",
    tagline: "Entender pessoas e o mundo",
    color: "#F472B6",
    icon: "users",
    position: 7,
    angle: "Comunicação, amizade, manipulação, mídia, cooperação. Como ler pessoas e contextos.",
    trails: [
      {
        slug: "ler-pessoas",
        title: "Ler pessoas é uma arte aprendível?",
        arc_hook: "Quem escuta de verdade ganha amigos sem esforço.",
        position: 1,
        missions: [
          {
            slug: "escutar-de-verdade",
            title: "Quase ninguém escuta de verdade — por que?",
            hook: "A maioria espera a vez de falar.",
            angle: "Diferença entre ouvir esperando responder vs. ouvir pra entender.",
            central_insight: "Quem escuta 5 minutos sem interromper, em 1 conversa só, fica memorável pra vida — porque quase ninguém faz isso.",
            curiosity_facts: [
              "Stephen Covey: 'a maioria escuta com a intenção de responder, não de entender'.",
              "Estudos de comunicação: pessoas que se sentem ESCUTADAS reportam ~50% mais ligação.",
              "Conversa boa = 70% escuta, 30% fala."
            ],
            challenge_prompt: "Tenha uma conversa de 5 minutos hoje só perguntando e escutando — sem falar de si.",
            challenge_when: "hoje",
            challenge_observable: "O que você aprendeu da pessoa.",
            learning_objective: "Aplicar escuta sem interrupção em 1 conversa real.",
            illustration_key: "users",
            source: "Stephen Covey",
            framework: "experimento"
          },
          {
            slug: "manipulacao-marcas",
            title: "Como propagandas manipulam você?",
            hook: "Você é o produto.",
            angle: "Gatilhos de Cialdini: escassez, prova social, autoridade, reciprocidade.",
            central_insight: "Quem reconhece os 3 truques mais usados (escassez, prova social, status) não cai em quase nenhum.",
            curiosity_facts: [
              "Robert Cialdini estudou 6 gatilhos universais de influência — usados em quase TODA propaganda hoje.",
              "Criança vê em média ~10.000 anúncios por ano nos EUA.",
              "Influencers usam o gatilho 'prova social' (todo mundo tem) sem você perceber."
            ],
            challenge_prompt: "Pegue 1 propaganda/influencer que você gosta e tente identificar 3 gatilhos.",
            challenge_when: "hoje",
            challenge_observable: "Quão fácil é ver os gatilhos depois que sabe quais são.",
            learning_objective: "Identificar 3 gatilhos de Cialdini em 1 conteúdo.",
            illustration_key: "search",
            source: "Robert Cialdini",
            framework: "caso + checklist"
          },
          {
            slug: "silencio-constroi-confianca",
            title: "Por que silêncio constrói confiança?",
            hook: "Quem fala demais perde — quem escolhe quando, ganha.",
            angle: "Pausa estratégica em conversa: vira espaço pro outro existir.",
            central_insight: "Se você espera 2 segundos antes de responder, a outra pessoa sente que foi ouvida — e quem se sente ouvido confia.",
            curiosity_facts: [
              "Negociadores treinados deixam silêncios DEPOIS da resposta do outro — quase sempre vem mais informação.",
              "Estudo da Universidade de Groningen: pausa de 4+ segundos numa conversa indica desconforto — mas pausa de 2s indica respeito.",
              "Provérbio: 'fale só quando suas palavras forem mais valiosas que o silêncio'."
            ],
            challenge_prompt: "Em 1 conversa hoje, conte mentalmente 2 segundos antes de responder. Note o efeito.",
            challenge_when: "hoje",
            challenge_observable: "Se a pessoa fala mais, ou se você ouve algo novo.",
            learning_objective: "Aplicar pausa de 2s em 1 conversa real.",
            illustration_key: "users",
            source: "Provérbios + Chris Voss",
            framework: "experimento social"
          },
          {
            slug: "feedback-que-serve",
            title: "Como dar feedback que serve, não que machuca?",
            hook: "Crítica vira fofoca quando não dá direção.",
            angle: "Feedback formativo: específico, oportuno, sobre comportamento (não pessoa).",
            central_insight: "Se você diz 'você é desorganizado', você ataca; se diz 'isso aqui caiu no chão e ninguém viu', você descreve — e descrição é a única coisa que muda algo.",
            curiosity_facts: [
              "Modelo SBI (Situation-Behavior-Impact): situação → comportamento → impacto. Sem julgamento moral.",
              "Estudos de gestão: feedback genérico ('seja melhor') tem efeito ZERO; feedback específico aumenta performance em ~30%.",
              "Quem recebe feedback bem dado quer MAIS feedback — quem recebe vago vira defensivo."
            ],
            challenge_prompt: "Pegue 1 feedback que queria dar mas vinha como julgamento. Reescreva no formato Situação-Comportamento-Impacto.",
            challenge_when: "hoje",
            challenge_observable: "Como você se sente lendo a versão refeita — geralmente menos braba.",
            learning_objective: "Reescrever 1 feedback no formato SBI.",
            illustration_key: "check",
            source: "Center for Creative Leadership (SBI Model)",
            framework: "modelo em 3 passos"
          }
        ]
      }
    ]
  }
].freeze

# ---------- Apply ----------

V2_SUBJECT_SLUGS = (
  CURRICULUM_V2.map { |s| s[:slug] } +
  # v3 — Currículo de curiosidade-do-mundo (seeded in academy_curiosidade_concepts.rb).
  # Listed here so the "deactivate stale subjects" sweep at the end keeps them active.
  %w[como-o-mundo-funciona curiosidades-do-corpo palavras-origens]
).freeze
V1_LEGACY_SUBJECT_SLUGS = %w[inteligencia carater_v1 relacionamentos dinheiro saude fe-sentido].freeze

# v5: load concept catalog FIRST so each mission can be saved with its 1:1
# concept_id at create time. The concepts file also re-patches concept_id
# on a second pass (idempotent) once missions exist.
load Rails.root.join("db/seeds/academy_concepts.rb")

# Subject-slug → fallback concept slug (used when MISSION_CONCEPTS has no entry).
SUBJECT_FALLBACK_CONCEPT = {
  "mente-forte"          => "atencao",
  "corpo-saude"          => "homeostase",
  "dinheiro-vida"        => "tradeoff",
  "carater"              => "virtude-habito",
  "tecnologia-criacao"   => "pensamento-computacional",
  "resolver-problemas"   => "decomposicao",
  "vida-sociedade"       => "comunicacao"
}.freeze

CONCEPT_ID_BY_SLUG = ::Academy::Concept.pluck(:slug, :id).to_h

def resolve_concept_id(mission_slug, subject_slug)
  primary = MISSION_CONCEPTS[mission_slug]&.first
  CONCEPT_ID_BY_SLUG[primary] ||
    CONCEPT_ID_BY_SLUG[SUBJECT_FALLBACK_CONCEPT[subject_slug]] ||
    CONCEPT_ID_BY_SLUG.values.first
end

ActiveRecord::Base.transaction do
  CURRICULUM_V2.each do |subject_attrs|
    trails_attrs = subject_attrs[:trails]
    s_attrs = subject_attrs.except(:trails)

    subject = ::Academy::Subject.find_or_initialize_by(slug: s_attrs[:slug])
    subject.assign_attributes(s_attrs.merge(active: true))
    subject.save!

    new_trail_slugs = trails_attrs.map { |t| t[:slug] }
    new_mission_slugs_for_subject = trails_attrs.flat_map { |t| t[:missions].map { |m| m[:slug] } }

    trails_attrs.each do |trail_attrs|
      missions_attrs = trail_attrs[:missions]
      t_attrs = trail_attrs.except(:missions)

      trail = ::Academy::Trail.find_or_initialize_by(subject_id: subject.id, slug: t_attrs[:slug])
      trail.assign_attributes(t_attrs.merge(active: true))
      trail.save!

      missions_attrs.each_with_index do |m, idx|
        mission = subject.missions.find_or_initialize_by(slug: m[:slug])
        mission.assign_attributes(
          trail_id: trail.id,
          title: m[:title],
          hook: m[:hook],
          angle: m[:angle].to_s.strip,
          source: m[:source],
          framework: m[:framework],
          sacada: m[:central_insight], # back-compat: legacy `sacada` mirrors the v2 insight
          central_insight: m[:central_insight],
          challenge_prompt: m[:challenge_prompt],
          challenge_when: m[:challenge_when],
          challenge_observable: m[:challenge_observable],
          curiosity_facts: m[:curiosity_facts] || [],
          illustration_key: m[:illustration_key],
          learning_objective: m[:learning_objective],
          concept_id: resolve_concept_id(m[:slug], subject.slug),
          position_in_trail: idx,
          order_in_subject: trail.position * 100 + idx,
          points_reward: m[:points_reward] || 25,
          active: true
        )
        mission.save!
      end
    end

    # Deactivate missions in this subject that aren't in the new v2 set
    # (handles old v1 content that lived under the same subject slug e.g.
    # `carater` which v1 also used).
    subject.missions.where.not(slug: new_mission_slugs_for_subject).update_all(active: false)

    # Deactivate trails that aren't part of v2 anymore.
    subject.trails.where.not(slug: new_trail_slugs).update_all(active: false)

  end

  # Soft-deactivate v1 subjects (those NOT in V2) and their missions.
  # Their progress and medal history stay intact.
  stale_subject_ids = ::Academy::Subject.where.not(slug: V2_SUBJECT_SLUGS).pluck(:id)
  if stale_subject_ids.any?
    ::Academy::Subject.where(id: stale_subject_ids).update_all(active: false)
    ::Academy::Mission.where(subject_id: stale_subject_ids).update_all(active: false)
  end
end

puts "✓ Academy v2 seeded: " \
     "#{::Academy::Subject.active.count} áreas ativas · " \
     "#{::Academy::Trail.active.count} trilhas · " \
     "#{::Academy::Mission.active.count} aulas ativas " \
     "(total áreas no DB: #{::Academy::Subject.count}, inativas preservadas)."

# Phase 2 — concept graph: already loaded BEFORE the curriculum loop above
# so missions could be saved with concept_id. We DON'T reload here.
# v4 — Pokédex visual keys (color + silhouette per concept). Must run after concepts.
load Rails.root.join("db/seeds/academy_pokedex_keys.rb")
# v4 — story_choice missions, typed concept_edges, Pokédex backfill
load Rails.root.join("db/seeds/academy_v4.rb")
# v3 — Currículo de curiosidade-do-mundo (3 novas Subjects + ~30 concepts).
# Must load BEFORE academy_lens_payloads.rb so payloads referencing the new
# concept slugs find them.
load Rails.root.join("db/seeds/academy_curiosidade_concepts.rb")
# Curated-static pivot — human-authored lens payloads (academy-curated-static-pivot.md)
load Rails.root.join("db/seeds/academy_lens_payloads.rb")

# v3 — Missions for the curiosidade-do-mundo curriculum. Must load AFTER
# lens payloads so the audit below sees curated content for the 30 new
# concepts.
load Rails.root.join("db/seeds/academy_curiosidade_missions.rb")

# Post-seed audit: enforce the "every active mission's concept has ≥1
# curated kid payload" invariant. The Mission model declares the check
# under `on: :publish` so individual saves during the seed don't fail
# before payloads exist. Running it here turns the seed into the
# enforcement boundary instead of an ENV bypass.
missing_payload = []
::Academy::Mission.where(active: true).includes(:concept).find_each do |mission|
  next if mission.valid?(:publish)

  missing_payload << "#{mission.slug} (concept=#{mission.concept&.slug || '?'})"
end

if missing_payload.any?
  raise "Academy seed audit FAILED: missions without curated kid payload — " \
        "#{missing_payload.join(', ')}"
end
puts "✓ Academy audit: #{::Academy::Mission.where(active: true).count} missões ativas · 100% com payload curado."
