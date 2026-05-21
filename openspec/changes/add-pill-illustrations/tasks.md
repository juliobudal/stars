## 0. Pré-requisitos

- [x] 0.1 Confirmar que `image_processing` + `ruby-vips` (ou `mini_magick`) estão disponíveis no Gemfile/bundle; se não, adicionar e rodar `make setup` para rebuild
- [x] 0.2 Confirmar `OPENROUTER_API_KEY` em `.env` (já presente em `:10`) e validar com curl de smoke contra `/api/v1/models?output_modalities=image`
- [x] 0.3 Criar diretório `public/academy/illustrations/` com `.keep`

## 1. Configuração + cliente

- [x] 1.1 Adicionar em `config/initializers/academy.rb` as chaves `c.image_model`, `c.image_size`, `c.image_aspect_ratio` lidas de `ENV` com defaults `"google/gemini-2.5-flash-image"`, `"1K"`, `"1:1"`
- [x] 1.2 Criar `Academy::Illustrations::Client` espelhando a forma de `Academy::Llm::Client`: POST `/api/v1/chat/completions` com `modalities: ["image","text"]` + `image_config`; timeout 180s; retry ×2 em `Net::ReadTimeout` e HTTP 5xx
- [x] 1.3 Parser do response: extrai data URL base64 de `result.dig("choices", 0, "message", "images", 0, "image_url", "url")`; valida prefix `data:image/`; devolve `(mime, bytes)`
- [x] 1.4 Definir `Academy::Illustrations::Client::Error` (subclasse de `StandardError`)
- [x] 1.5 Spec do client com WebMock cobrindo: success path retorna bytes; HTTP 500 retry; timeout retry; resposta sem `images[0]` levanta Error; data URL malformado levanta Error

## 2. Prompt composer

- [x] 2.1 Criar `Academy::Illustrations::PromptComposer` como module com `STYLE_VERSION = "duolingo@v1"` e `PREFIX` (string congelada conforme design §3)
- [x] 2.2 Método `.compose(hint:)` retorna `"#{PREFIX}\n\nScene: #{hint}"`
- [x] 2.3 Spec covering: prefix presente; hint anexado; versão exposta como constante; mudança no prefix muda `STYLE_VERSION` (assertion textual)

## 3. Serviço de geração

- [x] 3.1 Criar `Academy::Illustrations::Generate` herdando `ApplicationService` — recebe `lens_cache:` (instância de `Academy::LensCache`)
- [x] 3.2 Validar pré-condições: `payload["illustration_hint"]` presente; `Academy.config.openrouter_api_key.present?`; senão `fail_with(:missing_hint)` / `fail_with(:no_api_key)`
- [x] 3.3 Resolver slug do arquivo: `lens_cache.concept.slug` (assumindo método existente) ou derivar de `Academy::Concept#slug`; cair em `parameterize(separator: "-")` do `name` se slug não existir
- [x] 3.4 Compor prompt via `PromptComposer`; chamar `Client#generate` (método nomeado a definir em 1.x); receber bytes PNG
- [x] 3.5 Processar via `ImageProcessing::Vips`: `resize_to_limit(1024, 1024).convert("webp").saver(quality: 85).call(source: StringIO.new(bytes))`; obter bytes WebP
- [x] 3.6 Escrever em `Rails.root.join("public/academy/illustrations/#{slug}.webp")` com `File.binwrite`
- [x] 3.7 Atualizar `lens_cache.payload` adicionando `illustration_url` e `illustration_meta: { style:, model:, generated_at: Time.current.iso8601 }`; chamar `lens_cache.save!`
- [x] 3.8 Retornar `ok({ slug:, url:, bytes_written: size, model: })`
- [x] 3.9 Specs: mock do Client; verifica que arquivo é escrito; payload atualizado com `illustration_url` e `illustration_meta`; falhas de pré-condição não tocam disco nem banco; erro do Client propaga como `fail_with(:client_error, error: ...)` sem deixar arquivo parcial
- [x] 3.10 Spec de idempotência: rodar 2× consecutivas com `--force` falso e arquivo+url já presentes → segundo call retorna `ok({ skipped: true })` sem chamar Client

## 4. Rake task

- [x] 4.1 Criar `lib/tasks/academy_illustrations.rake` definindo `namespace :academy do namespace :illustrations do task :generate, [:opts] => :environment`
- [x] 4.2 Parseia opções: `FORCE=1`, `ONLY=slug1,slug2`, `DRY_RUN=1`, `MODEL=...` (usar ENV pra evitar problemas com flags em rake)
- [x] 4.3 Verifica `OPENROUTER_API_KEY`; aborta com `abort "OPENROUTER_API_KEY ausente. Defina em .env antes de rodar."` quando vazia (a menos que `DRY_RUN=1`)
- [x] 4.4 Query: `Academy::LensCache.where("payload ? 'illustration_hint'")`; aplicar `ONLY` se presente (`where(concept: Academy::Concept.where(slug: list))`)
- [x] 4.5 Loop com progress log (`puts "[N/total] gerando <slug>..."`); cada iteração: skipa se `payload['illustration_url']` presente, arquivo existe E `payload.dig('illustration_meta','style') == PromptComposer::STYLE_VERSION` (a menos que `FORCE`); senão chama `Academy::Illustrations::Generate.call(lens_cache: cache)`
- [x] 4.6 Em erro do service: loga (`Rails.logger.warn`), continua loop, acumula em `failures = []`; ao final, imprime resumo (gerados / pulados / falhos com slug + razão)
- [x] 4.7 `DRY_RUN=1`: imprime quais slugs seriam gerados, total estimado de custo (`count × 0.0004`), não chama Client nem escreve disco
- [x] 4.8 Spec de rake com `Rake.application.invoke_task`: dry-run não toca FS nem banco; sucesso real (com Client stubbado) atualiza N rows e escreve N arquivos
- [x] 4.9 Adicionar entrada em `Makefile`: `academy-illustrations: ; docker compose exec web bundle exec rake academy:illustrations:generate` (alvo opcional, conveniência)

## 5. Render no partial

- [x] 5.1 Editar `app/views/kid/academy/missions/_lens_predict.html.erb` linhas 92-95: adicionar branch `<% if payload["illustration_url"].present? %> image_tag(...) <% elsif payload["illustration_hint"].present? %> [italic atual] <% end %>`
- [x] 5.2 `image_tag`: `alt: payload["headline"]`, `loading: "lazy"`, `class: "w-full aspect-square object-cover rounded-2xl mb-4"`, `style: "border: 2px solid var(--hairline); box-shadow: 0 4px 0 var(--hairline);"`
- [ ] 5.3 Verificar visualmente: sem URL → render italic atual idêntico; com URL → imagem renderizada com radius/shadow corretos; ambos cenários sem console errors

## 6. Geração real + revisão visual

- [ ] 6.1 Rodar `make shell` → `bin/rails academy:illustrations:generate DRY_RUN=1` — confere que pega exatamente os 42 lens_caches
- [ ] 6.2 Rodar geração real: `bin/rails academy:illustrations:generate` — captura tempo total e custo real reportado pela OpenRouter (`/credits` ou dashboard)
- [ ] 6.3 Revisão humana: abrir o caderno de pílulas em dev (`/kid/academy/pills`) e cada show; documentar visualmente em `audit/pill-illustrations/<date>/` (screenshots + lista de outliers)
- [ ] 6.4 Re-roll de outliers via `bin/rails academy:illustrations:generate FORCE=1 ONLY=<slug1>,<slug2>` até <20% precisar de retoque
- [ ] 6.5 Se >20% precisar de retoque, mudar `Academy.config.image_model` para `recraft/recraft-v4` em `.env` local e regerar; comparar visualmente; commitar a decisão final no design.md
- [ ] 6.6 Git add dos 42 `.webp` em `public/academy/illustrations/` + commit isolado ("seed: academy pill illustrations (gemini-2.5-flash-image, duolingo@v1)") — manter separado dos commits de código

## 7. Documentação + polish

- [x] 7.1 Adicionar seção "Ilustrações de pílulas" em `docs/academy-v2.md` explicando: como rodar a rake task, onde os arquivos vivem, como regerar individualmente, qual é o custo
- [x] 7.2 Verificar `DESIGN.md` compliance no novo `<img>`: tokens via CSS vars (`--hairline`), sem hex cru; ajustar se necessário
- [x] 7.3 Confirmar `prefers-reduced-motion`: imagem não anima, mas se o `lens-card` contêiner tem motion contract, garantir que continua honrando
- [x] 7.4 Audit grep: nenhuma referência a `Profile`/`Family` em `Academy::Illustrations::*` (módulo permanece isolado)

## 8. Verificação

- [x] 8.1 `make rspec` — todas as suítes verdes (novas + existentes)
- [x] 8.2 `make lint` — limpo (rubocop-rails-omakase + standard)
- [x] 8.3 `make brakeman` — sem novos avisos
- [ ] 8.4 Smoke manual via Playwright no `/kid/academy/pills/<slug>` para 3 pílulas diferentes (cobre cores diferentes do pokedex_color_key); captura em `audit/pill-illustrations/<date>/playwright/`
- [ ] 8.5 Verificar tamanho final do repo: `du -sh public/academy/illustrations/` deve ser <3 MB
- [x] 8.6 Rodar `openspec validate add-pill-illustrations --strict` e resolver issues
