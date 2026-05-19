## ADDED Requirements

### Requirement: Mission review screen offers entry to Guide chat

The kid mission review screen SHALL render a "Pergunta ao Guia" entry button when (a) the LLM integration is available (`OPENROUTER_API_KEY` is set) AND (b) the mission has been completed by the current learner. When the integration is unavailable, the button SHALL be absent from the DOM (not disabled, not hidden via CSS).

#### Scenario: LLM key present and mission completed
- **WHEN** a learner who has completed a mission opens that mission's review screen
- **THEN** the review screen renders a "💭 Pergunta ao Guia" button linking to `/kid/academy/subjects/:subject_slug/missions/:mission_slug/guide`

#### Scenario: LLM key absent
- **WHEN** the application boots without `OPENROUTER_API_KEY` set
- **THEN** the mission review screen renders no "Pergunta ao Guia" button in the DOM

#### Scenario: Mission not yet completed
- **WHEN** a learner views a mission they have not completed
- **THEN** no Guide entry button is rendered (the review screen itself is not available pre-completion)

### Requirement: Guide chat scope is bound to a single (learner × mission) conversation

A Guide conversation SHALL be uniquely scoped to one learner and one mission. The system SHALL persist each conversation as a `academy_guide_conversations` row with the learner reference, mission reference, start timestamp, message counter, flag state, flag reasons array, and the frozen `prompt_version` used at conversation start.

#### Scenario: First chat entry creates a new conversation
- **WHEN** a learner enters the Guide chat for a mission for the first time today
- **THEN** the system creates a `academy_guide_conversations` record with `learner_id`, `mission_id`, `started_at = now`, `message_count = 0`, `flagged = false`, `flag_reasons = []`, and `prompt_version = "guide-persona@v1"`

#### Scenario: Subsequent chat entry within the same active session
- **WHEN** a learner re-enters the Guide chat for a mission with an open (non-closed) conversation from the same day
- **THEN** the system surfaces the existing conversation rather than creating a new one

### Requirement: Free-text input with persona+context-grounded responses

Kids SHALL be able to send free-text messages. The system SHALL call `Academy::Llm::Client#chat` with a system prompt assembled by `Academy::Guide::BuildPrompt` containing the Guide persona, the mission's concept essence, the mission's central insight, and compacted summaries of the curated lens payloads the learner visited. The assembled system prompt SHALL not exceed 1500 tokens; when over budget, summaries SHALL be truncated newest-lens-first.

#### Scenario: Sending the first message
- **WHEN** a learner submits a message in an empty Guide conversation
- **THEN** the system builds a system prompt containing persona + concept essence + central insight + curated payload summaries for that mission, sends `{system, user}` to the LLM, persists the user message and the LLM response, and renders both via Turbo Stream

#### Scenario: System prompt over token budget
- **WHEN** the mission has enough visited lenses to push the system prompt past 1500 tokens
- **THEN** `Academy::Guide::BuildPrompt` truncates lens summaries newest-first until the total fits, while persona, essence, and central insight remain intact

### Requirement: Per-session and per-day quota enforcement

The system SHALL enforce a quota of 5 user messages per conversation session and 1 session per learner per mission per local-TZ day (kid's TZ). When either limit is reached, the controller SHALL not call the LLM and SHALL render the conversation in read-only mode with a "volta amanhã pra continuar" footer.

#### Scenario: Quota counter visible
- **WHEN** a learner enters the Guide chat
- **THEN** the page displays "X perguntas restantes nesta sessão", where X = 5 minus the count of user messages in the open conversation

#### Scenario: Fifth message hits the cap
- **WHEN** a learner submits their fifth user message in a session
- **THEN** the LLM is called and persists normally, then the conversation is marked `closed_at = now` and subsequent input is hidden in favor of the "volta amanhã" footer

#### Scenario: Returning the same day after a closed session
- **WHEN** a learner whose conversation for a mission was closed earlier today re-enters the Guide chat for that mission
- **THEN** the existing conversation is shown read-only, no new conversation is created, and no LLM call is made

#### Scenario: Returning the next day
- **WHEN** a learner re-enters the Guide chat for the same mission on the next local-TZ day
- **THEN** the system creates a new `academy_guide_conversations` record and quota resets to 5 messages

### Requirement: Persona and topic scope enforced via system prompt only

The Guide persona prompt SHALL instruct the LLM to (a) maintain the Guia voice (autoritativa + misteriosa + fascinada), (b) refuse off-topic questions with a fixed redirect referencing the current concept, (c) never accept or solicit personally-identifiable information (real name, school, address, phone, exact age, location), (d) on detection of safety-relevant topics (bullying, anxiety, self-harm, abuse) emit a response prefixed with the literal token `[SAFETY_FLAG]` followed by a trigger reason in brackets and then the kid-facing message directing them to a trusted adult. No post-LLM filter SHALL be applied in the MVP.

#### Scenario: Off-topic question
- **WHEN** a kid asks something outside the concept of the mission (e.g., "qual a capital do Brasil?")
- **THEN** the Guide response redirects to the current concept ("isso é pra outra trilha — sobre [concept], o que mais te intrigou?")

#### Scenario: Safety-relevant question
- **WHEN** a kid's message mentions a safety topic such as bullying or anxiety
- **THEN** the LLM response begins with `[SAFETY_FLAG][reason]` (e.g., `[SAFETY_FLAG][bullying]`) followed by a message directing the kid to a trusted adult that day

#### Scenario: PII request from kid
- **WHEN** a kid types their real name, school, address, or asks the Guide to "remember" such data
- **THEN** the Guide response refuses to use or store the information and continues the conversation without it

### Requirement: Safety-flagged turns are persisted on conversation and message

When the LLM response begins with `[SAFETY_FLAG][reason]`, the system SHALL set `flagged = true` on the message row, append the bracketed reason to `conversation.flag_reasons`, and set `conversation.flagged = true`. The `[SAFETY_FLAG][reason]` prefix SHALL be stripped from the content shown to the kid but preserved on the stored row for parent visibility.

#### Scenario: Flag is persisted and surfaced
- **WHEN** the LLM returns `[SAFETY_FLAG][bullying] Isso é mais forte que eu...`
- **THEN** the message row is saved with `flagged = true`, `conversation.flag_reasons` includes `"bullying"`, `conversation.flagged = true`, and the kid sees only `"Isso é mais forte que eu..."`

### Requirement: Persist every message and token count

Every user submission and every LLM response SHALL be persisted as an `academy_guide_messages` row with `role`, `content`, `created_at`, and (for `guide` rows) `tokens_in` and `tokens_out` populated from the `Academy::Llm::Client` return value. `conversation.message_count` SHALL be incremented on every persisted message.

#### Scenario: Roundtrip persistence
- **WHEN** a learner sends one message and receives one Guide response
- **THEN** two `academy_guide_messages` rows exist (`role: user`, `role: guide`), `conversation.message_count = 2`, and the guide row has `tokens_in` and `tokens_out` set from the LLM client return value

### Requirement: Parent dashboard surfaces Guide conversations

The parent Academy dashboard SHALL include a "Conversas com o Guia" section listing the current family's Guide conversations across all children. The default view SHALL show flagged conversations first, then non-flagged conversations from the last 7 days, both with full transcripts visible inline. An "ver tudo" affordance SHALL expose the archive of older conversations.

#### Scenario: Flagged conversations surfaced first
- **WHEN** a parent opens the Academy dashboard
- **THEN** the "Conversas com o Guia" section lists all `flagged: true` conversations first, ordered by `started_at` desc, followed by non-flagged conversations from the past 7 days

#### Scenario: Full transcript visible
- **WHEN** a parent expands any listed conversation
- **THEN** the transcript renders all `academy_guide_messages` rows in order, with `[SAFETY_FLAG][reason]` markers shown for flagged turns and the trigger reason rendered as a tag

#### Scenario: Cross-child visibility within family
- **WHEN** a family has two children with Guide conversations
- **THEN** the parent dashboard lists conversations from both children, each labeled with the child's name and avatar

### Requirement: Parent dashboard reflects LLM availability state

The parent Academy dashboard "Conversas com o Guia" section SHALL render a stub state ("ative integração LLM pra liberar conversas com o Guia") when `OPENROUTER_API_KEY` is not set, instead of a section listing zero conversations.

#### Scenario: LLM key absent
- **WHEN** a parent opens the Academy dashboard without `OPENROUTER_API_KEY` set
- **THEN** the "Conversas com o Guia" section renders an "ative integração LLM" stub, not an empty list

### Requirement: Module isolation — no host model coupling

All Guide chat code SHALL live under the `Academy::` namespace (`app/models/academy/guide_*`, `app/services/academy/guide/*`, `app/controllers/{kid,parent}/academy/guide*_controller.rb`, `app/views/{kid,parent}/academy/guide/*`). The database tables SHALL be prefixed `academy_guide_`. The Guide code SHALL NOT directly reference `Profile`, `Family`, or any other host model; learner identity SHALL be accessed exclusively through the existing `Academy::Learner` adapter.

#### Scenario: Code organization
- **WHEN** any Guide chat code is added
- **THEN** it resides under `Academy::` namespace, its tables are prefixed `academy_guide_`, and no file under `app/{models,services,controllers,views}/academy/guide*` contains a direct reference to `Profile` or `Family`

### Requirement: Feature is fully inert without OpenRouter key

When `OPENROUTER_API_KEY` is not set, the system SHALL: (a) hide the kid entry button (per "Mission review screen offers entry to Guide chat"), (b) render parent stub state (per "Parent dashboard reflects LLM availability state"), and (c) redirect direct kid navigation to `/kid/academy/subjects/:s/missions/:m/guide` back to the mission review with a flash message ("Guia indisponível por enquanto").

#### Scenario: Direct kid navigation without key
- **WHEN** a kid navigates directly to `/kid/academy/subjects/mente-forte/missions/notificacoes-custam-23-min/guide` without the key set
- **THEN** the request is redirected to the mission review screen with a flash message indicating the Guide is unavailable

### Requirement: Loading state during LLM call

The kid chat form submission SHALL trigger the existing `academy_loading_controller.js` overlay during the LLM round trip and SHALL lock the input form to prevent double-submission. On `Academy::Llm::Client::Error`, the controller SHALL render a "Guia está descansando, tenta de novo" view that preserves the conversation state.

#### Scenario: Successful response
- **WHEN** a kid submits a message
- **THEN** the loading overlay appears, the form is locked, and on response both user message and Guide response are appended via Turbo Stream and the overlay dismisses

#### Scenario: LLM error
- **WHEN** the LLM call raises `Academy::Llm::Client::Error`
- **THEN** the controller renders a "Guia está descansando" message in place of the response, preserves the conversation, and re-enables the form for retry without consuming a message quota slot
