## Context

A pílula é a versão "single-lens, sem missão" do conteúdo Academy: o kid recebe uma dose isolada (60–90s) que reusa o partial `_lens_predict.html.erb` da missão. O lens `scientific` define no schema (`app/services/academy/lens/schemas/scientific.json`) um campo obrigatório `illustration_hint` — string de 50–320 caracteres descrevendo uma ilustração. Todos os 42 payloads em `db/seeds/academy_lens_payloads/scientific/` populam esse campo com prosa rica em pt-BR.

Hoje o partial renderiza o hint como texto cinza itálico (`_lens_predict.html.erb:92-95`). O conteúdo é 100% curado, seedado em `academy_lens_cache.payload` (jsonb), resolvido via `Academy::Lens::ResolveCuratedPayload`. O caderno de pílulas (`/kid/academy/pills`) reusa esse mesmo partial — ou seja, qualquer melhoria no render do lens scientific se propaga sem mais cirurgia.

Convenções do módulo Academy (`CLAUDE.md`):
- Zero FK em host (`Profile`, `Family`) — adapter `Academy::Learner`.
- Tabelas prefixadas `academy_*`, models sob `Academy::`, services em `Academy::*::*`.
- Services herdam `ApplicationService`, devolvem `Result = Data.define(:success, :error, :data)`.
- `OPENROUTER_API_KEY` ausente → degradação graciosa, sem erro visível ao kid (precedente: O Guia, `Academy::Guide::Available?`).
- Conteúdo curado é seedado; LLM em runtime é exclusivo de O Guia.

Camada visual governada por `DESIGN.md`: tokens Duolingo (#58CC02, Nunito 700/800, sombra `0 4px 0`, radius 10–16px).

Stakeholders: kid (consome a pílula), curador (escreve o hint), engenharia (roda o pipeline one-shot). Pais e dashboards não são afetados.

## Goals / Non-Goals

**Goals:**
- Gerar uma ilustração por hint, com estilo visual consistente (Duolingo flat) entre os 42 itens.
- Pipeline one-shot, idempotente, executável localmente (dev), commitando o resultado ao repo.
- Render do `<img>` totalmente alinhado a `DESIGN.md` (radius, sombra, sem quebrar o `lens-card`).
- Fallback intacto: pílulas sem URL renderizam o hint italic atual — zero regressão para os payloads não gerados.
- Custo previsível (~$0.02 total) e zero custo recorrente em produção.
- Acessibilidade: `alt` text derivado do `headline` da pílula, não do hint (hint é descritivo demais e prolixo pra screen reader).

**Non-Goals:**
- Gerar imagens para outros lens primitives (`narrative`, `analogy_bridge`, etc.) — nenhum deles tem `illustration_hint` no schema hoje; é trabalho separado.
- Geração on-demand em runtime — explicitamente rejeitado (latência, custo recorrente, divergência com a filosofia "único LLM em runtime é O Guia").
- Edição/regeneração via UI de admin/parent — fica via rake task até que volume justifique.
- Active Storage / S3 / R2 — fica em disco no `public/`. Migrar é problema para a primeira semana em que isso atrapalhar.
- Otimização SVG / vetorização — saída fica em WebP raster. Vetor é alvo da v2.
- Streaming / progressive enhancement do `<img>` — image tag simples, sem skeleton elaborado.

## Decisions

### 1. Pré-geração one-shot, resultado commitado em `public/academy/illustrations/`

Rake task roda em dev contra `OPENROUTER_API_KEY` local, baixa cada imagem como PNG (data URL base64), reotimiza para WebP, salva em `public/academy/illustrations/<concept_slug>.webp`, e grava `payload['illustration_url'] = "/academy/illustrations/<concept_slug>.webp"` de volta no `academy_lens_cache`. Os arquivos WebP vão pro git (~2 MB total).

**Rationale:** o conteúdo é estático, então o resultado da geração também é. Commit no repo evita Active Storage, evita CDN, evita dependência de rede em produção, e mantém a pílula servível offline durante o desenvolvimento.

**Alternativa rejeitada:** Active Storage com disco local em prod. Adiciona complexidade (storage service, variantes, blob lookup) por zero ganho — não tem upload de usuário envolvido.

**Alternativa rejeitada:** R2/S3 com CDN. Faz sentido se evoluirmos pra milhares de pílulas; pra 42, é overkill.

### 2. Modelo default: `google/gemini-2.5-flash-image` (Nano Banana)

Pesquisa via Context7 (`/websites/openrouter_ai`) + API ao vivo (`/api/v1/models?output_modalities=image`) — pricing token-based em $0.0000003/token; uma imagem gera ~1290 tokens → **~$0.0004/imagem**. 42 imagens × ~$0.0004 ≈ $0.02. Suporta `image_config.aspect_ratio` e `image_config.image_size` (`0.5K`, `1K`, `2K`, `4K`). Retorna data URL base64 em `message.images[0].image_url.url`. Modalidade `["image","text"]` — opcionalmente captura um caption text grátis na mesma chamada (não usaremos para `alt`, mas útil pra debug).

**Rationale:** custo trivial, prompt adherence sólida pra ilustração estilizada, mesmo ecossistema OpenRouter que já usamos via DeepSeek. Suporta `image_size: "1K"` (~1024×1024) que é generoso pro card mobile.

**Alternativa de upgrade (Recraft v4):** especialista em flat/vetor — match natural pro DESIGN.md. ~$0.04/imagem → $1.68 total. Disponível como `recraft/recraft-v4` ou `recraft/recraft-v4-vector` no OpenRouter. Trocar é mudar uma string em `config/initializers/academy.rb` (`Academy.config.image_model`). Mantemos como **fallback configurável**, não default — só pulamos pra ele se a calibração com Gemini falhar visualmente em ≥20% das pílulas.

**Alternativa de upgrade (Flux.2-pro):** preço similar ao Recraft, fortíssimo em fotorrealismo — pior fit pra "Duolingo cartoon". Listado no spec só como sabido-existir.

**Alternativa rejeitada (Flux.2-klein-4b, riverflow):** mais barato que Recraft mas com drift estético entre chamadas — quebra a consistência visual que é o requisito #1.

### 3. Prompt composer com prefix de estilo fixo

`Academy::Illustrations::PromptComposer.compose(hint)` retorna:

```
Flat vector illustration, Duolingo style, rounded geometric shapes,
vibrant Duolingo green (#58CC02) as primary accent, soft pastel
secondary palette (peach, sky blue, butter yellow), friendly mascot
energy, thick clean outlines, no text or letters anywhere, white
background, square 1:1 composition, child-friendly mood, cheerful
and curious.

Scene: <illustration_hint>
```

Prefix é **constante congelada** (`PREFIX = "..."`). Mudanças no prefix são tratadas como nova versão de estilo (`STYLE_VERSION = "duolingo@v1"`) — versão fica registrada no payload (`illustration_meta: { style: "duolingo@v1", model: "...", generated_at: "..." }`) pra rastreabilidade.

**Rationale:** sem um wrapper de estilo, cada imagem sai com look próprio e o caderno de pílulas vira colcha de retalhos. Versão congelada permite saber quais imagens foram geradas sob qual contrato visual.

**Decisão sobre prompt negativo:** Gemini Flash Image não expõe campo `negative_prompt` separado via OpenRouter — restrições ("no text, no letters") vão dentro do prompt principal. Se trocarmos pra Recraft (que suporta negative), o composer ramifica.

### 4. Pós-processamento: PNG → WebP via `image_processing`

Resposta vem como data URL base64 (`data:image/png;base64,…`). Pipeline:

```
base64 decode → PNG bytes → ImageProcessing::Vips.resize_to_limit(1024,1024)
                                                .convert("webp")
                                                .saver(quality: 85)
                          → bytes WebP → File.write
```

WebP a 85% gera ~30–60 KB por ilustração 1024² — bem abaixo dos 100 KB que justificariam outra estratégia.

**Rationale:** WebP tem suporte universal em browsers que rodam o app (Rails 8 default targets); a economia de ~70% sobre PNG é a diferença entre "commitar é trivial" e "considerar LFS". Vips já vem com Rails 8 (`image_processing` é dependência transitiva via Active Storage). Se não estiver disponível, fallback pra `mini_magick` — confirma na task 0.

**Alternativa rejeitada (manter PNG):** dobra o peso do repo sem ganho.

**Alternativa rejeitada (AVIF):** suporte mais novo; WebP é mais previsível.

### 5. Naming = concept slug, não payload hash

Arquivo nomeado pelo **slug do conceito** alvo da pílula (`agua-quebra-pedra.webp`). Conflito impossível porque cada `academy_lens_cache` row tem `(concept_id, lens_type, age_band, locale, interest_key)` único, e `interest_key` é nulo pros 42 payloads atuais.

**Rationale:** humano-legível, fácil rastrear arquivo↔conceito, fácil regenerar individualmente (`--only=agua-quebra-pedra`).

**Alternativa rejeitada (hash do payload):** mudanças no hint forçariam invalidação de arquivo + regenerar — útil em runtime, irrelevante em pipeline one-shot.

### 6. Idempotência e modos de execução

```
make shell → bin/rails academy:illustrations:generate
```

Skipa por default qualquer lens_cache row onde `payload['illustration_url']` já existe E o arquivo no disco existe. Flags:

- `--force` → regenera tudo (cuidado: $0.02 cada vez).
- `--only=slug-1,slug-2` → restringe ao subset.
- `--dry-run` → imprime quais rows seriam geradas, não chama LLM.
- `--model=recraft/recraft-v4` → override do default.

**Rationale:** primeira rodada gera tudo; rodadas seguintes (em re-execução do seed ou em CI) ficam noop. Permite calibrar prompt iterativamente sem perder o que ficou bom.

### 7. Inert sem `OPENROUTER_API_KEY` (e ausência em produção é OK)

Rake task verifica `Academy.config.openrouter_api_key`; se vazio, falha com mensagem clara: `"OPENROUTER_API_KEY ausente. Defina em .env antes de rodar."`. Esse erro só atinge o desenvolvedor — kid nunca encontra essa code path porque o resultado já está commitado.

`.env.production` permanece sem a chave para esse feature; o Guia já decide localmente sua own gating via `Academy::Guide::Available?`. Em prod, render do `<img>` lê só do `public/`, então não precisa de key.

**Rationale:** o feature é "geração offline + serve estático", não "geração on-demand". Tratar chave como ferramenta de dev, não dependência de produção.

### 8. Render: `<img>` quando URL presente, italic atual quando ausente

Edição cirúrgica em `_lens_predict.html.erb`:

```erb
<% if payload["illustration_url"].present? %>
  <%= image_tag payload["illustration_url"],
                alt: payload["headline"],
                loading: "lazy",
                class: "w-full aspect-square object-cover rounded-2xl mb-4",
                style: "border: 2px solid var(--hairline); box-shadow: 0 4px 0 var(--hairline);" %>
<% elsif payload["illustration_hint"].present? %>
  <p class="font-display text-[13px] leading-snug italic m-0 mb-4" style="color: var(--text-muted);">
    <%= payload["illustration_hint"] %>
  </p>
<% end %>
```

`alt` vem do `headline` (curto, declarativo) — o `illustration_hint` é prolixo demais pra screen reader. `loading="lazy"` porque o caderno de pílulas pode renderizar várias de uma vez no futuro.

**Rationale:** mantém o fallback atual intacto pra qualquer payload que ainda não tenha sido gerado (incluindo lens primitives diferentes de scientific se um dia ganharem `illustration_hint`).

### 9. Especificação de cliente HTTP

`Academy::Illustrations::Client` espelha `Academy::Llm::Client`:
- POST `https://openrouter.ai/api/v1/chat/completions`.
- Body: `{ model:, modalities: ["image","text"], messages: [{ role: "user", content: composed_prompt }], image_config: { aspect_ratio: "1:1", image_size: "1K" } }`.
- Timeout: 180s (geração de imagem é mais lenta que texto).
- Retry: 2 tentativas em `Net::ReadTimeout` ou HTTP 5xx (geração é cara, mas falha transiente é comum).
- Erro retornado como `Academy::Illustrations::Client::Error`; rake task captura, loga, segue pro próximo slug — uma falha isolada não derruba o batch.

### 10. Versionamento e regeneração futura

Cada payload atualizado ganha:

```jsonb
{
  "illustration_url": "/academy/illustrations/<slug>.webp",
  "illustration_meta": {
    "style": "duolingo@v1",
    "model": "google/gemini-2.5-flash-image",
    "generated_at": "2026-05-21T..."
  }
}
```

Bump de `STYLE_VERSION` força a rake task a regenerar (compara `meta.style` ao constante atual; se diferente, considera "stale" e regera mesmo sem `--force`).

**Rationale:** evita ter que lembrar de rodar `--force` quando o prefix muda.

## Risks / Trade-offs

- **[Drift estético]** Cada chamada ao Gemini Flash Image pode retornar um look levemente diferente, mesmo com o mesmo prefix. → Mitigação: rodar uma vez, inspecionar visualmente o batch, re-rolar individualmente os outliers via `--only=slug --force`. Se >20% precisar re-roll, trocar pra Recraft v4 e regerar tudo.
- **[Texto dentro da imagem]** Modelos de imagem ocasionalmente alucinam letras mesmo com "no text" no prompt. → Mitigação: prompt já enfático ("no text or letters anywhere"); pílulas com falha visual entram no batch de re-roll. Aceitável até descobrirmos uma taxa real.
- **[Mudança no schema OpenRouter]** API de imagem ainda está em evolução (notas do Context7 falam em "preview" para alguns modelos). → `Academy::Illustrations::Client` tem um único parser estrito; se a forma do response mudar, falha clean e fica no log da rake task. Não afeta runtime do kid.
- **[Peso do repo]** 2 MB agora; se Academy crescer e cobrir os 9 lens primitives × N conceitos, isso pode chegar a 50+ MB. → Aceito por ora; ponto de bifurcação para R2/CDN é quando passar de 20 MB. Documentado em `docs/academy-v2.md` como signal a observar.
- **[Resgenerar quebra layout]** Trocar para uma imagem de aspecto diferente quebraria o card. → Pipeline força 1:1 + `image_size: "1K"`; mesmo se o modelo retornar tamanho diferente, o pós-processamento via Vips faz `resize_to_limit(1024, 1024)`. Layout `aspect-square` no `<img>` segura visualmente.
- **[Conteúdo inapropriado]** Modelo de imagem produz algo estranho/ofensivo. → Revisão humana obrigatória no batch antes do commit (não automatizada). Conteúdo curado tem owner; geração é só extensão visual desse contrato.
- **[Erro de PII na imagem]** Improvável (hints não contêm dados pessoais), mas técnicas de jailbreak existem. → Não aplicável: prompts vêm de seeds escritos pelo time, não input de usuário.
- **[Falta de imagem para subset de payloads]** Se um novo payload for adicionado sem rodar a rake, vai cair no fallback italic. → Não é bug, é a feature. Documentado em `docs/academy-v2.md`.
