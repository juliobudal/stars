# frozen_string_literal: true

# Academy — fonte de conteúdo curado (feature 002: arcos narrativos).
#
# Esta constante é a ÚNICA fonte de verdade do conteúdo das trilhas. É lida
# tanto por db/seeds/academy.rb (cria os registros) quanto por
# spec/seeds/academy_content_spec.rb (valida os padrões de arco sem rodar o seed).
#
# Cada aula segue o método do mistério: enigma → pistas → revelação → teste →
# fisgada. Sem clichê, sem moral da história, sem "reflita sobre".
#
# Metadados de ARCO por trilha (NÃO persistidos — só validados no build):
#   refrao:             frase-âncora que reaparece na revelação de TODAS as aulas
#   callback_anchor:    termo que aparece na 1ª aula E na última (fechamento)
#   arc_payload_marker: termo do gancho de abertura que reaparece na última aula
#   cliffhanger_to:     slug da trilha-destino que a fisgada final provoca
#                       (nil = última do conjunto → gancho aberto)

ACADEMY_CONTENT = [
  {
    slug: "seu-cerebro-mente",
    title: "Seu cérebro mente pra você",
    hook: "Tudo que você vê, lembra e sente passa por um filtro — e o filtro inventa coisas. Vamos pegar ele no flagra.",
    emoji: "🧠",
    accent: "lilac",
    refrao: "versão editada",
    callback_anchor: "cócega",
    arc_payload_marker: "filtro",
    cliffhanger_to: "o-corpo-faz-isso",
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
          revelation: "Seu cérebro prevê tudo que VOCÊ mesmo vai fazer, milésimos de segundo antes. Como ele já sabe o que vem, ele apaga a surpresa. Sem surpresa, não tem cócega. A cócega que some é a primeira versão editada que você pega no flagra: seu cérebro mexendo no que você sente antes mesmo de você sentir.",
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
          revelation: "Você não enxerga com os olhos — enxerga com a atenção. O que você não está procurando fica invisível, mesmo na sua cara. O que chega até você é uma versão editada do mundo: seu cérebro mostra o que acha importante e corta o resto pra economizar energia.",
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
          revelation: "Memória não é um vídeo guardado. Cada lembrança é uma versão editada, remontada na hora — e seu cérebro troca uma peça aqui, outra ali, sem avisar. Por isso duas pessoas lembram a mesma briga de jeitos diferentes, e as duas acham que estão certas.",
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
          revelation: "A cor é uma invenção do seu cérebro pra organizar a luz: o vermelho do morango não está no morango — está sendo criado dentro de você, agora. Lembra das cócegas da primeira pílula, que sumiam quando o cérebro previa? É o mesmo filtro em ação: ele edita a luz e te entrega uma versão editada chamada 'cor'. Pegamos o filtro no flagra — do toque à cor, ele inventa tudo.",
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
          hook: "Pegamos o filtro do cérebro no flagra. Mas ele não manda só na sua cabeça — ele faz o seu CORPO fazer coisas que ninguém te explicou: bocejo que pega no outro, choque elétrico no cotovelo, arrepio do nada. Trilha 'O corpo faz isso e ninguém te contou'."
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
    refrao: "motivo escondido",
    callback_anchor: "bocejo",
    arc_payload_marker: "manias",
    cliffhanger_to: "forcas-invisiveis",
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
          revelation: "O bocejo contagioso é o seu cérebro copiando o outro no automático — o mesmo sistema que te faz sentir o que os outros sentem. Por trás de uma bobagem assim mora um motivo escondido: o bocejo que pega é um termômetro de o quanto você se conecta com alguém.",
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
          revelation: "Quase todos os seus nervos correm escondidos, protegidos por músculo e gordura. Esse passa exposto, na quina. Bater nele é apertar um fio elétrico vivo. De novo um motivo escondido por trás do estranho: o 'osso da risada' é o ponto onde seu corpo esqueceu de colocar proteção.",
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
          revelation: "O arrepio é uma herança dos seus ancestrais peludos. Neles funcionava: casaco térmico e 'modo maior'. Você perdeu o pelo mas ficou com o botão. O motivo escondido aqui é o tempo: hoje o arrepio aperta à toa — um reflexo de um corpo que você não tem mais.",
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
          revelation: "Seu cérebro divide a vida em 'cenas'. Cruzar uma porta avisa ele: cena nova, pode limpar a anterior. Ele apaga a lembrança da cena velha pra liberar espaço — esse é o motivo escondido do branco na porta. E olha o fechamento: do bocejo que pega ao choque no cotovelo, do arrepio ao branco na porta, todas essas manias do corpo têm a mesma assinatura — nenhuma é defeito, cada uma tem um motivo escondido.",
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
          hook: "As manias do corpo têm motivo escondido — e algumas dessas forças decidem POR você sem avisar: por que é impossível comer uma batata frita só, por que a palavra 'GRÁTIS' te hipnotiza? Trilha 'Forças invisíveis que decidem por você'."
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
    refrao: "nos bastidores",
    callback_anchor: "batata",
    arc_payload_marker: "escolhe sozinho",
    cliffhanger_to: "a-luz-noticia-velha",
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
          revelation: "Comidas feitas pra viciar (sal + gordura + crocância) sequestram o sistema de 'quero mais' do seu cérebro. Você não está com fome — está perseguindo a próxima gotinha de dopamina que nunca chega de verdade. Quem desenha o salgadinho sabe disso: a primeira força age nos bastidores, dentro da sua própria cabeça.",
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
          revelation: "'Grátis' não é só um preço baixo: é um botão emocional. Como não tem risco de perder nada, seu cérebro desliga a parte que pesa 'vale a pena?'. Por isso lojas dão 'brinde grátis' — é mais uma força agindo nos bastidores, te fazendo levar o que não precisa só pra não 'perder' o de graça.",
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
          revelation: "Quando você não sabe o que fazer, seu cérebro usa um atalho: 'faz o que a maioria faz, deve estar certo'. É a prova social. Serve pra te manter seguro em grupo — mas também faz multidão inteira olhar pra um céu sem nada. Aqui a força age nos bastidores através dos outros: o grupo vira seu piloto automático.",
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
          revelation: "Existe uma parte antiga do seu cérebro que só pensa no agora — pra ela, o futuro quase não conta. Por isso esperar parece um prejuízo, mesmo quando você sai ganhando. E aqui fecha o arco: da batata frita ao marshmallow, do 'grátis' à multidão, foram quatro forças agindo nos bastidores. Você não escolhe sozinho como pensava — mas quem percebe o truque consegue enganar o enganador.",
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
          hook: "Você pegou quatro forças no flagra dentro da sua cabeça. Agora a maior pegadinha vem de FORA: a luz que chega aos seus olhos está sempre atrasada — você nunca vê o agora, nem uma vez na vida. Trilha 'A luz é uma notícia velha'."
        }
      }
    ]
  },
  {
    slug: "a-luz-noticia-velha",
    title: "A luz é uma notícia velha",
    hook: "Você nunca viu o agora. Nem uma vez na vida. A luz que chega aos seus olhos sempre saiu de algum lugar — e viajar leva tempo.",
    emoji: "🔭",
    accent: "sky",
    refrao: "notícia atrasada",
    callback_anchor: "Sol",
    arc_payload_marker: "o agora",
    cliffhanger_to: "as-palavras-mudam",
    lessons: [
      {
        slug: "o-sol-ja-e-passado",
        title: "O Sol que você vê já é passado",
        enigma: "Se o Sol apagasse agora, em quanto tempo você ia descobrir?",
        payload: {
          clues: [
            "A luz do Sol não chega instantânea: ela viaja, e leva cerca de 8 minutos pra cruzar o espaço até os seus olhos.",
            "Ou seja: você sempre vê o Sol de 8 minutos atrás. O Sol de agora, ninguém viu ainda.",
            "Se ele apagasse neste segundo, o céu seguiria ensolarado por mais 8 minutos. Você só saberia depois."
          ],
          revelation: "A luz do Sol é uma notícia atrasada: demora 8 minutos pra te alcançar. Você nunca vê o Sol de agora — só o Sol do passado, ainda viajando até você no momento em que bate no seu olho.",
          check: {
            kind: "multiple_choice",
            prompt: "Por que você nunca vê o Sol 'de agora'?",
            options: [
              "Porque o Sol é muito brilhante",
              "Porque a luz dele demora cerca de 8 minutos pra chegar",
              "Porque seus olhos são lentos"
            ],
            answer_index: 1,
            explanation: "Quando a luz finalmente chega, ela mostra como o Sol estava 8 minutos antes."
          },
          hook: "8 minutos é pouco? Então olha pra uma estrela: a notícia dela pode ter saído antes de você nascer. Próxima."
        }
      },
      {
        slug: "estrela-que-morreu",
        title: "A estrela que talvez não exista mais",
        enigma: "Você pode estar olhando bem agora uma estrela que já morreu?",
        payload: {
          clues: [
            "As estrelas estão tão longe que a luz delas viaja anos — às vezes milhares de anos — pra chegar aqui.",
            "Quando essa luz finalmente bate no seu olho, ela conta como a estrela era lá atrás, não como ela está hoje.",
            "Algumas estrelas que aparecem no céu já se apagaram faz tempo. Você está vendo um fantasma de luz."
          ],
          revelation: "A luz da estrela é uma notícia atrasada de anos: mostra o passado dela, nunca o presente. Você pode estar admirando uma estrela que já não existe — só a notícia dela ainda está cruzando o espaço até você.",
          check: {
            kind: "multiple_choice",
            prompt: "O que a luz de uma estrela te mostra?",
            options: [
              "Como ela está exatamente agora",
              "Como ela era quando a luz partiu, há muito tempo",
              "O que vai acontecer com ela"
            ],
            answer_index: 1,
            explanation: "A imagem é antiga: viajou anos pra chegar. O 'agora' da estrela ainda nem chegou aos seus olhos."
          },
          hook: "Tá longe demais pra assustar? Então diminui a distância ao máximo: olha pra sua própria mão. Continua."
        }
      },
      {
        slug: "ate-sua-mao-atrasa",
        title: "Até sua mão chega atrasada",
        enigma: "Olhar pra própria mão também é ver o passado?",
        payload: {
          clues: [
            "A luz que bate na sua mão e volta pro seu olho também precisa viajar — só que a distância é curtinha.",
            "Curtinha, mas não é zero: a luz leva um tiquinho (bilionésimos de segundo) pra fazer esse caminho.",
            "Some a isso o tempinho que seu cérebro leva pra montar a imagem: o que você vê da sua mão já é levemente passado."
          ],
          revelation: "Mesmo de pertinho, a luz é uma notícia atrasada: a imagem da sua mão demora um tiquinho pra chegar e ser montada. Não existe distância tão curta em que o atraso vire zero — ele só fica menor.",
          check: {
            kind: "multiple_choice",
            prompt: "Olhar algo bem pertinho…",
            options: [
              "Zera o atraso da luz",
              "Diminui o atraso, mas nunca chega a zero",
              "Aumenta o atraso"
            ],
            answer_index: 1,
            explanation: "Menos distância, menos atraso. Mas 'zero atraso' não existe: a luz sempre leva um tempinho."
          },
          hook: "Se até a sua mão chega atrasada… sobra algum 'agora' pra você ver? Última pílula."
        }
      },
      {
        slug: "nunca-ve-o-agora",
        title: "Por que você nunca vê o agora",
        enigma: "Existe algum 'agora' que os seus olhos consigam ver de verdade?",
        payload: {
          clues: [
            "Lembra do Sol da primeira pílula? 8 minutos de atraso. Você nunca viu o Sol de verdade — só o Sol de antes.",
            "Tudo que você enxerga é luz que VIAJOU até seus olhos. E viajar leva tempo. Sempre.",
            "Do Sol à estrela, da estrela à sua mão: muda o tamanho do atraso, nunca o fato de existir atraso."
          ],
          revelation: "Toda luz é uma notícia atrasada — do Sol, da estrela, da sua mão, desta tela. Você sempre vê o passado, nunca o agora. O 'agora' que seus olhos mostram já foi embora no instante em que a luz partiu: você vive um passinho atrás do mundo, e nunca o alcança.",
          check: {
            kind: "prediction",
            prompt: "Existe alguma coisa que você veja exatamente no 'agora', com zero atraso?",
            options: [
              "Sim, o que está bem pertinho de mim",
              "Não, toda luz chega com um tiquinho de atraso"
            ],
            answer_index: 1,
            explanation: "Pertinho diminui o atraso, mas nunca zera. Ver é sempre ver o passado."
          },
          hook: "A luz te engana sobre o TEMPO. Mas tem algo que mexe no que você VÊ e SENTE só trocando uma palavrinha — dá pra ficar quase 'cego' pra uma cor por não ter nome pra ela. Trilha 'As palavras mudam o que você enxerga'."
        }
      }
    ]
  },
  {
    slug: "as-palavras-mudam",
    title: "As palavras mudam o que você enxerga",
    hook: "Trocar UMA palavra muda o que você vê, lembra e sente — sem você perceber. Quem está mexendo aí dentro?",
    emoji: "💬",
    accent: "lilac",
    refrao: "uma lente",
    callback_anchor: "azul",
    arc_payload_marker: "uma palavra",
    cliffhanger_to: nil,
    lessons: [
      {
        slug: "a-cor-sem-nome",
        title: "A cor que você não enxerga",
        enigma: "Dá pra um povo demorar pra ver o azul só por não ter uma palavra pra ele?",
        payload: {
          clues: [
            "Por muito tempo, várias línguas antigas não tinham uma palavra separada pra 'azul' — chamavam de verde ou de escuro.",
            "Um povo da Namíbia, os Himba, tem várias palavras pra tons de verde, mas nenhuma só pra azul.",
            "Num teste, eles demoravam pra achar um quadrado azul no meio de verdes — e achavam rapidinho um tom de verde que pra nós era idêntico aos outros."
          ],
          revelation: "A palavra funciona como uma lente: ter o nome de uma cor ajuda seu cérebro a 'separar' ela do resto. Sem a palavra pra azul, o azul não some — mas fica mais difícil de destacar. O nome afia o que você consegue enxergar.",
          check: {
            kind: "multiple_choice",
            prompt: "Por que os Himba demoram pra achar o azul?",
            options: [
              "Porque são daltônicos",
              "Porque não têm uma palavra que separe o azul, e o nome ajuda a destacar",
              "Porque o azul é uma cor escura"
            ],
            answer_index: 1,
            explanation: "Não é o olho, é o nome: a palavra ajuda o cérebro a recortar aquela cor do fundo."
          },
          hook: "Se a palavra muda a COR que você vê… será que ela muda o que você LEMBRA? Próxima."
        }
      },
      {
        slug: "verbo-reescreve-memoria",
        title: "O verbo que reescreve a memória",
        enigma: "A mesma batida de carro pode ficar mais rápida na sua memória só trocando uma palavra?",
        payload: {
          clues: [
            "Mostraram a MESMA batida de carro pra duas turmas e perguntaram a velocidade.",
            "Pra uma, perguntaram: 'a que velocidade os carros se TOCARAM?'. Pra outra: 'a que velocidade os carros se ESPATIFARAM?'.",
            "Quem ouviu 'espatifaram' chutou velocidades maiores — e, uma semana depois, 'lembrou' de vidro quebrado que não existia no vídeo."
          ],
          revelation: "A palavra é uma lente que entra até na memória: trocar 'tocar' por 'espatifar' fez o cérebro reconstruir a cena mais violenta — e até inventar detalhes. A palavra não descreve só a lembrança; ela edita a lembrança por dentro.",
          check: {
            kind: "multiple_choice",
            prompt: "Trocar 'tocaram' por 'espatifaram' mudou o quê?",
            options: [
              "Só o jeito de perguntar",
              "A velocidade lembrada e até detalhes inventados depois",
              "Nada, a memória é um vídeo fiel"
            ],
            answer_index: 1,
            explanation: "Uma palavra mais forte puxou uma lembrança mais violenta. A memória se ajustou à lente."
          },
          hook: "A palavra mexe na sua memória. E se ela mexer na sua CORAGEM? Continua."
        }
      },
      {
        slug: "fala-na-terceira-pessoa",
        title: "Falar com você na terceira pessoa",
        enigma: "Dizer 'VOCÊ consegue' (com o seu nome) funciona melhor que 'eu consigo'?",
        payload: {
          clues: [
            "Antes de algo difícil — uma prova, um salto — tem gente que fala sozinha: 'eu consigo'.",
            "Pesquisadores testaram trocar pra terceira pessoa: 'Você consegue, João' — usando o próprio nome.",
            "Quem usou o nome e o 'você' ficou mais calmo e foi melhor do que quem usou 'eu'. Mesma cabeça, palavras diferentes."
          ],
          revelation: "A palavra é uma lente até pra você falar com você mesmo: dizer 'você, [seu nome]' cria uma distancinha do medo, como um treinador te orientando de fora. Trocar 'eu' por 'você' muda o quanto a pressão te pega.",
          check: {
            kind: "multiple_choice",
            prompt: "Por que 'você, [nome]' ajuda mais que 'eu'?",
            options: [
              "Porque é mais educado",
              "Porque cria uma distância do medo, como alguém te orientando de fora",
              "Porque você fala mais alto"
            ],
            answer_index: 1,
            explanation: "A terceira pessoa te tira do meio do furacão: você vira seu próprio treinador."
          },
          hook: "A palavra mexe na cor, na memória e na coragem. E tem gente que percebeu isso há MUITO tempo. Última pílula."
        }
      },
      {
        slug: "descoberta-de-3000-anos",
        title: "A descoberta de 3.000 anos",
        enigma: "Afinal, quem está mexendo no que você vê, lembra e sente — e desde quando alguém sabe disso?",
        payload: {
          clues: [
            "Lembra do azul que custa a aparecer sem nome? E da batida que ficou mais violenta com outro verbo? Era sempre uma palavra mexendo na lente.",
            "Muito antes de existir laboratório, alguém já tinha escrito sobre isso. No livro de Provérbios (18:21): 'a vida e a morte estão no poder da língua'.",
            "Não era só poesia: experimentos modernos mostram que a palavra certa acalma, anima, assusta ou engana — bem como aquele texto antigo já avisava."
          ],
          revelation: "Quem mexe no que você vê, lembra e sente é a palavra — a sua e a dos outros. Ela é uma lente que você carrega o tempo todo, ajustando a realidade sem avisar. A descoberta nova da ciência bate com algo que alguém anotou há uns 3.000 anos: trocar uma palavra pode mudar tudo.",
          check: {
            kind: "prediction",
            prompt: "Trocar uma única palavra pode mudar o que você sente?",
            options: [
              "Não, palavra é só palavra",
              "Sim — a palavra é uma lente que ajusta o que você percebe"
            ],
            answer_index: 1,
            explanation: "Da cor ao medo, foi sempre a mesma lente. Quem escolhe a palavra ajusta a lente."
          },
          hook: "Você já viu o cérebro inventar, o corpo te entregar, as forças te empurrarem, a luz te atrasar e a palavra te enganar. Agora a pergunta fica com você: quando perceber o truque, vai mirar a lente — ou deixar que mirem ela em você? 🔍"
        }
      }
    ]
  }
].freeze
