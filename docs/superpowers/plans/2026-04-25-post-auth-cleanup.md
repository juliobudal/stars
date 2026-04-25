# Post-Auth Cleanup Plan — Parallel Agents + Opus Review

> **Strategy**: 8 independent workstreams dispatched in parallel. Each workstream has an **implementer** (Sonnet for medium, Haiku for trivial) followed by a single **Opus 4.7 reviewer** that gates "done". Reviewer must approve before implementer's work merges. If reviewer requests changes, implementer is re-dispatched with the feedback. No workstream blocks another.

**Goal**: clear all remaining failures and concerns left after the family + PIN auth refactor (commits 0f55b3a..d76bfed).

**Final state target**:
- `bundle exec rspec` → 0 failures.
- Brakeman → 0 warnings (already clean, must stay clean).
- Rubocop → 0 new violations.
- Onboarding copy reads correctly for first-parent and invited-parent flows.
- Deprecated `:unprocessable_entity` symbols gone from spec assertions.

---

## Workstream Catalog

| ID | Title | Failure count | Implementer model | Reviewer model |
|----|-------|---------------|-------------------|----------------|
| W1 | `Ui::Btn` spec migration | 9 | Sonnet | Opus 4.7 |
| W2 | `Ui::CategoryTabs` spec migration | 1 | Haiku | Opus 4.7 |
| W3 | `Ui::FilterChips` spec migration | 2 | Haiku | Opus 4.7 |
| W4 | `Ui::KidProgressCard` spec migration | 1 | Haiku | Opus 4.7 |
| W5 | `Ui::StatCard` spec migration | 2 | Haiku | Opus 4.7 |
| W6 | `Ui::Toggle` spec migration | 2 | Haiku | Opus 4.7 |
| W7 | Onboarding view copy fix | 0 (concern) | Sonnet | Opus 4.7 |
| W8 | Rack deprecation sweep | 0 (warning) | Haiku | Opus 4.7 |

---

## Common Workstream Rules

- Read the relevant component template + spec **before** editing.
- For W1–W6: prefer aligning the **spec** to current component output (the components are the post-rebrand source of truth — see commits `129d153` and `e1056ab`). Only modify the component if the spec reveals a true regression (must be argued explicitly to the reviewer).
- TDD-where-it-matters: run the failing spec first, observe actual output, then edit. Re-run after edit to confirm green.
- One atomic commit per workstream. Conventional Commits format. Include the failure count fixed in the body.
- Run `docker compose exec -T web bundle exec rspec <spec_path>` after each fix.
- All work on branch `main`. No worktrees.
- Reviewer must read both the component and the spec, run the test, and confirm no behavior regression hides behind the spec change.

---

## W1 — `Ui::Btn` spec migration (9 failures)

**Files**:
- Read: `app/components/ui/btn/component.rb`, `app/components/ui/btn/btn.css`
- Edit: `spec/components/ui/btn/component_spec.rb`

**Symptoms**:
- Variant assertions expect Tailwind utility classes (e.g. `bg-primary`, `bg-secondary`). Component now emits BEM classes like `ui-btn ui-btn--primary`.
- Size assertions expect `text-[14px]`, `text-[16px]`, `text-[18px]`. Component now emits `ui-btn--sm`, `ui-btn--md`, `ui-btn--lg`.

**Fix direction**:
- Replace utility-class assertions with the BEM class equivalents emitted by the component.
- Keep the spec intent identical (verify variant/size mapping).

**Run after**: `docker compose exec -T web bundle exec rspec spec/components/ui/btn/component_spec.rb`

**Implementer model**: Sonnet (9 cases, mechanical but bulky)

**Reviewer model**: Opus 4.7. Gate criteria:
- All 9 cases now pass.
- Asserted classes match component output verbatim.
- No behavior contract was loosened (e.g. variant must still map to a unique class — not just "any class present").

**Commit**: `test(ui): align Ui::Btn specs with BEM class output`

---

## W2 — `Ui::CategoryTabs` spec migration (1 failure)

**Files**:
- Read: `app/components/ui/category_tabs/component.html.erb`, `app/components/ui/category_tabs/category_tabs.css`
- Edit: `spec/components/ui/category_tabs/component_spec.rb`

**Symptom**: Spec expects `button.active`. Component now likely emits `button.tab--active` or similar BEM class.

**Fix direction**: Update selector to actual class.

**Run after**: `docker compose exec -T web bundle exec rspec spec/components/ui/category_tabs/component_spec.rb`

**Implementer model**: Haiku.
**Reviewer model**: Opus 4.7.
**Commit**: `test(ui): align Ui::CategoryTabs spec with current class names`

---

## W3 — `Ui::FilterChips` spec migration (2 failures)

**Files**:
- Read: `app/components/ui/filter_chips/component.html.erb`
- Edit: `spec/components/ui/filter_chips/component_spec.rb`

**Symptoms**: `button.tab` and `button.active[aria-selected='true']` no longer match. Component emits different class names but should retain `aria-selected`.

**Fix direction**: Update selectors. Preserve aria assertion.

**Implementer model**: Haiku.
**Reviewer model**: Opus 4.7.
**Commit**: `test(ui): align Ui::FilterChips spec with current class names`

---

## W4 — `Ui::KidProgressCard` spec migration (1 failure)

**Files**:
- Read: `app/components/ui/kid_progress_card/component.html.erb`
- Edit: `spec/components/ui/kid_progress_card/component_spec.rb`

**Symptom**: Spec expects `.awaiting-badge`. Class likely renamed.

**Fix direction**: Find the new badge class in component, update selector. If badge is gone entirely, that's a regression — escalate.

**Implementer model**: Haiku.
**Reviewer model**: Opus 4.7. Specifically verify the badge still **renders** (just under a different class) before approving.
**Commit**: `test(ui): align Ui::KidProgressCard spec with badge class rename`

---

## W5 — `Ui::StatCard` spec migration (2 failures)

**Files**:
- Read: `app/components/ui/stat_card/component.html.erb`
- Edit: `spec/components/ui/stat_card/component_spec.rb`

**Symptoms**: Spec expects `.card` and `.stat-icon-tile`. Both classes likely changed.

**Fix direction**: Match new class names. Preserve "fallback to primary tint for unknown tint" semantic.

**Implementer model**: Haiku.
**Reviewer model**: Opus 4.7. Confirm fallback logic still tested, not just "any class present".
**Commit**: `test(ui): align Ui::StatCard spec with current class names`

---

## W6 — `Ui::Toggle` spec migration (2 failures)

**Files**:
- Read: `app/components/ui/toggle/component.html.erb`
- Edit: `spec/components/ui/toggle/component_spec.rb`

**Symptoms**:
- `.toggle.is-checked[role='switch'][aria-checked='true']` not found.
- `label.toggle` not found.

**Fix direction**: Match current markup. **Critical**: Toggle is a form input — accessibility (role, aria-checked, name binding) MUST stay tested. Do not let the spec degrade to a syntactic class check.

**Implementer model**: Haiku.
**Reviewer model**: Opus 4.7. Required to verify a11y attrs are still asserted, not just removed.
**Commit**: `test(ui): align Ui::Toggle spec with current class names`

---

## W7 — Onboarding view copy fix (concern)

**Files**:
- Read: `app/views/parent/profiles/new.html.erb`, `app/views/parent/profiles/_form.html.erb`, `app/controllers/parent/profiles_controller.rb`
- Edit: most likely `app/views/parent/profiles/new.html.erb` (or `_form.html.erb`)

**Symptom**: Onboarding flow (`?onboarding=true`) reuses kid-creation copy ("Crie um perfil para seu filho(a)"). Misleading — onboarding creates the **first parent** profile, not a kid.

**Fix direction**:
- Branch the view by `params[:onboarding]` / `params[:invited]`:
  - `onboarding=true` (no `invited`) — first-parent copy: "Crie seu perfil de pai/mãe", PIN field, no role selector.
  - `invited=true` — invited-parent copy: "Bem-vindo à família! Crie seu perfil.", PIN field.
  - Default — kid-creation copy as today.
- The role override already lives server-side (`Parent::ProfilesController#create`). Don't add a role selector.
- Keep all form field labels matching what the new system specs (Tasks 25, 29) use: "Nome", "PIN (4 dígitos)", button "Salvar Perfil".

**Run after**: `docker compose exec -T web bundle exec rspec spec/system/signup_flow_spec.rb spec/system/parent_invite_flow_spec.rb` (must still pass)

**Implementer model**: Sonnet (copy + branching, easy to over-engineer).
**Reviewer model**: Opus 4.7. Gate on:
- Copy reads naturally for both onboarding and non-onboarding flows.
- No new translation keys without justification (accept Portuguese inline strings — matches project style).
- Both system specs still pass.
**Commit**: `feat(auth): split onboarding copy from kid-creation copy`

---

## W8 — Rack deprecation sweep

**Files**:
- Search: `grep -rln ":unprocessable_entity" spec/ app/`
- Edit: any matches

**Symptom**: `rspec-rails` warns `:unprocessable_entity` is deprecated; future Rack versions remove it. Replace with `:unprocessable_content`.

**Fix direction**:
- Replace `:unprocessable_entity` → `:unprocessable_content` in **spec files only** (controllers may still use the symbol — Rails autoloads the alias for now; aim to remove from spec assertions to silence the deprecation noise).
- Verify Rails 8.1 supports `:unprocessable_content` as a valid `head` / `render` symbol — if not, leave controllers alone.

**Run after**: `docker compose exec -T web bundle exec rspec 2>&1 | grep -c "unprocessable_entity is deprecated"` should report `0`.

**Implementer model**: Haiku (mechanical sed-like work).
**Reviewer model**: Opus 4.7. Gate on:
- All spec assertions still pass.
- No controller behavior changed (production code untouched, OR if changed, both old and new symbols still work).
**Commit**: `test: replace deprecated :unprocessable_entity in spec assertions`

---

## Dispatch Order

All 8 workstreams are mutually independent. Dispatch implementers in **a single message with 8 parallel `Agent` tool uses**.

After all 8 implementers report, dispatch 8 Opus reviewers in **a single parallel message**.

Per workstream: if reviewer says ✅, mark done; if ❌, re-dispatch implementer with reviewer feedback (single Sonnet/Haiku call), then a second reviewer pass.

After all 8 are ✅:
1. Run full suite: `docker compose exec -T web bundle exec rspec`
2. Run Brakeman: `docker compose exec -T web bin/brakeman --no-pager`
3. Run Rubocop: `docker compose exec -T web bin/rubocop`
4. Confirm: 0 spec failures, 0 brakeman warnings, 0 new rubocop violations.

---

## Risks

- **Spec already matches a hidden component bug**: if any reviewer determines the spec is correct and the component is wrong, escalate. Don't downgrade test rigor to make red green.
- **Onboarding copy fix breaks system specs**: the 5 new system specs (signup, family_login, profile_pick, switch_profile, parent_invite) drive the onboarding form. W7 implementer MUST run them before committing.
- **Rack deprecation removal loses signal**: if Rails 8.1 doesn't yet alias `:unprocessable_content` in all paths, W8 may break specs silently. W8 reviewer must run the full suite after the change.
