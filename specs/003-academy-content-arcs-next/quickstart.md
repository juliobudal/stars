# Quickstart — Implementar & verificar as trilhas Tier S

**Feature**: 003-academy-content-arcs-next · Tudo roda dentro do container `web` (ver CLAUDE.md / `make`).

## 1. Editar o conteúdo (única fonte de verdade)

Arquivo: `db/seeds/academy_content.rb`, constante `ACADEMY_CONTENT`.

1. Em `as-palavras-mudam`: trocar `cliffhanger_to: nil` → `cliffhanger_to: "tudo-quase-vazio"` e editar o `hook` da última aula para conter literal **"Tudo que parece sólido é quase vazio"** (ver `research.md` D4).
2. Acrescentar a trilha **`tudo-quase-vazio`** (4 aulas) — usar enigmas/revelações/ganchos de `research.md` D2 e os metadados travados.
3. Acrescentar a trilha **`voce-feito-de-estrelas`** (4 aulas) — `research.md` D3; `cliffhanger_to: nil`.

Respeitar o contrato `contracts/arc-content.contract.md` (C1–C6) ao escrever — em especial as ocorrências **literais** de refrão, marcador e título-destino.

## 2. Validar sem subir o banco (gate de build)

O `ArcValidator` roda no build do seed e na spec. Rodar a spec de conteúdo:

```bash
make rspec SPEC=spec/seeds/academy_content_spec.rb
```

Esperado: verde. Se o validador acusar violação (ex.: refrão ausente numa revelação, título-destino não literal no hook), o erro aponta `[trilha/aula] regra (FR-00x)` — corrigir o texto.

> Se adicionar assertivas de contagem (5→7) / cadeia de cliffhanger, fazê-lo nesta spec (testes 2/3 do contrato).

## 3. Semear e conferir no browser

```bash
make db-reseed     # ou make seed, conforme o estado do banco
```

App em `localhost:10301` (porta de dev do projeto). Logar como kid (creds de seed) → `/kid/academy`:

- As 7 trilhas aparecem; as 2 novas no fim, desbloqueando em sequência.
- Concluir a última aula de **As palavras mudam o que você enxerga** → a fisgada nomeia **Tudo que parece sólido é quase vazio**.
- Percorrer **T6** ponta a ponta → enigma de abertura reaberto na 4ª aula (mão/encostar/torrão de açúcar + Salmo 8); fisgada nomeia **Você é feito de estrelas mortas**.
- Percorrer **T7** → fechamento (osso/explosão + Gênesis 3:19 + Sagan); fisgada é gancho aberto.
- Cada aula completável em ≤ 3 min (SC-104).

## 4. Gates finais

```bash
make rspec        # suíte do módulo verde (SC-105)
make lint         # rubocop-omakase
```

Sem migration nova (`git status db/migrate` vazio). Sem mudança de schema. Sem UI nova.

## Definition of Done

- [ ] `ACADEMY_CONTENT` com 7 trilhas, T6/T7 com 4 aulas cada, metadados de arco travados.
- [ ] `as-palavras-mudam.cliffhanger_to` = `tudo-quase-vazio` e hook final nomeando T6.
- [ ] `ArcValidator` retorna zero violações no conjunto completo (build + spec).
- [ ] Revisão humana FR-101: 8 revelações distintas, tom mistério+fascínio, zero clichê, versículos como descoberta.
- [ ] `make rspec` verde, `make lint` limpo, sem migration.
- [ ] Smoke no browser: cadeia de cliffhanger íntegra `as-palavras-mudam → T6 → T7 → gancho aberto`.
