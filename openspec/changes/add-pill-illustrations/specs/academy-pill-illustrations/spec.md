## ADDED Requirements

### Requirement: Curated lens payloads with illustration hints SHALL receive pre-generated images

For every `academy_lens_cache` row whose `payload->>'illustration_hint'` is present, the system SHALL provide a pipeline that produces a single illustration file persisted at `public/academy/illustrations/<concept_slug>.webp` and writes the relative URL back into `payload->>'illustration_url'`. Generation SHALL be invoked via the `academy:illustrations:generate` rake task; it SHALL NOT occur during the kid's runtime request.

#### Scenario: First-time generation populates URL and writes file
- **WHEN** the rake task `academy:illustrations:generate` runs against a `LensCache` row whose `payload` has `illustration_hint` set and `illustration_url` absent
- **THEN** the system calls the OpenRouter image API, optimizes the resulting bytes to WebP at most 1024×1024 quality 85, writes `public/academy/illustrations/<concept_slug>.webp`, and updates `payload` to include `illustration_url: "/academy/illustrations/<concept_slug>.webp"` plus `illustration_meta` with `style`, `model`, and `generated_at`

#### Scenario: Idempotent re-run with no changes is a no-op
- **WHEN** the rake task is invoked a second time without `FORCE=1` and the target row already has `illustration_url` populated, the file exists on disk, and `illustration_meta.style` matches the current `PromptComposer::STYLE_VERSION`
- **THEN** the row is reported as skipped, the LLM is not called, and the file on disk is not rewritten

#### Scenario: Style version bump triggers regeneration
- **WHEN** `PromptComposer::STYLE_VERSION` differs from the value stored in `illustration_meta.style` for an existing row
- **THEN** the rake task regenerates that row's illustration even without `FORCE=1`

### Requirement: Image rendering SHALL prefer the pre-generated illustration over the textual hint

The `scientific` lens partial SHALL render an `<img>` element when `payload["illustration_url"]` is present, and SHALL render the existing italic textual hint as a fallback when only `payload["illustration_hint"]` is present. The two branches SHALL be mutually exclusive.

#### Scenario: URL present renders image
- **WHEN** a kid views a pill whose payload contains both `illustration_url` and `illustration_hint`
- **THEN** the partial renders an `<img>` with `src` from `illustration_url`, `alt` derived from `payload["headline"]`, `loading="lazy"`, square aspect, rounded corners and the DESIGN.md `0 4px 0 var(--hairline)` shadow; no italic textual fallback is rendered

#### Scenario: URL absent falls back to italic hint
- **WHEN** a kid views a pill whose payload contains `illustration_hint` but no `illustration_url`
- **THEN** the partial renders the italic muted paragraph exactly as before this change

#### Scenario: Neither URL nor hint present
- **WHEN** a payload has neither field
- **THEN** the partial renders no illustration block at all (no empty `<img>`, no empty paragraph)

### Requirement: Image generation prompts SHALL be wrapped in a fixed Duolingo style prefix

`Academy::Illustrations::PromptComposer.compose(hint:)` SHALL return a string that begins with the frozen `PREFIX` constant describing the Duolingo visual contract (flat vector, vibrant `#58CC02`, soft pastel palette, no text, square 1:1, child-friendly mood) and then appends the curated `illustration_hint` under a `Scene:` marker. The composer SHALL expose a `STYLE_VERSION` constant identifying the prefix revision.

#### Scenario: Composed prompt is prefix + scene
- **WHEN** `PromptComposer.compose(hint: "Ilustração de um olho humano...")` is called
- **THEN** the returned string starts with the verbatim `PREFIX` string and contains `"\n\nScene: Ilustração de um olho humano..."` afterward

#### Scenario: Style version is exposed and stable
- **WHEN** the codebase is at the current revision
- **THEN** `PromptComposer::STYLE_VERSION` returns `"duolingo@v1"` and the constant is frozen

### Requirement: The image generation client SHALL talk to OpenRouter via chat completions with image modality

`Academy::Illustrations::Client` SHALL POST to `https://openrouter.ai/api/v1/chat/completions` with `model` from `Academy.config.image_model`, `modalities: ["image", "text"]`, a single user message containing the composed prompt, and `image_config: { aspect_ratio: Academy.config.image_aspect_ratio, image_size: Academy.config.image_size }`. The client SHALL parse `choices[0].message.images[0].image_url.url` as a base64 data URL, decode it, and return `(mime_type, bytes)`. The client SHALL apply a 180s read timeout and retry up to twice on `Net::ReadTimeout` or HTTP 5xx.

#### Scenario: Successful response yields image bytes
- **WHEN** the OpenRouter API returns HTTP 200 with `choices[0].message.images[0].image_url.url` set to `data:image/png;base64,<bytes>`
- **THEN** the client returns `("image/png", decoded_bytes)`

#### Scenario: Missing images array raises Error
- **WHEN** the response payload omits the `images` array (e.g., model returned only text)
- **THEN** the client raises `Academy::Illustrations::Client::Error` with a message identifying the missing field

#### Scenario: Transient 5xx triggers retry, then success
- **WHEN** the API returns HTTP 503 once followed by HTTP 200 with a valid response
- **THEN** the client retries automatically and returns the decoded bytes from the second attempt

#### Scenario: Persistent failure raises Error
- **WHEN** all retry attempts fail with timeouts or 5xx
- **THEN** the client raises `Academy::Illustrations::Client::Error` and the rake task continues to the next row without aborting the batch

### Requirement: The rake task SHALL refuse to run without an API key unless dry-running

`academy:illustrations:generate` SHALL abort with an explicit error message when `Academy.config.openrouter_api_key` is blank, except when `DRY_RUN=1` is set. The render path (the partial) SHALL NOT depend on the API key — pre-generated files served from `public/` SHALL work without it.

#### Scenario: Missing key in normal run
- **WHEN** the rake task is invoked without `DRY_RUN=1` and `OPENROUTER_API_KEY` is unset
- **THEN** the task aborts with a message such as `"OPENROUTER_API_KEY ausente. Defina em .env antes de rodar."` and exits non-zero

#### Scenario: Missing key with dry-run
- **WHEN** the rake task is invoked with `DRY_RUN=1` and `OPENROUTER_API_KEY` is unset
- **THEN** the task prints the list of rows it would have generated plus an estimated cost, and exits zero

#### Scenario: Production rendering without API key
- **WHEN** the application runs in production without `OPENROUTER_API_KEY` set and the WebP files exist under `public/academy/illustrations/`
- **THEN** kids see the rendered images normally (no degraded path is triggered)

### Requirement: The rake task SHALL support targeted regeneration and dry runs

The rake task SHALL accept the environment options `FORCE=1` (regenerate even when up-to-date), `ONLY=<slug1>,<slug2>` (restrict to listed concept slugs), `DRY_RUN=1` (no LLM calls or disk writes), and `MODEL=<id>` (override `Academy.config.image_model` for the run).

#### Scenario: ONLY restricts the working set
- **WHEN** the task is invoked with `ONLY=agua-quebra-pedra,memoria-falsa`
- **THEN** only those two concept slugs are considered; other rows with `illustration_hint` are ignored

#### Scenario: FORCE regenerates an up-to-date row
- **WHEN** the task is invoked with `FORCE=1` against a row whose `illustration_url` is set and `illustration_meta.style` matches `PromptComposer::STYLE_VERSION`
- **THEN** the row is regenerated (new API call, new file, refreshed `illustration_meta.generated_at`)

#### Scenario: DRY_RUN reports without acting
- **WHEN** the task is invoked with `DRY_RUN=1`
- **THEN** the task prints a one-line summary per candidate row plus an estimated total cost (`count × $0.0004`) and writes no files and updates no payloads

### Requirement: Generated files SHALL be optimized and stored deterministically

Generated images SHALL be stored as WebP at quality 85, resized so the longest side is at most 1024 pixels, and named `<concept_slug>.webp` under `public/academy/illustrations/`. Each generated file SHALL be at most ~80 KB in practice; the total directory size SHALL stay under 3 MB for the initial batch of 42 illustrations.

#### Scenario: WebP encoding applied
- **WHEN** the generation pipeline finishes a row
- **THEN** the file at `public/academy/illustrations/<concept_slug>.webp` is a valid WebP at quality 85, with both dimensions ≤ 1024

#### Scenario: Repository footprint stays bounded
- **WHEN** the first full batch (~42 rows) completes
- **THEN** `du -sh public/academy/illustrations/` reports < 3 MB
