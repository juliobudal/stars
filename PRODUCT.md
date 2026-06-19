# Product

## Register

product

## Users

**Famílias cristãs com filhos em idade de formação (≈6–14 anos).** Dois personas convivem no mesmo app, em sessões separadas:

- **Pais** — buscam um sistema que ajude a formar caráter, hábitos e virtudes nos filhos sem virar policial 24/7. Usam o app em momentos curtos (aprovar tarefa, configurar recompensa, revisar progresso). Contexto típico: celular, à noite, depois do jantar.
- **Crianças/adolescentes** — usuários principais do dia a dia. Tela pequena (mobile-first, `max-w-[430px]`), interação rápida entre escola e brincadeira. Querem ver progresso, ganhar estrelas, resgatar recompensas, conversar com "O Guia".

A "moeda" do app são **estrelas** (`Profile.points`), ganhas ao concluir tarefas (aprovadas pelos pais) e trocadas por recompensas combinadas com os pais. A Academy é formação pura: as pílulas não dão estrelas, o estímulo é o desbloqueio sequencial e a curiosidade.

## Product Purpose

LittleStars transforma a rotina familiar e a formação humana num jogo cooperativo entre pais e filhos. Existem três núcleos:

1. **Economia de estrelas** — tarefas configuradas pelos pais → criança realiza → pais aprovam → estrelas creditadas → criança resgata recompensas.
2. **Academy — "Pílulas de Conhecimento"** (redesign 2026-05-28, spec `specs/001-academy-redesign/`) — radicalmente simples: **5 tabelas**, modelo **Trilha → Aulas (pílulas) ordenadas**, desbloqueadas em sequência (aula N abre quando N-1 é concluída). Cada aula segue o **método do mistério**: `enigma → pistas → revelação → teste → fisgada`. Conteúdo 100% curado em seeds (`db/seeds/academy*.rb`); o único LLM em runtime é o chatbot **"O Guia"** (DeepSeek via OpenRouter, persona *authoritative + mysterious + fascinated*, **5 perguntas/dia** por criança, escopado a uma aula). Sem `OPENROUTER_API_KEY` o botão 🦉 some e a aula funciona normal. O v2/v4 (pokédex, conceitos/grafo, skills, ranks, segredos, missions/subjects, medals) foi **removido**.
3. **Vida em família** — wishlist da criança, streaks diárias, perfis múltiplos por família, convites entre membros.

Sucesso = a criança quer abrir o app sozinha, e os pais sentem que o tempo de tela é formativo, não anestésico.

## Brand Personality

**Encorajador · lúdico · formativo.**

- **Encorajador** — celebra progresso (confetti, badges, streak), nunca pune. Erros são parte do caminho.
- **Lúdico** — visual Duolingo (verde `#58CC02`, Nunito 700/800, sombras 3D `0 4px 0`, cantos 10–16px, micro-animações). O app *sente* leve, não acadêmico.
- **Formativo** — leva formação de caráter a sério. Conteúdo de Academy inclui Provérbios, Tiago e filósofos universais lado a lado; "O Guia" tem persona de mentor sábio, não de NPC fofinho.

## Anti-references

Three lanes to refuse, with the trap each one represents:

- **SaaS genérico (Stripe-azul, navy corporate, paleta cinza-bege).** Frio, adulto, sem alma. Mata o jogo.
- **App de produtividade adulto (Linear, Notion, Raycast minimal-mono).** Crianças não respondem a minimalismo monocromático sem afeto. Precisamos de cor, peso, depth.
- **App infantil agressivo (Roblox neon, TikTok Kids, ABCmouse piscante).** Overestímulo, dopamina barata, sem profundidade formativa. Duolingo é o teto de "intensidade lúdica" — firme + alegre, nunca convulsivo.
- **Cristão kitsch (fontes script douradas, ilustrações santarronas, paleta "school CCB").** Conteúdo cristão entra pela substância (textos curados), nunca pela estética datada.

## Design Principles

1. **Cada toque tem peso.** Botões deprimem (`translateY(2px); box-shadow: none`). Tudo interativo tem sombra `0 4px 0`. O app responde com corpo, não com fade.
2. **Bold weight, compact radii.** Nunito 700/800, raios 10–16px (nunca 22–32px soft). Confiança visual, não fofice apagada.
3. **Mobile-first para a criança, escala para os pais.** Shell kid trava em 430px; parent expande com sidebar em `lg+`. Nunca o contrário.
4. **Conteúdo formativo sem condescendência.** Copy direta, sem baby-talk. Provérbios e filósofos coexistem. Crianças leem mais do que se pensa.
5. **Token-first, zero hex solto.** Toda cor/fonte/raio/sombra via CSS var em `tailwind/theme.css`. Componentização via `Ui::*` ViewComponents — markup inline só com justificativa documentada em `DESIGN.md §6`.

## Accessibility & Inclusion

- **WCAG AA** mínimo: contraste de texto, hit targets ≥ 44px, foco visível em todos os interativos.
- **`prefers-reduced-motion`** respeitado em todo elemento com sombra 3D (`DESIGN.md §5`) — translateY/scale viram no-op, transições reduzidas.
- **Sem dependência de cor sozinha**: estados (success/error/info) sempre acompanhados de ícone + label.
- **Copy curta e ícone redundante** em superfícies kid, considerando leitores iniciantes.
- **PT-BR como idioma principal**; nomes técnicos em inglês (commits, código, models) por convenção do repo.
