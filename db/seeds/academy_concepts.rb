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
    { slug: "criatividade",         name: "Criatividade",               definition: "Tédio + tempo sem estímulo = ideias originais." },
    { slug: "identidade-voto",      name: "Identidade-voto",            definition: "Cada repetição é um voto em quem você é se tornando — não no resultado distante." },
    { slug: "momentum-habito",      name: "Momentum do hábito",         definition: "Quebrar uma sequência dói mais que começar — perder a fileira custa mais que pular o dia." },
    { slug: "ambiente-vs-vontade",  name: "Ambiente decide",            definition: "Vontade é folha ao vento; ambiente é o vento. Quem desenha o ambiente, decide o comportamento." },
    { slug: "dunning-kruger",       name: "Dunning-Kruger",             definition: "Quem sabe pouco acha que sabe tudo; quem sabe muito sente que sabe pouco — a confiança e a competência caminham torto." },
    { slug: "raiva-amigdala",       name: "Raiva-amígdala",             definition: "A amígdala dispara raiva antes do córtex acordar — esperar 6 segundos é dar tempo do andar de cima abrir." },
    { slug: "dor-da-rejeicao",      name: "Dor da rejeição",            definition: "Rejeição social acende as mesmas regiões cerebrais da dor física — não é frescura, é circuito." },
    { slug: "ansiedade-energia",    name: "Ansiedade é energia",        definition: "Ansiedade é energia procurando saída — mesmo combustível da empolgação, só diferença é interpretação." }
  ],
  "saude" => [
    { slug: "sono-consolidacao",    name: "Sono consolida memória",     definition: "Dormir é quando o cérebro 'salva o arquivo' do dia." },
    { slug: "melatonina",           name: "Melatonina",                 definition: "Hormônio do sono — luz azul suprime por até 90 min." },
    { slug: "homeostase",           name: "Homeostase",                 definition: "O corpo busca equilíbrio constante; sinais externos atrapalham." },
    { slug: "glicose-pico",         name: "Pico de glicose",            definition: "Açúcar sobe rápido, cai rápido — a queda cobra com mais fome." },
    { slug: "ultraprocessados",     name: "Ultraprocessados",           definition: "Alimentos desenhados pra nunca saciar." },
    { slug: "consistencia",         name: "Consistência",               definition: "Regularidade vence intensidade em quase tudo do corpo." },
    { slug: "sinal-corporal",       name: "Sinais do corpo",            definition: "Fome, sede, cansaço — corpo fala em código fácil de confundir." },
    { slug: "respiracao-vagal",     name: "Respiração vagal",           definition: "Soltar o ar devagar acende o nervo vago — desacelera coração e cérebro em segundos." },
    { slug: "postura-feedback",     name: "Postura feedback",           definition: "Corpo molda mente: ombro caído puxa humor pra baixo, peito aberto puxa pra cima." },
    { slug: "dor-sinal",            name: "Dor é sinal",                definition: "Dor é alarme — quando ouvir, quando duvidar, quando ignorar." },
    { slug: "frio-alerta",          name: "Frio acorda",                definition: "Um susto de frio acende noradrenalina — foco em 30 segundos sem cafeína." }
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
    { slug: "feedback-formativo",   name: "Feedback formativo",         definition: "Descreve comportamento + impacto, sem julgar pessoa." },
    { slug: "principio-caridade",   name: "Princípio da caridade",      definition: "Entender o outro tão bem que ele aceitaria sua versão antes de você discordar." },
    { slug: "opiniao-reforco",      name: "Opinião endurece",           definition: "Defender uma opinião em voz alta endurece ela em você — virou identidade." },
    { slug: "comunicacao-desc",     name: "DESC: Descrever-Expressar-Sugerir-Consequência", definition: "Pedido difícil ganha forma quando descreve fato, expressa sentimento, sugere ação, mostra consequência." },
    { slug: "asch-conformidade",    name: "Asch / Conformidade",        definition: "7 pessoas erradas convencem 1 certa a ficar quieta — pressão social vence razão." },
    { slug: "viral-nao-verdade",    name: "Viral ≠ verdade",            definition: "Engajamento mede o que prende atenção, não o que é verdade — confusão fatal da era do feed." },
    { slug: "media-angulo",         name: "Mídia escolhe ângulo",       definition: "Mesmo fato vira histórias diferentes conforme o ângulo que mostra — viés está no recorte, não na invenção." },
    { slug: "amizade-dunbar",       name: "Amizade real vs popularidade", definition: "Cérebro humano consegue cuidar de ~5 amigos íntimos. Acima disso é conhecido. Confundir os dois é o desencaixe da era dos seguidores." }
  ],
  "virtude" => [
    { slug: "virtude-habito",       name: "Virtude é hábito",           definition: "Caráter é o que você FAZ repetidamente — não o que sente." },
    { slug: "coragem",              name: "Coragem",                    definition: "Agir apesar do medo — não na ausência dele." },
    { slug: "honestidade",          name: "Honestidade",                definition: "Primeiro contrato consigo mesmo." },
    { slug: "gratidao",             name: "Gratidão",                   definition: "Filtro atencional treinável — você passa a notar o que estava lá." },
    { slug: "verdade-que-serve",    name: "Verdade que serve",          definition: "Verdade dura sem amor é covardia disfarçada de coragem — descarrega quem fala, machuca quem ouve." },
    { slug: "procrastinacao-medo",  name: "Procrastinação é medo",      definition: "Adiar quase nunca é preguiça — é medo bem educado disfarçado de espera." },
    { slug: "humildade-pedido",     name: "Pedir ajuda",                definition: "Orgulho prefere sofrer sozinho a admitir que precisa — humildade prefere o contrário." },
    { slug: "comparacao-rouba",     name: "Comparação rouba",           definition: "Olhar pro lado o tempo todo apaga o que está à sua frente — comparação é ladrão silencioso." },
    { slug: "reclamacao-treina",    name: "Reclamação treina",          definition: "Cada queixa repetida treina o cérebro pra notar mais o que dá pra reclamar — o ruim cresce com a luz." },
    { slug: "perdao-liberta",       name: "Perdão liberta quem perdoa", definition: "Guardar mágoa é beber veneno e esperar o outro morrer — perdoar é largar o veneno, não inocentar o outro." }
  ],
  "financeiro" => [
    { slug: "juros-compostos",      name: "Juros compostos",            definition: "Ganho que ganha ganho — o tempo é o ingrediente raro." },
    { slug: "tradeoff",             name: "Tradeoff",                   definition: "Tudo custa algo — escolher é renunciar." },
    { slug: "escassez",             name: "Escassez",                   definition: "Recurso limitado força escolha." },
    { slug: "pagar-se-primeiro",    name: "Pagar-se primeiro",          definition: "Guardar antes de gastar — o que sobra desaparece." },
    { slug: "custo-afundado",       name: "Custo afundado",             definition: "Não desperdice mais só pra justificar o que já gastou — dinheiro perdido não volta sendo defendido." },
    { slug: "valor-habilidade",     name: "Valor da habilidade",        definition: "Profissão difícil paga mais porque poucas pessoas conseguem — escassez de gente capaz vira preço." },
    { slug: "criar-valor",          name: "Criar vs extrair valor",     definition: "Dinheiro grande vem de inventar coisa útil pra outros — não de tirar pedaço do que já existe." },
    { slug: "golpe-promessa-facil", name: "Golpe da promessa fácil",    definition: "Se dinheiro fácil e seguro existisse, o mundo já tinha pegado — quase sempre é golpe." },
    { slug: "inflacao",             name: "Inflação",                   definition: "Mesmo dinheiro compra menos com o tempo — guardar embaixo do colchão é perder devagar." }
  ],
  "tecnologia" => [
    { slug: "pensamento-computacional", name: "Pensamento computacional", definition: "Decompor + abstrair + iterar." },
    { slug: "probabilidade",        name: "Probabilidade",              definition: "Lidar com incerteza usando números." },
    { slug: "sistemas",             name: "Sistemas",                   definition: "Todo conjunto tem entrada, processo, saída — e feedback." },
    { slug: "algoritmo-recomendacao", name: "Algoritmo de recomendação", definition: "Cada toque vira voto — o feed é projetado a partir do seu comportamento." },
    { slug: "aprendizado-ativo",    name: "Aprendizado ativo",          definition: "Criar/ensinar fixa muito mais que consumir passivamente." },
    { slug: "dns-internet",         name: "DNS / nome vira número",     definition: "Cada nome de site (youtube.com) é traduzido em um número (IP) por servidores DNS — sem isso, ninguém acharia ninguém." },
    { slug: "wifi-ondas",           name: "WiFi é onda",                definition: "Internet sem fio é onda de rádio invisível — quanto mais gente no mesmo canal, mais lento pra todos." },
    { slug: "busca-rank",           name: "Como busca decide ordem",    definition: "Buscador não acha 'a verdade': escolhe a ordem das respostas com fórmula secreta — quem entende a fórmula sobe nela." },
    { slug: "cdn-cache",            name: "Vídeo perto de você",        definition: "Vídeo do TikTok não vem da China: tem cópia em servidor no Brasil — por isso chega rápido." },
    { slug: "internet-permanente",  name: "Internet é tinta, não giz",  definition: "Toda foto/post tem cópia em vários lugares ao postar — apagar do seu feed não apaga das cópias do mundo." },
    { slug: "fingerprint-digital",  name: "Fingerprint digital",        definition: "Mesmo sem login, sites te reconhecem por combinação de fonte, resolução, idioma — você é uma digital invisível." },
    { slug: "senha-unica",          name: "Senha única > forte",        definition: "Senha forte não protege se for igual em vários lugares — vazou num, vazou em todos." },
    { slug: "codigo-receita",       name: "Código = receita",           definition: "Programar não é mágica: é receita que a máquina segue exatamente — variável, condicional, repetição." },
    { slug: "copiar-aprender",      name: "Copiar pra aprender",        definition: "Copiar pra entender o como vira aprendizado; copiar pra entregar como seu é roubo — limite muda quando você cita." },
    { slug: "antes-de-enviar",      name: "Antes de enviar",            definition: "Tela apaga o filtro que existiria cara-a-cara — antes de mandar, imagine quem amava lendo. Se hesitar, não envie." }
  ],
  "cientifico" => [
    { slug: "decomposicao",         name: "Decomposição",               definition: "Problema gigante = soma de pequenos problemas resolvíveis." },
    { slug: "estrategia",           name: "Estratégia",                 definition: "Decidir antes de agir — escolher o caminho, não só correr." },
    { slug: "decisao-rapida",       name: "Decisão sob pressão",        definition: "Decidir bem com pouco tempo é treinável." },
    { slug: "feedback-loop",        name: "Loop de feedback",           definition: "Saída vira nova entrada — sistema se auto-ajusta." },
    { slug: "causa-e-efeito",       name: "Causa e efeito",             definition: "X provoca Y, mas Y às vezes volta pra X." },
    { slug: "pareto",               name: "Princípio de Pareto",        definition: "20% das causas geram 80% dos efeitos — escolha bem o 20%." },
    { slug: "5-porques",            name: "Cinco Porquês",              definition: "Cavar 5 níveis abaixo do sintoma pra encontrar a causa real." },
    { slug: "refutabilidade",       name: "Refutabilidade",             definition: "Boa hipótese pode ser provada errada — quem tenta confirmar confirma; quem tenta refutar aprende." },
    { slug: "framing",              name: "Framing",                    definition: "Mesma resposta muda com a pergunta — 'salvar 70%' soa diferente de 'perder 30%' mesmo sendo o mesmo." },
    { slug: "intuicao-vs-calculo",  name: "Intuição vs cálculo",        definition: "Bombeiro veterano sente o teto cair sem calcular; iniciante precisa calcular — expertise muda o ferramental." }
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
  [ "feedback-loop", "habito-loop", :echoes ],

  # Edges novos — cluster Mente Forte expandido
  [ "raiva-amigdala", "sistema-1-vs-2", :echoes ],
  [ "dunning-kruger", "vies-confirmacao", :echoes ],
  [ "dunning-kruger", "ceticismo", :echoes ],
  [ "ambiente-vs-vontade", "habito-loop", :echoes ],
  [ "ambiente-vs-vontade", "regra-dos-2-min", :echoes ],
  [ "identidade-voto", "identidade", :echoes ],
  [ "identidade-voto", "habito-loop", :leads_to ],
  [ "momentum-habito", "habito-loop", :echoes ],
  [ "momentum-habito", "consistencia", :echoes ],
  [ "dor-da-rejeicao", "empatia", :echoes ],

  # Edges Corpo & Saúde novos
  [ "respiracao-vagal", "sinal-corporal", :echoes ],
  [ "respiracao-vagal", "homeostase", :echoes ],
  [ "postura-feedback", "sinal-corporal", :echoes ],
  [ "dor-sinal", "sinal-corporal", :echoes ],
  [ "dor-sinal", "homeostase", :echoes ],
  [ "frio-alerta", "sinal-corporal", :echoes ],

  # Edges Dinheiro novos
  [ "custo-afundado", "tradeoff", :echoes ],
  [ "custo-afundado", "vies-confirmacao", :echoes ],
  [ "valor-habilidade", "escassez", :echoes ],
  [ "criar-valor", "aprendizado-ativo", :echoes ],
  [ "inflacao", "juros-compostos", :echoes ],
  [ "golpe-promessa-facil", "ceticismo", :echoes ],
  [ "golpe-promessa-facil", "probabilidade", :echoes ],

  # Edges Caráter novos
  [ "verdade-que-serve", "honestidade", :echoes ],
  [ "verdade-que-serve", "comunicacao", :echoes ],
  [ "procrastinacao-medo", "coragem", :echoes ],
  [ "humildade-pedido", "coragem", :echoes ],
  [ "comparacao-rouba", "gratidao", :echoes ],
  [ "comparacao-rouba", "atencao", :echoes ],
  [ "reclamacao-treina", "habito-loop", :echoes ],
  [ "reclamacao-treina", "atencao", :echoes ],

  # Edges Tecnologia novos
  [ "dns-internet", "sistemas", :echoes ],
  [ "wifi-ondas", "sistemas", :echoes ],
  [ "busca-rank", "algoritmo-recomendacao", :echoes ],
  [ "cdn-cache", "sistemas", :echoes ],
  [ "internet-permanente", "ceticismo", :echoes ],
  [ "fingerprint-digital", "algoritmo-recomendacao", :echoes ],
  [ "senha-unica", "ceticismo", :echoes ],
  [ "codigo-receita", "pensamento-computacional", :echoes ],
  [ "copiar-aprender", "aprendizado-ativo", :echoes ],

  # Edges Resolver Problemas novos
  [ "refutabilidade", "ceticismo", :echoes ],
  [ "refutabilidade", "vies-confirmacao", :echoes ],
  [ "framing", "sistema-1-vs-2", :echoes ],
  [ "framing", "vies-confirmacao", :echoes ],
  [ "intuicao-vs-calculo", "sistema-1-vs-2", :echoes ],

  # Edges Vida & Sociedade novos
  [ "principio-caridade", "empatia", :echoes ],
  [ "principio-caridade", "ceticismo", :echoes ],
  [ "opiniao-reforco", "vies-confirmacao", :echoes ],
  [ "opiniao-reforco", "identidade", :echoes ],
  [ "comunicacao-desc", "comunicacao", :echoes ],
  [ "comunicacao-desc", "feedback-formativo", :echoes ],
  [ "asch-conformidade", "prova-social", :echoes ],
  [ "viral-nao-verdade", "ceticismo", :echoes ],
  [ "viral-nao-verdade", "probabilidade", :echoes ],
  [ "media-angulo", "vies-confirmacao", :echoes ]
].freeze

# Mission slug → [primary_concept_slug, secondary…]. First slug is is_primary=true.
MISSION_CONCEPTS = {
  # Mente Forte / atencao
  "celular-difícil-parar"      => %w[dopamina recompensa-variavel atencao],
  "notificacoes-custam-23-min" => %w[switch-cost atencao foco],
  "foco-profundo-25min"        => %w[deep-work foco habito-loop],
  "habito-2-minutos"           => %w[regra-dos-2-min habito-loop identidade],
  # Mente Forte / hábitos
  "habito-vence-meta"          => %w[identidade-voto identidade habito-loop],
  "parar-doi-mais-que-comecar" => %w[momentum-habito habito-loop consistencia],
  "ambiente-decide-mais-que-vontade" => %w[ambiente-vs-vontade habito-loop],
  # Mente Forte / vieses
  "vies-confirmacao"           => %w[vies-confirmacao ceticismo],
  "memoria-falsa"              => %w[memoria-reconstrutiva ceticismo],
  "pensar-devagar"             => %w[sistema-1-vs-2 ceticismo],
  "sabe-mais-sente-menos"      => %w[dunning-kruger ceticismo],
  # Mente Forte / emoções
  "de-onde-vem-raiva"          => %w[raiva-amigdala sistema-1-vs-2],
  "por-que-rejeicao-doi"       => %w[dor-da-rejeicao empatia],
  "ansiedade-e-energia"        => %w[ansiedade-energia sistema-1-vs-2 respiracao-vagal],
  # Corpo & Saúde / energia
  "acucar-engana-cerebro"      => %w[glicose-pico dopamina ultraprocessados],
  "noite-ruim-apaga-semana"    => %w[sono-consolidacao memoria-reconstrutiva],
  "10-min-movimento"           => %w[consistencia habito-loop neuroplasticidade],
  "agua-confunde-fome"         => %w[sinal-corporal homeostase],
  # Corpo & Saúde / telas
  "tela-pre-sono"              => %w[melatonina sono-consolidacao atencao],
  "scroll-infinito-mente"      => %w[recompensa-variavel dopamina atencao],
  # Corpo & Saúde / respiração-dor (NOVO)
  "respirar-acalma"            => %w[respiracao-vagal sinal-corporal],
  "postura-puxa-humor"         => %w[postura-feedback sinal-corporal],
  "dor-quando-confiar"         => %w[dor-sinal sinal-corporal homeostase],
  "frio-foco-30s"              => %w[frio-alerta sinal-corporal],
  # Dinheiro / impulso
  "impulso-perigoso"           => %w[recompensa-imediata gratificacao-tardia],
  "anchoring-no-preco"         => %w[escassez-percebida vies-confirmacao],
  "custo-oportunidade-real"    => %w[tradeoff escassez],
  "ja-gastei-tanto"            => %w[custo-afundado tradeoff],
  # Dinheiro / de onde nasce (NOVO)
  "por-que-pagam-mais"         => %w[valor-habilidade escassez],
  "ideia-vira-dinheiro"        => %w[criar-valor aprendizado-ativo identidade],
  "dinheiro-facil-e-golpe"     => %w[golpe-promessa-facil ceticismo probabilidade],
  # Dinheiro / cresce sem você
  "guardar-mais-que-gastar"    => %w[pagar-se-primeiro tradeoff habito-loop],
  "dinheiro-vira-dinheiro"     => %w[juros-compostos gratificacao-tardia consistencia],
  "inflacao-imposto-invisivel" => %w[inflacao juros-compostos tradeoff],
  # Caráter / palavra & honestidade
  "mentiras-pequenas-custam"   => %w[honestidade virtude-habito identidade],
  "compromisso-cumprido"       => %w[palavra-dada confianca habito-loop],
  "verdade-dura-covardia"      => %w[verdade-que-serve honestidade comunicacao],
  # Caráter / coragem & medo
  "coragem-nao-ausencia-medo"  => %w[coragem virtude-habito identidade],
  "esperar-pronto-e-medo"      => %w[procrastinacao-medo coragem identidade-voto],
  "pedir-ajuda-pesa-mais"      => %w[humildade-pedido coragem confianca],
  # Caráter / gratidão & contentamento
  "gratidao-muda-vista"        => %w[gratidao atencao virtude-habito],
  "comparar-te-rouba"          => %w[comparacao-rouba atencao gratidao],
  "reclamar-te-enfraquece"     => %w[reclamacao-treina atencao identidade],
  "perdao-liberta-quem-perdoa" => %w[perdao-liberta gratidao virtude-habito],
  # Tecnologia / máquinas pensam
  "loop-feedback"              => %w[sistemas pensamento-computacional],
  "probabilidade-do-dado"      => %w[probabilidade ceticismo pensamento-computacional],
  "como-ia-decide"             => %w[ceticismo probabilidade pensamento-computacional],
  "algoritmo-conhece-voces-1milhao" => %w[algoritmo-recomendacao feedback-loop],
  # Tecnologia / internet (NOVO)
  "digito-youtube-o-que-rola"  => %w[dns-internet sistemas pensamento-computacional],
  "wifi-onda-com-limite"       => %w[wifi-ondas sistemas],
  "quem-decide-busca"          => %w[busca-rank algoritmo-recomendacao],
  "video-chega-rapido-como"    => %w[cdn-cache sistemas],
  # Tecnologia / privacidade & segurança (NOVO)
  "algoritmo-tem-limites"      => %w[algoritmo-recomendacao feedback-loop vies-confirmacao],
  "foto-fica-mesmo-apagada"    => %w[internet-permanente ceticismo],
  "ve-quem-te-ve"              => %w[fingerprint-digital algoritmo-recomendacao],
  "senha-unica-vale-mais"      => %w[senha-unica ceticismo],
  # Tecnologia / você criando
  "criador-vs-consumidor"      => %w[aprendizado-ativo criatividade identidade],
  "codigo-e-receita-executavel" => %w[codigo-receita pensamento-computacional],
  "copiar-pra-aprender"        => %w[copiar-aprender aprendizado-ativo honestidade],
  # Resolver Problemas / clássico
  "quebrar-problema"           => %w[decomposicao pensamento-computacional estrategia],
  "erro-dado"                  => %w[neuroplasticidade identidade ceticismo],
  "priorizar-pareto"           => %w[pareto estrategia tradeoff],
  "5-porques"                  => %w[5-porques causa-e-efeito ceticismo],
  # Resolver Problemas / mente de cientista (NOVO)
  "cientista-tenta-refutar"    => %w[refutabilidade ceticismo aprendizado-ativo],
  "pergunta-decide-resposta"   => %w[framing sistema-1-vs-2 ceticismo],
  "intuicao-vs-calculo-quando" => %w[intuicao-vs-calculo sistema-1-vs-2 ceticismo],
  # Vida & Sociedade / ler pessoas
  "escutar-de-verdade"         => %w[escuta-ativa empatia comunicacao],
  "manipulacao-marcas"         => %w[prova-social escassez-percebida vies-confirmacao],
  "silencio-constroi-confianca" => %w[pausa-estrategica escuta-ativa confianca],
  "feedback-que-serve"         => %w[feedback-formativo comunicacao palavra-dada],
  # Vida & Sociedade / conflito sem destruir (NOVO)
  "defender-endurece-opiniao"  => %w[opiniao-reforco vies-confirmacao identidade],
  "100-certo-e-cego"           => %w[principio-caridade ceticismo empatia],
  "pedido-dificil-sem-inimigo" => %w[comunicacao-desc comunicacao palavra-dada],
  # Vida & Sociedade / você e a multidão (NOVO)
  "7-erradas-vs-1-certa"       => %w[asch-conformidade prova-social coragem],
  "viralizar-nao-e-verdade"    => %w[viral-nao-verdade ceticismo probabilidade],
  "midia-mostra-o-angulo"      => %w[media-angulo vies-confirmacao ceticismo],
  "amizade-real-vs-seguidor"   => %w[amizade-dunbar empatia confianca],
  # Tecnologia / privacidade & segurança — extra
  "antes-de-enviar-pense"      => %w[antes-de-enviar internet-permanente honestidade]
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
  },
  "dunning-kruger" => {
    the_essence: "Quem sabe pouco se acha expert; quem sabe muito sente que sabe pouco — confiança engana.",
    common_confusion: "Achar que confiança é prova de competência; muitas vezes é prova do oposto.",
    forbidden_terms: [ "burrice", "idiota" ]
  },
  "raiva-amigdala" => {
    the_essence: "Raiva sobe pela amígdala antes do córtex acordar — 6 segundos são o tempo de espera do andar de cima.",
    common_confusion: "Achar que raiva é falha de caráter; é química com timing previsível.",
    forbidden_terms: [ "controle a raiva" ]
  },
  "dor-da-rejeicao" => {
    the_essence: "Cérebro processa rejeição na mesma região da dor física — quando dói, não é frescura.",
    common_confusion: "Achar que rejeição é só 'na cabeça'; é circuito cerebral idêntico ao da dor.",
    forbidden_terms: [ "só ignora", "deixa pra lá" ]
  },
  "ambiente-vs-vontade" => {
    the_essence: "Vontade é folha ao vento; ambiente é o vento — desenhe o ambiente, e a vontade descansa.",
    common_confusion: "Achar que força de vontade resolve; ambiente sempre vence vontade em prazo longo.",
    forbidden_terms: [ "só depende de você" ]
  },
  "identidade-voto" => {
    the_essence: "Cada repetição é voto em quem você é se tornando — não no resultado distante.",
    common_confusion: "Achar que o hábito serve pra alcançar uma meta; ele serve pra confirmar uma identidade.",
    forbidden_terms: []
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
