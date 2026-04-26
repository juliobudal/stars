# Kid Comments & Custom Missions — Design

**Date:** 2026-04-26
**Status:** Approved (pending user review of spec)

## Goal

Two related kid-side features for LittleStars:

1. **Submission comment** — when a kid submits a mission for approval, allow attaching a short text note ("Eu fiz junto com a mamãe", "Demorou mais hoje porque..."). The parent sees this note in the approval queue.
2. **Custom mission** — let a kid propose a one-off mission they already did ("Arrumei a estante!"), suggest a point value, and submit it for parent approval. Parent can adjust points before approving. Approval credits points immediately (retrospective claim, no re-execution).

## Non-Goals

- Threaded chat / multiple comments per mission (single field on submission only)
- Editable comments after submission
- Promoting custom missions into the reusable `GlobalTask` catalog (one-off only)
- Kid-set categories outside the family's existing `Category` set
- Recurring custom missions

## User Stories

- As a kid, when I submit a regular mission, I can optionally type a short note for my parent.
- As a kid, I can tap "+ Nova missão" on my dashboard, fill in title / description / suggested points / category, and submit it.
- As a parent, in the approval queue I can see the kid's submission comment.
- As a parent, for a custom mission I can edit the points before approving (kid suggested 50, I approve 30).
- As a parent, custom missions are visually marked "Sugerida pela criança" so I don't confuse them with catalog missions.

## Architecture

### Data model — `ProfileTask` schema change

Currently `ProfileTask belongs_to :global_task` (required) and delegates `title/points/category/description/icon` to `global_task`. Custom missions are one-off, so we make `global_task_id` nullable and store custom fields directly on `ProfileTask`.

Migration:

```ruby
change_column_null :profile_tasks, :global_task_id, true
add_column :profile_tasks, :custom_title, :string
add_column :profile_tasks, :custom_description, :text
add_column :profile_tasks, :custom_points, :integer
add_reference :profile_tasks, :custom_category, foreign_key: { to_table: :categories }
add_column :profile_tasks, :submission_comment, :text
add_column :profile_tasks, :source, :integer, default: 0, null: false
add_index :profile_tasks, :source
```

Enum:

```ruby
enum :source, { catalog: 0, custom: 1 }, default: :catalog
```

Validations (conditional on `source`):

- `catalog`: `global_task_id` present; `custom_*` columns nil
- `custom`: `custom_title` (1..120 chars), `custom_points` (1..1000), `custom_category_id` present; `global_task_id` nil

Delegation rewritten as methods that branch on `custom?`:

```ruby
def title;       custom? ? custom_title       : global_task.title;       end
def description; custom? ? custom_description : global_task.description; end
def points;      custom? ? custom_points      : global_task.points;      end
def category;    custom? ? custom_category    : global_task.category;    end
def icon;        custom? ? nil                : global_task.icon;        end
```

`submission_comment` is just a column — read directly.

### Services

**`Tasks::CreateCustomService`** (new, under `app/services/tasks/`):

- Inputs: `profile:`, `params:` (`custom_title`, `custom_description`, `custom_points`, `custom_category_id`, optional `submission_comment`, optional `proof_photo`)
- Wraps in `ActiveRecord::Base.transaction`
- Creates `ProfileTask` with `source: :custom`, `status: :awaiting_approval`, `assigned_date: Date.current`, `completed_at: Time.current`
- Returns `OpenStruct(success?:, profile_task:, error:)`

**`Tasks::ApproveService`** (existing, extended):

- New optional kwarg: `points_override: nil`
- If `points_override` present and `profile_task.custom?`, update `custom_points = points_override` before crediting
- Credits `profile_task.points` (post-override) to `Profile.points`
- ActivityLog `earn` entry: `note` includes `submission_comment` (if any) and `[Sugerida pela criança]` flag when `custom?`

**Submission path for catalog missions** (existing controller / service that transitions `pending → awaiting_approval`):

- Add `submission_comment` to permitted params
- Persist on `ProfileTask` before status change

### UI

**Kid side:**

- Dashboard: add "+ Nova missão" button (Duolingo-style 3D primary button) above or alongside today's mission list. Routes to `GET /kid/missions/new`.
- `kid/missions/new` form (ViewComponent or simple ERB):
  - Title (required, 120 char max)
  - Description (optional textarea)
  - Suggested points (numeric input, 1..1000, with playful copy "Quanto vale?")
  - Category (radio cards or select of family's Categories)
  - Optional proof photo
  - Optional comment textarea
  - Submit → `POST /kid/missions`
- Existing submission flow gains a `submission_comment` textarea ("Quer mandar um recado?"). Optional.

**Parent side:**

- `approval_row` component renders:
  - "Sugerida pela criança" pill badge when `custom?`
  - `submission_comment` block when present (styled like a quote)
  - Editable points input (number) when `custom?` — value defaults to `custom_points`, posted as `points_override` to ApproveService
  - Standard catalog missions: existing UI unchanged, plus comment block when present

### Routes

```ruby
namespace :kid do
  resources :missions, only: %i[new create]
end
```

`Kid::MissionsController#create` calls `Tasks::CreateCustomService` and redirects to dashboard with flash success.

`Parent::ApprovalsController#update` accepts optional `points_override` and forwards to `Tasks::ApproveService`.

### Real-time

Existing Turbo broadcasts on `ProfileTask` (approval count, kid balance) cover both flows. Custom missions reuse `awaiting_approval` status, so no new channels needed.

## Error Handling

- Invalid custom params → form re-render with errors, status 422
- `points_override` outside 1..1000 → ApproveService returns `success?: false`, parent UI flashes error
- Race on approve (concurrent approves of same task) → existing transaction + status guard in ApproveService
- Category deleted while custom mission pending → `custom_category_id` nullified (`on_delete: :nullify` on FK); UI falls back to "Sem categoria" label

## Testing (RSpec)

**Model specs (`profile_task_spec.rb`):**

- Validations for `source: catalog` and `source: custom`
- Delegation fallback: `title`, `points`, `category` correct for both sources

**Service specs:**

- `Tasks::CreateCustomService` — happy path creates `awaiting_approval` ProfileTask; invalid params return `success?: false`
- `Tasks::ApproveService` — `points_override` updates `custom_points` and credits override amount; `submission_comment` flows into ActivityLog note

**System specs (Capybara):**

- Kid creates custom mission → appears in parent approval queue with badge → parent adjusts points → approves → kid balance increases by override amount
- Kid submits regular mission with comment → parent sees comment in approval row → approves → ActivityLog note contains comment

## Edge Cases

- Custom mission with no proof photo: allowed (kid claims it without photo)
- Kid suggests 0 or negative points: validation rejects (`>= 1`)
- Kid suggests >1000 points: validation rejects (high cap, parent still adjusts)
- Parent rejects custom mission: ProfileTask status `rejected`, no points credited, no ActivityLog earn entry (existing reject flow handles)
- Comment with only whitespace: stripped, treated as nil

## Out of Scope (future)

- Comment threads / parent replies
- Promoting custom mission to GlobalTask catalog
- Kid editing custom mission after submission
- Daily reset for custom missions (one-off, doesn't recur)
