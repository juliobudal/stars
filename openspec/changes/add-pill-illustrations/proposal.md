## Why

42 pílulas (lens primitive `scientific`) carregam um campo `illustration_hint` — uma descrição textual rica de uma ilustração ("Ilustração de um olho humano com uma lente ajustável na íris…"). Hoje esse texto é renderizado em `_lens_predict.html.erb:92-95` como um parágrafo cinza itálico, o que entrega a *promessa* da imagem mas não a imagem em si. O conteúdo das pílulas é curado e estático (seedado, sem LLM em runtime), então gerar a imagem uma única vez a partir do hint é tanto barato quanto coerente com a filosofia do módulo: o único LLM em runtime continua sendo "O Guia". O resultado é uma pílula visualmente completa, no estilo Duolingo, sem custo recorrente nem dependência de rede no caminho do kid.

## What Changes

- Novo rake task `academy:illustrations:generate` (one-shot, idempotente) que percorre `academy_lens_cache` onde `payload->>'illustration_hint'` está presente e `payload->>'illustration_url'` ainda não — gera a imagem via OpenRouter, salva em `public/academy/illustrations/<slug>.webp` e grava a URL relativa de volta no payload.
- Novo serviço `Academy::Illustrations::Generate` (ApplicationService) — recebe `lens_cache:`, compõe prompt com o prefixo de estilo Duolingo, chama o cliente de imagem, baixa, otimiza e persiste.
- Novo cliente `Academy::Illustrations::Client` — espelha a forma de `Academy::Llm::Client` (Net::HTTP, retry, timeout) batendo em `POST /api/v1/chat/completions` com `modalities: ["image","text"]`, parsing do data URL base64 retornado em `message.images[].image_url.url`.
- Novo módulo `Academy::Illustrations::PromptComposer` — concatena um prefixo fixo de estilo (paleta Duolingo, flat vector, sem texto, 1:1) com o `illustration_hint` curado.
- Modificação cirúrgica em `app/views/kid/academy/missions/_lens_predict.html.erb`: quando `payload["illustration_url"]` existe, renderiza `<img>` com tokens de DESIGN.md (radius 16, shadow `0 4px 0 var(--hairline)`); senão preserva o fallback italic atual.
- Configuração em `config/initializers/academy.rb` para `image_model` (default `google/gemini-2.5-flash-image`), `image_size` (default `1K`), `aspect_ratio` (default `1:1`), todos sobrescrevíveis por env.
- Arquivos gerados commitados ao repo em `public/academy/illustrations/` (~50 KB/img × 42 ≈ 2 MB) — pílulas funcionam offline e ficam versionadas.
- Documentação: nota em `docs/academy-v2.md` sobre o pipeline de geração + comando para regerar.

## Capabilities

### New Capabilities

- `academy-pill-illustrations`: pipeline de pré-geração de ilustrações para pílulas curadas; cobre composição de prompt (estilo Duolingo), chamada ao OpenRouter, armazenamento em disco, escrita no payload, idempotência, fallback gracioso para texto quando a URL não existe.

### Modified Capabilities

<!-- Nenhum capability spec existente em `openspec/specs/`; nada a modificar. -->

## Impact

- **Código novo**: rake task (`lib/tasks/academy_illustrations.rake`), 1 cliente HTTP (`Academy::Illustrations::Client`), 2 services (`Generate`, `PromptComposer`), 1 helper para `<img>` (ou inline no partial), specs para cada um. Sem nova migration (campo vai dentro do `jsonb payload` existente em `academy_lens_cache`).
- **Código tocado**: `_lens_predict.html.erb` (≈ 8 linhas), `config/initializers/academy.rb` (3 chaves novas), `docs/academy-v2.md` (parágrafo de operação).
- **Infra reaproveitada**: `OPENROUTER_API_KEY` já configurado (.env local), padrão `ApplicationService::Result`, tokens de `DESIGN.md`, jsonb existente.
- **Dependências**: nenhuma gem nova. `image_processing` já está no Rails 8 default; se não estiver, usa `mini_magick` ou recodifica via `vips` (decisão final em design §4).
- **Envelope de custo**: 42 imagens × `gemini-2.5-flash-image` (~$0.0004) ≈ **$0.02 one-shot**. Mesmo regenerando tudo 3× durante calibração de prompt: ~$0.06. Trivial.
- **Risco**: degradação se o prompt prefix não fixar bem o estilo entre imagens (cada uma vira um look diferente) — mitigado com seed fixo + prefix forte + opção de re-roll por slug via `--force --only=<slug>`.
- **Produção**: `.env.production` ainda não tem `OPENROUTER_API_KEY`; como a geração é one-shot em dev e o resultado é commitado, **prod não precisa da key pra renderizar as imagens**. A key continua opcional em prod (mesmo padrão do Guia chatbot).
