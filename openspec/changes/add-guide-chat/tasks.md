## 1. Data layer

- [x] 1.1 Create migration `add_academy_guide_conversations_and_messages` with both tables, indexes, and FKs to `academy_learners` / `academy_missions` per design §5
- [x] 1.2 Run migration and confirm schema in `db/schema.rb`
- [x] 1.3 Add `Academy::GuideConversation` model with `belongs_to :learner` / `belongs_to :mission`, `has_many :messages`, `flag_reasons` as `text[]`, and `prompt_version` defaulting to `"guide-persona@v1"`
- [x] 1.4 Add `Academy::GuideMessage` model with `belongs_to :conversation`, Rails 8 hash enum `role: { user: 0, guide: 1, system_note: 2 }`, and `counter_cache: :message_count` callback (or after_create_commit increment) on the conversation
- [x] 1.5 Add minimal model specs covering associations, role enum, and `flagged` defaults

## 2. Persona + prompt assembly

- [ ] 2.1 Add `Academy::Guide::Persona` constant module containing the frozen v1 persona/safety/scope prompt string (mirrors `Academy::Llm::JudgePersona` pattern). Locale: pt-BR. Must reinforce: persona voice, refuse off-topic with concept-redirect, refuse PII, emit `[SAFETY_FLAG][reason]` for bullying/anxiety/self-harm/abuse
- [ ] 2.2 Add `Academy::Guide::BuildPrompt` service inheriting `ApplicationService`; takes `learner:, mission:`; assembles `{system: ..., messages_so_far: []}`; pulls `mission.concept.the_essence`, `mission.central_insight`, and visited lens summaries from `LensCache` (compact: central claim + source + key number per lens)
- [ ] 2.3 Enforce `MAX_SYSTEM_TOKENS = 1500` in `BuildPrompt` — truncate lens summaries newest-first when over (rough token estimate: chars / 4)
- [ ] 2.4 Spec `BuildPrompt`: returns expected system prompt shape; truncates correctly when over budget; preserves persona/essence/central insight under truncation

## 3. Quota + availability

- [ ] 3.1 Add `Academy::Guide::Available?` predicate service returning `false` when `Academy.config.openrouter_api_key` is blank
- [ ] 3.2 Add `Academy::Guide::QuotaCheck` service returning `Result` indicating (can_send, remaining_messages, session_state: :open|:closed_today|:new_session_available). Day boundary uses learner TZ (same helper as `Tasks::ResetService`)
- [ ] 3.3 Add `Academy::Guide::FindOrStartConversation` service: returns the open conversation for (learner × mission × today) if any, else creates one with `prompt_version: "guide-persona@v1"`
- [ ] 3.4 Spec `QuotaCheck` covering: fresh state → 5 messages allowed; mid-session → remaining decrements; 5th message hit → marks `closed_at`; same-day re-entry post-close → `closed_today`; next-day → new session allowed; TZ rollover honors learner TZ
- [ ] 3.5 Spec `FindOrStartConversation` covering create-vs-reuse semantics

## 4. Ask service (LLM round trip)

- [ ] 4.1 Add `Academy::Guide::Ask` service taking `learner:, mission:, user_content:`. Steps: (a) gate `Available?`, (b) `QuotaCheck`, (c) `FindOrStartConversation`, (d) persist user message, (e) `BuildPrompt` + load prior `messages_so_far`, (f) `Academy::Llm::Client#chat`, (g) detect `[SAFETY_FLAG][reason]` prefix → set flag + strip from kid-facing content, (h) persist guide message with tokens, (i) close conversation if message_count hit cap
- [ ] 4.2 Spec `Ask` covering: success path returns kid-facing content; safety prefix triggers flag + reason append + strip; quota refusal short-circuits before LLM; `Client::Error` propagates without consuming a quota slot or persisting partial messages
- [ ] 4.3 Stub `Academy::Llm::Client#chat` in specs to avoid real network calls

## 5. Kid controller + views

- [ ] 5.1 Add route `resources :missions, only: [] do resource :guide, only: :show; resources :guide_messages, only: :create, controller: "guide_messages" end` (or equivalent) nested under existing kid academy subjects/missions
- [ ] 5.2 Add `Kid::Academy::GuidesController#show`: redirects to mission review with flash if `!Guide::Available?` or mission not completed by learner; otherwise `FindOrStartConversation` and renders chat page
- [ ] 5.3 Add `Kid::Academy::GuideMessagesController#create`: calls `Guide::Ask`; on success returns Turbo Stream appending user message bubble + guide message bubble + updating quota counter + (if closed) replacing form with "volta amanhã" footer; on `Client::Error` returns Turbo Stream appending a "Guia está descansando" inline note without consuming quota
- [ ] 5.4 Build `Kid::Academy::Guide::ChatViewComponent` rendering conversation header (concept title), message list, quota counter, form (or read-only footer when closed)
- [ ] 5.5 Build `Kid::Academy::Guide::MessageBubbleComponent` rendering user/guide message with DESIGN.md tokens (Nunito, kid voice card style, distinct kid vs guide visual)
- [ ] 5.6 Add Stimulus controller `kid--academy--guide-form` that disables submit + triggers `academy_loading_controller` overlay during request and clears textarea on Turbo Stream response
- [ ] 5.7 Add the "💭 Pergunta ao Guia" entry button to `app/views/kid/academy/missions/review.html.erb`, conditional on `Academy::Guide::Available?.call.success?`
- [ ] 5.8 System spec: completed-mission learner with key set → button visible → click → chat renders → submit message (LLM stubbed) → user + guide bubbles appended → counter decrements
- [ ] 5.9 System spec: key absent → no button in DOM; direct navigation redirects with flash
- [ ] 5.10 System spec: 5th message hits cap → form replaced with footer; re-enter same day → read-only state

## 6. Parent dashboard surface

- [ ] 6.1 Add `Parent::Academy::GuidesController#index` listing family conversations: flagged first (ordered `started_at desc`), then non-flagged from last 7 days. "Ver tudo" param expands archive
- [ ] 6.2 Build `Parent::Academy::Guide::ConversationCardComponent` rendering child label + avatar + started_at + flagged badge + expandable transcript
- [ ] 6.3 Build `Parent::Academy::Guide::TranscriptComponent` rendering each message with role styling and (for guide) the `[SAFETY_FLAG][reason]` tag when applicable
- [ ] 6.4 Add `Parent::Academy::Guide::AvailabilityStub` rendering "ative integração LLM" copy
- [ ] 6.5 Wire route `namespace :parent do namespace :academy do resources :guides, only: :index end end` and add nav link in existing parent academy nav
- [ ] 6.6 System spec: parent with two kids and mixed flagged/recent conversations sees correct ordering, expansion renders transcript, archive toggle works
- [ ] 6.7 System spec: key absent → parent section renders stub copy instead of empty list

## 7. Integration polish

- [ ] 7.1 Confirm `academy_loading_controller.js` overlay engages cleanly on chat submission (no double overlays, no stuck state) — manual browser smoke
- [ ] 7.2 Validate DESIGN.md compliance: tokens used from `theme.css`, no raw hex, 3D shadow on chat buttons honors `prefers-reduced-motion`, Nunito 700/800
- [ ] 7.3 Confirm zero new references to host models in any `app/{models,services,controllers,views}/academy/guide*` file (grep audit)
- [ ] 7.4 Verify Turbo Stream broadcast doesn't leak across learners — channel scoped per conversation

## 8. Verification

- [ ] 8.1 Run `make rspec` — all suites green
- [ ] 8.2 Run `make lint` — clean
- [ ] 8.3 Run `make brakeman` — no new warnings
- [ ] 8.4 Manual Playwright smoke: kid completes one Atenção mission, opens Guide, sends 5 messages, hits cap, parent views transcripts (flagged + non-flagged). Capture in `audit/guide-chat-mvp/` per existing audit pattern
- [ ] 8.5 Run `openspec validate add-guide-chat --strict` and resolve any issues
