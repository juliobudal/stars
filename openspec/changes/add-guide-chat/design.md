## Context

The curated-static pivot (`.planning/designs/academy-curated-static-pivot.md`) intentionally moved content authoring offline, leaving the `Academy::Llm::Client` (OpenRouter, ~135 LoC, retry + timeout + reasoning support) idle in production runtime. That client already has its only consumer (`Lens::Generate`) bypassed in 95%+ of requests. This change resurrects it as the engine for a tightly-scoped, post-mission Q&A surface.

Existing module conventions to respect (Academy module contract, see `CLAUDE.md`):
- Zero FK from Academy tables into host (`Profile`, `Family`) — communicate via `Academy::Learner` adapter.
- Tables prefixed `academy_*`, models under `Academy::`, services in `Academy::*::*`.
- Services inherit `ApplicationService`, return `Result = Data.define(:success, :error, :data)`.
- `OPENROUTER_API_KEY` missing → controllers redirect gracefully (precedent: rest of Academy).

Visual layer is governed by `DESIGN.md` (Duolingo tokens: #58CC02, Nunito 700/800, `0 4px 0` shadows, 10–16px radii).

Stakeholders: kid (primary user), parent (transcript reviewer), curator (no role — content is curated separately).

## Goals / Non-Goals

**Goals:**
- Single, isolated kid surface where a kid can ask follow-up questions about the concept they just learned, in the Guia voice.
- Persona + topic scoping enforced entirely via the system prompt (no post-LLM filter, no regex guards).
- Conversation persisted and visible to parents by default; flagged conversations surfaced first in parent dashboard.
- Quota that protects token spend and reinforces "consciousness, not consumption" (1 session/day/mission, 5 messages/session).
- Feature gracefully invisible when LLM key is absent — no broken UI, no error states.
- Zero impact on existing curated-static delivery path. `Lens::Generate` and the lens runtime are untouched.

**Non-Goals:**
- Streaming responses (request/response only; loading overlay reused from `academy_loading_controller.js`).
- Cross-mission memory (each conversation starts blank; no retrieval).
- Stars/XP/gamification (asking is free, not rewarded — keeps motivation intrinsic).
- Moderation API integration (OpenAI Moderation, etc.) — explicitly deferred; prompt-only safety is the MVP wager.
- Editing or regenerating curated lens content from chat (chat reads concept context; cannot mutate it).
- Multi-kid conversations or shared transcripts.
- Cross-conversation continuity ("você me perguntou ontem...") — future work if usage signal warrants it.

## Decisions

### 1. Conversation scope = (learner × mission), not (learner × concept)

Each conversation is bound to a single mission completion. Concept is the topical hook (via `Mission#concept`), but the curated payloads the kid actually saw are the conversational anchor. **Rationale:** the kid asks about "the thing I just did", not "the abstract concept". Two missions can share a concept (regra-dos-2-min appears in two trails) but the lived examples differ. **Alternative considered:** scope per concept — rejected because it would surface "memory" of previous mission across trails, breaking the simplicity wager.

### 2. System prompt = persona + concept essence + central insight + compacted curated payloads

The `Academy::Guide::BuildPrompt` service assembles a fixed-shape system message per (learner × mission). Token budget for system: ~1200 tokens (persona 400 + concept essence 100 + central insight 50 + payload summaries 600 + safety/scope rules 150). **Compacted payloads** = for each lens the learner visited, extract only the kid-visible "central claim" + "fonte" + "número-chave". **Rationale:** the Guia must be able to reference what the kid saw, not the raw JSON. **Alternative:** stuff full payloads — rejected, blows past ~3k tokens for a 6-lens mission.

### 3. Prompt-only safety + scope, with explicit safety routing marker

The system prompt instructs: (a) refuse off-topic with a fixed redirect; (b) refuse PII collection or sharing; (c) if user message mentions bullying/anxiety/self-harm/abuse, emit response prefixed with `[SAFETY_FLAG]` and direct kid to a trusted adult. `Academy::Guide::Ask` detects the prefix and sets `conversation.flagged = true` + appends the trigger reason. **Rationale:** "go simple" — accept that prompt-level enforcement will leak occasionally; iterate on the prompt when it does. **Alternative:** post-LLM regex/whitelist — deferred per user decision.

### 4. Quota = 5 messages/session, 1 session/day/(learner × mission)

Enforced at `Academy::Guide::QuotaCheck` before each LLM call. Day boundary uses kid's TZ (same pattern as `Tasks::ResetService`). When quota exhausted, controller returns a "volta amanhã" view, no error. **Rationale:** caps cost predictably (worst case: families × kids × missions completed/day × $0.0015), forces signal-quality questions over chat-as-toy. **Alternative considered:** family-level daily quota — rejected as harder to reason about.

### 5. Persistence model — two tables, simple JSON-free messages

```
academy_guide_conversations
  id, learner_id (FK academy_learners), mission_id (FK academy_missions)
  started_at, closed_at (nullable; set when 5 msgs hit or quota expires)
  message_count (integer, denormalized for cheap reads)
  flagged (boolean, default false)
  flag_reasons (text[], appended each flagged turn)
  prompt_version (string, frozen at conversation start so prompt iteration doesn't retroactively change interpretation)
  index: (learner_id, mission_id, started_at desc)

academy_guide_messages
  id, conversation_id (FK)
  role (enum: user, guide, system_note)
  content (text)
  tokens_in, tokens_out (integers, nullable for user/system rows)
  flagged (boolean, mirrors LLM trigger for that turn)
  created_at
  index: (conversation_id, created_at)
```

Messages stored as plain text rows, not a JSON blob. **Rationale:** parent dashboard needs to render message-by-message; a SQL row per message keeps that trivial. Roles use Rails 8 enum hash form per `CLAUDE.md` convention.

### 6. Parent visibility = default-on, no opt-out in MVP

Parent dashboard's new "Conversas com o Guia" section lists all conversations (flagged first, then recent), full transcripts visible. No per-kid privacy setting in MVP. **Rationale:** transparency > privacy for 7–14yo bracket; we ship cautious and loosen later if a real signal demands it. **Alternative:** "modo privado" toggle that hides transcript but keeps metadata — deferred to v2 if asked.

### 7. Feature gating reuses Academy's inert-without-key pattern

`Academy::Guide::Available?` service returns `false` when `OPENROUTER_API_KEY` is blank. Kid review template skips the entry button when unavailable. Parent dashboard section renders an "ative integração LLM" stub instead of an empty list. Controllers redirect-with-flash when accessed directly. **Rationale:** matches existing controller behavior in `Academy::Lens`-touching paths; no new envvar-handling concepts.

### 8. UI = single chat page with full-page form post + Turbo Stream append

Kid clicks button → navigates to `/kid/academy/subjects/:s/missions/:m/guide` (full page, not a modal — modals on kid mobile feel like ads). Page renders the conversation so far + form. Form submits to `POST .../guide/messages` returning a Turbo Stream that appends both the user message and the guide response, with the existing `academy_loading_controller.js` overlay during the request. **Rationale:** Turbo Streams already broadcast balance updates in this app (`ApproveService`); the pattern is in-house. **Alternative:** server-sent events / streaming completions — deferred (DeepSeek supports it, but our `Client#chat` doesn't, and adding streaming triples the controller/JS surface).

### 9. `prompt_version` field anchors the persona to a frozen string

Stored on conversation creation as e.g. `"guide-persona@v1"`. Future prompt iterations bump the version; old transcripts remain interpretable in context of the persona they were generated under. **Rationale:** parent reading a 2-month-old transcript should see it through the persona that produced it. Cheap to add now, costly to retrofit.

## Risks / Trade-offs

- **[Prompt-only safety leaks]** A motivated 12yo will eventually elicit off-topic or off-persona output. → Accepted MVP risk. Mitigation: log every flagged turn + parent visibility; iterate on prompt when patterns emerge. Add post-LLM filter in v2 if leak frequency > tolerance.
- **[OpenRouter outage]** Upstream down → kid sees error instead of Guia. → `Academy::Llm::Client` already has retry + 180s timeout; controller catches `Client::Error` and renders a "Guia está descansando" view, preserving conversation state so kid can retry on next message.
- **[Latency UX]** DeepSeek typical 2–8s, can spike to 30s+ on reasoning models. → Loading overlay (`academy_loading_controller.js` already covers 75s failsafe); message form locked during pending response so kid can't double-submit.
- **[Token blowout]** Curated payload summaries grow with mission size. → `BuildPrompt` enforces a `MAX_SYSTEM_TOKENS = 1500` budget; summaries truncated newest-lens-first if over.
- **[Parent dashboard noise]** Many low-signal conversations clutter the list. → Default sort: flagged + last 7 days only on dashboard landing; full archive behind "ver tudo".
- **[Flag false positives]** LLM emits `[SAFETY_FLAG]` for benign mentions of "ansiedade de prova". → Parent sees the trigger reason inline, can dismiss. Better one false positive than one missed signal.
- **[Conversation re-entry attempt mid-day]** Kid completes session, comes back same day. → Show conversation in read-only mode with "volta amanhã" footer, not error.
- **[Module boundary erosion]** Tempting to read `Profile` directly from `GuideController`. → Enforce: all profile access goes through `Academy::Learner` adapter (already exists in module).
