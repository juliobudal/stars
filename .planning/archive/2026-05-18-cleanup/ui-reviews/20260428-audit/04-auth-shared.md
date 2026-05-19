# Auth / Onboarding / Shared — UI Audit (Duolingo design system)

Date: 2026-04-28
Scope: family_sessions, profile_sessions, registrations, password_resets, password_mailer, invitations, invitation_mailer, shared, pwa, components/form_builders, application_component.rb

---

## 1. Tokens (raw hex / Berry Pop residue)

- **HIGH** `app/views/pwa/manifest.json.erb:20-21` — `theme_color` and `background_color` set to literal `"red"` (placeholder); should be Duolingo green `#58CC02` and `#F7F7F7` (vars not allowed in manifest, use brand hex).
- **HIGH** `app/views/invitation_mailer/invite.html.erb:11` — raw hex `#AFAFAF` (acceptable for email but not branded — should be `#777777` text-muted equivalent and consistent with mailer brand styling, no header/logo/buttons styled).
- **MEDIUM** `app/views/pwa/manifest.json.erb:1-19` — `name: "App"`, `description: "App."` — placeholder strings, no LittleStars brand identity.
- **LOW** `app/components/form_builders/*/component.yml` — only YAML stubs exist (no `component.rb`/`component.html.erb`); not wired up. No actual code implements form_builders → app uses raw `f.text_field` with hand-rolled Tailwind classes everywhere.

## 2. Typography (Nunito 700/800, no Fraunces)

- **PASS** `app/views/shared/_head.html.erb:4` loads Nunito 400/700/800/900. No Fraunces references found in scope.
- **LOW** `app/views/shared/_head.html.erb:4` — weight `400` is loaded but never used (body default is 700); could drop to slim payload.
- **LOW** `app/views/invitation_mailer/invite.html.erb` and `password_mailer/reset.html.erb` — no font-family declared inline; mail clients fall back to Times/Arial. Inconsistent with brand.

## 3. Shadows / radii (0 4px 0, 10–16px)

- **PASS** auth pages use `0 4px 0 var(--star-2)`, 14–16px radii, `--shadow-card`.
- **MEDIUM** `app/views/invitations/show.html.erb:7-9` — manual `button_to` with inline button styling instead of `Ui::Btn::Component`; reproduces shadow contract by hand and risks drift.
- **LOW** `app/views/shared/_parent_nav.html.erb:99` — mobile bottom nav uses `bg-white/80 backdrop-blur-lg border-t border-hairline` (flat, no `0 4px 0` depth) — inconsistent with kid bottom nav (line 11 uses 3D `0 4px 0`).

## 4. Layout (centered card, mobile-first)

- **MEDIUM** Auth pages diverge: `family_sessions/new`, `registrations/new` wrap form in a `.ls-card-3d` white card; `password_resets/new` and `edit` do NOT (form sits on raw bg). Pattern broken.
- **MEDIUM** `password_resets/new.html.erb:1-2` — uses `max-w-[430px]` then `md:max-w-[768px]` — auth pages should stay narrow (≤430 kid shell or ≤480 form card); 768 expansion is mismatched.
- **HIGH** `invitations/show.html.erb:1-10` — no logo, no card, no eyebrow; bare `<h1>` + paragraph + button. Completely off-pattern vs. login/register.
- **MEDIUM** `profile_sessions/new.html.erb` uses `BgShapes variant: "warm"` while `family_sessions/new` and `registrations/new` use `"cool"` — unexplained variance for entry screens.

## 5. Page structure consistency (logo, hero, layout)

- **HIGH** Logo block (yellow tile + "LittleStars") is duplicated verbatim in `family_sessions/new:6-12`, `profile_sessions/new:5-12`, `registrations/new:6-12` — should be a shared partial or `Ui::Brand::Component`. `parent_nav` and `kid` shells use `Ui::LogoMark::Component` already — proves component exists, just unused on auth.
- **HIGH** `password_resets/new` and `edit` have NO logo / brand mark — breaks consistency.
- **HIGH** `invitations/show` has NO logo / eyebrow / card / shared chrome.
- **MEDIUM** Eyebrow pattern (`text-[11px] font-extrabold tracking-[1px] uppercase` colored sky-dark) repeated in 3 auth views — extract to `Ui::Eyebrow` per DESIGN §3.

## 6. Forms (inputs, errors, validation)

- **HIGH** All auth forms hand-roll input classes (`w-full px-4 py-3 rounded-[14px] border-2 border-hairline bg-white text-[15px] font-bold focus:outline-none focus:border-primary`). Duplicated 8+ times across 5 files. DESIGN §8 calls for `.form-field`/`.form-input`. No focus ring (`box-shadow: 0 0 0 3px var(--primary-soft)`) — only border color changes.
- **HIGH** No `<label>` elements in any auth form — only `placeholder` + `aria-label`. Not a label per DESIGN.form-label spec.
- **HIGH** No error rendering for ActiveRecord errors on `@family.errors` in `registrations/new` — only `flash[:alert]`. Field-level errors are silently dropped.
- **MEDIUM** `registrations/new.html.erb:39` placeholder "Senha (mín. 12 caracteres)" — hint should be a real `hint`/helper text under the field, not buried in placeholder (placeholder vanishes on type).
- **MEDIUM** `password_resets/edit.html.erb:11` — `<%= hidden_field_tag :token, @token %>` rendered AFTER `form_with url: ...(token: @token)` which already includes it — duplicate token in payload.
- **MEDIUM** `form_builders/` directory contains only `.yml` doc stubs — never implemented. Either implement them or delete. Currently misleading dead scaffolding.

## 7. Buttons (Ui::Btn::Component usage)

- **PASS** auth login/register/password reset use `Ui::Btn::Component`.
- **HIGH** `invitations/show.html.erb:7-9` — bypasses `Ui::Btn`, uses `button_to` with inline styling.
- **MEDIUM** `password_mailer/reset.html.erb:6` and `invitation_mailer/invite.html.erb:8` — primary CTA is unstyled `link_to` (default browser blue underline). Should be a styled "button-link" inline `<a>` with brand colors.

## 8. Mailers (HTML brand consistency)

- **HIGH** `password_mailer/reset.html.erb` and `invitation_mailer/invite.html.erb` — no inline styles, no brand colors, no Nunito stack, no logo, no padding/wrapper, no header. Looks like generic Rails scaffolding.
- **MEDIUM** No `mailers/_layout.html.erb` (`ApplicationMailer` layout) — each mailer view stands alone with no shared chrome.
- **PASS** Both mailers ship `.text.erb` fallback.
- **LOW** `password_mailer/reset.html.erb:1` no `<html>`/`<body>` wrapper — relies on Rails default mailer layout (none present). Inconsistent with `invitation_mailer/invite.html.erb` which does include `<html><body>`.

## 9. Shared partials / duplication

- **HIGH** Logo lockup duplicated 3× in auth views (see §5).
- **HIGH** Auth input class string duplicated 8× (see §6).
- **MEDIUM** Eyebrow uppercase label duplicated 3×.
- **MEDIUM** Auth card wrapper (`ls-card-3d w-full max-w-[360px] ...`) duplicated 2×.
- **LOW** `_parent_nav.html.erb:6-7` has duplicated `<%# Mobile sticky header %>` comment lines (and `<%# Sidebar %>` 21-22) — leftover.

## 10. PWA (manifest, icons)

- **CRITICAL** `app/views/pwa/manifest.json.erb` is unbranded: `name: "App"`, `description: "App."`, `theme_color: "red"`, `background_color: "red"` — install banner / splash screen will show "App" with red. Must be `LittleStars`, `#58CC02`, `#F7F7F7`.
- **HIGH** Only one icon size (512×512), no 192×192 or smaller. Many platforms reject manifests without 192. No `short_name` field.
- **HIGH** `service-worker.js` is entirely commented-out scaffolding — no offline shell, no cache, no push handler. Not registered anywhere. PWA install will fail offline.
- **MEDIUM** `_head.html.erb` does not link `manifest.webmanifest` (`<link rel="manifest" ...>`). PWA never advertised.
- **MEDIUM** `_head.html.erb:11-13` references `/icon.png` and `/icon.svg` — confirm both exist in `public/`. No `apple-touch-icon` sized variants.

## 11. Accessibility

- **HIGH** No autocomplete attrs on auth fields. Should be `autocomplete="email"`, `autocomplete="current-password"` (login), `autocomplete="new-password"` (registration/reset) per WHATWG.
- **HIGH** No real `<label>` elements — `aria-label` is a fallback, not a label. Screen readers and password managers degrade.
- **MEDIUM** `family_sessions/new.html.erb:25` and similar — `flash[:alert]` has no `role="alert"` / `aria-live="polite"`.
- **MEDIUM** `password_resets/edit.html.erb` — no `<h1>` lockup with brand context for screen readers (lone "Nova senha").
- **MEDIUM** `_parent_nav.html.erb:14-18` — mobile toggle button has icon only and no `aria-label` (only `id="sidebar-toggle"`).
- **LOW** `invitations/show.html.erb` — `button_to` "Aceitar convite" is fine for accessibility but lacks loading/disabled state on submit.
- **LOW** `_kid_nav.html.erb` — uses `title:` attr for label tooltips but no `aria-label` on `link_to`; visually shows label, but `current` page not marked with `aria-current="page"` (parent nav does this — kid does not).

## 12. Dead code / orphans

- **MEDIUM** `app/components/form_builders/*` — eight yml-only directories with no Ruby/ERB. Either dead scaffolding or a yet-to-be-built abstraction; currently zero imports.
- **MEDIUM** `app/views/pwa/service-worker.js` — 100% commented out.
- **LOW** `_parent_nav.html.erb:6-7, 21-22` — duplicated comment lines.
- **LOW** `_head.html.erb:4` — Nunito weight `400` loaded but never used per design (body is 700).
- **LOW** `application_component.rb` — `@options = options` stored but never read by any subclass — dead instance var.

---

## Top 10 Fixes (Prioritized)

1. **CRITICAL — PWA manifest brand:** rewrite `pwa/manifest.json.erb` with `name: "LittleStars"`, `short_name: "LittleStars"`, real description, `theme_color: "#58CC02"`, `background_color: "#F7F7F7"`, add 192×192 + 512×512 + maskable icons.
2. **HIGH — Mailer brand chrome:** create `app/views/layouts/mailer.html.erb` with inline-styled brand header (logo + green band), Nunito stack with web-safe fallback, branded CTA button. Apply to `password_mailer` and `invitation_mailer`.
3. **HIGH — Extract `Ui::Brand` (logo lockup) component:** replace duplicated yellow-tile logo block in `family_sessions/new`, `profile_sessions/new`, `registrations/new`; add to `password_resets/*` and `invitations/show`.
4. **HIGH — Auth form `Ui::Input` / `.form-input` class:** consolidate the duplicated input class string into a CSS class or component (per DESIGN §8); add proper focus ring `0 0 0 3px var(--primary-soft)`.
5. **HIGH — Add `<label>` + `autocomplete` attrs:** replace placeholder-only inputs with real labels (sr-only if visually hidden) and add `autocomplete="email|current-password|new-password"` across all auth forms.
6. **HIGH — `invitations/show` rebuild:** apply auth shell pattern (BgShapes, logo, eyebrow, card, `Ui::Btn::Component`); currently bare scaffold.
7. **HIGH — Field-level error rendering:** surface `@family.errors` (and password reset errors) under each input in registration/reset forms; not just `flash[:alert]`.
8. **HIGH — Service worker:** ship a real precache + offline fallback or remove the file and the registration. Currently commented stub gives zero PWA value.
9. **MEDIUM — `password_resets` consistency:** wrap form in same `.ls-card-3d`, add logo, drop the `md:max-w-[768px]` widening; align with login/register pattern.
10. **MEDIUM — Form builders cleanup:** either implement `app/components/form_builders/*` (matching yml specs) and adopt across auth, or delete the empty stubs to remove dead scaffolding.

---

## Counts

- CRITICAL: 1
- HIGH: 17
- MEDIUM: 17
- LOW: 9
- Total: 44 findings
