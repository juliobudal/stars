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
            title: "O que muda quando você dura 25 minutos seguidos?",
            hook: "Quem amarra 25 minutos aprende. Quem fragmenta, esquece.",
            angle: "Pomodoro + estudo de prática deliberada de Anders Ericsson: a qualidade do bloco bate a quantidade da hora dispersa.",
            central_insight: "Se você junta 25 minutos sem interrupção, o cérebro chega na camada profunda; se fragmenta, fica na superfície sem grudar.",
            curiosity_facts: [
              "Anders Ericsson (Florida State) acompanhou músicos e cirurgiões: o que separa os melhores é tempo em prática deliberada — não horas totais.",
              "Estudo da Universidade de Michigan: 1h focada ensina mais que 4h fragmentadas.",
              "Foco é músculo — fica mais forte cada vez que você o usa, e mais fraco cada vez que cede."
            ],
            challenge_prompt: "Faça 1 bloco de 25 minutos com celular fora da vista, fazendo uma coisa só.",
            challenge_when: "hoje",
            challenge_observable: "Quanto rendeu vs. um dia normal.",
            learning_objective: "Aplicar 1 bloco de Pomodoro de 25 min e comparar com sessão fragmentada.",
            illustration_key: "target",
            source: "Anders Ericsson",
            framework: "regra prática"
          }
        ]
      },
      {
        slug: "habitos-sem-sofrer",
        title: "Hábitos Sem Sofrer",
        arc_hook: "Quem desenha o ambiente decide o comportamento — vontade é só ajudante.",
        position: 2,
        missions: [
          {
            slug: "habito-2-minutos",
            title: "Como criar um hábito novo sem sofrer?",
            hook: "Vontade morre em planos grandes. Vive em 2 minutos.",
            angle: "Lei 3 de James Clear (Hábitos Atômicos): faça o hábito de entrada ridiculamente pequeno.",
            central_insight: "Se o novo hábito cabe em 2 minutos, você começa. Se cabe em 1 hora, você desiste no terceiro dia.",
            curiosity_facts: [
              "James Clear: 'ler 1 página por dia' venceu 'ler 1 hora por dia' em 100% dos casos que ele acompanhou.",
              "O cérebro guarda a IDENTIDADE da repetição, não o tamanho — fez 1x = 'sou alguém que faz isso'.",
              "BJ Fogg (Stanford) chama de 'tiny habits' — começo minúsculo é o único que sobrevive 30 dias."
            ],
            challenge_prompt: "Pegue 1 hábito que você quer ter e crie a versão de 2 minutos. Faça hoje.",
            challenge_when: "hoje",
            challenge_observable: "Se foi mais fácil do que o cérebro previa.",
            learning_objective: "Reduzir 1 desejo de hábito à sua versão de 2 min e cumprir 1x.",
            illustration_key: "spark",
            source: "James Clear + BJ Fogg",
            framework: "regra prática + paradoxo"
          },
          {
            slug: "habito-vence-meta",
            title: "Por que o hábito vence a meta?",
            hook: "Meta é onde você quer chegar. Hábito é quem você está virando.",
            angle: "Identidade-voto: cada repetição é voto em 'sou alguém que…'. Meta morre quando atinge ou falha; identidade só morre se você parar de votar.",
            central_insight: "Se você corre porque 'quer perder 5kg', para no 5º kg. Se corre porque 'sou alguém que corre', segue mesmo depois.",
            curiosity_facts: [
              "Aristóteles, 2.300 anos atrás: 'somos o que fazemos repetidamente — excelência é hábito, não ato'.",
              "Estudo de Roy Baumeister: pessoas com identidade ligada ao hábito têm 3× mais chance de manter após 1 ano.",
              "Quem para de fumar dizendo 'eu não sou fumante' tem mais sucesso que quem diz 'estou tentando parar'."
            ],
            challenge_prompt: "Escolha 1 hábito atual seu. Reescreva como identidade: 'sou alguém que ___'. Diga em voz alta hoje quando for fazer.",
            challenge_when: "hoje",
            challenge_observable: "Se a versão-identidade muda quanto custa fazer.",
            learning_objective: "Converter 1 hábito de meta-resultado para identidade-voto.",
            illustration_key: "spark",
            source: "James Clear + Aristóteles",
            framework: "reframe"
          },
          {
            slug: "parar-doi-mais-que-comecar",
            title: "Por que parar dói mais que continuar?",
            hook: "Começar custa esforço. Quebrar a fileira custa identidade.",
            angle: "Momentum do hábito + efeito Hawthorne caseiro: visualizar a sequência (calendário, streak) faz o cérebro proteger ela como recurso.",
            central_insight: "Se você marca X no calendário em 14 dias seguidos, perder o 15º não custa 1 dia — custa a sequência inteira na sua cabeça.",
            curiosity_facts: [
              "Jerry Seinfeld atribuiu sua produtividade ao 'don't break the chain' — calendário marcado a cada dia escrevendo.",
              "Pesquisa de psicologia do esporte mostra: o streak ativa as mesmas regiões cerebrais da posse — perder = perder.",
              "Apps de hábito como Strava e Duolingo são engenharia em cima disso — a fileira vale mais que o dia."
            ],
            challenge_prompt: "Pegue um hábito que tenta há tempo. Marque hoje no calendário. Faça por 3 dias seguidos sem quebrar — sinta o peso do 4º.",
            challenge_when: "esta-semana",
            challenge_observable: "Se no 4º dia você fez mesmo sem querer só pra não perder a fileira.",
            learning_objective: "Marcar 3 dias seguidos visíveis e perceber o peso da quebra.",
            illustration_key: "spark",
            source: "Jerry Seinfeld + Charles Duhigg",
            framework: "experimento"
          },
          {
            slug: "ambiente-decide-mais-que-vontade",
            title: "Por que ambiente decide mais que vontade?",
            hook: "Mude a sala — não a alma. Vontade chega tarde; ambiente já decidiu.",
            angle: "BJ Fogg (Stanford): comportamento = motivação × habilidade × gatilho. Reduzir fricção do bom + adicionar fricção do ruim faz vontade descansar.",
            central_insight: "Se você guarda doce na cozinha, come doce; se guarda no carro do vizinho, não come — não mudou a vontade, mudou o ambiente.",
            curiosity_facts: [
              "BJ Fogg: 'comportamento não muda na cabeça — muda no design'.",
              "Estudo de cantina escolar: trocar lugar de salada e batata-frita na fila aumentou consumo de salada em 30% sem qualquer aviso.",
              "Atletas olímpicos contratam coaches só pra desenhar rotinas de manhã — porque o ambiente da manhã decide o dia."
            ],
            challenge_prompt: "Pegue 1 hábito ruim seu. Mude 1 coisa no AMBIENTE pra dificultar (não na vontade). Veja 2 dias.",
            challenge_when: "esta-semana",
            challenge_observable: "Se o hábito apareceu menos vezes só por causa da mudança de ambiente.",
            learning_objective: "Modificar 1 elemento do ambiente físico pra reduzir 1 hábito indesejado.",
            illustration_key: "spark",
            source: "BJ Fogg + Richard Thaler",
            framework: "experimento + nudge"
          }
        ]
      },
      {
        slug: "vies-cerebro",
        title: "Seu Cérebro Mente Pra Você",
        arc_hook: "Quem conhece os truques do próprio cérebro pensa melhor que 90% das pessoas.",
        position: 3,
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
            angle: "Sistema 1 vs Sistema 2 de Tversky e Kahneman. Rápido decide quase tudo automaticamente; raramente acordamos o lento.",
            central_insight: "Quem só usa o cérebro rápido vive de palpite. Quem treina o devagar, decide melhor sob pressão.",
            curiosity_facts: [
              "Amos Tversky e Daniel Kahneman mostraram: 95% das nossas decisões são automáticas, sistema-1.",
              "Sistema-2 (lento) só liga quando algo é difícil — senão, é palpite.",
              "Teste clássico: bastão + bola = R$1,10; bastão custa R$1 a mais. Quanto a bola? Quase todo mundo erra de cara."
            ],
            challenge_prompt: "Antes da próxima decisão importante hoje, espere 60 segundos antes de decidir.",
            challenge_when: "hoje",
            challenge_observable: "Se a resposta mudou.",
            learning_objective: "Inserir pausa de 60s entre estímulo e decisão em 1 caso real.",
            illustration_key: "clock",
            source: "Amos Tversky",
            framework: "dado científico"
          },
          {
            slug: "sabe-mais-sente-menos",
            title: "Por que quanto mais você sabe, MENOS você sente que sabe?",
            hook: "Iniciante se acha expert. Expert se acha iniciante. A escala vira do avesso.",
            angle: "Efeito Dunning-Kruger: quem sabe pouco não tem repertório pra ver o que falta saber. Quem sabe muito enxerga a vastidão do que ainda não domina.",
            central_insight: "Se a pessoa parece 100% certa do que diz, suspeite — não é prova de saber, é prova de não saber o suficiente pra duvidar.",
            curiosity_facts: [
              "Dunning e Kruger (Cornell, 1999) testaram alunos: os piores de cada turma SE achavam acima da média; os melhores, abaixo.",
              "Mesmo padrão em médicos, motoristas, programadores e jogadores de xadrez — universal.",
              "Sócrates já tinha sacado: 'só sei que nada sei' — o expert que sabe que o assunto é maior que ele."
            ],
            challenge_prompt: "Pense em 1 assunto que você se acha bom. Liste 3 perguntas sobre ele que você NÃO sabe responder. Honesto.",
            challenge_when: "hoje",
            challenge_observable: "Se ficou mais difícil achar 3 lacunas do que parecia.",
            learning_objective: "Identificar 3 lacunas honestas em 1 assunto que se considera dominar.",
            illustration_key: "search",
            source: "David Dunning + Justin Kruger",
            framework: "experimento + paradoxo"
          }
        ]
      },
      {
        slug: "emocoes-fortes",
        title: "Emoções Fortes",
        arc_hook: "Emoção não é fraqueza nem inimiga — é dado de alta velocidade.",
        position: 4,
        missions: [
          {
            slug: "atencao-sem-tela",
            title: "Por que tédio é cheiro de criatividade?",
            hook: "O cérebro só inventa quando o mundo para de gritar.",
            angle: "Manoush Zomorodi + Sandi Mann: tédio é fome de mente — quem nunca passa por ele, perde a janela de geração de ideias.",
            central_insight: "Se você nunca fica entediado, você nunca tem ideias novas — o cérebro precisa de espaço vazio pra criar.",
            curiosity_facts: [
              "Sandi Mann (Universidade de Central Lancashire): 6 min de tédio antes de tarefa criativa AUMENTAM originalidade em ~25%.",
              "Crianças que nunca ficam entediadas têm menos imaginação espontânea.",
              "Big Magic e Walter Isaacson contam: quase toda invenção famosa nasceu no banho, na caminhada, no avião — tédio físico, mente solta."
            ],
            challenge_prompt: "Caminhe 15 min HOJE sem celular, sem fone. Só andando.",
            challenge_when: "hoje",
            challenge_observable: "Ideias ou pensamentos que apareceram.",
            learning_objective: "Cumprir 15 min de movimento sem estímulo digital.",
            illustration_key: "walk",
            source: "Sandi Mann + Manoush Zomorodi",
            framework: "experimento"
          },
          {
            slug: "de-onde-vem-raiva",
            title: "De onde vem a raiva (e por que 6 segundos mudam tudo)?",
            hook: "A raiva acende em 250 milésimos. O 'eu' acorda em 6 segundos.",
            angle: "Amígdala dispara antes do córtex pré-frontal acordar. Os 6 segundos clássicos são o tempo do andar de cima entrar online.",
            central_insight: "Se você responder antes de 6 segundos, a amígdala fala por você; se esperar, o córtex chega e a frase muda.",
            curiosity_facts: [
              "Joseph LeDoux mapeou: estímulo de ameaça pega o caminho curto pra amígdala em ~12ms — pulou o pensamento.",
              "Lisa Feldman Barrett mostra: nomear a emoção ('estou com raiva') desacelera a amígdala em segundos.",
              "Marco Aurélio (séc. II), Meditações: 'lembra que o tempo entre ser provocado e responder é o lugar onde mora a liberdade'."
            ],
            challenge_prompt: "Na próxima vez que você sentir raiva subindo, conte até 6 antes de responder. Conta o que muda na frase.",
            challenge_when: "esta-semana",
            challenge_observable: "Se a primeira frase que ia sair seria diferente da que saiu depois dos 6 segundos.",
            learning_objective: "Aplicar pausa de 6 segundos em 1 momento de raiva real.",
            illustration_key: "bolt",
            source: "Joseph LeDoux + Marco Aurélio",
            framework: "dado neurológico + tradição"
          },
          {
            slug: "ansiedade-e-energia",
            title: "Ansiedade é energia procurando saída — não inimigo.",
            hook: "Mesmo combustível da empolgação. A diferença é como você lê.",
            angle: "Lisa Feldman Barrett: ansiedade e empolgação compartilham assinatura corporal idêntica — coração acelera, mãos suam, estômago aperta. Cérebro decide o nome pela narrativa em volta.",
            central_insight: "Se você renomeia 'estou ansioso' como 'meu corpo está se preparando', a química não muda — mas o que você faz com ela muda completamente.",
            curiosity_facts: [
              "Lisa Feldman Barrett (Northeastern) mostrou: ansiedade e empolgação compartilham o mesmo perfil corporal — diferença é interpretação.",
              "Alison Wood Brooks (Harvard): quem diz 'estou empolgado' antes de falar em público tem performance ~17% melhor que quem diz 'estou calmo'.",
              "Tentar 'acalmar' é mais difícil que reinterpretar — porque a química já saiu; não dá ré, mas dá pra mudar o nome."
            ],
            challenge_prompt: "Antes da próxima situação que dá frio na barriga, fale em voz alta: 'estou empolgado, meu corpo está pronto'. Note.",
            challenge_when: "esta-semana",
            challenge_observable: "Se a sensação corporal segue igual mas a cabeça reage diferente.",
            learning_objective: "Aplicar reinterpretação (ansioso → empolgado) em 1 situação real.",
            illustration_key: "bolt",
            source: "Lisa Feldman Barrett + Alison Wood Brooks",
            framework: "reframe + dado científico"
          },
          {
            slug: "por-que-rejeicao-doi",
            title: "Por que rejeição dói no corpo (não só na cabeça)?",
            hook: "Levou um 'não' e doeu no peito? Não é metáfora — é o mesmo circuito da dor física.",
            angle: "Naomi Eisenberger (UCLA): exclusão social acende o córtex cingulado anterior — região idêntica à da dor de queimadura.",
            central_insight: "Se rejeição dói exatamente como machucado, então 'só deixa pra lá' é como dizer pra alguém quebrado 'só anda'. O remédio é diferente: nomear, validar, mover.",
            curiosity_facts: [
              "Eisenberger (2003) usou ressonância pra mostrar: cérebro de quem é deixado de fora de um joguinho online acende a mesma área da dor física.",
              "Pesquisa: Tylenol (analgésico comum) reduziu sintomas de dor emocional em estudos — porque pega a mesma química.",
              "Crianças expulsas de grupos na infância carregam efeito mensurável no cérebro adulto — não é frescura."
            ],
            challenge_prompt: "Pense em 1 rejeição recente (pequena vale). Nomeie em voz alta: 'isso doeu porque…'. Veja se nomear desinflama.",
            challenge_when: "hoje",
            challenge_observable: "Se colocar palavra na dor reduz a intensidade dela.",
            learning_objective: "Nomear 1 rejeição recente e observar o efeito da nomeação.",
            illustration_key: "heart-pulse",
            source: "Naomi Eisenberger (UCLA)",
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
            hook: "Quem se mexe 10 min todo dia, em 1 mês vence quem 'maratona' 1 hora no sábado.",
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
        arc_hook: "O sono cobra silêncio — e a tela cobra de volta.",
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
          }
        ]
      },
      {
        slug: "respiracao-dor-calma",
        title: "Respiração, Dor e Calma",
        arc_hook: "Seu corpo é o primeiro botão de calma — antes do remédio, antes do pensamento.",
        position: 3,
        missions: [
          {
            slug: "respirar-acalma",
            title: "Como respirar muda o cérebro em 30 segundos?",
            hook: "Soltar o ar devagar é o único botão de calma sem app, sem remédio, sem dinheiro.",
            angle: "Respirar devagar acende o nervo vago — desacelera coração, abaixa cortisol, devolve foco. Em 30 segundos.",
            central_insight: "Se você inspira em 4s e solta em 6s, o nervo vago liga e o corpo entra em modo calma — antes do pensamento decidir nada.",
            curiosity_facts: [
              "Respiração 4-7-8 (inspirar 4s, segurar 7s, soltar 8s) reduz frequência cardíaca em segundos — sistema parassimpático online.",
              "Andrew Huberman (Stanford): 2 ciclos de 'fisiological sigh' (2 inspirações curtas + sopro longo) cortam ansiedade em ~30 segundos.",
              "Monges tibetanos passam horas em respiração lenta — exames mostram cérebro 3-4× mais relaxado que média."
            ],
            challenge_prompt: "Antes da próxima coisa estressante hoje, faça 5 ciclos de 4-7-8. Note o antes/depois no corpo.",
            challenge_when: "hoje",
            challenge_observable: "Se o coração desacelerou e a frase pensada mudou.",
            learning_objective: "Aplicar 1 ciclo de respiração lenta antes de momento estressante e observar mudança corporal.",
            illustration_key: "heart-pulse",
            source: "Andrew Huberman + Andrew Weil",
            framework: "experimento corporal"
          },
          {
            slug: "postura-puxa-humor",
            title: "Por que postura ruim deixa você triste?",
            hook: "Ombro caído puxa o humor pra baixo. Não é metáfora.",
            angle: "Feedback corpo→mente: postura encolhida diminui testosterona, aumenta cortisol e o cérebro 'lê' o corpo pra calibrar emoção.",
            central_insight: "Se você senta encolhido por 2 minutos, o cérebro vai te empurrar pra humor encolhido; abrir o peito 2 minutos puxa pro contrário — corpo manda mensagem pra cabeça.",
            curiosity_facts: [
              "Erik Peper (San Francisco State): postura ereta aumenta recall de memórias positivas em ~35%.",
              "Pesquisa de psicologia social: 2 min de 'pose de poder' (peito aberto) já mexem com hormônios mensuráveis no sangue.",
              "Atletas em pódio fazem a mesma pose mundialmente — peito pra fora, braço erguido — antes de qualquer treinamento cultural."
            ],
            challenge_prompt: "Hoje, no momento que sentir desânimo, force 2 minutos de postura aberta (peito pra fora, ombros pra trás). Note se algo mudou.",
            challenge_when: "hoje",
            challenge_observable: "Se forçar o corpo aberto puxou o ânimo junto.",
            learning_objective: "Experimentar 2 min de postura aberta num momento de desânimo e relatar mudança.",
            illustration_key: "muscle",
            source: "Erik Peper",
            framework: "experimento corporal"
          },
          {
            slug: "dor-quando-confiar",
            title: "Quando dor é alarme — e quando é alarme falso?",
            hook: "Dor é sinal. Mas o sino toca às vezes sem fogo.",
            angle: "Gate-control de Melzack: dor é interpretação do cérebro a partir de sinal nervoso + contexto + memória — não medição direta.",
            central_insight: "Se a dor aparece sempre no mesmo lugar e some quando você se distrai, é alarme treinado; se ela cresce com movimento e tem mancha visível, é alarme real — saber diferenciar evita exagero e descuido.",
            curiosity_facts: [
              "Ronald Melzack (McGill) mostrou: cérebro 'fabrica' a dor — fantasma de membro amputado dói de verdade, sem perna.",
              "Pessoas com dor crônica que aprendem como dor funciona reduzem ~40% da intensidade só por entender o mecanismo.",
              "Soldados feridos em batalha relatam dor MENOR que civis com ferimento equivalente — o contexto muda o sinal."
            ],
            challenge_prompt: "Pegue 1 dor pequena que você teve hoje (cabeça, barriga). Faça 3 perguntas: cresce com movimento? tem inchaço/mancha? some quando distrai? Decida se é alarme real ou treinado.",
            challenge_when: "hoje",
            challenge_observable: "Se a checagem mudou como você reagiu (descansar vs ignorar).",
            learning_objective: "Aplicar 3 perguntas-de-alarme em 1 dor real e decidir resposta.",
            illustration_key: "heart-pulse",
            source: "Ronald Melzack",
            framework: "modelo + experimento"
          },
          {
            slug: "frio-foco-30s",
            title: "Por que frio acorda mais que café?",
            hook: "Um susto de frio acende foco em 30 segundos — sem cafeína, sem açúcar.",
            angle: "Choque térmico libera noradrenalina (3× o nível de base) que dá foco — efeito dura ~1h, sem o crash da cafeína.",
            central_insight: "Se você joga água gelada no rosto ou termina o banho com 30 segundos frio, o cérebro acorda como se fosse alarme — e o foco fica pelas próximas horas.",
            curiosity_facts: [
              "Estudos mostram que 30s a 1min de água fria triplicam o nível de noradrenalina circulante.",
              "Wim Hof testou: pessoas que aplicam frio + respiração toleram baixas temperaturas que 'fisiologicamente impossíveis'.",
              "Banhos frios curtos reduzem inflamação e ajudam recuperação muscular — usado por atletas há décadas."
            ],
            challenge_prompt: "Termine o próximo banho com 30 segundos de água fria. Cronometre. Repare no foco da próxima hora.",
            challenge_when: "hoje",
            challenge_observable: "Se o foco ficou diferente vs. um dia normal sem o frio.",
            learning_objective: "Aplicar 30s de água fria ao fim do banho e comparar foco da hora seguinte.",
            illustration_key: "drop",
            source: "Wim Hof + Andrew Huberman",
            framework: "experimento + dado fisiológico"
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
        title: "Quem decide quando você compra?",
        arc_hook: "Cada compra é uma escolha contra mil outras invisíveis.",
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
              "Pesquisa: ~60% dos itens comprados por impulso teriam sido recusados se houvesse 24h de espera.",
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
            slug: "ja-gastei-tanto",
            title: "Por que 'já gastei tanto' te faz gastar mais?",
            hook: "Dinheiro perdido não volta sendo defendido.",
            angle: "Custo afundado: continuar investindo em algo que já deu errado só pra justificar o que foi gasto antes — armadilha cognitiva clássica.",
            central_insight: "Se você está num filme ruim e pensa 'já paguei o ingresso, vou aguentar', você gasta 2 horas além do dinheiro perdido — agora perde dinheiro E tempo.",
            curiosity_facts: [
              "Daniel Kahneman e Richard Thaler mostraram: humanos defendem perdas como se ainda dessem pra recuperar — quase sempre afundam mais.",
              "Empresas falidas continuam vivas mais tempo do que deveriam só porque sócios não admitem perda.",
              "Esportistas que apostam no jogo errado tendem a dobrar a aposta pra 'recuperar' — quase nunca recuperam."
            ],
            challenge_prompt: "Pense em 1 coisa atual sua (curso, jogo, hábito, projeto) que você só continua por causa do que já investiu. Honesto: vale continuar pelo FUTURO, ou só pelo passado?",
            challenge_when: "esta-semana",
            challenge_observable: "Se admitiu pelo menos 1 'já gastei tanto' que estava te custando mais.",
            learning_objective: "Identificar 1 decisão atual presa em custo afundado e re-avaliar pela frente.",
            illustration_key: "coin",
            source: "Richard Thaler + Daniel Kahneman",
            framework: "experimento mental"
          }
        ]
      },
      {
        slug: "de-onde-dinheiro-nasce",
        title: "De Onde Dinheiro Nasce?",
        arc_hook: "Dinheiro não cai do céu — nasce de habilidade rara, ideia útil ou troca esperta.",
        position: 2,
        missions: [
          {
            slug: "por-que-pagam-mais",
            title: "Por que algumas profissões pagam tanto mais que outras?",
            hook: "Médico ganha 10× o pintor de parede. Por quê?",
            angle: "Oferta e demanda da habilidade: quanto mais raro o conjunto de habilidades + quanto maior a demanda + quanto mais difícil substituir, maior o preço — economia básica de Sowell.",
            central_insight: "Se algo é raro de fazer (poucos sabem) e muito pedido (todo mundo precisa), o preço sobe. Habilidade comum + pouca demanda = pouco pagamento, mesmo trabalho duro.",
            curiosity_facts: [
              "Thomas Sowell: salário é preço da sua habilidade no mercado — nada moral, só raridade × demanda.",
              "Programadores ganham bem porque demanda dispara e formar 1 leva anos — escassez de gente capaz.",
              "Influencer top ganha milhões porque atenção virou recurso raro — e ele junta milhões de atenções num lugar só."
            ],
            challenge_prompt: "Liste 3 profissões que ganham muito e 3 que ganham pouco. Pra cada uma, pergunte: é rara? Tem muita gente precisando? É fácil substituir?",
            challenge_when: "hoje",
            challenge_observable: "Se o padrão de raridade × demanda explica os salários melhor que 'merece' ou 'não merece'.",
            learning_objective: "Aplicar análise oferta-demanda em 6 profissões e detectar o padrão.",
            illustration_key: "coin",
            source: "Thomas Sowell",
            framework: "análise"
          },
          {
            slug: "ideia-vira-dinheiro",
            title: "Como uma ideia vira dinheiro?",
            hook: "Bilhões nascem de gente que viu um problema antes dos outros — e fez algo a respeito.",
            angle: "Dinheiro grande vem de criar valor (resolver problema novo, atender necessidade real) — não de extrair valor (tirar pedaço do que outros fizeram).",
            central_insight: "Se você resolve um problema que muita gente tem, eles te pagam de novo e de novo; se você só tira pedaço do que outros fazem, sua margem some quando alguém faz igual.",
            curiosity_facts: [
              "Airbnb nasceu de 3 caras alugando colchão inflável quando uma feira lotou hotel em SF — viram um problema e construíram a solução.",
              "Mark Cuban virou bilionário não vendendo coisa cara, mas inventando jeito novo de transmitir áudio pela internet em 1995.",
              "Pesquisas mostram: empreendedores que 'resolvem' problema próprio têm 3× mais sucesso que os que 'querem ficar ricos'."
            ],
            challenge_prompt: "Pense em 1 coisa irritante do seu dia (algo que você gostaria que existisse). Anote. Pergunte: quantas pessoas têm o mesmo problema?",
            challenge_when: "hoje",
            challenge_observable: "Se a ideia é boba só pra você ou se outros também sofrem com isso.",
            learning_objective: "Identificar 1 problema próprio + estimar quantas pessoas teriam o mesmo.",
            illustration_key: "spark",
            source: "Paul Graham + Mariana Mazzucato",
            framework: "experimento"
          },
          {
            slug: "dinheiro-facil-e-golpe",
            title: "Por que dinheiro fácil é quase sempre golpe?",
            hook: "Se fosse fácil e seguro, o mundo já teria pegado. Sobrou pra você? Suspeite.",
            angle: "Eficiência do mercado: oportunidades reais não ficam paradas — alguém aproveita. O que 'sobra fácil' geralmente é golpe ou risco escondido.",
            central_insight: "Se alguém te oferece 'rendimento alto, sem risco, urgente, indica amigos', são 4 sinais clássicos de golpe — o mundo inteiro teria filas se fosse verdade.",
            curiosity_facts: [
              "Esquemas de pirâmide têm o mesmo padrão há séculos: prometem retorno grande, exigem urgência, pedem novos participantes.",
              "Charles Ponzi (1920) inventou o esquema-Ponzi prometendo 50% em 90 dias — durou 8 meses antes de explodir.",
              "Charlie Munger: 'me mostre o incentivo e te mostro o resultado' — quem ganha com o convite, geralmente ganha em cima de você."
            ],
            challenge_prompt: "Procure hoje 1 anúncio nas redes que promete 'renda extra fácil'. Aplique os 4 sinais (retorno alto, sem risco, urgência, indica amigos). Conte quantos batem.",
            challenge_when: "hoje",
            challenge_observable: "Quantos dos 4 sinais aparecem no anúncio que você achou.",
            learning_objective: "Aplicar checklist de 4 sinais de golpe em 1 anúncio real.",
            illustration_key: "search",
            source: "Charlie Munger + Charles Ponzi",
            framework: "checklist + caso histórico"
          }
        ]
      },
      {
        slug: "como-dinheiro-cresce",
        title: "Como Dinheiro Cresce Sem Você?",
        arc_hook: "Tempo é o ingrediente que faz dinheiro pequeno virar montanha — se você não atrapalhar.",
        position: 3,
        missions: [
          {
            slug: "guardar-mais-que-gastar",
            title: "Por que pessoas ricas guardam mais que gastam?",
            hook: "Saldo que cresce vence salário que some.",
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
          },
          {
            slug: "inflacao-imposto-invisivel",
            title: "Por que inflação é imposto que ninguém vota?",
            hook: "Pão de 1 real ontem virou pão de 8 reais hoje. Quem aumentou?",
            angle: "Inflação corrói poder de compra: mesmo dinheiro compra menos. Guardar embaixo do colchão = perder devagar sem perceber.",
            central_insight: "Se você não investe nem em renda fixa básica, seu dinheiro encolhe enquanto está guardado — inflação tira sem você assinar nada.",
            curiosity_facts: [
              "Em 1994, R$100 no Brasil compravam 100 pães. Em 2024, compram ~12 — mesmo dinheiro, 8× menos comida.",
              "Milton Friedman: 'inflação é tributação sem legislação' — ninguém vota nela, todos pagam.",
              "Países com inflação altíssima (Venezuela, Argentina recente) — o dinheiro perde valor mais rápido que se ganha."
            ],
            challenge_prompt: "Pergunte pra um adulto da família: quanto custava um pão / uma Coca / uma passagem 20 anos atrás? Calcule o aumento.",
            challenge_when: "esta-semana",
            challenge_observable: "Quanto a vida ficou mais cara mesmo sem ninguém 'subir o preço de propósito'.",
            learning_objective: "Comparar preço de 1 item agora vs. 20 anos atrás e medir corrosão.",
            illustration_key: "coin",
            source: "Milton Friedman",
            framework: "experimento intergeracional"
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
        slug: "palavra-honestidade",
        title: "Palavra & Honestidade",
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
            title: "Por que cumprir o pequeno conta mais que jurar o grande?",
            hook: "Cada 'volto em 10 min' cumprido vale mais que mil promessas solenes.",
            angle: "Cada compromisso cumprido deposita; cada falha saca.",
            central_insight: "Quem cumpre o pequeno todo dia constrói algo invisível — e raríssimo: confiança.",
            curiosity_facts: [
              "Ronald Heifetz: relação carrega 'conta de confiança' — cada gesto pequeno deposita ou saca.",
              "1 falha grande pode anular 20 depósitos.",
              "Pessoas confiáveis ganham, em média, 30% mais ao longo da carreira."
            ],
            challenge_prompt: "Faça 1 compromisso pequeno hoje (ex: 'volto em 10 min'). Cumpra exato.",
            challenge_when: "hoje",
            challenge_observable: "Se a pessoa percebeu (geralmente percebe).",
            learning_objective: "Cumprir 1 compromisso exato em horário e palavra.",
            illustration_key: "check",
            source: "Ronald Heifetz",
            framework: "metáfora financeira"
          },
          {
            slug: "verdade-dura-covardia",
            title: "Quando 'verdade dura' é covardia disfarçada?",
            hook: "Falar a verdade pra descarregar é alívio seu — não bondade.",
            angle: "Verdade que serve tem 3 marcas: é necessária, é dita com cuidado, e quem fala paga o custo. Falta uma das três, vira descarga emocional.",
            central_insight: "Se você fala uma verdade dura sem pensar no outro, você não foi corajoso — descarregou seu desconforto.",
            curiosity_facts: [
              "Provérbios 15:1 (NTLH): 'a resposta branda desvia o furor, mas a palavra dura suscita a ira'.",
              "Pesquisas de psicologia de feedback: críticas que começam por 'sinceramente' costumam ferir 3× mais sem mudar comportamento.",
              "Aristóteles em Ética a Nicômaco: virtude é meio-termo — verdade vira covardia quando falta cuidado, e fofoca quando falta utilidade."
            ],
            challenge_prompt: "Pense numa 'verdade dura' que você sentiu vontade de dizer recentemente. Pergunte: era necessária pro outro? Ou descarregar seria mais pra você?",
            challenge_when: "esta-semana",
            challenge_observable: "Quantas das 'verdades duras' que você diria sobrariam após o filtro.",
            learning_objective: "Aplicar o filtro 'necessidade × cuidado × custo próprio' em 1 verdade dura recente.",
            illustration_key: "users",
            source: "Provérbios + Aristóteles",
            framework: "filtro ético"
          }
        ]
      },
      {
        slug: "coragem-medo",
        title: "Coragem & Medo",
        arc_hook: "Coragem não é a ausência do medo — é dar o passo enquanto ele ainda fala.",
        position: 2,
        missions: [
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
          },
          {
            slug: "esperar-pronto-e-medo",
            title: "Por que 'esperar estar pronto' é não querer começar?",
            hook: "Procrastinação raramente é preguiça. Quase sempre é medo bem educado.",
            angle: "Steven Pressfield chama de 'The Resistance' — quanto mais importante a tarefa pra você, mais o cérebro fabrica desculpas elegantes pra adiar.",
            central_insight: "Se você está adiando algo que sabe que importa, pergunte-se: 'do que estou com medo aqui?' A resposta honesta destrava muito mais que 'só me organizar melhor'.",
            curiosity_facts: [
              "Tim Pychyl (Carleton University) mostra: procrastinadores não têm pior gestão de tempo — têm pior regulação emocional. Adiam pra fugir do desconforto.",
              "Steven Pressfield: 'a resistência é mais forte quanto mais a tarefa importa pra alma da pessoa'.",
              "Estudo: nomear o medo escondido por trás do adiamento reduz procrastinação em ~40% — sem nenhuma técnica de produtividade."
            ],
            challenge_prompt: "Pegue 1 coisa que você está adiando há mais de 1 semana. Em voz alta: 'estou adiando isso porque tenho medo de ___'. Termine a frase honestamente.",
            challenge_when: "hoje",
            challenge_observable: "Qual medo apareceu (rejeição, falhar, parecer bobo, descobrir que não vai dar certo).",
            learning_objective: "Nomear o medo escondido por trás de 1 procrastinação atual.",
            illustration_key: "bolt",
            source: "Steven Pressfield + Tim Pychyl",
            framework: "reframe"
          },
          {
            slug: "pedir-ajuda-pesa-mais",
            title: "Por que pedir ajuda parece mais difícil que sofrer?",
            hook: "Orgulho prefere afundar sozinho a admitir que precisa de mão estendida.",
            angle: "Orgulho ativa a mesma região cerebral do status social — pedir ajuda é interpretado como perda de status, mesmo quando salva a vida. Humildade é treinar o cérebro a aceitar a perda aparente pelo ganho real.",
            central_insight: "Se você espera o problema ficar gigante pra pedir ajuda, quem ajuda fica chocado — não pelo problema, mas por você ter aguentado sozinho tanto tempo. Pedir cedo é força, não fraqueza.",
            curiosity_facts: [
              "Provérbios 11:2: 'quando vem a soberba, vem também a desonra; mas com os humildes está a sabedoria'.",
              "Brené Brown: 'vulnerabilidade não é fraqueza — é o lugar de onde nasce coragem, conexão e criatividade'.",
              "Pesquisa: pessoas que pedem ajuda mais cedo resolvem problemas ~3× mais rápido, e quem ajuda raramente acha menos delas — quase sempre o contrário."
            ],
            challenge_prompt: "Pense em 1 coisa pequena que está te custando há dias e que alguém perto resolveria em minutos. Peça ajuda HOJE.",
            challenge_when: "hoje",
            challenge_observable: "Quão rápido o problema sumiu quando alguém colocou a mão.",
            learning_objective: "Pedir ajuda em 1 problema atual sem esperar 'piorar primeiro'.",
            illustration_key: "users",
            source: "Provérbios + Brené Brown",
            framework: "reframe"
          }
        ]
      },
      {
        slug: "gratidao-contentamento",
        title: "Gratidão & Contentamento",
        arc_hook: "A vista é treinada — você passa a ver o que pratica olhar.",
        position: 3,
        missions: [
          {
            slug: "gratidao-muda-vista",
            title: "Por que gratidão muda o que você vê?",
            hook: "Cérebro grato passa a notar coisas boas que sempre estiveram lá — você ganha vista nova sem mudar o cenário.",
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
            slug: "comparar-te-rouba",
            title: "Por que comparar com os outros rouba o que você tem?",
            hook: "Quem olha pro lado o tempo todo perde o que estava à frente.",
            angle: "Comparação social ascendente (olhar quem tem mais) ativa a mesma região cerebral da inveja — e desativa as regiões da satisfação. O efeito é mensurável e cumulativo.",
            central_insight: "Se você compara o seu bastidor com a vitrine dos outros, sempre vai perder — você está somando os seus problemas reais com a versão polida dos outros.",
            curiosity_facts: [
              "Eclesiastes 4:4: 'todo o esforço e toda a destreza no trabalho representam concorrência do homem com o seu próximo. Também isso é vaidade e correr atrás do vento'.",
              "Pesquisa Penn State (2020): 30 minutos por dia em redes sociais aumentam sintomas de tristeza em ~33% — efeito direto da comparação social.",
              "Filósofo Sêneca: 'aquele que sabe ser pobre é rico' — porque parou de comparar com o que não tem."
            ],
            challenge_prompt: "Hoje, antes de abrir rede social, faça a pergunta: 'eu vou comparar a minha vida real com a vitrine dos outros?'. Se sim, espere mais 1h.",
            challenge_when: "hoje",
            challenge_observable: "Quantas vezes a comparação aconteceu mesmo com aviso prévio.",
            learning_objective: "Aplicar 1 pausa consciente antes de feed e notar o efeito da comparação.",
            illustration_key: "search",
            source: "Eclesiastes + Sêneca",
            framework: "tradição + dado"
          },
          {
            slug: "reclamar-te-enfraquece",
            title: "Por que reclamar enfraquece — mesmo quando dá razão?",
            hook: "Toda queixa treina o cérebro a notar mais o que dá pra reclamar.",
            angle: "Cada reclamação ativa neurônios que pavimentam o caminho — a 10ª vez que você se queixa do mesmo, fica mais fácil enxergar o problema e mais difícil enxergar saída.",
            central_insight: "Se você reclama de algo todo dia, você não está 'desabafando' — está treinando seu cérebro a ver mais problema e menos solução. O ruim cresce com a luz que você dá.",
            curiosity_facts: [
              "Marco Aurélio, Meditações (séc. II): 'a felicidade da sua vida depende da qualidade dos seus pensamentos'.",
              "Pesquisas de Steven Parton mostram: ouvir reclamação dos outros encolhe o hipocampo (memória) — efeito mensurável.",
              "Provérbios 17:22: 'o coração alegre é bom remédio, mas o espírito abatido seca os ossos'."
            ],
            challenge_prompt: "Hoje, marque cada vez que você reclamar de algo (escreva mentalmente um X). À noite, conte. Aposto que vai surpreender.",
            challenge_when: "hoje",
            challenge_observable: "Quantas reclamações você soltou — provavelmente mais do que esperava.",
            learning_objective: "Contar honestamente o número de reclamações em 1 dia e ficar consciente da frequência.",
            illustration_key: "search",
            source: "Marco Aurélio + Provérbios",
            framework: "experimento"
          },
          {
            slug: "perdao-liberta-quem-perdoa",
            title: "Por que perdoar liberta quem perdoa (não quem é perdoado)?",
            hook: "Guardar mágoa é beber veneno e esperar o outro morrer.",
            angle: "Hannah Arendt: perdão é a única ação que quebra o ciclo de retaliação. Marcos 11:25 + Mateus 6:14 — perdoar não é dizer 'tudo bem'; é largar a corda que prendia você ao machucado.",
            central_insight: "Se você guarda mágoa, paga pedágio cerebral todo dia revivendo a cena — o outro raramente sabe. Perdoar não inocenta ele; liberta você do pedágio diário.",
            curiosity_facts: [
              "Hannah Arendt: 'sem perdão, ficamos presos a um único ato pra sempre' — perdão é a saída de emergência do passado.",
              "Estudo Forgiveness Project (Charlotte vanOyen Witvliet, Hope College): pessoas que praticam perdão têm pressão arterial e cortisol menores — efeito biológico, não só emocional.",
              "Marcos 11:25 e Eclesiástico 28:2 — tradição cristã há 2 mil anos diz: perdão é receita pra a alma própria, não favor pro outro."
            ],
            challenge_prompt: "Pense em 1 mágoa antiga que ainda te visita. Escreva uma frase: 'eu solto isso porque me cansa carregar'. Releia em 3 dias.",
            challenge_when: "esta-semana",
            challenge_observable: "Se a mágoa visitou menos vezes a sua cabeça nessa semana.",
            learning_objective: "Praticar 1 ato deliberado de soltar uma mágoa pequena.",
            illustration_key: "sparkle",
            source: "Hannah Arendt + Marcos 11:25",
            framework: "tradição + dado fisiológico"
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
        title: "Como as Máquinas Pensam?",
        arc_hook: "Quem entende como a máquina decide, decide melhor sobre ela.",
        position: 1,
        missions: [
          {
            slug: "loop-feedback",
            title: "Como um app sabe o que mudar pra te prender mais?",
            hook: "Todo app roda um loop: mostra → mede sua reação → ajusta → mostra de novo.",
            angle: "Loop de feedback (controle): sistema lê o efeito da última ação no usuário e usa o sinal pra calibrar a próxima.",
            central_insight: "Se você entende que app é 'mostra → mede você → corrige', você lê os truques antes deles te lerem.",
            curiosity_facts: [
              "Termostato, piloto automático e TikTok funcionam com a mesma lógica: medir, comparar com alvo, corrigir.",
              "Engenheiros chamam de 'closed loop' — fechado porque a saída vira entrada da próxima rodada.",
              "Quanto mais rápido o ciclo, mais o sistema se ajusta a você sem você perceber."
            ],
            challenge_prompt: "Abra 1 app e tente identificar 3 'medições' que ele faz da sua reação (tempo de scroll, pausa em vídeo, palavra digitada).",
            challenge_when: "hoje",
            challenge_observable: "Quantos sinais o app coleta que você nem imaginava.",
            learning_objective: "Identificar 3 sinais que o app mede em você em tempo real.",
            illustration_key: "phone",
            source: "Pensamento computacional / teoria de controle",
            framework: "metáfora"
          },
          {
            slug: "probabilidade-do-dado",
            title: "Por que '1 em 6' não é promessa do próximo lançamento?",
            hook: "Dado tem 1 em 6 de cair no 5 — mas pode cair 4 vezes seguidas sem nenhum 5. Não é mágica.",
            angle: "Probabilidade descreve frequência em N tentativas grandes, não previsão de uma só tentativa.",
            central_insight: "Se você entende que '1 em 6' é promessa de longo prazo, não do próximo lance, você para de cair em armadilha de azarão.",
            curiosity_facts: [
              "Pra '1 em 6' aparecer no esperado, precisa de centenas de lançamentos, não 6.",
              "Cassinos lucram porque a galera confunde 'chance' com 'garantia da próxima vez'.",
              "Mesma lógica vale pra IA que dá probabilidade: '92% de gato' não é certeza."
            ],
            challenge_prompt: "Lance um dado 12 vezes e anote. Aposto que o 5 NÃO sai exatamente 2 vezes — ou cai mais, ou cai menos.",
            challenge_when: "hoje",
            challenge_observable: "Quantas vezes o 5 caiu em 12 lances.",
            learning_objective: "Distinguir frequência esperada (longo prazo) de previsão do próximo evento.",
            illustration_key: "spark",
            source: "Fundamentos de probabilidade",
            framework: "experimento"
          },
          {
            slug: "como-ia-decide",
            title: "Como ChatGPT realmente toma decisão?",
            hook: "ChatGPT não pensa. Ele chuta a próxima palavra com base em padrão de trilhões de textos humanos.",
            angle: "LLM (Large Language Model) como preditor estatístico de próximo token. Não há entendimento — há frequência de padrão.",
            central_insight: "Se você entende que IA está chutando estatisticamente o que parece resposta certa, você sabe quando duvidar — Provérbios 14:15 diz: 'o prudente atenta para os seus passos'.",
            curiosity_facts: [
              "ChatGPT foi treinado em ~10 trilhões de palavras humanas — a Wikipédia inteira é menos de 0,5% disso.",
              "Pra cada palavra que ela escreve, calcula a probabilidade de milhares de próximas palavras e escolhe a mais provável.",
              "Em perguntas sobre fatos específicos, erra entre 15% e 25% — e fala com a mesma confiança quando acerta e quando inventa."
            ],
            challenge_prompt: "Faça 3 perguntas factuais à IA hoje (datas, nomes, números) e cheque cada resposta numa fonte externa. Aposto que pelo menos 1 tem erro escondido.",
            challenge_when: "hoje",
            challenge_observable: "Quantas respostas tinham erro factual quando você verificou em outra fonte.",
            learning_objective: "Tratar IA como ferramenta estatística com erro — não como oráculo que 'sabe'.",
            illustration_key: "spark",
            source: "Emily Bender / 'stochastic parrots' + Provérbios 14:15",
            framework: "desmistificação + discernimento cristão"
          }
        ]
      },
      {
        slug: "internet-de-verdade",
        title: "Como a Internet Realmente Funciona",
        arc_hook: "Antes da mágica, tem cabos, números e fila — desmistificar é poder.",
        position: 2,
        missions: [
          {
            slug: "digito-youtube-o-que-rola",
            title: "O que acontece entre você digitar 'youtube.com' e o vídeo aparecer?",
            hook: "Em meio segundo, sua mensagem dá meio planeta de volta — e ninguém te explica como.",
            angle: "DNS + roteamento: nome (youtube.com) vira número (IP), pacotes viajam por dezenas de roteadores até o servidor, voltam com vídeo em pedaços.",
            central_insight: "Se cada nome de site é só apelido que precisa ser traduzido em número, e cada mensagem viaja em pedacinhos por caminhos diferentes, internet é correio rápido — não mágica.",
            curiosity_facts: [
              "Servidores DNS são tipo lista telefônica gigante — quando você digita 'youtube.com', alguém pergunta 'qual é o IP disso?' antes da conexão começar.",
              "Sua mensagem viaja em pacotes de até 1500 bytes cada — quebrada em pedacinhos que podem pegar caminhos diferentes e se reagrupar no destino.",
              "Vint Cerf e Bob Kahn inventaram TCP/IP em 1973 — o protocolo que governa praticamente toda a internet até hoje."
            ],
            challenge_prompt: "Abra o terminal e digite 'ping youtube.com'. Veja o IP que aparece e quantos milissegundos demora a resposta.",
            challenge_when: "hoje",
            challenge_observable: "Qual o IP que aparece e quanto tempo a viagem leva.",
            learning_objective: "Executar 1 ping e ver IP + latência real até um servidor.",
            illustration_key: "spark",
            source: "Vint Cerf + Bob Kahn",
            framework: "desmistificação"
          },
          {
            slug: "wifi-onda-com-limite",
            title: "Por que WiFi não tem fio mas tem limite?",
            hook: "WiFi não é mágica nem vácuo — é onda invisível que se atrapalha com as outras.",
            angle: "WiFi é onda de rádio em frequências específicas (2,4 e 5 GHz). Quanto mais dispositivos no mesmo canal, mais 'pessoas falando ao mesmo tempo' — congestionamento que reduz velocidade.",
            central_insight: "Se WiFi é só onda de rádio dividida em canais, todo dispositivo conectado divide o mesmo bolo — em casa cheia, todos ficam lentos porque a fila é a mesma.",
            curiosity_facts: [
              "WiFi tem ~14 canais em 2,4GHz — mas só 3 não se sobrepõem (1, 6, 11). Vizinhos no mesmo canal brigam pela mesma faixa.",
              "Microondas operam em 2,45 GHz — quase a mesma frequência do WiFi 2,4 GHz, por isso esquentar comida pode derrubar conexão.",
              "5 GHz é mais rápido e menos congestionado, mas atravessa parede pior — por isso o WiFi do quarto distante fica fraco."
            ],
            challenge_prompt: "Veja quantos dispositivos estão conectados ao WiFi de casa agora. Tente baixar algo grande com tudo conectado vs. com metade desligado. Compare.",
            challenge_when: "hoje",
            challenge_observable: "Se a velocidade muda quando você reduz dispositivos na rede.",
            learning_objective: "Comparar velocidade de download com diferentes números de dispositivos ativos.",
            illustration_key: "spark",
            source: "Guglielmo Marconi (base do rádio)",
            framework: "experimento"
          },
          {
            slug: "quem-decide-busca",
            title: "Quem decide a ordem das respostas no Google?",
            hook: "Você pergunta. Aparecem 10 milhões. Os 10 primeiros são escolhidos por fórmula secreta.",
            angle: "Algoritmo de busca (PageRank evoluído) ranqueia páginas por dezenas de sinais: links recebidos, qualidade percebida, comportamento do usuário, idioma, localização — tudo simultâneo.",
            central_insight: "Se buscador não 'sabe a verdade' e sim ordena por fórmula, então quem aparece em cima ganhou o jogo da fórmula — não necessariamente é o melhor.",
            curiosity_facts: [
              "Larry Page e Sergey Brin criaram PageRank em 1998 — a ideia central: páginas com mais links de outras páginas importantes sobem.",
              "Hoje o algoritmo do Google considera mais de 200 fatores diferentes pra ordenar os resultados.",
              "Páginas que dominam o topo geralmente pagam SEO especialistas — não são necessariamente as mais corretas, são as mais 'otimizadas pra a fórmula'."
            ],
            challenge_prompt: "Pesquise 1 pergunta de curiosidade no Google. Anote os 3 primeiros resultados. Pergunte: por que esses? Pague atenção ao tipo de site.",
            challenge_when: "hoje",
            challenge_observable: "Padrão dos 3 primeiros (site grande, com publicidade, atualizado recentemente).",
            learning_objective: "Identificar 3 sinais que provavelmente colocaram os top 3 resultados em destaque.",
            illustration_key: "search",
            source: "Larry Page + Sergey Brin",
            framework: "desmistificação"
          },
          {
            slug: "video-chega-rapido-como",
            title: "Como vídeo do TikTok chega tão rápido se está em outro país?",
            hook: "Vídeo NÃO vem da China. Tem cópia 30km de você.",
            angle: "CDN (Content Delivery Network): grandes plataformas mantêm CÓPIAS dos vídeos populares em servidores espalhados pelo planeta — quando você abre, o vídeo vem do servidor mais próximo, não da matriz.",
            central_insight: "Se TikTok carrega vídeo viral em 1 segundo, é porque ele já estava ESPELHADO em um servidor perto de você antes de você pedir — ninguém esperou a viagem física até a China.",
            curiosity_facts: [
              "Cloudflare, Akamai e Netflix Open Connect têm milhares de servidores espalhados pelo mundo — quase todo tráfego importante passa por eles.",
              "Netflix coloca 'caixas' de armazenamento dentro de provedores de internet locais — o filme que você assiste pode estar literalmente no prédio do seu provedor.",
              "Sem CDN, qualquer vídeo viral derrubaria o servidor original — milhões de pessoas pedindo ao mesmo tempo, sem rede de cópias."
            ],
            challenge_prompt: "Abra 'whatismyipaddress.com' e veja sua cidade detectada. Abra um vídeo no YouTube e cheque (em ferramentas de desenvolvedor → network) de onde o vídeo vem.",
            challenge_when: "hoje",
            challenge_observable: "Se o vídeo vem de servidor próximo (Brasil) ou distante (EUA).",
            learning_objective: "Comparar localização do servidor de vídeo com sua localização atual.",
            illustration_key: "spark",
            source: "Adrian Cockcroft (arquitetura Netflix)",
            framework: "desmistificação"
          }
        ]
      },
      {
        slug: "privacidade-seguranca",
        title: "Privacidade e Segurança Digital",
        arc_hook: "O que você posta tem cópia em mil lugares — e quem te vê continua vendo mesmo sem login.",
        position: 3,
        missions: [
          {
            slug: "algoritmo-tem-limites",
            title: "Por que o feed não te mostra tudo que existe?",
            hook: "Antes do algoritmo escolher, regras de idade e tema cortam categorias inteiras — você nem vê.",
            angle: "Camadas de filtro (safeguards): idade declarada, palavras proibidas, modo restrito e horário rodam antes do algoritmo de recomendação.",
            central_insight: "Se você entende que existem freios antes do algoritmo, você para de achar que ele 'sabe tudo de você' — ele só escolhe dentro do que a regra deixou passar.",
            curiosity_facts: [
              "Mesma conta de família, idades diferentes: feeds diferentes — o filtro de idade roda ANTES da recomendação.",
              "Palavras-chave proibidas (violência gráfica, automutilação, drogas) somem mesmo se você buscar direto.",
              "Modo restrito do YouTube corta ~30 em cada 100 vídeos candidatos antes deles chegarem na tela."
            ],
            challenge_prompt: "Tente abrir 3 conteúdos pesados hoje (luta intensa, prank perigoso, etc.). Conte quantas telas de 'restrito' aparecem.",
            challenge_when: "hoje",
            challenge_observable: "Quantos vídeos foram bloqueados antes de carregar.",
            learning_objective: "Reconhecer pelo menos 2 camadas de filtro (idade, tema, horário, modo restrito) operando antes do feed.",
            illustration_key: "search",
            source: "Provérbios 22:6 + relatórios de transparência YouTube/TikTok",
            framework: "desmistificação + safeguards"
          },
          {
            slug: "foto-fica-mesmo-apagada",
            title: "Por que sua foto fica em 5 lugares mesmo depois de apagar?",
            hook: "Internet é tinta, não giz — apagar do seu feed não apaga do mundo.",
            angle: "Cada upload é replicado: cópia no servidor da plataforma, no cache de CDN, no celular de quem viu, em screenshots, em backups da plataforma. Apagar 1 cópia (a sua) não toca as outras 4.",
            central_insight: "Se você posta uma foto, no instante seguinte ela tem 5 cópias — sua decisão de apagar só remove 1. Por isso pensar 2 vezes antes de postar vale mais que apagar depois.",
            curiosity_facts: [
              "Wayback Machine (archive.org) preserva versões antigas de bilhões de sites — coisas apagadas vivem lá pra sempre.",
              "Bruce Schneier, especialista em segurança: 'na internet, a memória é o padrão; o esquecimento é o esforço'.",
              "Estudos mostram que ~40% das fotos comprometedoras de adolescentes online foram postadas pela pessoa MESMA — e apagadas depois sem efeito."
            ],
            challenge_prompt: "Pegue 1 post seu antigo. Imagine que ele foi visto por 5 pessoas que não conhecem você. Como ele soaria pra elas hoje?",
            challenge_when: "hoje",
            challenge_observable: "Se o post envelheceu bem ou se você o veria diferente hoje.",
            learning_objective: "Avaliar 1 post próprio antigo pela perspectiva de quem não conhece o contexto.",
            illustration_key: "search",
            source: "Bruce Schneier",
            framework: "reframe"
          },
          {
            slug: "ve-quem-te-ve",
            title: "Sem login, eles ainda te reconhecem. Como?",
            hook: "Você é uma digital invisível: fonte, tela, idioma, hora do clique.",
            angle: "Fingerprinting: combinação única de fonte instalada + resolução + idioma + extensões + GPU = identifica seu navegador entre milhões, mesmo sem cookie nem login.",
            central_insight: "Se mesmo sem login os sites te reconhecem por combinação de detalhes, então 'modo anônimo' não esconde tudo — apenas o cookie. O fingerprint vai junto.",
            curiosity_facts: [
              "EFF (Electronic Frontier Foundation) tem o site 'Cover Your Tracks' — testa quão único é seu navegador. Geralmente é único entre milhões.",
              "Browsers como Brave e Firefox lançaram features anti-fingerprinting nos últimos anos — Chrome ainda é mais permissivo.",
              "Cory Doctorow: 'modo anônimo te esconde de você mesmo, não dos sites'."
            ],
            challenge_prompt: "Entre em 'coveryourtracks.eff.org' e clique 'test your browser'. Veja quão único você é online.",
            challenge_when: "hoje",
            challenge_observable: "Quão raro é seu fingerprint — quase sempre 1 em milhões.",
            learning_objective: "Rodar 1 teste de fingerprint e ver a unicidade do próprio navegador.",
            illustration_key: "search",
            source: "Electronic Frontier Foundation + Cory Doctorow",
            framework: "experimento"
          },
          {
            slug: "senha-unica-vale-mais",
            title: "Senha forte ou senha única? Qual vale mais?",
            hook: "Senha forte que você usa em todo site é igual chave de cofre que abre 100 casas.",
            angle: "Vazamento de senha em 1 site exposto = vazamento em todos os sites que usaram a mesma. Único vence forte: senha única medíocre é mais segura que senha forte reutilizada.",
            central_insight: "Se você usa a mesma senha em 10 sites, basta UM ser hackeado pra todos os 10 caírem — único é mais importante que forte.",
            curiosity_facts: [
              "Have I Been Pwned (haveibeenpwned.com): bilhões de senhas vazadas estão lá; digite seu email e veja em quantos vazamentos você está.",
              "Gerenciadores de senha (Bitwarden, 1Password) resolvem o problema: você decora 1 forte, eles geram únicas pra cada site.",
              "Pesquisa: 65% das pessoas reutilizam senhas entre sites — por isso vazamentos pegam tantas contas em cadeia."
            ],
            challenge_prompt: "Entre em haveibeenpwned.com com seu email principal. Veja em quantos vazamentos você apareceu.",
            challenge_when: "hoje",
            challenge_observable: "Quantos vazamentos do seu email — quase sempre mais que 1.",
            learning_objective: "Verificar quantos vazamentos atingiram 1 email seu real.",
            illustration_key: "search",
            source: "Troy Hunt (Have I Been Pwned)",
            framework: "experimento"
          },
          {
            slug: "antes-de-enviar-pense",
            title: "Antes de mandar essa mensagem: se a sua vó lesse, mandava?",
            hook: "Tela apaga o filtro que existiria cara-a-cara — antes de enviar, imagine quem te ama lendo.",
            angle: "Desinibição online: anonimato + ausência do rosto do outro + impulsividade da tela liberam falas que pessoa nunca soltaria pessoalmente. O conteúdo fica gravado e ressoa muito além do momento.",
            central_insight: "Se você hesita em mostrar a mensagem pra quem te ama, não envie. Tela apagou o filtro, mas a consequência viaja igual.",
            curiosity_facts: [
              "John Suler descreveu em 2004 o 'online disinhibition effect' — sem o rosto do outro presente, falamos coisas que jamais diríamos cara-a-cara.",
              "Conselho clássico: leia em voz alta antes de enviar. Se soaria estranho na frente da sua avó, é sinal pra apagar e reescrever.",
              "Provérbios 15:1: 'a resposta branda desvia o furor; a palavra dura suscita a ira'. 2.500 anos antes do WhatsApp."
            ],
            challenge_prompt: "Antes da próxima mensagem 'no impulso' hoje, espere 60 segundos. Releia. Se soaria mal de boca, reescreva.",
            challenge_when: "hoje",
            challenge_observable: "Quantas mensagens você reescreveu antes de mandar.",
            learning_objective: "Aplicar 1 pausa de 60s antes de mandar 1 mensagem impulsiva.",
            illustration_key: "users",
            source: "John Suler + Provérbios 15:1",
            framework: "regra prática + tradição"
          }
        ]
      },
      {
        slug: "voce-criando",
        title: "Você Criando",
        arc_hook: "Quem cria muda — quem só consome aprende sobre os outros, não sobre si.",
        position: 4,
        missions: [
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
          },
          {
            slug: "codigo-e-receita-executavel",
            title: "Como uma linha de código faz coisa?",
            hook: "Código não é mágica — é receita que a máquina segue sem improvisar.",
            angle: "Programar é decompor problema em passos exatos + variáveis (caixinhas com nomes) + condicionais (se isso, faça aquilo) + repetição. O computador executa literal — diferente de pessoa, não 'entende o que você quis dizer'.",
            central_insight: "Se computador segue receita literal e nunca 'preenche o que faltou', então quem escreve código bom é quem aprende a pensar com clareza — programar treina raciocínio mais que digitação.",
            curiosity_facts: [
              "Seymour Papert (MIT) criou em 1967 a linguagem LOGO, com tartaruga que andava em comando — crianças de 8 anos programando geometria.",
              "Hoje, Scratch (do MIT também) tem 100+ milhões de usuários no mundo — código por blocos, sem digitar nada.",
              "GPT-4 e outras IAs facilitaram MUITO escrever código — mas quem entende lógica usa essas ferramentas 10× melhor que quem não entende."
            ],
            challenge_prompt: "Entre em scratch.mit.edu. Em 10 minutos, faça uma tartaruga (sprite) andar 100 passos pra direita e mudar de cor. Sem tutorial: tente.",
            challenge_when: "hoje",
            challenge_observable: "Se você conseguiu fazer a tartaruga obedecer 2 comandos seguidos.",
            learning_objective: "Programar em Scratch 1 sprite executando 2 comandos sequenciais.",
            illustration_key: "spark",
            source: "Seymour Papert",
            framework: "experimento + introdução"
          },
          {
            slug: "copiar-pra-aprender",
            title: "Copiar pra aprender é gold. Copiar pra entregar é roubo. Como distinguir?",
            hook: "A mesma cópia muda de nome conforme o que você faz com ela depois.",
            angle: "Copiar pra entender o COMO (replicar pra estudar a técnica) é base do aprendizado de toda arte e ofício. Copiar pra ENTREGAR como seu é roubo. O divisor é: cita ou esconde?",
            central_insight: "Se você copia algo, replica pra aprender o jeito, e depois cria sua versão com aquela técnica — você virou aprendiz. Se copia, esconde e entrega — virou ladrão.",
            curiosity_facts: [
              "Austin Kleon (Steal Like an Artist): 'todos os artistas começam copiando — o segredo é copiar muitos, não um só, e citar quem te ensinou'.",
              "Picasso disse: 'bons artistas copiam, grandes artistas roubam' — querendo dizer 'absorvem tão profundamente que vira parte deles'. Diferente de plagiar.",
              "Wikipedia funciona em modelo de cópia com citação — é por isso que ela cresceu mais que qualquer enciclopédia tradicional."
            ],
            challenge_prompt: "Pegue 1 desenho/texto/música que você gosta. Tente reproduzir até onde conseguir. Marque o que aprendeu. (Não entregue como seu — só estude.)",
            challenge_when: "esta-semana",
            challenge_observable: "Qual técnica nova você captou ao tentar replicar.",
            learning_objective: "Reproduzir 1 obra alheia pra estudar técnica e nomear o que aprendeu.",
            illustration_key: "magic",
            source: "Austin Kleon + Picasso",
            framework: "ética + prática"
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
        title: "Quando Trava — o Que Fazer?",
        arc_hook: "Travar é dado, não fracasso — desde que você leia o sinal.",
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
            hook: "Acertar só confirma o que já sabe. Errar é o que ensina o novo.",
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
      },
      {
        slug: "mente-de-cientista",
        title: "Mente de Cientista",
        arc_hook: "Quem tenta confirmar, confirma. Quem tenta refutar, aprende.",
        position: 2,
        missions: [
          {
            slug: "cientista-tenta-refutar",
            title: "Por que cientista tenta provar que está errado?",
            hook: "Boa hipótese é a que PODE quebrar — não a que parece bonita.",
            angle: "Karl Popper: refutabilidade. Uma teoria boa faz previsão específica que poderia falhar; uma teoria 'que explica tudo' não explica nada.",
            central_insight: "Se sua ideia não tem como ser provada errada, ela não é teoria — é fé disfarçada. O sinal de uma boa hipótese é poder cair, e não cair quando testada.",
            curiosity_facts: [
              "Karl Popper (1934) revolucionou a filosofia da ciência: ciência avança por refutação, não por confirmação.",
              "Einstein previu em 1915 que a gravidade do sol deformaria luz das estrelas em ângulo exato. Em 1919, eclipse confirmou. Se NÃO tivesse confirmado, teoria caía. Por isso era teoria de verdade.",
              "Astrologia, teorias da conspiração e auto-ajuda 'tudo explica' são clássicas em NÃO serem refutáveis — explicam qualquer resultado, então não predizem nada."
            ],
            challenge_prompt: "Pegue 1 opinião sua. Pergunte: 'que prova me faria mudar de ideia?'. Se não tem resposta clara, suspeite — é fé, não opinião.",
            challenge_when: "hoje",
            challenge_observable: "Se foi fácil achar uma prova refutadora ou se nada te faria mudar de ideia.",
            learning_objective: "Aplicar teste de refutabilidade em 1 opinião própria.",
            illustration_key: "search",
            source: "Karl Popper",
            framework: "teste filosófico"
          },
          {
            slug: "pergunta-decide-resposta",
            title: "Por que o jeito de fazer a pergunta decide a resposta?",
            hook: "'Salvar 70%' soa diferente de 'perder 30%' — mesma matemática, sentimentos opostos.",
            angle: "Framing (Tversky e Kahneman): a forma como a opção é apresentada muda completamente a escolha, mesmo quando o conteúdo é idêntico.",
            central_insight: "Se você muda a pergunta, muda a resposta — e quem controla o framing controla a decisão sem você perceber.",
            curiosity_facts: [
              "Experimento clássico (1981): dois grupos receberam mesmo problema com palavras diferentes. Grupo 'salvar 200 de 600' escolheu a opção segura; grupo 'deixar morrer 400 de 600' escolheu a arriscada. Mesma matemática.",
              "Médicos: pacientes aceitam mais uma cirurgia se ouvem '90% de sobrevivência' do que '10% de mortalidade' — mesma estatística, decisão diferente.",
              "Propaganda usa framing o tempo todo: 'iogurte com 95% sem gordura' vende mais que 'iogurte com 5% de gordura'."
            ],
            challenge_prompt: "Hoje, pegue 1 propaganda e tente REESCREVER a frase principal pelo lado contrário (perder vs ganhar, antes vs depois). Veja se muda o impacto.",
            challenge_when: "hoje",
            challenge_observable: "Se a versão invertida soa menos atraente — o que diz da força do framing original.",
            learning_objective: "Inverter o framing de 1 propaganda real e comparar impacto emocional.",
            illustration_key: "search",
            source: "Amos Tversky + Daniel Kahneman",
            framework: "experimento"
          },
          {
            slug: "intuicao-vs-calculo-quando",
            title: "Quando intuição vence cálculo (e quando ela mente)?",
            hook: "Bombeiro veterano sente o teto cair sem calcular. Investidor 'sente' o mercado e quebra.",
            angle: "Gary Klein × Daniel Kahneman: intuição funciona QUANDO há (1) domínio estável + (2) feedback rápido + (3) muitas horas de prática. Falta um, intuição é palpite disfarçado.",
            central_insight: "Se o ambiente é estável e você tem milhares de horas + feedback rápido (bombeiro, médico de emergência), intuição é gold. Se é caótico (bolsa, política, futuro), intuição é miragem — calcule.",
            curiosity_facts: [
              "Bombeiro veterano que 'sentiu' o piso ceder e mandou time sair antes de incêndio (sem entender por que) — depois descobriram: temperatura assimétrica que ele percebeu inconscientemente.",
              "Pesquisas com investidores: nenhuma estratégia de 'sentir o mercado' venceu fundo passivo de índice em 10 anos consecutivos.",
              "Daniel Kahneman e Gary Klein chegaram a um acordo raro: ambos concordam que intuição vale, MAS só nos domínios certos."
            ],
            challenge_prompt: "Pense em 1 decisão que você vai tomar essa semana. Pergunte: é domínio estável + feedback rápido + muita prática minha? Se sim, intuição vale. Se não, calcule.",
            challenge_when: "esta-semana",
            challenge_observable: "Em qual das duas situações sua intuição estaria certa vs. arriscada.",
            learning_objective: "Aplicar critério de Klein-Kahneman em 1 decisão real.",
            illustration_key: "puzzle",
            source: "Gary Klein + Daniel Kahneman",
            framework: "modelo de decisão"
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
            title: "Por que quase ninguém escuta de verdade?",
            hook: "Quem escuta 5 minutos sem interromper, em 1 conversa só, fica memorável pra vida.",
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
            hook: "Toda propaganda usa 3 truques antigos — quem aprende a vê-los, para de cair em quase todos.",
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
            title: "Por que 2 segundos de silêncio depois que o outro fala vira ouro?",
            hook: "Quem espera 2 segundos antes de responder ganha mais que quem responde rápido.",
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
      },
      {
        slug: "conflito-sem-destruir",
        title: "Conflito Sem Destruir",
        arc_hook: "Discordar sem virar inimigo é a arte que separa relação de campo de batalha.",
        position: 2,
        missions: [
          {
            slug: "defender-endurece-opiniao",
            title: "Por que defender uma opinião em voz alta endurece ela em você?",
            hook: "Cada vez que você defende algo publicamente, fica mais difícil mudar de ideia depois.",
            angle: "Efeito de compromisso (Cialdini) + identidade-voto: defender em voz alta vira 'sou alguém que pensa X' — refutar agora ameaça identidade, não só ideia.",
            central_insight: "Se você defende uma opinião publicamente, ela vira parte sua — e mudar passa a custar não 'admitir erro de ideia', mas 'admitir derrota de identidade'. Por isso quase ninguém muda de ideia em briga.",
            curiosity_facts: [
              "Robert Cialdini: pessoas que escreveram a favor de uma posição (mesmo sem acreditar) começam a acreditar mais nela em dias.",
              "Estudo clássico de Festinger: dissonância cognitiva — quanto mais alto o custo de defender uma posição, mais a pessoa passa a acreditar nela.",
              "Por isso negociadores experientes não pedem 'admita que está errado' — pedem 'me ajude a entender' e dão saída pro outro mudar sem perder cara."
            ],
            challenge_prompt: "Em discussão hoje, tente NÃO defender publicamente sua posição imediatamente. Diga 'preciso pensar mais' antes. Veja se a opinião muda depois.",
            challenge_when: "hoje",
            challenge_observable: "Se conseguir mais informação antes de declarar mudou a opinião final.",
            learning_objective: "Adiar declaração pública em 1 discussão e re-avaliar depois.",
            illustration_key: "users",
            source: "Robert Cialdini + Leon Festinger",
            framework: "experimento social"
          },
          {
            slug: "100-certo-e-cego",
            title: "Por que '100% certo' é sinal de cego?",
            hook: "Quem nunca achou que o outro também tem ponto, ainda não tem ponto bom.",
            angle: "Princípio da caridade (Daniel Dennett, regra das discussões honestas): primeiro entenda o argumento do outro tão bem que ele aceitaria sua descrição — depois discorde, se ainda discordar.",
            central_insight: "Se você só sabe descrever a opinião do outro de forma ridícula, você ainda não a entendeu — e qualquer crítica que faz vai pra um espantalho, não pra a posição real.",
            curiosity_facts: [
              "Daniel Dennett: 4 regras pra crítica honesta — comece reescrevendo o argumento do outro tão bem que ele diga 'isso! eu queria ter dito assim!'.",
              "John Stuart Mill: 'quem só conhece o próprio lado, conhece pouco — não viu o argumento do outro completo'.",
              "Em debates políticos, ~80% das pessoas conseguem caricaturar bem 'o outro lado' mas não conseguem reproduzir o melhor argumento oposto. Sinal de espantalho."
            ],
            challenge_prompt: "Pegue 1 opinião que você considera errada. Tente escrever em 3 frases o MELHOR argumento de quem pensa o contrário — como se você acreditasse.",
            challenge_when: "hoje",
            challenge_observable: "Se foi mais difícil que parecia escrever o argumento contra como se fosse seu.",
            learning_objective: "Reconstruir argumento oposto em 3 frases sem caricaturar.",
            illustration_key: "search",
            source: "Daniel Dennett + John Stuart Mill",
            framework: "exercício filosófico"
          },
          {
            slug: "pedido-dificil-sem-inimigo",
            title: "Como pedir uma coisa difícil sem virar inimigo?",
            hook: "DESC: Descrever + Expressar + Sugerir + Consequência. Pedidos viram diálogo, não ataque.",
            angle: "Modelo DESC (Bower & Bower): em vez de acusar ('você nunca…'), descrever fato + sentimento + sugestão + impacto — desarma defesa e abre conversa.",
            central_insight: "Se você quer mudança real do outro, não acuse — descreva o que viu, expresse o que sentiu, sugira o que quer, mostre o impacto. 'Você é egoísta' não muda nada. DESC muda quase sempre.",
            curiosity_facts: [
              "Modelo DESC nasceu em 1976 em terapia comportamental — foi adotado por gestores, pais, casais.",
              "Pesquisa de comunicação: pedidos no formato DESC têm 4× mais chance de mudar comportamento do outro vs. acusação direta.",
              "Marshall Rosenberg (Comunicação Não-Violenta) construiu modelo parecido — observação, sentimento, necessidade, pedido."
            ],
            challenge_prompt: "Pegue 1 reclamação que você tem com alguém próximo. Reescreva no formato DESC. Tente conversar usando essa versão.",
            challenge_when: "esta-semana",
            challenge_observable: "Se a outra pessoa ouviu sem defesa imediata.",
            learning_objective: "Aplicar DESC em 1 conversa difícil real.",
            illustration_key: "users",
            source: "Sharon Bower + Marshall Rosenberg",
            framework: "modelo em 4 passos"
          }
        ]
      },
      {
        slug: "voce-e-multidao",
        title: "Você e a Multidão",
        arc_hook: "Quem segue a maioria sem ver, vira ela — sem decidir.",
        position: 3,
        missions: [
          {
            slug: "7-erradas-vs-1-certa",
            title: "Por que 7 pessoas erradas convencem 1 certa a ficar calada?",
            hook: "Asch mostrou: maioria errada faz pessoa certa duvidar do próprio olho.",
            angle: "Experimento de Solomon Asch (1951): 75% das pessoas concordaram com resposta visivelmente errada quando 7 outros antes deles deram a errada — pressão social vence percepção direta.",
            central_insight: "Se 7 pessoas dizem que a linha curta é a longa, a maioria das pessoas duvida dos próprios olhos antes de discordar. Saber disso é o que separa 'opinião própria' de 'eco'.",
            curiosity_facts: [
              "Solomon Asch (1951) mostrou linhas a grupos. 7 cúmplices apontavam errado de propósito. ~75% dos participantes reais cederam pelo menos 1 vez.",
              "Quando 1 outra pessoa também discordava da maioria, o conformismo caía drasticamente — coragem é contagiosa quando aparece.",
              "Versões modernas mostram efeito ainda em pequenos grupos online (chat com 4 pessoas) — pressão social escala para qualquer mídia."
            ],
            challenge_prompt: "Em alguma decisão de grupo hoje (escolher restaurante, votar em algo), defenda a posição diferente se você sinceramente pensa diferente. Note quanto custou.",
            challenge_when: "hoje",
            challenge_observable: "Se foi mais difícil que parecia falar contrário à maioria.",
            learning_objective: "Discordar publicamente em 1 situação de grupo e relatar o custo emocional.",
            illustration_key: "users",
            source: "Solomon Asch",
            framework: "experimento clássico"
          },
          {
            slug: "viralizar-nao-e-verdade",
            title: "Por que viral não é igual a verdade?",
            hook: "Algoritmo escolhe o que prende atenção — não o que é verdadeiro.",
            angle: "Engajamento como métrica favorece outrage, surpresa, polarização — coisas que viralizam não pela verdade, mas pelo gatilho emocional. Verdade chata morre no feed.",
            central_insight: "Se algo viraliza, isso só prova que prendeu atenção de muita gente — não que é verdade. Quem confunde os dois acredita em mentira só porque ela 'pegou'.",
            curiosity_facts: [
              "Estudo MIT (Soroush Vosoughi, 2018) analisou 126 mil notícias no Twitter: notícias FALSAS espalham 6× mais rápido que verdadeiras.",
              "Porque conteúdo que provoca raiva, surpresa ou medo gera engajamento — verdade comum não dispara emoção forte.",
              "Por isso 'eu vi na internet' precisa virar 'vi onde, quem publicou, quem confirmou' — viral é métrica de espalhamento, não de verdade."
            ],
            challenge_prompt: "Pegue 1 conteúdo viral que você viu hoje. Pergunte: quem é a fonte original? Onde isso foi confirmado? Quanto tempo leva pra achar a fonte?",
            challenge_when: "hoje",
            challenge_observable: "Se levou mais que 2 minutos pra achar fonte primária — ou se nem existe.",
            learning_objective: "Investigar fonte primária de 1 conteúdo viral.",
            illustration_key: "search",
            source: "Soroush Vosoughi (MIT)",
            framework: "experimento + dado"
          },
          {
            slug: "midia-mostra-o-angulo",
            title: "Por que mídia mostra o que mostra (e omite o que omite)?",
            hook: "Mesmo fato vira histórias diferentes — dependendo do ângulo que mostra.",
            angle: "Framing midiático: mesmo evento ganha narrativa diferente conforme o que se enquadra no recorte. Não é mentira (raramente); é seleção. Saliência (o que aparece) decide percepção pública.",
            central_insight: "Se você vê só 1 fonte, você vê só 1 ângulo. Comparar 3 fontes diferentes sobre o MESMO evento revela o ângulo que cada uma escolheu mostrar.",
            curiosity_facts: [
              "Wilbur Schramm e outros pesquisadores de mídia mapearam: 5 grandes 'tipos de framing' que jornalismos usam — herói/vítima, conflito, custo, responsabilidade individual ou sistêmica.",
              "Manchete sobre o mesmo fato em jornal de esquerda, de centro, e de direita produz 3 narrativas mensuravelmente diferentes — sem mentir, só recortando.",
              "Por isso quem lê 1 só fonte de notícia tem 'visão estreita por construção', mesmo se for fonte 'séria'."
            ],
            challenge_prompt: "Pegue 1 notícia atual. Procure ela em 3 fontes diferentes (G1, BBC, jornal local). Anote o que cada uma DESTACOU e o que cada uma OMITIU.",
            challenge_when: "hoje",
            challenge_observable: "Quão diferentes ficaram as 3 versões da mesma notícia.",
            learning_objective: "Comparar 3 fontes sobre 1 notícia e mapear ângulos divergentes.",
            illustration_key: "search",
            source: "Wilbur Schramm",
            framework: "análise comparativa"
          },
          {
            slug: "amizade-real-vs-seguidor",
            title: "Por que 5 amigos de verdade valem mais que 5 mil seguidores?",
            hook: "Seu cérebro consegue cuidar de ~5 pessoas. O resto, no fundo, é paisagem.",
            angle: "Robin Dunbar mapeou camadas de relação no cérebro humano: ~5 íntimos, ~15 amigos próximos, ~50 amigos, ~150 conhecidos. Acima de 150, é abstração. Era das redes confunde camada com volume.",
            central_insight: "Se o cérebro só cuida de ~5 íntimos, ter 5 mil seguidores não enche esse vazio — só dá ilusão. Investir tempo nos 5 reais é matemática, não sentimentalismo.",
            curiosity_facts: [
              "Robin Dunbar (Oxford) mapeou em primatas e humanos: cérebro escala pra cerca de 150 relações estáveis máximas — o 'número de Dunbar'.",
              "Dentro dos 150, há camadas: ~5 íntimos que você ligaria às 3 da manhã, ~15 amigos próximos, ~50 amigos, ~150 conhecidos.",
              "Pesquisa de mídia social: usuários que 'curtem' 200 perfis ativamente seguem cuidar profundamente de menos de 10 — capacidade não escala com volume."
            ],
            challenge_prompt: "Liste seus 5 íntimos verdadeiros (quem você ligaria às 3 da manhã). Mande mensagem genuína pra 1 deles hoje — sem agenda.",
            challenge_when: "hoje",
            challenge_observable: "Se a lista de 5 é mais curta do que parecia — e como você se sente após mandar a mensagem.",
            learning_objective: "Identificar os 5 íntimos reais e fazer 1 ato deliberado de manutenção.",
            illustration_key: "users",
            source: "Robin Dunbar",
            framework: "modelo + dado"
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
