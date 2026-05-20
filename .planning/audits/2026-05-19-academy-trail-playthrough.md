# Academy trail playthrough — QA report

**Date:** 2026-05-19
**Branch:** `feat/academy-lens-v3-completion`
**Reviewer:** Playwright session (kid persona "Theo", profile auto-selected).
**Mission exercised:** *Por que comprar por impulso é uma armadilha?*
(`subjects/dinheiro-vida/missions/impulso-perigoso`, concept `recompensa-imediata`, id 3).

## TL;DR

Three blocker-class issues, two UX issues. The mission **cannot be finished**
today: it loops the same 3 curated lenses for 6 stages, then 503s at stage 7
because `ChooseNext` forces a closure lens that does not exist as curated
content for any concept.

## Findings

### 🔴 1 — Lens loop (stages 4-6 repeat 1-3 byte-for-byte)

Concept `recompensa-imediata` ships **3 curated payloads**: `narrative`,
`scientific`, `statistical`. `Academy::Lens::ChooseNext` (curated-static
chooser, `app/services/academy/lens/choose_next.rb`) requires
`COVERAGE_FLOOR = 4` distinct types **and** a `CLOSURE_LENSES`
(`analogy_bridge` / `ethical`) visit before it can close. Closure lenses have
zero curated rows anywhere in the catalog. Result: after stage 3 the chooser
falls through the `pick_next` ladder and picks `available - [last]`, which
yields the same three types in rotation.

For the learner this means stages 4/5/6 render the **identical narrative,
illustration, quick-check stem, and option list** as stages 1/2/3.
Pedagogically it reads as a bug.

Evidence: stages 1+4 = same Léo narrative + same "qual o pulo na cabeça do
Léo na hora que ele viu o boné na vitrine?" MCQ; stages 2+5 = same
bombom/dopamina explanation; stages 3+6 = same 96-toques wager.

### 🔴 2 — `HARD_CAP = 7` → 503

At stage 7, `ChooseNext` enforces `HARD_CAP`, sees no closure lens in the
visited set, and returns `force_close(:analogy_bridge)`.
`Missions::AdvanceLens#try_generate_with_fallbacks!` walks
`analogy_bridge → ethical → engineering → historical → first_person`, each
returns `no_curated_payload`, the service fails with
`:lens_generation_failed`, the controller returns 503.

```
[Missions::AdvanceLens] lens=analogy_bridge failed=no_curated_payload — trying next candidate
[Missions::AdvanceLens] lens=ethical          failed=no_curated_payload — trying next candidate
[Missions::AdvanceLens] lens=engineering      failed=no_curated_payload — trying next candidate
[Missions::AdvanceLens] lens=historical       failed=no_curated_payload — trying next candidate
[Missions::AdvanceLens] lens=first_person     failed=no_curated_payload — trying next candidate
Completed 503 Service Unavailable in 32ms
```

The kid sees the graceful "A Academia tá pensando — volta em instantes" page.
That's good defensive UX but masks a hard failure — **no mission of this
concept can ever be marked completed**.

### 🔴 3 — Vite 500 because of missing `tooltip.css`

`app/assets/entrypoints/application.css:39` `@import`ed
`../../components/ui/tooltip/tooltip.css`, which does not exist. Vite returned
500 for the whole CSS bundle, so the kid app rendered fully unstyled until
the import was removed in this session.

### 🟡 4 — Narrative scenes 2-N are pre-rendered greyed-out

Spoiler. The "Próxima cena →" affordance is undermined when the kid can
already glance at every scene before clicking.

### 🟡 5 — Quick-check question is rendered alongside the still-unfolding
narrative

On viewport-tall narratives, the MCQ is visible below the fold while the kid
is still on Cena 1. Easy to answer before reading the story.

## What works well (keep)

- Visual identity is on-brand once CSS loads (Duolingo tokens, gradient hero
  hot trail, 3D-shadow cards, segmented progress bar).
- Curated copy is high quality: Léo narrative has a real arc with cause →
  consequence → repair; statistical lens cites a real source (Dscout 2022, n=94).
- 503 path degrades to a friendly placeholder instead of a stack trace.

## Fix plan (this PR)

1. **Chooser:** treat `COVERAGE_FLOOR` and the closure-lens requirement as
   *soft* when the concept's curated set is smaller than `COVERAGE_FLOOR` or
   has no closure lens. Close cleanly once every curated type for the concept
   has been visited.
2. **Cap:** lower the effective hard cap to
   `[curated_types.size, HARD_CAP].min` so we never request a lens that can't
   render.
3. **Narrative:** render only the current scene; reveal subsequent ones on
   "Próxima cena →".
4. **CSS:** removal of the `tooltip.css` import already shipped in this
   session — keep it removed.

## Out of scope (follow-ups)

- Author `analogy_bridge` / `ethical` curated payloads for every concept so
  missions can hit the original 4-type + closure pedagogy.
- Move the quick-check below a "Li tudo, bora" affordance, or stick it inside
  a frame revealed after the final scene.
