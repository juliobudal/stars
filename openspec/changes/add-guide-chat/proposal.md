## Why

The pivot to curated-static lens payloads ships polished content but is one-way: kid consumes the 5–7 lições and the conversation ends at the review screen. Curiosity that's been triggered ("por que 23 min e não 5?", "como isso funciona com o meu celular?") has no outlet inside the product. We have an idle, production-grade `Academy::Llm::Client` (OpenRouter/DeepSeek) that the curated pivot demoted from runtime authoring — repurposing it for a tightly-scoped post-mission Q&A turns a sunk-cost dependency into the missing dialogue layer, without putting LLM back on the critical path of content delivery.

## What Changes

- New post-mission entry: "💭 Pergunta ao Guia" button on the kid mission review screen, visible only when `OPENROUTER_API_KEY` is set.
- New kid chat surface at `/kid/academy/subjects/:subject/missions/:mission/guide` — single-mission scoped conversation with free-text input and Turbo-Stream message append (no streaming).
- LLM call uses the existing `Academy::Llm::Client`, with a `Academy::Guide::Persona` system prompt assembled from `Concept#the_essence`, `Mission#central_insight`, and a compact summary of the curated `LensCache` payloads for that mission.
- Hard guardrails enforced via prompt only: scope ("only this concept"), persona (Guia voice), PII refusal ("never accept/ask child's real name, school, address"), safety routing ("if bullying/anxiety/self-harm — tell a trusted adult, today"). No post-LLM filtering in MVP.
- Quota: 5 user messages per session, 1 session per day per (learner × mission). UI shows remaining count; quota exhaustion offers "volta amanhã pra continuar".
- Persistence: every conversation and message saved (`academy_guide_conversations`, `academy_guide_messages`); `flagged: true` is set when the LLM emits a known safety routing marker.
- Parent dashboard: new "Conversas com o Guia" section under `parent/academy` listing all flagged + recent conversations per child, with full transcripts.
- Module isolation: tables prefixed `academy_*`, models under `Academy::`, kid views under `app/views/kid/academy/guide/`, no FK into host (`Profile`) — uses `Academy::Learner` adapter only.
- Inert when key missing: button hidden in kid review, parent dashboard section shows "ative integração LLM" instead.

## Capabilities

### New Capabilities
- `academy-guide-chat`: kid-side post-mission Q&A chat scoped to one mission's concept; covers entry point, conversation lifecycle, quota enforcement, persona/safety prompt assembly, persistence, and parent visibility surface.

### Modified Capabilities
<!-- No existing capability specs in openspec/specs/; nothing to modify. -->

## Impact

- **New code**: 1 migration (`academy_guide_conversations` + `academy_guide_messages`), 2 models, `Academy::Guide::{Persona, Ask, BuildPrompt, QuotaCheck}` services, `Kid::Academy::GuideController`, `Parent::Academy::GuideController`, ViewComponents for chat bubble + message list, 1 Stimulus controller for the form, partial reuse of `academy_loading_controller.js`.
- **Touched code**: `app/views/kid/academy/missions/review.html.erb` (adds entry button), parent academy nav (adds section link).
- **Reused infra**: `Academy::Llm::Client` (no changes), `ApplicationService::Result` pattern, `Ui::*` ViewComponents, DESIGN.md tokens.
- **Dependencies**: no new gems; same OpenRouter env (`OPENROUTER_API_KEY`).
- **Cost envelope**: ~5.5k tokens per session × DeepSeek pricing ≈ ~$0.0015/session; quota caps daily spend at active-kids-count × $0.0015 per mission completed.
- **Risk surface**: prompt-only safety is the explicit MVP trade-off — accept that off-topic or boundary failures will surface and be patched at the prompt layer, not via a post-filter.
