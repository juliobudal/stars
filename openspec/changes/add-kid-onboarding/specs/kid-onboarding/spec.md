## ADDED Requirements

### Requirement: Child profiles SHALL be gated behind onboarding until completion

When `current_profile.child? && current_profile.onboarded_at.nil?`, every kid-namespace controller (other than the onboarding controller itself) SHALL redirect to `kid_welcome_path` via a `before_action`. Parent profiles SHALL NOT be affected by this guard.

#### Scenario: Un-onboarded child hits /kid
- **WHEN** an authenticated child profile with `onboarded_at IS NULL` requests `GET /kid`
- **THEN** the response is `302 Found` redirecting to `/kid/welcome`

#### Scenario: Onboarded child hits /kid
- **WHEN** an authenticated child profile with `onboarded_at` populated requests `GET /kid`
- **THEN** the response is `200 OK` and renders the dashboard

#### Scenario: Parent hits /kid
- **WHEN** an authenticated parent requests `GET /kid`
- **THEN** the system follows the existing `require_child!` rule (redirects to `/`) without invoking onboarding gating

#### Scenario: Onboarding controller is exempt from its own guard
- **WHEN** an un-onboarded child requests `GET /kid/welcome`
- **THEN** the response is `200 OK` (no redirect loop)

### Requirement: The onboarding flow SHALL present four guided screens

The flow SHALL expose four GET endpoints under `/kid/welcome*`, each rendering a focused screen with a 4-step progress indicator. The screens SHALL be: welcome, interests picker, how-it-works tour, ready confirmation.

#### Scenario: Welcome screen
- **WHEN** an un-onboarded child requests `GET /kid/welcome`
- **THEN** the page renders the kid's `SmileyAvatar`, a personalized greeting using `current_profile.name`, a 3-line product summary, and a primary button linking to `/kid/welcome/interests`; the progress indicator shows step 1 of 4

#### Scenario: Interests picker screen
- **WHEN** an un-onboarded child requests `GET /kid/welcome/interests`
- **THEN** the page renders all entries from `ProfileInterest::Catalog.all` as selectable chips, pre-checks any existing `current_profile.profile_interests`, displays "min 3, max 5", and the progress indicator shows step 2 of 4

#### Scenario: How-it-works screen
- **WHEN** an un-onboarded child requests `GET /kid/welcome/how`
- **THEN** the page renders three explanation cards (Missões, Estrelinhas, Recompensas), visually distinct per DESIGN.md tokens, and the progress indicator shows step 3 of 4

#### Scenario: Ready screen
- **WHEN** an un-onboarded child requests `GET /kid/welcome/ready`
- **THEN** the page renders a confetti-triggering surface, the kid's mascote, a "Começar" button that POSTs to `/kid/welcome/finish`, and the progress indicator shows step 4 of 4

### Requirement: Interest selection SHALL persist to profile_interests

`PATCH /kid/welcome/interests` SHALL accept `interest_keys[]`, validate that each key exists in `ProfileInterest::Catalog`, require between 3 and 5 selections, replace any existing `profile_interests` for the kid, and redirect to `kid_welcome_how_path` on success.

#### Scenario: Valid selection persists and advances
- **WHEN** an un-onboarded child PATCHes `/kid/welcome/interests` with `interest_keys=["dinossauros","espaco","futebol"]`
- **THEN** the kid's previous `profile_interests` are deleted, three new rows are inserted with ranks 1, 2, 3 in that order, and the response is `302 Found` redirecting to `/kid/welcome/how`

#### Scenario: Fewer than 3 selections rejected
- **WHEN** the kid submits 2 keys
- **THEN** the response is `422 Unprocessable Entity` rendering the interests view with a flash alert and no `profile_interests` are persisted

#### Scenario: Unknown key ignored
- **WHEN** the kid submits `interest_keys=["dinossauros","fake_key","espaco","futebol"]`
- **THEN** only the catalog-valid keys are kept; if at least 3 remain, the submission succeeds; if fewer than 3 valid keys remain, the submission is rejected per the previous scenario

### Requirement: Finish action SHALL mark onboarding complete and be idempotent

`POST /kid/welcome/finish` SHALL set `current_profile.onboarded_at` to `Time.current`, set a success flash notice, redirect to `kid_root_path`, and tolerate replay (a second POST SHALL also redirect successfully without raising).

#### Scenario: First finish stamps and redirects
- **WHEN** an un-onboarded child POSTs `/kid/welcome/finish`
- **THEN** `current_profile.reload.onboarded_at` is set to a recent timestamp, the response is `302 Found` to `/kid`, and a flash[:notice] is present

#### Scenario: Replay finish is idempotent
- **WHEN** an already-onboarded child POSTs `/kid/welcome/finish` again
- **THEN** the response is `302 Found` to `/kid` and no error is raised; the `onboarded_at` value MAY be refreshed but the row remains valid

### Requirement: Profiles backfill SHALL preserve existing children

The migration adding `onboarded_at` SHALL backfill all existing child profiles with `Time.current` so that the deploy does not interrupt active kid sessions in production.

#### Scenario: Migration backfills child profiles
- **WHEN** the migration runs against a database containing N child profiles created before the migration
- **THEN** after migration all N rows have `onboarded_at IS NOT NULL`, and the kid dashboard renders for any of them without redirecting to welcome

#### Scenario: New child profile defaults to nil
- **WHEN** a new child profile is created after the migration
- **THEN** `onboarded_at IS NULL` until `POST /kid/welcome/finish` succeeds
