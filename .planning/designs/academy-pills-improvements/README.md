# Academy — pílulas mais inteligentes & mais divertidas

Conjunto de planos derivados da análise de 2026-05-20 sobre o que está sendo
ensinado, como, e em que tom. Cada arquivo cobre **um item** acionável,
estimado e com critério de aceite. Implementação em sessões futuras.

Análise de origem (resumida no chat 2026-05-20):
- 53 conceitos, 70% em "cognitivo/social" (formação humana); subrepresentação
  de curiosidade-do-mundo (ciência, mundo natural, matemática, história).
- 8 lens types, 4 deles concentrando ~95% dos payloads; closure lenses em
  só 9.5% das missões (G-1 de `academy-gaps-2026-05-19.md`).
- Tom forte (concreto, sem moralização), mas: vocabulário acima da idade,
  zero humor, persona única "O Guia", sem personalização por interesses.
- WisdomPills com 40 entries, 25% atribuídas a "O Guia" (autoria sintética).
- Não há "pílula avulsa diária" — menor surface hoje é missão de 3+ lentes.

## Visão de portfólio

```
┌─ Alto ROI (mexe NO QUÊ é ensinado) ─────────────────────────────────────┐
│ A  Currículo de curiosidade-do-mundo (3 novas Subjects + ~30 conceitos) │
│ B  Closure lenses curadas (31 concepts) — herda de G-1 do gaps-doc      │
│ C  Lentes corporais/temporais (first_person/historical/engineering)     │
├─ Médio ROI (mexe NO COMO) ──────────────────────────────────────────────┤
│ D  Pílula do Dia — surface diário de 60s no kid home                    │
│ E  Calibrar age band + leiturabilidade (Flesch-PT + maxLength)          │
│ F  Sinal de interesses do kid → LearnerContext                          │
│ G  Lightning Round (retrieval gamificado semanal)                       │
├─ Baixo ROI (polimento) ─────────────────────────────────────────────────┤
│ H  Expandir WisdomPills 40 → 120 e baixar "O Guia" pra 10%              │
│ I  Sub-vozes por lens_type (Naturalista, Historiador, Engenheiro)       │
│ J  Suavizar FORBIDDEN_TONE_PATTERNS pra liberar wonder-hook             │
└─────────────────────────────────────────────────────────────────────────┘
```

## Ordem sugerida de execução

1. **A** primeiro — expandir o currículo de curiosidade-do-mundo é o que mais
   muda a percepção do produto. Sem isso, tudo é "lição de meta-skill".
2. **F** (interesses) em paralelo com A — barato e amplifica A.
3. **B** + **C** — fecham buracos pedagógicos visíveis hoje.
4. **D** — quando há massa crítica de payloads curados (>= 80 conceitos),
   surface a "Pílula do Dia".
5. **E** — calibração de age band pode rodar como audit batch depois.
6. **G** — depende de massa de conceitos + maestria capturada.
7. **H, I, J** — polimento; podem entrar em qualquer momento.

## Convenções dos planos

Cada arquivo segue o template:
- **Objetivo** — frase única do "porque importa".
- **Motivação** — evidência (números, paths, citações) que justifica.
- **Escopo** — o que entra e o que NÃO entra.
- **Trabalho** — passos concretos com paths de arquivo.
- **Critérios de aceite** — verificáveis (query SQL, spec, screenshot).
- **Riscos** — o que pode dar errado.
- **Estimativa** — horas-pessoa.
- **Dependências** — outros itens deste portfólio.

## Status (preencher conforme avança)

| Item | Plano | Status | Notas |
|------|-------|--------|-------|
| A    | [A-curriculo-curiosidade.md](A-curriculo-curiosidade.md) | done 2026-05-20 | 10 áreas, 83 conceitos, 30 missões novas (6 trails) |
| B    | [B-closure-lenses.md](B-closure-lenses.md) | done 2026-05-20 | 30 analogy_bridge curados, 83/83 concepts c/ closure |
| C    | [C-lentes-corporais.md](C-lentes-corporais.md) | done 2026-05-20 | 39 payloads (first_person 14, historical 11, engineering 14) + ChooseNext spec 12/12 |
| D    | [D-pilula-do-dia.md](D-pilula-do-dia.md) | done 2026-05-20 | PillView + service idempotente + UI + caderno `/kid/academy/pills` (3/3 specs) |
| E    | [E-calibrar-age-band.md](E-calibrar-age-band.md) | done 2026-05-20 | Readability gate no seeder (FRE<50 bloqueia) + audit `.planning/reports/2026-05-20-readability-audit.txt` (94.6% ok, 0 block) + age band 7-12 unificado |
| F    | [F-interesses-do-kid.md](F-interesses-do-kid.md) | done 2026-05-20 | infra completa + variantes + interest_picker request spec 5/5 |
| G    | [G-lightning-round.md](G-lightning-round.md) | done 2026-05-20 | BuildLightningRound + wizard + tabela `academy_lightning_round_runs` + badge "⚡ Lightning Champion" (4 runs/7d com ≥4 acertos) + 8/8 specs |
| H    | [H-wisdom-pills-pool.md](H-wisdom-pills-pool.md) | done 2026-05-20 | 122 pílulas, 8.2% "O Guia", theme + sample(theme:) |
| I    | [I-sub-vozes-por-lens.md](I-sub-vozes-por-lens.md) | done 2026-05-20 | 5 sub-vozes + header inject + galeria `/kid/academy/cast` + badge "Conheceu todo o elenco" (3/3 specs) |
| J    | [J-tom-wonder-hook.md](J-tom-wonder-hook.md) | done 2026-05-20 | "Você sabia que" liberado; OpenerCheck positivo + 7/7 specs |
