# Product Requirements Document (PRD): LittleStars 🌟

> **Versão:** 1.1 · **Última atualização:** 2026-04-19 · **Status:** MVP Draft

---

## 1. Visão do Produto

**LittleStars** é um app familiar que transforma tarefas domésticas em missões gamificadas. Crianças ganham "estrelinhas" por completar tarefas e trocam por recompensas reais definidas pelos pais.

### Problema
Pais dependem de cobranças verbais repetitivas para tarefas domésticas. Crianças não têm motivação tangível nem aprendem sobre esforço → recompensa de forma estruturada.

### Proposta de Valor
- **Para os pais:** Gestão prática de tarefas com validação real (não automática) e visibilidade total.
- **Para as crianças:** Motivação visual, metas claras e a experiência de "comprar" algo com esforço próprio (educação financeira básica).

---

## 2. Personas

| Persona | Perfil | Necessidade Principal | Frustrações |
|---|---|---|---|
| **Pai/Mãe** | Adulto, 28-45 anos, rotina atarefada | Ferramenta rápida, sem overhead de configuração | Repetir cobranças, falta de controle justo |
| **Criança** | 5-12 anos, orientada a recompensas | Interface divertida, metas visíveis, feedback imediato | Não saber o que falta para "ganhar o prêmio" |

---

## 3. Mecânicas Core

### 3.1 Economia de Estrelinhas (Tokenomics)
Moeda virtual onde esforço (tarefas) converte-se em poder de compra. Ensina **gratificação adiada**: gastar imediatamente em algo barato (Sobremesa) ou juntar semanas para algo caro (Videogame).

### 3.2 Ciclo de Aprovação Assíncrono
A criança **não ganha pontos automaticamente**. O fluxo é:

```
Criança clica "Terminei" → status: awaiting_approval (bloqueado)
        ↓
Pai/Mãe verifica no mundo real
        ↓
Aprovar → pontos creditados  OU  Rejeitar → volta para pending
```

### 3.3 Interface Dupla (Dual UI)
O mesmo app renderiza duas experiências completamente distintas:
- **Kid View:** Botões grandes, confetes, zero menus complexos, foco no saldo e missões.
- **Parent View:** Dashboard gerencial, filas de aprovação, cadastro de tarefas/recompensas, histórico consolidado.

### 3.4 Template vs Instância (Tarefas)
- **GlobalTask:** Template na biblioteca dos pais (ex: "Lavar louça — 50⭐").
- **ProfileTask:** Cópia independente atribuída à criança com `instanceId` e `status` próprios. A mesma tarefa pode estar finalizada para um filho e pendente para outro.

---

## 4. Épicos e User Stories

### Épico 1: Gestão de Perfis e Acessos

#### US01 — Seleção de Perfil (Login Lúdico)
**Como** usuário, **quero** ver os perfis da família na tela inicial **para** entrar no meu painel clicando no meu avatar.

**Critérios de Aceite:**
- [ ] Tela lista Pais e Crianças com avatares e nomes.
- [ ] Clique em perfil "Pai" → Parent Dashboard.
- [ ] Clique em perfil "Filho" → Kid View.

#### US02 — Gerenciamento de Filhos
**Como** Pai/Mãe, **quero** adicionar, editar ou remover perfis de filhos **para** configurar o sistema para todas as crianças da casa.

**Critérios de Aceite:**
- [ ] Pai define Nome e escolhe Avatar/Emoji (🦸‍♂️, 👸, 🦊).
- [ ] Excluir filho remove em cascata: saldo, atividades e tarefas atribuídas.

---

### Épico 2: Motor de Tarefas e Missões

#### US03 — Banco Global de Missões
**Como** Pai/Mãe, **quero** cadastrar tarefas no Banco Global com título, valor, categoria e frequência **para** criar um catálogo reutilizável.

**Critérios de Aceite:**
- [ ] Campos obrigatórios: Título, Estrelinhas (número), Categoria (Escola/Casa/Rotina), Frequência (Diária/Semanal com dias específicos).
- [ ] Listar e excluir tarefas globais existentes.

#### US04 — Visualização de Missões (Kid View)
**Como** Filho, **quero** ver cartões grandes e coloridos com minhas missões de hoje **para** saber o que fazer para ganhar estrelinhas.

**Critérios de Aceite:**
- [ ] Separar tarefas "Pendentes" das "Aguardando Aprovação".
- [ ] Cartões com botão grande ("Fazer Missão") e ícone por categoria.
- [ ] Não mostrar tarefas de outros irmãos.

#### US05 — Submissão de Missão
**Como** Filho, **quero** clicar "Terminei" **para** enviar a missão para aprovação dos pais.

**Critérios de Aceite:**
- [ ] Modal recapitula detalhes da missão antes de confirmar.
- [ ] Confirmação move a tarefa para `awaiting_approval`.
- [ ] Pontos **não** são creditados até aprovação.

#### US06 — Aprovação/Rejeição de Missões
**Como** Pai/Mãe, **quero** ver a fila de aprovações pendentes **para** validar no mundo real e aprovar ou rejeitar.

**Critérios de Aceite:**
- [ ] Lista segmentada por criança.
- [ ] Aprovar: animação verde + pontos creditados ao saldo.
- [ ] Rejeitar: flash vermelho + tarefa volta para "Pendente" do filho.

---

### Épico 3: Economia, Loja e Recompensas

#### US07 — Cartão de Saldo (A Carteira)
**Como** Filho, **quero** ver meu saldo de estrelinhas destacado e animado **para** saber o quão perto estou da recompensa.

**Critérios de Aceite:**
- [ ] Saldo reage em tempo real com animação numérica.
- [ ] Visual remete a baú/portal de moedas douradas.

#### US08 — Gerenciamento da Lojinha
**Como** Pai/Mãe, **quero** adicionar prêmios ao catálogo com preço em estrelinhas **para** motivar meus filhos.

**Critérios de Aceite:**
- [ ] Campos: Título, custo em ⭐, Ícone/Emoji.

#### US09 — Resgate de Recompensas
**Como** Filho, **quero** comprar itens da Loja com minhas estrelinhas **para** receber minha recompensa.

**Critérios de Aceite:**
- [ ] Loja exibe itens com preços e ícones animados (idle rotation).
- [ ] Saldo insuficiente → botão "Resgatar" desabilitado/cinza.
- [ ] Resgate confirmado → celebração com confetes + estrelas + glow radial; pontos deduzidos.

---

### Épico 4: Transparência

#### US10 — Extrato de Atividades
**Como** usuário, **quero** ver um extrato do que ganhei e gastei **para** que haja transparência e justiça.

**Critérios de Aceite:**
- [ ] Visão Pai: histórico de todos os filhos com datas, nomes e ações.
- [ ] Visão Filho: histórico pessoal simplificado (+50⭐ Louça; -200⭐ Sobremesa).
- [ ] Ordenação: mais recente primeiro.
- [ ] Cores: Ganhos (Verde/Laranja), Gastos (Vermelho/Rosa).

---

## 5. Design System

### Identidade Visual
**Mood:** Lúdico, vibrante, acolhedor, tátil.

**Shapes:** Bordas exageradas (`rounded-3xl` / `32px`), bordas coloridas espessas (`border-[6px]`).

### Paleta de Cores

| Função | Cor | Hex |
|---|---|---|
| Moeda/Primary | Laranja Vibrante | `#FF8B13` |
| Conquistas | Amarelo Mostarda | `#FFD54F` |
| Conquistas (accent) | Ouro | `#FFA000` |
| Recompensas | Rosa Suave | `#FFCDD2` |
| Recompensas (bg) | Rosa Claro | `#FFEBEE` |
| Estatísticas | Ciano | `#4DD0E1` |
| Estatísticas (accent) | Azul Piscina | `#00ACC1` |
| Bordas decorativas | Amarelo Quente | `#FFE082` |

### Animações Chave (Framer Motion)

| Evento | Comportamento | Duração |
|---|---|---|
| **Resgate de Recompensa** | Backdrop blur → Glow radial expansivo → 16 partículas orbitais → 12 estrelas flutuantes → texto de sucesso (spring) | 1.5–2.5s |
| **Aprovação Parental** | Card bg `#fff → #dcfce7 → #fff` com scale pulse → glow verde `drop-shadow 20px` → 6 sparks radiais | 0.8s |
| **Loja (idle)** | Rotação suave ±5° + box-shadow pulse laranja | 3s loop ∞ |
| **Modal Tarefa (idle)** | Ícone flutuando `y: 0→-8→0` | 3s loop ∞ |

---

## 6. Arquitetura Técnica

### Tech Stack
| Camada | Tecnologia |
|---|---|
| Framework | React 18+ |
| Linguagem | TypeScript |
| Estilização | Tailwind CSS |
| Animação | Framer Motion |
| Iconografia | Lucide React |
| Backend (futuro) | Firebase (Auth + Firestore) |

### Modelos de Dados

```typescript
interface Profile {
  id: string;
  name: string;
  avatar: string;       // emoji ou key de imagem
  points: number;
  tasks: ProfileTask[];
  stats: Record<string, number>;
}

interface GlobalTask {
  id: string;
  title: string;
  category: 'escola' | 'casa' | 'rotina' | 'outro';
  points: number;
  frequency: 'daily' | 'weekly';
  daysOfWeek: number[]; // 0=Dom, 1=Seg... 6=Sáb
}

interface ProfileTask extends GlobalTask {
  instanceId: string;
  status: 'pending' | 'awaiting_approval' | 'approved' | 'rejected';
  completedAt: number | null;
}

interface Reward {
  id: string;
  title: string;
  cost: number;
  icon: string;
}

interface ActivityLog {
  id: string;
  profileId: string;
  type: 'earn' | 'redeem';
  title: string;
  points: number;
  timestamp: number;
}
```

### Regras de Negócio

1. **Transações Atômicas:** Operações de `+earn` e `-redeem` devem usar Batch Writes (ou Cloud Functions) para evitar race conditions e saldo negativo.
2. **Reset Temporal:** Tarefas diárias resetam à meia-noite. Tarefas com `daysOfWeek` são instanciadas apenas nos dias configurados.
3. **Isolamento por Perfil:** Cada criança enxerga apenas suas próprias `ProfileTasks` e seu próprio histórico.

---

## 7. Scope: O que é MVP e o que NÃO é

### ✅ MVP (v1.0)
- Seleção de perfil (sem autenticação real — PIN opcional futuro).
- CRUD de filhos, tarefas globais e recompensas.
- Ciclo completo: criação → atribuição → execução → aprovação → crédito.
- Loja com resgate e validação de saldo.
- Extrato de atividades (read-only).
- Estado local (useState/useReducer). Persistência em localStorage.

### ❌ Fora do MVP
- Firebase/Firestore (Sprint 2+).
- Autenticação real (PIN, senha, biometria).
- Notificações push.
- Múltiplas famílias / multi-tenant.
- Streaks, níveis, achievements.
- PWA / modo offline completo.

---

## 8. Roadmap Técnico

| Sprint | Foco | Entregáveis |
|---|---|---|
| **1 — Fundação** | UI local-first | Tela de perfis, Kid View (missões + saldo + loja), Parent View (dashboard + aprovações + cadastros). Estado em memória com localStorage. |
| **2 — Firebase** | Persistência real | Firestore setup, migração de `useState` para `onSnapshot`, sincronização real-time entre dispositivos. |
| **3 — Segurança** | Rules + Auth | Firestore Security Rules (filhos: write apenas em `status` da própria `ProfileTask`; pais: write completo). Firebase Auth básico. |

---

## Changelog

| Versão | Data | Mudanças |
|---|---|---|
| 1.0 | 2026-04-19 | Documento inicial. |
| 1.1 | 2026-04-19 | Adicionado: seção de Scope (MVP vs Fora), personas com tabela, data models em TypeScript, critérios de aceite como checklists, tabela de cores, changelog. Removido: jargão desnecessário, duplicações entre seções. |
