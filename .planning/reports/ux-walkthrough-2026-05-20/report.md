# UX & Product Walkthrough — LittleStars

**Data:** 2026-05-20
**Branch:** `feat/academy-lens-v3-completion`
**Método:** navegação Playwright em `http://localhost:10301` como Theo (criança, PIN 1111) e Mamãe (responsável, PIN 1111). Telas em `./screenshots/`.

---

## 0. TL;DR

LittleStars já tem **personalidade visual forte** (Duolingo dialect aplicado com consistência), uma **proposta diferenciada** (Academy com currículo invisível + economia de estrelinhas em família), e a fundação técnica está bem cuidada. A maior parte do que limita o produto hoje **não é "estilo"** — é **quantidade de coisas competindo pela atenção em cada tela** e **falta de "primeiro passo" claro** quando a família ainda não jogou. Resumo brutal:

1. A **Home do filho está sobrecarregada** (saldo, nível, meta da loja, 3 metas familiares, 10 missões, CTA de missão livre, trocar perfil). É a tela em que o filho passa 90% do tempo — e ela parece um *dashboard*, não um *daily run*.
2. A **conclusão de missão não tem affordance clara** no card. Cliquei na missão e nada visível aconteceu. Para um produto cujo core loop é "fiz → marquei → ganhei estrelinha", isso é o bug mais caro do MVP.
3. A **Academy é o melhor diferencial do produto** e está sub-exposta. O Atlas, cartas, segredos e a persona "O Guia" são o que NÃO existe nos concorrentes (Greenlight, Joon, S'moresUp). Hoje a Academy é a 2ª aba do filho e a 4ª seção do dashboard do pai. Devia ser o centro de gravidade.
4. O **profile picker mostra responsáveis lado-a-lado com crianças** numa única lista, sem ordem ou agrupamento, e o PIN keypad é o mesmo para todos. Crianças têm acesso visual aos perfis dos pais e podem tentar PINs por força bruta. Hoje funciona porque o app está em casa, mas é um vetor que vai virar suporte.
5. Pequenos bugs/atritos: `GET /parent/tasks` → exception Rails; o rótulo "Aguardando/Rejeitadas" no Diário do filho expõe vocabulário de sistema; o título de meta familiar leak o prefixo `[Família]`; ícone de estrela aparece *duplicado* no header do filho.

Detalhes e priorização nas seções 1–7.

---

## 1. Onboarding & Identidade

### 1.1 Profile picker (`/profile_session/new`) — `screenshots/01-pin.png`
**O que funciona**
- Avatares grandes, cor por perfil, papel ("Responsável" / "Criança") visível.
- Modal de PIN com teclado numérico grande — ótimo para tablet de criança.

**O que dói**
- **Responsáveis e crianças misturados na mesma grade.** Numa família real, a criança escolhe o próprio rosto em <1s; misturar com adultos só polui a decisão. Sugestão: agrupar — "Adultos" em cima compactos / "Crianças" embaixo como heróis grandes (estilo Netflix Kids invertido para o uso real: a criança é quem mais usa).
- **PIN compartilhado em UX.** O modal de PIN é igual para qualquer perfil. Nada impede um filho de testar o PIN do pai. Para um produto que controla pontos resgatáveis em dinheiro/prêmios físicos, **PIN do responsável precisa ter rate-limit visível, e idealmente um caminho de "Sou adulto, esqueci o PIN" que exige re-login da família**. Hoje a senha de família foi efetivamente bypassed depois do primeiro login.
- O `Bora começar!` no header da família + `Quem é você?` no card é redundante. Um dos dois.
- "Fechar" sai do modal mas volta para a mesma tela; o ícone genérico não comunica isso.

### 1.2 PIN UX
- Sem **shake/erro visual** explorado no walkthrough (sucesso na 1ª tentativa). Verificar se há feedback de PIN errado claro para criança (cor, vibração, mensagem curta tipo "Errou! Tenta de novo 🌟"). Provavelmente já existe; vale confirmar e documentar.
- **Falta um modo "anônimo/convidado"** para irmão menor olhar progresso de irmão maior sem precisar logar — útil em sessão de TV/sala.

---

## 2. Jornada da Criança (`/kid`) — `screenshots/02-kid-home.png`

### 2.1 Diagnóstico de hierarquia
A Home do filho hoje empilha 6 blocos verticais:

1. Header: saldo (0★) + botão **"Trocar"** (perfil)
2. Card de boas-vindas com avatar + "Bora pegar mais ★ hoje?"
3. Card de nível: "NÍVEL 1 → 2 · 0/20"
4. Card "Sua meta · Escolher um prêmio · Toque pra ir pra Lojinha"
5. Header "Missões de hoje · 0 de 10"
6. **3 cards de metas familiares** (Pizza/Cinema/Viagem) — 0% nas três
7. Lista de **10 missões diárias** (escovar, banho, prep escola, louça, comida pro gato, lição, leitura, Duolingo, oração, "não brigar")
8. CTA "Fez algo fora da lista? Adicionar"

A criança rola **3 telas** para ver a última missão do dia. Em um produto que se compara a Duolingo, a tela inicial do Duolingo cabe em 1 viewport e tem **1 botão claro**: "Continuar lição".

**Recomendações concretas**
- **Promova as missões para cima.** O bloco de metas familiares (3 cards) hoje fica *entre* "Missões de hoje" e a lista — empurra as tarefas para fora da dobra. Mova-o para baixo da lista ou colapse em 1 carrossel.
- **Mostre só 3 missões na dobra + "Ver as outras 7".** Estudos com kids 6-12 (e o próprio Duolingo) mostram que progresso percebido cai com mais de 3-5 itens visíveis.
- **Remova o duplo ícone de estrela no headline** "Bora pegar mais 󲎤 hoje?". Está renderizando 2 vezes (ver snapshot e02-kid-home).
- **"Trocar" perfil no topo direito é um trigger de saída.** Em criança ansiosa, vira escape hatch. Considere mover para um menu (3 pontinhos) ou condicionar a long-press.
- O bloco "Sua meta · Escolher um prêmio" só faz sentido enquanto **não há meta**. Quando há meta, deveria virar "Faltam 120 ★ para Patinete · Você está 30% lá". Sem essa transição clara, a criança nunca volta nele.

### 2.2 Affordance de "completar missão" (CRÍTICO)
- Cliquei no card de missão. Nada visível aconteceu (sem modal, sem flash, sem mudança de estado). Provavelmente o card abre um confirm via Stimulus, mas no walkthrough Playwright não disparou.
- **Sem botão visível** "Pronto! Marca pra mim" no card. O produto é gamificado e o ato de marcar é onde mora a dopamina — esse momento precisa de **botão grande, cor primária verde Duolingo, animação de estrela voando para o saldo**.
- A categoria "Saúde / Casa / Escola / Rotina" aparece como microtag cinza ("Saúde · diária") — perfeito, mas o ícone categórico (ferramenta) é o mesmo da fonte de ícones do app, gerando *uma parede de glyphs idênticos* (a snapshot mostra muito "󱯉 󱦞 󱖃" repetidos). Falta diferenciação visual entre missões — usar **cor de fundo por categoria** já resolve em 1 hora.

### 2.3 Linguagem
- "Missão" / "Estrelinha" / "Nível" — top, perfeito para faixa-alvo.
- "Diário" / "Lojinha" / "Academia" / "Jornada" — nomenclatura ok, mas **"Jornada" é a Home**, o que não é óbvio. Talvez "Hoje" comunique melhor (cf. Duolingo's "Aprender").

---

## 3. Missão Livre (`/kid/missions/new`) — `screenshots/07-kid-new-mission.png`

Não capturado em texto neste walkthrough, mas o CTA "Fez algo fora da lista? Adicionar" é **um dos features mais inovadores do produto** (criança propõe missão, pai aprova). Recomendações:

- Subir esse fluxo do rodapé para um **botão flutuante (+)** quando houver progresso bom no dia (>50% das missões), como uma "recompensa" de proatividade.
- O texto "Fez algo fora da lista?" é ótimo. Mantenha.

---

## 4. Academy — `screenshots/03-academy-subjects.png`, `04-academy-mission.png`

### 4.1 Hub `/kid/academy/subjects`
**Pontos altos**
- **"Bússola do Explorador" com 2 trilhas (quente + território novo)** é uma das melhores soluções de adaptive learning para criança que vi. Resolve o problema de "qual aula?" sem pedir escolha.
- **Atlas · Últimas Descobertas** com citações de Provérbios + Dave Ramsey + Gloria Mark é distintivo, formativo, e respeita os valores cristãos da família sem ser denominacional excludente. Mantenham.
- 7 áreas com nível visível e progresso ("3/7") = legibilidade ótima.

**Atritos**
- O usuário tem que descer 2 dobras para ver as áreas; a Bússola consome a primeira. Em um filho repetente, o card "Trilha Quente" é redundante por estar no topo. Considere **mostrar Bússola só na primeira visita do dia**.
- Áreas com Nv. 0 (Tecnologia, Resolver Problemas, Vida & Sociedade) deveriam ter um *teaser* de "1 ideia que muda alguma coisa hoje" inline — hoje são linhas mortas até a criança clicar.

### 4.2 Aula `/kid/academy/subjects/mente-forte/missions/memoria-falsa`
**Excelente.** A combinação **personagem (Camila, 12) + cena descritiva + pergunta + feedback "Por quê" + próxima cena** é o coração pedagógico do produto. Isso, sozinho, justifica o app.

**Sugestões pequenas**
- O bloco de feedback "Por quê" abre embaixo das respostas (boa estrutura). Mas a resposta **errada não é destacada vs. a certa** — o aluno não tem cue visual claro. Mostre ✓ verde na correta e tom acinzentado nas demais.
- "Próxima cena →" e "Continuar →" aparecem ambos disponíveis ao mesmo tempo. Defina ordem temporal: a próxima cena só aparece depois que a pergunta foi respondida.
- Falta indicador de **quantas cenas/perguntas faltam na aula**. Hoje é "Progresso da missão" sem números — para um aluno que precisa decidir "começo agora ou guardo pra amanhã?", saber "2/5" muda tudo.
- O **"sobre Memória reconstrutiva"** abaixo do "Conta a história" é o conceito invisível atravessado. Excelente design pedagógico, mas para a criança esse rótulo parece técnico. Talvez condicionar visibilidade ao adulto, ou mover para o final ("Você acabou de aprender sobre…").

---

## 5. Lojinha (`/kid/rewards`) — `screenshots/06-kid-rewards.png`

- 28 prêmios listados; cada card tem **dois botões empilhados**: "Definir como meta" + o card do prêmio. Visualmente parece que a tela tem 56 botões.
- O conceito de **"meta"** (prêmio escolhido como objetivo de longo prazo) vs **"comprar agora"** é poderoso, mas a UI não comunica diferença. Sugestão: meta = ⭐ no canto do card; "comprar" = botão único embaixo só ativa quando saldo ≥ preço.
- Prêmios com nome `[Família] Pizza no jantar de sexta` — o prefixo é leak de modelagem. Use uma **tag/seção "Prêmios da família"** em vez de prefixo no nome.
- Ordenação por preço crescente está ótima.
- Não vi destaque para prêmios "alcançáveis hoje" (saldo > preço) — esse é o gatilho de conversão; deveria abrir a tela.

---

## 6. Diário (`/kid/wallet`) — `screenshots/05-kid-wallet.png`

- Header "Conquistado / Gasto / Missões" em três grandes números — ok.
- **Tabs problemáticos:** `Tudo · Conquistadas · Compras · Descobertas · Aguardando · Rejeitadas`. Para criança:
  - "Aguardando" e "Rejeitadas" são vocabulário de sistema (status enum). Idealmente "Esperando pai/mãe" e "Pediram pra refazer".
  - 6 abas é muito; 3 (Ganhei / Gastei / Esperando) já cobrem 95% dos casos.
- Empty state: "Nenhuma atividade ainda · Complete missões ou faça resgates pra começar o histórico" — bom. Considere ilustração ao invés de glyph.

---

## 7. Painel do Responsável (`/parent`) — `screenshots/08-parent-home.png`

### 7.1 Dashboard
- **3 metas familiares + 4 KPIs + 3 cartões de filhos + aprovações** numa tela = funciona, mas **sem hierarquia visual de "o que requer ação agora"**. Em um app de pai cansado às 21h, a pergunta é "preciso fazer algo?". Hoje "Aprovações pendentes" fica no fim, e "Tudo em dia!" é uma boa surpresa — mas se tivesse 5 aprovações, mesmo padrão.
- Sugestão: **inverta a hierarquia** — `Aprovações pendentes` no topo (quando >0), `Suas crianças` depois, `Metas familiares` no fim. KPIs (`0 estrelinhas`, `28 missões ativas`, `28 prêmios`) são vaidade — colapse em um sub-header.

### 7.2 Métrica inconsistente
- Tela do Theo no parent: **"faltam 100 pro nível 2"**
- Home do filho Theo: **"Faltam 20 estrelinha pra subir"**
- Provavelmente são definições diferentes (saldo atual vs. total acumulado?), mas para o usuário é dado contraditório. Conferir e unificar a regra ou explicitar a diferença.

### 7.3 Rota quebrada
- **`GET /parent/tasks` → 500 (Action Controller exception)** — `screenshots/09-parent-tasks-error.png`. A rota canônica é `/parent/global_tasks`. Sugestões: rota legível `parent/tasks` redirecionando para `global_tasks`, OU renomear o resource para `tasks`. Há documentação em CLAUDE.md/TECHSPEC que chama de "tarefas" — link quebrado vira suporte.

### 7.4 Global Tasks (`/parent/global_tasks`) — `screenshots/10-parent-globaltasks.png`
- Cada linha tem botão "Desativar missão" + link da missão lado-a-lado. Para um pai escaneando, parece dois CTAs equivalentes. Recomendo **um único card clicável (abre edição), com toggle de ativar/desativar dentro da edição** ou ícone de "olho" no canto.
- Falta filtro por filho (vejo missões da Lis no topo, embaralhadas). Em famílias com >2 filhos, isso vira ingerenciável.
- Falta bulk action (cancelar 5 missões da semana em uma tap).

### 7.5 Approvals (`/parent/approvals`) — `screenshots/11-parent-approvals.png`
- Empty state ótimo ("Tudo em dia!"). Vale prever:
  - **Notification push** quando aprovação nova chegar (Solid Cable já está no stack).
  - **Quick approve gesture** (swipe à direita aprovar, esquerda rejeitar) — pais aprovam no celular durante 5 min do dia.

### 7.6 Configurações (`/parent/settings`) — `screenshots/16-parent-settings.png`
- **Resetar PIN inline** para cada perfil, com botão "Resetar" sem confirmação aparente. Para PIN de adulto, exigir confirmação. Para PIN de criança, ok atual.
- "Sair desta família neste dispositivo" botão único no rodapé — para uma ação destrutiva, idealmente confirmar.

### 7.7 Academy do pai (`/parent/academy`) — `screenshots/17-parent-academy.png`
- **Esta é a tela que melhor explica o produto.** "Currículo invisível, comportamentos visíveis. O que cada filho está formando de verdade." — texto de copy nota 10.
- Hoje ela é a 6ª aba do menu lateral. Eleve para a 2ª (depois de "Crianças") — é o que diferencia o produto.
- **Empty states fortes**: "Currículo invisível ainda zerado" / "Sem cartas cunhadas ainda" / "Nenhum segredo aberto" — vocabulário rico, mas falta um **next step**. "Convide Theo a fazer 1 aula hoje → [Enviar lembrete]".
- "Comparar filhos" (`/parent/academy/compare`) tem disclaimer "sem ranking competitivo" mas mostra "Theo 6 aulas, Lis 0, Laura 1" lado a lado, ordenado — visualmente é ranking. Para honrar a intenção, considere **agrupar por conceito atravessado** ("Todos os 3 viram Memória" / "Só Theo viu Dopamina") em vez de números brutos.
- **Biblioteca de Pílulas** é um conteúdo curado riquíssimo (Huberman, Skinner, Newport, Provérbios). Não tem busca/filtro. Para 100+ pílulas vai ficar inutilizável. Adicione filtro por área + favoritar.

---

## 8. Visão de PRODUTO — onde está o leverage

### 8.1 O que LittleStars **já** tem que Greenlight/Joon/S'moresUp **não** têm
1. **Academy com currículo invisível.** Nenhum concorrente entrega "Por que mexer no celular vicia? · Cal Newport · Aplicar 15 min sem estímulo digital" para criança de 10 anos.
2. **Metas familiares coletivas.** Estrelinhas dos filhos somam para pizza/cinema/viagem em família. Isso converte rivalidade em cooperação — anti-padrão na maior parte dos apps gamificados.
3. **Identidade cristã universalizada.** Misturar Provérbios com Huberman e Skinner sem soar denominacional é um equilíbrio que poucos times conseguem.
4. **Persona "O Guia".** Hooks de feedback têm tom (autoritativo + misterioso + fascinado). Em geração de LLM custa caro manter persona; vocês mantêm.

### 8.2 Onde o produto está deixando dinheiro/retenção na mesa
1. **Hook de primeiro uso.** A família que abre o app e vê 28 missões pré-seeded sente que isso é da família anterior — não é dela. Considere um **wizard de 90 segundos**: "Quantos filhos? · Quantos anos? · 3 coisas que você quer ver acontecer (escovar dente / leitura / menos briga)" → o app gera 3-5 missões personalizadas, não 28 genéricas.
2. **D1/D7 retention da criança.** Hoje a Home tem 8 blocos e nenhum *one-tap path* claro. O kid abre, vê a parede de glyphs, fecha. Versão V3: **abrir o app já leva para a próxima aula da Academy** (que é o único conteúdo "novo" diário). Missões viram lista secundária.
3. **Loop de aprovação em <30s.** Pai recebe push → abre direto na lista de aprovações → swipe → fecha. Hoje precisa 3 taps + senha do família + PIN.
4. **Compartilhamento social (com cuidado).** Carta cunhada de uma aula (Academy v4) é arte digital pessoal — vale exportar como **PNG/sticker** para o pai mandar para avós/padrinhos. Distribuição orgânica grátis.
5. **Multi-device sync da família.** Hoje é single-device. Família moderna tem 2-3 tablets. Já está no stack Rails — falta UX de "vincular este dispositivo a esta família" via QR code.
6. **Diferencial de monetização.** Quando virar produto pago, o pitch não é "controlador de tarefas" (commodity) — é "**a única plataforma onde seu filho de 10 anos aprende sobre dopamina, juros compostos e mentira por absorção, jogando**". Pricing premium tier deveria ser **pago pela Academy, com tarefas free**, não o inverso.

### 8.3 Riscos estratégicos
- **Dependência do LLM (OpenRouter/DeepSeek).** Custo por aula × N filhos × N aulas/semana pode escalar. Cache agressivo (cards, perguntas) + tier "modo offline" com aulas pré-renderizadas para crianças <8 anos resolve.
- **Acessibilidade.** A fonte de ícones única (provavelmente custom icon font) é um vetor de regressão visual e de a11y (screen reader lê glyph como `󲎤`). Investir em **substituição por SVG semântico** vai pagar tanto em a11y quanto em customização (cor por categoria).
- **A criança pode "gamesear"** marcando missões falsamente. Hoje a aprovação parental existe, mas se o pai aprova em lote sem ver, o sinal de formação degrada. Considere amostragem — 1 missão por dia exige foto/áudio curto.

---

## 9. Bugs / glitches encontrados (priorizar)

| # | Severidade | Item | Local | Sugestão |
|---|---|---|---|---|
| 1 | **High** | `GET /parent/tasks` → 500 | `screenshots/09-parent-tasks-error.png` | Adicionar rota alias ou renomear resource |
| 2 | **High** | Card de missão na Home do filho sem affordance clara de "completar" | `/kid` | Botão grande primário no card |
| 3 | Med | Ícone de estrela duplicado no headline "Bora pegar mais ★ hoje?" | `/kid` (e02-kid-home) | Remover render duplicado |
| 4 | Med | Prefixo `[Família]` leak em nomes de prêmios/metas | `/kid/rewards`, `/kid` | Usar tag/section, não nome |
| 5 | Med | Métrica inconsistente "faltam 100" vs "faltam 20" para nível 2 | `/parent` vs `/kid` | Unificar regra |
| 6 | Med | Tabs com vocabulário de sistema ("Aguardando/Rejeitadas") | `/kid/wallet` | Reescrever em linguagem de criança |
| 7 | Low | "Trocar perfil" muito acessível ao filho | `/kid` header | Mover para menu/long-press |
| 8 | Low | Lista de áreas com Nv. 0 sem teaser de aula | `/kid/academy/subjects` | Mostrar 1ª pergunta inline |
| 9 | Low | "Comparar filhos" parece ranking apesar do disclaimer | `/parent/academy/compare` | Agrupar por conceito atravessado |
| 10 | Low | Sem confirmação em "Resetar PIN" / "Sair desta família" | `/parent/settings` | Adicionar dialog |
| 11 | Low | 3 erros de console (Vite HMR websocket — esperado em dev/Docker) | global | Investigar se vaza em produção |

---

## 10. Recomendações priorizadas (next 2 semanas)

**Sprint A (1 semana) — destravar o core loop do filho**
1. Botão de "completar missão" claro e celebratório no card (animação estrela → saldo).
2. Mover bloco de "Missões de hoje" para acima das metas familiares; mostrar 3 + "ver mais".
3. Cor de fundo por categoria nas missões (Saúde/Casa/Escola/Rotina).
4. Corrigir `/parent/tasks` 500.

**Sprint B (1 semana) — destacar Academy**
5. Reordenar nav do pai: Crianças → **Academy** → Tarefas → Recompensas.
6. Empty states da Academy do pai com next-step ("Convide X a fazer 1 aula").
7. Exportar carta cunhada como imagem compartilhável.

**Sprint C (depois) — ambição**
8. Wizard de primeiro uso (3 perguntas → missões personalizadas; sem seed genérica).
9. Quick-approve por swipe (mobile).
10. Substituir icon font por SVG semântico (a11y + cor).

---

**Fim do report.**
Telas em `./screenshots/`. Walkthrough completo cobriu Profile picker · PIN · Kid home/Academy/Wallet/Lojinha/Nova-missão · Parent home/Tasks/Approvals/Rewards/Categories/Activity/Settings/Profiles/Academy(dashboard/library/journeys/compare)/Reward-new.
