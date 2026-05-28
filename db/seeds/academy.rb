# frozen_string_literal: true

# Academy — Pílulas de Conhecimento (redesign, spec 001).
#
# Conteúdo 100% curado. Cada aula segue o método do mistério:
# enigma → pistas → revelação → teste → fisgada. Sem clichê, sem moral da
# história, sem "reflita sobre". Fenômenos reais explicados de um jeito que
# uma criança contaria pro amigo na escola.
#
# Idempotente: limpa trilhas/aulas e recria. Progresso de aprendizes
# (LessonProgress) usa lesson_id, então é recriado pelo uso, não pelo seed.

puts "Academy: seeding trails + lessons…"

Academy::GuideMessage.delete_all
Academy::GuideConversation.delete_all
Academy::LessonProgress.delete_all
Academy::Lesson.delete_all
Academy::Trail.delete_all

academy_trails = [
  {
    slug: "seu-cerebro-mente",
    title: "Seu cérebro mente pra você",
    hook: "Tudo que você vê, lembra e sente passa por um filtro — e o filtro inventa coisas. Vamos pegar ele no flagra.",
    emoji: "🧠",
    accent: "lilac",
    lessons: [
      {
        slug: "cocegas-em-si-mesmo",
        title: "Cócegas em si mesmo",
        enigma: "Por que você NÃO consegue fazer cócegas em você mesmo?",
        payload: {
          clues: [
            "Outra pessoa te faz cócega no mesmo lugar, com a mesma força — e você se contorce.",
            "Você faz exatamente igual em si mesmo… e nada. Nem um arrepio.",
            "Cientistas testaram com uma máquina de cócegas. Quando era o robô sozinho, funcionava. Quando você comandava o robô, parava de funcionar."
          ],
          revelation: "Seu cérebro prevê tudo que VOCÊ mesmo vai fazer, milésimos de segundo antes. Como ele já sabe o que vem, ele apaga a surpresa. Sem surpresa, não tem cócega. A cócega é o seu cérebro sendo pego desprevenido.",
          check: {
            kind: "multiple_choice",
            prompt: "Então o que faz a cócega funcionar?",
            options: [
              "A força do toque",
              "A surpresa — algo que seu cérebro não previu",
              "O lugar do corpo"
            ],
            answer_index: 1,
            explanation: "Mesmo toque, mesmo lugar, mesma força: só muda se seu cérebro esperava ou não. Surpresa é o ingrediente secreto."
          },
          hook: "Se o cérebro prevê o que você faz… será que ele também prevê o que você VÊ? Próxima pílula."
        }
      },
      {
        slug: "gorila-invisivel",
        title: "O gorila invisível",
        enigma: "Como dá pra um gorila passar na sua frente sem você ver?",
        payload: {
          clues: [
            "Num experimento famoso, pediram pra pessoas contarem quantos passes um time de basquete dava.",
            "No meio do vídeo, uma pessoa fantasiada de gorila entra, bate no peito e sai. Demora 9 segundos.",
            "Metade das pessoas que contavam os passes juravam que não passou gorila nenhum."
          ],
          revelation: "Você não enxerga com os olhos — enxerga com a atenção. O que você não está procurando fica invisível, mesmo na sua cara. Seu cérebro mostra o que ele acha importante e esconde o resto pra economizar energia.",
          check: {
            kind: "multiple_choice",
            prompt: "Por que tanta gente não viu o gorila?",
            options: [
              "O gorila era pequeno e rápido",
              "A atenção delas estava travada em contar passes",
              "O vídeo era escuro"
            ],
            answer_index: 1,
            explanation: "Atenção é um holofote: ilumina uma coisa e deixa o resto no escuro. O gorila estava visível — só não estava sendo procurado."
          },
          hook: "Se você não vê o que não procura… quanto da sua MEMÓRIA é real e quanto é invenção? Continua."
        }
      },
      {
        slug: "memoria-falsa",
        title: "A memória que nunca aconteceu",
        enigma: "Dá pra você lembrar, com certeza absoluta, de algo que NUNCA aconteceu?",
        payload: {
          clues: [
            "Pesquisadores contaram pra adultos quatro histórias da infância deles. Três eram verdade. Uma era inventada: terem se perdido num shopping aos 5 anos.",
            "Depois de algumas conversas, muita gente 'lembrou' do shopping — com detalhes, cheiros, o medo. Tudo inventado.",
            "Cada vez que você lembra de algo, seu cérebro não abre um arquivo: ele remonta a lembrança do zero. E pode trocar peças sem avisar."
          ],
          revelation: "Memória não é um vídeo guardado. É uma história que seu cérebro reconta toda vez — e edita um pouco a cada vez. Por isso duas pessoas lembram a mesma briga de jeitos diferentes, e as duas acham que estão certas.",
          check: {
            kind: "multiple_choice",
            prompt: "Lembrar de uma coisa é mais parecido com…",
            options: [
              "Abrir um vídeo gravado",
              "Remontar um quebra-cabeça de memória, podendo trocar peças",
              "Ler um diário que nunca muda"
            ],
            answer_index: 1,
            explanation: "Cada lembrança é reconstruída na hora. Útil, rápida — mas confiável demais é furada."
          },
          hook: "Seu cérebro inventa lembranças. Será que ele inventa… as cores também? (Spoiler: sim.) Próxima."
        }
      },
      {
        slug: "cores-nao-existem",
        title: "As cores não existem lá fora",
        enigma: "E se a cor vermelha não existir no mundo — só dentro da sua cabeça?",
        payload: {
          clues: [
            "Lá fora só tem luz: ondas de tamanhos diferentes batendo nas coisas. Não tem 'vermelho' flutuando no ar.",
            "Seus olhos captam essas ondas e mandam um sinal elétrico pro cérebro. O cérebro é quem pinta aquilo de uma cor.",
            "Algumas pessoas enxergam menos cores (daltonismo). Alguns animais enxergam cores que você nem imagina. Mesma luz, 'cores' diferentes."
          ],
          revelation: "A cor é uma invenção do seu cérebro pra organizar a luz. O vermelho do morango não está no morango — está sendo criado dentro de você, agora. O mundo é silencioso e sem cor; o show de cores roda na sua cabeça.",
          check: {
            kind: "multiple_choice",
            prompt: "Onde a cor vermelha realmente 'acontece'?",
            options: [
              "No morango",
              "Na luz do sol",
              "Dentro do seu cérebro, que interpreta a luz"
            ],
            answer_index: 2,
            explanation: "O morango só reflete um tipo de onda de luz. Chamar isso de 'vermelho' é trabalho do seu cérebro."
          },
          hook: "Se até a cor é invenção do cérebro… vamos descer pro corpo. Por que ele faz coisas que ninguém te explicou? Nova trilha te espera."
        }
      }
    ]
  },
  {
    slug: "o-corpo-faz-isso",
    title: "O corpo faz isso e ninguém te contou",
    hook: "Bocejo, choque no cotovelo, arrepio, aquele branco na porta do quarto. Seu corpo tem manias estranhas com motivos surpreendentes.",
    emoji: "💪",
    accent: "sky",
    lessons: [
      {
        slug: "bocejo-contagioso",
        title: "Bocejo pega no outro",
        enigma: "Por que ver alguém bocejar te faz bocejar — até em foto?",
        payload: {
          clues: [
            "Você provavelmente sentiu vontade de bocejar só de ler a palavra 'bocejo' agora.",
            "Cachorros bocejam quando o dono boceja. Mas com gente estranha o contágio é bem mais fraco.",
            "Quanto mais perto você é de uma pessoa, mais o bocejo dela 'pega' em você."
          ],
          revelation: "O bocejo contagioso é o seu cérebro copiando o outro no automático — o mesmo sistema que te faz sentir o que os outros sentem. Bocejo que pega é um termômetro escondido de o quanto você se conecta com alguém.",
          check: {
            kind: "multiple_choice",
            prompt: "O bocejo 'pega' mais quando a pessoa é…",
            options: [
              "Um estranho na rua",
              "Alguém próximo de você, tipo família ou amigo",
              "Alguém muito mais velho"
            ],
            answer_index: 1,
            explanation: "Quanto maior a conexão, mais forte o contágio. Por isso pega mais de quem você ama."
          },
          hook: "Seu corpo copia os outros sem pedir licença. E aquela dor elétrica no cotovelo, de onde vem? Continua."
        }
      },
      {
        slug: "osso-da-risada",
        title: "O 'osso da risada'",
        enigma: "Por que bater o cotovelo dá um choque elétrico esquisito — e nada a ver com risada?",
        payload: {
          clues: [
            "Não é osso. E definitivamente não dá vontade de rir.",
            "Passa um nervo bem na quina do seu cotovelo, quase sem nada protegendo — o nervo ulnar.",
            "Quando você bate ali, esmaga o nervo contra o osso. Ele dispara um sinal direto: aquele formigamento elétrico até os dedos."
          ],
          revelation: "Quase todos os seus nervos correm escondidos, protegidos por músculo e gordura. Esse passa exposto, na quina. Bater nele é apertar um fio elétrico vivo. O 'osso da risada' é o lugar onde seu corpo esqueceu de colocar proteção.",
          check: {
            kind: "multiple_choice",
            prompt: "O choque vem de…",
            options: [
              "Um osso especial que vibra",
              "Um nervo exposto sendo esmagado contra o osso",
              "Um músculo que estica demais"
            ],
            answer_index: 1,
            explanation: "É o nervo ulnar, sem proteção naquele ponto. Você sente o sinal dele até os dedos."
          },
          hook: "Tem um fio elétrico exposto no seu braço. E por que seus pelos ficam em pé com medo ou frio? Próxima."
        }
      },
      {
        slug: "arrepio-fantasma",
        title: "Arrepio: a herança peluda",
        enigma: "Por que você fica 'todo arrepiado' com frio ou medo — se isso não esquenta nem protege nada?",
        payload: {
          clues: [
            "Cada pelo do seu braço tem um musculinho que o levanta. É ele que faz a 'pele de galinha'.",
            "Olha um gato com medo: ele estufa todo o pelo e parece o dobro do tamanho. Mesmo músculo, mesmo truque.",
            "Animais peludos arrepiam pra prender ar quente perto da pele (casaco) ou pra parecer maiores e assustar inimigos."
          ],
          revelation: "O arrepio é uma herança dos seus ancestrais peludos. Neles funcionava: casaco térmico e 'modo maior'. Você perdeu o pelo mas ficou com o botão. Hoje ele aperta à toa — um reflexo de um corpo que você não tem mais.",
          check: {
            kind: "multiple_choice",
            prompt: "Por que o arrepio quase não serve pra nada em você?",
            options: [
              "Porque seu corpo está com defeito",
              "Porque é um reflexo herdado de ancestrais peludos — você ficou com o botão, sem o pelo",
              "Porque você está sempre com frio"
            ],
            answer_index: 1,
            explanation: "Em bichos peludos arrepiar aquece e intimida. Em você é só o reflexo antigo disparando no vazio."
          },
          hook: "Seu corpo guarda reflexos de um animal que você nem é mais. E por que você esquece o que ia fazer ao cruzar uma porta? Continua."
        }
      },
      {
        slug: "efeito-porta",
        title: "O branco da porta",
        enigma: "Por que você entra num cômodo e esquece na hora o que ia fazer ali?",
        payload: {
          clues: [
            "Você decide: 'vou no quarto pegar o carregador'. Chega no quarto e… branco total.",
            "Você volta pra sala, e puf — lembra de novo. Como se a memória tivesse ficado pra trás.",
            "Cientistas testaram isso num jogo. Toda vez que o personagem cruzava uma porta, esquecia mais — mesmo sem distração nenhuma."
          ],
          revelation: "Seu cérebro divide a vida em 'cenas'. Cruzar uma porta avisa ele: cena nova, pode limpar a anterior. Ele apaga a lembrança da cena velha pra liberar espaço. A porta não é coincidência — é o gatilho que zera sua memória de curto prazo.",
          check: {
            kind: "multiple_choice",
            prompt: "O que dispara o esquecimento?",
            options: [
              "Andar uma certa distância",
              "Cruzar a porta — o cérebro marca uma 'cena nova' e limpa a anterior",
              "Ficar com fome"
            ],
            answer_index: 1,
            explanation: "É a porta, não a distância. Atravessar um limite avisa o cérebro pra começar uma cena nova."
          },
          hook: "Seu cérebro corta a vida em cenas e apaga as antigas. Agora: por que é impossível comer uma batata frita só? Nova trilha."
        }
      }
    ]
  },
  {
    slug: "forcas-invisiveis",
    title: "Forças invisíveis que decidem por você",
    hook: "Você acha que escolhe sozinho. Mas tem forças puxando suas decisões nos bastidores — e elas adoram ficar escondidas.",
    emoji: "🧲",
    accent: "coral",
    lessons: [
      {
        slug: "uma-batata-frita",
        title: "Uma batata frita só",
        enigma: "Por que é quase impossível comer uma batata frita e parar?",
        payload: {
          clues: [
            "Ninguém precisa se segurar pra parar de comer brócolis. Mas batata frita…",
            "A cada mordida, seu cérebro solta uma gotinha de uma substância de 'quero mais' — a dopamina.",
            "O truque cruel: a dopamina vem mais forte na expectativa da próxima do que na que você está comendo. Você está sempre perseguindo a próxima."
          ],
          revelation: "Comidas feitas pra viciar (sal + gordura + crocância) sequestram o sistema de 'quero mais' do seu cérebro. Você não está com fome — está perseguindo a próxima gotinha de dopamina que nunca chega de verdade. Quem desenha o salgadinho sabe disso.",
          check: {
            kind: "multiple_choice",
            prompt: "A dopamina te empurra mais forte…",
            options: [
              "Quando você já está satisfeito",
              "Na expectativa da próxima batata, não na que você come",
              "Só na primeira batata"
            ],
            answer_index: 1,
            explanation: "O 'quero mais' mora na expectativa. Por isso você persegue a próxima — e a próxima, e a próxima."
          },
          hook: "Tem um sistema no seu cérebro que adora 'a próxima'. E por que a palavra 'GRÁTIS' te faz querer coisa que você nem usa? Continua."
        }
      },
      {
        slug: "o-poder-do-gratis",
        title: "O feitiço do 'grátis'",
        enigma: "Por que 'grátis' faz você pegar coisa que você nem ia querer pagando?",
        payload: {
          clues: [
            "Num teste: bombom caro por 1 centavo, ou bombom simples de graça. Quase todo mundo pega o de graça — mesmo sendo pior negócio.",
            "Aí baixaram tudo 1 centavo: o caro por 14, o simples por 1 centavo (não mais grátis). A maioria voltou pro caro.",
            "Só o 'zero' mudou tudo. 1 centavo e 0 centavo são quase o mesmo preço — mas no seu cérebro são mundos diferentes."
          ],
          revelation: "'Grátis' não é só um preço baixo: é um botão emocional. Como não tem risco de perder nada, seu cérebro desliga a parte que pesa 'vale a pena?'. Por isso lojas dão 'brinde grátis' — você leva coisa que não precisa só pra não 'perder' o de graça.",
          check: {
            kind: "multiple_choice",
            prompt: "Por que 'grátis' é tão poderoso?",
            options: [
              "Porque é o menor preço possível, matematicamente",
              "Porque tira o medo de perder — e seu cérebro para de avaliar se vale a pena",
              "Porque coisas grátis são sempre melhores"
            ],
            answer_index: 1,
            explanation: "Não é a matemática — é a emoção. Sem risco de perda, o cérebro não pesa o custo."
          },
          hook: "Seu medo de perder é um botão que dá pra apertar. E por que, se uma pessoa olha pra cima, todo mundo olha junto? Próxima."
        }
      },
      {
        slug: "todo-mundo-olha-pra-cima",
        title: "Todo mundo olha pra cima",
        enigma: "Se uma pessoa parar na rua e olhar pro céu, por que uma multidão para junto?",
        payload: {
          clues: [
            "Pesquisadores colocaram 1 pessoa parada olhando pra cima numa calçada cheia. Quase ninguém ligou.",
            "Botaram 5 pessoas olhando pra cima. De repente, um monte de gente parou e olhou também — pra um céu vazio.",
            "Quanto mais gente olhando, mais forte a força. Ninguém quer ser o único que 'não tá vendo'."
          ],
          revelation: "Quando você não sabe o que fazer, seu cérebro usa um atalho: 'faz o que a maioria faz, deve estar certo'. É a prova social. Serve pra te manter seguro em grupo — mas também faz multidão inteira olhar pra um céu sem nada. O grupo vira seu piloto automático.",
          check: {
            kind: "multiple_choice",
            prompt: "Por que a multidão olha pra um céu vazio?",
            options: [
              "Porque tem algo lá em cima",
              "Porque o cérebro copia a maioria quando está sem saber o que fazer (prova social)",
              "Porque é educado olhar junto"
            ],
            answer_index: 1,
            explanation: "É o atalho da prova social: 'se muitos fazem, deve ter motivo'. Rápido — e fácil de enganar."
          },
          hook: "O grupo pode virar seu piloto automático. Última: por que esperar dói mais do que parece justo? Continua."
        }
      },
      {
        slug: "esperar-doi",
        title: "Por que esperar dói",
        enigma: "Por que seu cérebro prefere 1 doce agora do que 2 doces daqui a pouco?",
        payload: {
          clues: [
            "Ofereceram a crianças: 1 marshmallow agora, ou espere uns minutinhos sozinho e ganhe 2.",
            "Muitas não aguentaram. O '2 depois' parecia valer menos que o '1 agora' bem na frente delas.",
            "Seu cérebro 'encolhe' o valor de qualquer coisa que está no futuro. Quanto mais longe, mais ele encolhe."
          ],
          revelation: "Existe uma parte antiga do seu cérebro que só pensa no agora — pra ela, o futuro quase não conta. Por isso esperar parece um prejuízo, mesmo quando você sai ganhando. Quem percebe esse truque consegue enganar o enganador e segurar a onda pelo prêmio maior.",
          check: {
            kind: "multiple_choice",
            prompt: "Por que '2 depois' parece valer menos que '1 agora'?",
            options: [
              "Porque 2 é confuso de contar",
              "Porque o cérebro encolhe o valor de tudo que está no futuro",
              "Porque doce perde o gosto com o tempo"
            ],
            answer_index: 1,
            explanation: "O futuro é 'descontado' pelo cérebro. Saber disso é o primeiro passo pra não cair no truque."
          },
          hook: "Você acabou de pegar três forças invisíveis no flagra. Da próxima vez que escolher algo, repara: quem está decidindo — você ou elas? 🔍"
        }
      }
    ]
  }
]

academy_trails.each_with_index do |t, ti|
  trail = Academy::Trail.create!(
    slug: t[:slug], title: t[:title], hook: t[:hook],
    emoji: t[:emoji], accent: t[:accent], position: ti, active: true
  )
  t[:lessons].each_with_index do |l, li|
    Academy::Lesson.create!(
      trail: trail, slug: l[:slug], title: l[:title], enigma: l[:enigma],
      position: li, active: true,
      payload: l[:payload].deep_stringify_keys
    )
  end
  puts "  ✓ #{t[:title]} — #{t[:lessons].size} aulas"
end

puts "Academy: #{Academy::Trail.count} trilhas, #{Academy::Lesson.count} aulas. ✨"
