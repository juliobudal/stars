# 🌟 LittleStars - User Stories

Este documento cataloga todos os requisitos de negócio e funcionalidades do aplicativo **LittleStars** mapeados no formato Ágil de Histórias de Usuário.

---

## 👨‍👩‍👧‍👦 Épico 1: Gestão de Perfis e Acessos

### US01: Seleção de Perfil (Login Lúdico)
**Como um** usuário (Pai ou Filho)  
**Eu quero** ver uma tela inicial com os perfis cadastrados  
**Para que** eu possa entrar no meu painel correspondente apenas clicando na minha foto/avatar.
* **Critérios de Aceite:**
  * A tela deve listar os Pais e as Crianças com seus respectivos avatares e nomes.
  * O clique num perfil de "Pai" leva ao Painel de Controle (Dashboard).
  * O clique num perfil de "Filho" leva à Visão Lúdica Infantil (Kid View).

### US02: Gerenciamento de Filhos
**Como um** Pai/Mãe (Administrador)  
**Eu quero** poder adicionar, editar ou remover perfis de filhos  
**Para que** eu possa configurar o sistema para todas as crianças da casa.
* **Critérios de Aceite:**
  * O pai deve poder definir um Nome e escolher um Avatar/Emoji (ex: 🦸‍♂️, 👸, 🦊).
  * Excluir um filho deve remover seu saldo, atividades e tarefas atribuídas associadas.

---

## ✅ Épico 2: Motor de Tarefas e Missões

### US03: Banco Global de Missões
**Como um** Pai/Mãe  
**Eu quero** cadastrar tarefas num "Banco Global" definindo título, valor (estrelinhas), categoria e frequência (diária ou semanal)  
**Para que** eu possa criar um catálogo de rotinas domésticas e transferi-las rapidamente para as crianças depois.
* **Critérios de Aceite:**
  * O formulário deve exigir: Título, Quantidade de Estrelinhas, Categoria (Escola, Casa, Rotina, etc.) e Frequência.
  * O pai pode ver a lista de todas as tarefas globais já cadastradas e excluí-las.

### US04: Visualização das Missões (Visão Infantil)
**Como um** Filho  
**Eu quero** ver uma lista de cartões grandes e coloridos mostrando minhas missões de hoje  
**Para que** eu saiba exatamente o que preciso fazer para ganhar minhas estrelinhas.
* **Critérios de Aceite:**
  * A interface deve separar as tarefas "Pendentes" (Para Fazer) das "Aguardando Aprovação".
  * Cartões devem ter botões grandes ("Fazer Missão") e ícones de identificação por categoria.
  * O app não deve mostrar tarefas de outros irmãos.

### US05: Fluxo de Execução da Missão
**Como um** Filho  
**Eu quero** clicar em "Terminei" na minha missão  
**Para que** eu possa enviá-la para o meu pai aprovar e me dar minhas estrelinhas.
* **Critérios de Aceite:**
  * Ao clicar no botão, o card mostra um modal recapitulando os detalhes da missão.
  * Ao confirmar, a missão sai da aba "Pendentes", muda de status e fica aguardando.
  * A criança *não ganha os pontos automaticamente* antes do pai aprovar.

### US06: Aprovação/Rejeição de Missões
**Como um** Pai/Mãe  
**Eu quero** ver uma aba de "Aprovações" com os pedidos pendentes dos filhos  
**Para que** eu possa checar no mundo real (ex: ver se o quarto foi arrumado) e aprovar ou rejeitar o ganho dos pontos.
* **Critérios de Aceite:**
  * A tela deve listar as tarefas segmentadas por criança.
  * Ao "Aprovar", a tarefa ascende um brilho verde e envia os pontos para o saldo da criança.
  * Ao "Rejeitar", a tarefa pisca em vermelho e volta para a aba "Para Fazer" do filho.

---

## 🛍️ Épico 3: Economia, Loja e Recompensas

### US07: Cartão de Saldo (A Carteira)
**Como um** Filho  
**Eu quero** ver o meu saldo atual de Estrelinhas de forma destacada e animada  
**Para que** eu saiba o quão perto estou de comprar a recompensa que eu quero.
* **Critérios de Aceite:**
  * O saldo global deve reagir em tempo real (mudando o número de forma animada).
  * O visual deve remeter a um baú ou portal de moedas douradas/laranjas.

### US08: Gerenciamento da Lojinha
**Como um** Pai/Mãe  
**Eu quero** adicionar prêmios ao catálogo e estipular o preço em estrelinhas  
**Para que** eu possa motivar meus filhos com recompensas físicas ou experiências (ex: Sorvete, Video Game, Passeio).
* **Critérios de Aceite:**
  * O painel permite criar o Título do prêmio, o custo exato em estrelinhas e associar a um Ícone ou Emoji.

### US09: Resgate de Recompensas
**Como um** Filho  
**Eu quero** navegar pelas opções da Loja e comprar um item com minhas estrelinhas  
**Para que** eu receba a minha recompensa por todo o esforço.
* **Critérios de Aceite:**
  * A loja exibe os itens com preços e ícones giratórios animados.
  * Se o saldo for insuficiente, o botão "Resgatar" deve estar bloqueado/cinza.
  * Quando há saldo e o resgate é confirmado no modal, uma chuva de confetes, estrelas e explosão radial ("Glow") deve celeberar a compra do usuário e os pontos devem ser deduzidos de sua conta.

---

## 📜 Épico 4: Transparência e Gamificação

### US10: Extrato/Histórico de Atividades
**Como um** Usuário (Pai ou Filho)  
**Eu quero** visualizar um extrato/cronologia (Log) descrevendo tudo o que ganhei e o que gastei recentemente  
**Para que** não haja discussões sobre contas apagadas magicamente, trazendo justiça ao jogo.
* **Critérios de Aceite:**
  * A visão dos Pais exibe o histórico de *todos os filhos em conjunto*, indicando datas, quem resgatou/completou, o quê e quando.
  * A visão da Criança exibe apenas o seu *próprio histórico pessoal* em uma lista simplificada (+100 Estrelinhas da louça; -200 Estrelinhas de Sobremesa).
  * Ordenação deve ser da mais recente para a mais antiga.
  * Ícones visuais distinguem "Ganhos" de cor viva (Verde/Laranja) e "Gastos" (Vermelho/Rosa).
