# Family + PIN Auth Design

**Date:** 2026-04-25
**Status:** Draft for review
**Scope:** Replace current parent-email/password + click-to-pick-kid auth with a two-layer system: family-level credentials gating a unified profile picker, then per-profile 4-digit PINs gating profile sessions.

---

## 1. Goals

- One central credential per family (email + password) acts as the device-level gate.
- All profiles (kids and parents) authenticate inside the family with a 4-digit numeric PIN entered through a playful modal.
- Each parent keeps an optional personal email for notifications, but does not own login credentials anymore.
- Existing app namespaces (`parent/*`, `kid/*`) and role-based gates continue to work.

## 2. Non-Goals

- Multi-factor auth.
- Per-device revocation lists or session tables.
- Audit logs for PIN resets (deferred).
- Lockout / brute-force throttling beyond the existing controller `rate_limit`.
- Migrating existing data (dev seeds will be nuked).

---

## 3. Architecture

Two-layer authentication:

1. **Family layer** — `Family` owns `email` (citext, unique) and `password_digest` (bcrypt via `has_secure_password`). A 90-day `cookies.signed.permanent[:family_id]` holds the device-level identity. There is no server-side session table; logout is cookie deletion only.
2. **Profile layer** — `Profile` owns `pin_digest` (bcrypt over a 4-digit numeric PIN). An ephemeral `session[:profile_id]` holds the active profile; the cookie is browser-session-scoped, so closing the browser forces a re-PIN.

`Authenticatable` exposes `current_family` (cookie-derived) and `current_profile` (session-derived, scoped to `current_family.profiles`). All non-auth routes require `current_family`. The `parent/*` and `kid/*` namespaces additionally require `current_profile` and the matching role.

Service objects (`app/services/auth/`) wrap multi-step mutations. Controllers stay thin and follow the project's existing pattern (return `OpenStruct(success?:, error:)`).

## 4. Data Model Changes

### `families` (modified)

| Column            | Type        | Notes                                  |
|-------------------|-------------|----------------------------------------|
| `email`           | citext      | unique, not null, indexed              |
| `password_digest` | string      | not null                               |

Validations: email presence + format; password length ≥ 12 on create.

### `profiles` (modified)

| Column            | Change                                               |
|-------------------|------------------------------------------------------|
| `password_digest` | **drop**                                             |
| `pin_digest`      | **add** string, not null (set at profile create time) |
| `email`           | keep as optional personal email (no longer login)    |
| `confirmed_at`    | drop (parent confirmation belongs to family now)     |

The existing partial unique index on `profiles.email WHERE role = 1` is dropped.

PIN format validation: exactly 4 numeric characters at write-time (not stored in plaintext).

### Migration strategy

Per Q15: nuke + reseed. A single migration drops `profiles.password_digest`, `profiles.confirmed_at`, the partial email index; adds `families.email`, `families.password_digest`, `profiles.pin_digest`. `db/seeds.rb` is rewritten to create a demo family with a known email/password and one parent + two kid profiles, each with `pin_digest` set.

---

## 5. Routes

```ruby
root "home#index"                        # branches based on auth state
# - no family cookie       → redirect new_family_session_path
# - cookie + no profile id → redirect new_profile_session_path
# - both                   → redirect role root

resource :family_session,  only: [:new, :create, :destroy]
resource :profile_session, only: [:new, :create, :destroy]

resource  :registration,   only: [:new, :create]
resource  :password_reset, only: [:new, :create, :edit, :update]

get  "invitations/:token/accept" => "invitations#show",   as: :invitation_acceptance
post "invitations/:token/accept" => "invitations#accept", as: :accept_invitation

namespace :parent do
  # unchanged + new:
  resources :profiles do
    member do
      patch :reset_pin
    end
  end
end

namespace :kid do
  # unchanged
end
```

The existing `resources :sessions` route is removed in favor of the two split resources.

---

## 6. Components

### Models

- `Family` — `has_secure_password validations: false`, validates email/password as above, `has_many :profiles`.
- `Profile` — drops password validations, adds `authenticate_pin(pin)` returning bool, validates `pin_digest` presence on create, validates submitted PIN matches `\A\d{4}\z` on assignment via a virtual `pin` attribute that hashes into `pin_digest`.

### Controllers

- `FamilySessionsController#new/create/destroy` — email+password login; `create` sets `cookies.signed.permanent[:family_id]` (90 days) and redirects to `new_profile_session_path`. Existing `rate_limit 10/3min` retained on `create`. `destroy` deletes the cookie and `reset_session`.
- `ProfileSessionsController#new/create/destroy` — `new` renders the picker; `create` accepts `profile_id` + `pin`, calls `profile.authenticate_pin(pin)`, on success `reset_session` (cookies preserved) and sets `session[:profile_id]`, redirects to role root; on failure re-renders the modal frame with error. `destroy` clears `session[:profile_id]` only. `rate_limit 10/3min` on `create`.
- `RegistrationsController` — `new` renders family form, `create` calls `Auth::CreateFamily`. On success, sets the family cookie and redirects to `new_parent_profile_path?onboarding=true`.
- `Parent::ProfilesController` — gains a `pin` field on the form. `create` calls `Auth::CreateProfile`. New `reset_pin` member action calls `Auth::ResetPin`.
- `Parent::SettingsController` — gains a "Resetar PIN" link per profile in the family.
- `PasswordResetsController` — rewired so `find_by(email: …)` targets `Family` instead of `Profile`.
- `InvitationsController` — `show` renders confirm page, `accept` calls `Auth::AcceptInvitation`, sets the family cookie, redirects to `new_parent_profile_path?onboarding=true&invited=true` so the invitee creates their parent profile + PIN.

### Concern (`Authenticatable`)

```ruby
def current_family
  @current_family ||= Family.find_by(id: cookies.signed[:family_id])
end

def current_profile
  return @current_profile if defined?(@current_profile)
  @current_profile =
    if session[:profile_id] && current_family
      current_family.profiles.find_by(id: session[:profile_id])
    end
end

def require_family!
  redirect_to new_family_session_path, alert: "Faça login na família." unless current_family
end

def require_profile!
  return redirect_to new_family_session_path unless current_family
  redirect_to new_profile_session_path unless current_profile
end
```

`require_parent!` / `require_child!` retain their existing semantics, but now layer on top of `require_profile!`.

### Services (`app/services/auth/`)

- `Auth::CreateFamily.call(params)` — wraps `Family.create!` in a transaction. Returns `OpenStruct(success?:, family:, error:)`.
- `Auth::CreateProfile.call(family:, params:, pin:)` — creates profile, hashes PIN. Validates role-specific constraints. Returns OpenStruct.
- `Auth::ResetPin.call(profile:, new_pin:, actor:)` — verifies actor is parent in the same family, updates `pin_digest`. Returns OpenStruct.
- `Auth::AcceptInvitation.call(token:)` — finds invitation, checks `expires_at`/`accepted_at`, marks accepted, returns the family for cookie setting. Returns OpenStruct.

### UI

- `Ui::PinModal::Component` — Soft Candy keypad style (selected mockup A): bubbly numeric pad with shadow, 4 dot indicators that fill on press, profile avatar + name at the top. Backed by `pin_pad_controller.js` (Stimulus). Rendered inside a Turbo Frame on the picker page so submission re-renders only the frame on PIN error. JS-disabled fallback: a plain numeric input form on a dedicated page (`/profile_sessions/new?profile_id=X` returns the modal as a full page when the request is non-frame).
- `Ui::ProfilePicker::Component` — single grid mixing kids and parents, sorted by `created_at`. No tabs. Replaces the current tabbed `sessions/index`.
- Switch-profile button — top-right of both `layouts/parent.html.erb` and `layouts/kid.html.erb`. Click opens a confirm modal ("Sair desta conta?"); confirm issues `DELETE /profile_session`.

---

## 7. Data Flow

### Signup (new family)

1. `GET /registration/new` — family form (name + email + password).
2. `POST /registration` — `Auth::CreateFamily.call`. On success: set `family_id` cookie, redirect to `new_parent_profile_path?onboarding=true`.
3. `GET /parent/profiles/new?onboarding=true` — first-parent form (name + 4-digit PIN).
4. `POST /parent/profiles` — `Auth::CreateProfile.call` (role: parent, family: current_family). On success: set `session[:profile_id]`, redirect to `parent_root_path`.

### Returning device, family cookie present

1. `GET /` → root → `current_family` exists, `current_profile` blank → redirect to `new_profile_session_path`.
2. Picker renders all profiles in a single grid.
3. Click profile → opens Turbo Frame PIN modal at `/profile_sessions/new?profile_id=X`.
4. Submit PIN → `POST /profile_session` with `profile_id` + `pin` → `profile.authenticate_pin(pin)`. Pass: `reset_session` (cookies preserved), set `session[:profile_id]`, redirect to role root. Fail: re-render modal frame with error.

### Returning device, no family cookie

1. `GET /` → no `current_family` → redirect to `new_family_session_path`.
2. Family login form (email + pw) → `POST /family_session` → set cookie → redirect to picker.

### Switch profile

1. Switch button → confirm modal → `DELETE /profile_session` → clears `session[:profile_id]` → redirect to picker. Family cookie untouched.

### Logout family

1. Parent settings → "Sair desta família neste dispositivo" → `DELETE /family_session` → cookie deleted + `reset_session` → redirect to `new_family_session_path`.

### Reset PIN (parent → any profile)

1. Parent settings → per-profile "Resetar PIN" → form (new PIN) → `PATCH /parent/profiles/:id/reset_pin` → `Auth::ResetPin.call` → flash success.

### Forgot family password

1. `GET /password_reset/new` → email field → mailer flow rewired to `Family.find_by(email: …)` → email link → `edit/update` set new password.

### Invitation accept

1. Click email link → `GET /invitations/:token/accept` → confirm page.
2. `POST /invitations/:token/accept` → `Auth::AcceptInvitation.call` → set family cookie → redirect to `new_parent_profile_path?onboarding=true&invited=true` → invitee creates own parent profile + PIN.

---

## 8. Error Handling

### Family auth
- Wrong email/password → flash "Email ou senha inválidos." (generic, no enumeration), re-render `new`.
- `rate_limit 10/3min` on `family_sessions#create` → `head :too_many_requests`.
- Missing/expired/tampered family cookie → signed cookie returns nil → `require_family!` redirects with notice.

### Profile auth
- Wrong PIN → re-render Turbo Frame with "PIN incorreto" and cleared pad. No lockout.
- `profile_id` not in current family → `current_family.profiles.find` returns nil → 404 (or re-render picker with alert depending on path).
- `rate_limit 10/3min` on `profile_sessions#create` → 429.

### Cross-family access
- `authorize_family!` (existing) raises `ActiveRecord::RecordNotFound` → 404.

### Role gates
- Kid hits `/parent/*` → `require_parent!` redirects to `kid_root_path` with "Acesso restrito".
- Parent hits `/kid/*` → `require_child!` redirects to `parent_root_path`.

### Registration
- Email already taken → validation error on form.
- Weak password (<12 chars) → validation error.

### PIN setup
- Non-numeric or wrong length → "PIN deve ter 4 dígitos numéricos."
- Duplicate PINs within a family are allowed (low-stakes, optional UX consideration only).

### Reset PIN
- Non-parent invoker → `require_parent!` blocks.
- Cross-family target → `authorize_family!` raises 404.

### Invitation
- Expired token (`expires_at < now`) or already accepted (`accepted_at` present) → 404 page "Convite expirado ou inválido."

### Password reset
- Unknown email → flash "Se o email existir, enviamos instruções." (no enumeration).
- Expired token → "Link expirado, peça novo."

### Modal / JS
- JS disabled → PIN modal degrades to a plain form rendered as a full page.

---

## 9. Testing Strategy

Unit + happy-path system specs (per Q16).

### Models (`spec/models/`)
- `family_spec.rb` — email validation, password length ≥12, `authenticate(password)`.
- `profile_spec.rb` — `pin_digest` validation (4 numeric chars on set), `authenticate_pin(pin)`, role/family scopes.

### Services (`spec/services/auth/`)
- `create_family_spec.rb` — happy path + duplicate email + weak password.
- `create_profile_spec.rb` — happy path + invalid PIN + cross-family fail.
- `reset_pin_spec.rb` — parent resets own + parent resets kid + non-parent denied + cross-family denied.
- `accept_invitation_spec.rb` — happy path + expired + already-accepted.

### Requests (`spec/requests/`)
- `family_sessions_spec.rb` — login success sets cookie, wrong creds re-render, destroy clears.
- `profile_sessions_spec.rb` — picker requires family, PIN success sets session, wrong PIN re-renders, profile from another family → 404.

### System (`spec/system/`) — happy path each major flow
- `signup_flow_spec.rb` — register family → first parent profile + PIN → land on parent dashboard.
- `family_login_flow_spec.rb` — visit root without cookie → family login → picker.
- `profile_pick_flow_spec.rb` — picker → click profile → PIN modal → enter PIN → land on role root.
- `switch_profile_flow_spec.rb` — logged in → click switch → confirm → back at picker, family cookie intact.
- `parent_invite_flow_spec.rb` — parent invites email → accept link → onboarding → new parent profile + PIN.

### Helpers (`spec/support/system_auth_helpers.rb`)
- New `sign_in_family(family)` — set signed cookie directly.
- New `sign_in_profile(profile)` — set family cookie + `session[:profile_id]`.
- Existing flow specs (kid_flow, parent_flow, activity_and_balance, bulk_approval, etc.) updated to use the new helpers.

### Coverage targets
- All new services 100%.
- `Family` and `Profile` models 100%.
- Auth controllers covered via the request + system mix above.

---

## 10. Decisions Locked

| # | Decision |
|---|----------|
| Q1 | Hybrid family auth: email+password gates picker, PIN gates profile. |
| Q2 | 4-digit numeric PIN for both kids and parents. |
| Q3 | Parent sets every PIN (own + kids); kids cannot change own. |
| Q4 | Parent resets all PINs from settings; family password recovers parent PIN if forgotten. |
| Q5 | No lockout. Existing `rate_limit 10/3min` retained. |
| Q6 | Family owns email + password; parents become regular profiles like kids. |
| Q7 | Family has 1 login email; parent profiles keep optional personal email for notifications. |
| Q8 | PIN modal style: Soft Candy keypad (mockup A). |
| Q9 | Profile picker: single unified grid, no tabs. |
| Q10 | Two-step signup: family creds → first parent profile + PIN. |
| Q11 | Remember device: 90-day signed cookie holding `family_id`, no server table. |
| Q12 | Profile session: ephemeral (browser-close), re-PIN every new session. |
| Q13 | Switch-profile button + confirm modal. |
| Q14 | Invitations adapted: token → family cookie → onboarding for new parent profile + PIN. |
| Q15 | Existing data: nuke + reseed. |
| Q16 | Tests: unit + happy-path system specs. |
| Approach | Two split controllers: `FamilySessionsController` + `ProfileSessionsController`. |

---

## 11. Open Items

None. All gray areas resolved during brainstorming.
