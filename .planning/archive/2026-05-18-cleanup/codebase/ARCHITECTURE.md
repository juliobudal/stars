# Architecture

**Analysis Date:** 2026-04-21

## Pattern Overview

**Overall:** Dual-interface namespaced Rails 8 fullstack app with service-driven business logic, ViewComponent-based UI, and real-time updates via Turbo Streams.

**Key Characteristics:**
- Clear separation of concerns: Models → Services → Controllers → ViewComponents → ERB Views
- Dual role-based interfaces: `parent/` namespace (admin dashboard) and `kid/` namespace (gamified child interface)
- Transaction-wrapped service objects for all mutations (task approval, reward redemption)
- Real-time Turbo Stream broadcasts for live updates across connected clients
- Stimulus controllers for micro-interactions (confetti, animations, form state)
- Query objects for complex SQL aggregations (approval queue)

## Layers

**Models (Data Layer):**
- Purpose: ActiveRecord models representing domain entities with validations and relationships
- Location: `app/models/`
- Contains: `Family`, `Profile`, `GlobalTask`, `ProfileTask`, `Reward`, `Redemption`, `ActivityLog`
- Depends on: PostgreSQL, ActiveRecord
- Used by: Services, Controllers, Queries

**Services (Business Logic Layer):**
- Purpose: Encapsulate multi-step mutations in ACID transactions, return `Result` objects with `success?` predicate
- Location: `app/services/`
- Contains: `Tasks::ApproveService`, `Tasks::RejectService`, `Tasks::DailyResetService`, `Rewards::RedeemService`, `Rewards::ApproveRedemptionService`, `Rewards::RejectRedemptionService`
- Depends on: Models, ActiveRecord transactions
- Used by: Controllers, broadcast-triggered actions

**Queries (Data Retrieval Layer):**
- Purpose: Complex SQL aggregations and filtered dataset builders
- Location: `app/queries/`
- Contains: `Approvals::PendingTasksQuery`, `Approvals::PendingRedemptionsQuery`
- Depends on: Models, scopes
- Used by: Controllers

**Controllers (HTTP/Request Layer):**
- Purpose: Handle HTTP requests, route to services, format responses (HTML/Turbo Stream)
- Location: `app/controllers/`
- Contains: Root `SessionsController` (profile selection), namespaced `parent/` and `kid/` controllers
- Depends on: Services, Models, authentication concern
- Used by: Rails routing

**ViewComponents (Reusable UI Layer):**
- Purpose: Render isolated, reusable UI components (cards, modals, buttons, avatars, badges)
- Location: `app/components/`
- Structure: 99 component files across 50 directories (form builders, UI atoms, composite widgets)
- Depends on: ERB templates, CSS (Tailwind)
- Used by: Views, layouts

**Views (Template Layer):**
- Purpose: Assemble ViewComponents and ERB to render page HTML
- Location: `app/views/`
- Contains: Dual namespaces `views/kid/` and `views/parent/`, shared layouts, shared partials
- Depends on: ViewComponents, helpers, Stimulus data attributes
- Used by: Controllers

**Layouts (Global Template):**
- Location: `app/views/layouts/`
- Contains: 
  - `kid.html.erb` — playful, mobile-first design with Lumi character, confetti
  - `parent.html.erb` — dashboard layout with sidebar, stats
  - `application.html.erb` — fallback for non-role-specific pages

## Data Flow

**Task Approval Flow:**

1. Child submits "Terminei!" on mission card (Kid::MissionsController#complete)
2. Controller marks `ProfileTask` status → `awaiting_approval`
3. ProfileTask broadcasts via `broadcast_approval_count` to family channel
4. Parent sees updated count in approval queue (real-time Turbo Stream)
5. Parent clicks "approve" → Parent::ApprovalsController#approve
6. `Tasks::ApproveService` wrapped in transaction:
   - Validates task is `awaiting_approval`
   - Updates `ProfileTask` status → `approved`
   - Increments `Profile.points`
   - Logs activity (`ActivityLog` record created)
7. Profile model broadcasts via `broadcast_points` to kid's notifications channel
8. Kid's wallet updates live (Turbo Stream), celebration animation fires

**Reward Redemption Flow:**

1. Child clicks reward card → Kid::RewardsController#redeem
2. `Rewards::RedeemService` called:
   - Locks profile row (pessimistic lock)
   - Validates points >= reward cost
   - Decrements `Profile.points`
   - Creates `Redemption` record with status `pending`
   - Logs activity (`ActivityLog` created with negative points)
3. Redemption broadcasts to parent approval queue
4. Parent approves/rejects via Parent::ApprovalsController#{approve,reject}_redemption
5. `Rewards::{ApproveRedemptionService,RejectRedemptionService}` updates redemption status ± returns points

**State Management:**

- **Profile Points:** Stored on `Profile.points` (integer), read from kid wallet views
- **Points History:** Append-only `ActivityLog` records (log_type: earn/redeem/adjust)
- **Task Status:** Enum on `ProfileTask` (pending → awaiting_approval → approved/rejected)
- **Redemption Status:** Enum on `Redemption` (pending → approved/rejected)
- **Real-time Broadcasts:** Turbo Streams sent via `Profile#broadcast_points` and `ProfileTask#broadcast_approval_count`

## Key Abstractions

**Service Result:**
- Purpose: Standardized return value for all service mutations
- Location: `app/services/application_service.rb`
- Definition: `Data.define(:success, :error, :data)` with `success?` predicate
- Usage: `result = SomeService.call(args); result.success? ? ok : handle_error`

**Profile (Dual-Role Model):**
- Purpose: Represents a family member (child or parent) with role-based access
- Enum: `:role` with values `{ child: 0, parent: 1 }`
- Key Fields: `points`, `name`, `avatar`, `color`, `family_id`
- Broadcasts: Auto-broadcasts point changes to kid's notification channel

**ProfileTask (Task Assignment):**
- Purpose: Many-to-many join of Profile ↔ GlobalTask with lifecycle status
- Status Enum: `{ pending: 0, awaiting_approval: 1, approved: 2, rejected: 3 }`
- Delegates: Reads `title`, `points`, `category`, `icon`, `description` from `GlobalTask`
- Broadcasts: Updates approval count and removes from kid dashboard on completion

**GlobalTask (Task Template):**
- Purpose: Parent-created task template assigned to multiple children
- Frequency: `:daily` or `:weekly`
- Category: `:escola`, `:casa`, `:rotina`, `:outro`
- Relationships: One-to-many with `ProfileTask`

**Authenticatable Concern:**
- Purpose: Authentication and authorization guards for role-specific routes
- Location: `app/controllers/concerns/authenticatable.rb`
- Methods: `require_login`, `require_parent!`, `require_child!`, `authorize_family!`
- Guards: Defense-in-depth checks for family ownership before mutations

## Entry Points

**Browser → Profile Selection:**
- Location: `app/controllers/sessions_controller.rb`
- Route: Root path `/`
- Triggers: Page load, logout
- Responsibilities: Render family profiles, set `session[:profile_id]`, redirect to role-specific dashboard

**Parent Dashboard:**
- Location: `app/controllers/parent/dashboard_controller.rb`
- Route: `/parent`
- Triggers: Parent login
- Responsibilities: Load family stats (children count, pending tasks, total stars), render dashboard

**Kid Dashboard:**
- Location: `app/controllers/kid/dashboard_controller.rb`
- Route: `/kid`
- Triggers: Child login
- Responsibilities: Load pending/awaiting/completed tasks, render mission cards, display balance

**Approval Queue:**
- Location: `app/controllers/parent/approvals_controller.rb`
- Route: `/parent/approvals`
- Triggers: Parent clicks "Aprovar" in sidebar
- Responsibilities: Query pending tasks + redemptions, handle approve/reject patches, broadcast updates

## Error Handling

**Strategy:** Transaction rollback + service-level error messages + controller-level error handling

**Patterns:**

1. **Service-level validation:**
   ```ruby
   # app/services/tasks/approve_service.rb
   unless @profile_task.awaiting_approval?
     return fail_with("Tarefa não está aguardando aprovação")
   end
   ```

2. **Transaction with rollback:**
   ```ruby
   ActiveRecord::Base.transaction do
     @profile.lock!  # Pessimistic lock
     raise ActiveRecord::Rollback if condition_fails
     # mutations
   end
   ```

3. **Controller error response:**
   ```ruby
   # Parent::ApprovalsController#approve
   result = Tasks::ApproveService.call(@profile_task)
   if result.success?
     # Turbo Stream response
   else
     redirect_to parent_approvals_path, alert: result.error
   end
   ```

4. **Application-level rescue:**
   - `ActiveRecord::RecordNotFound` → 404 response
   - `ActionController::ParameterMissing` → 400 response

## Cross-Cutting Concerns

**Logging:**
- Framework: `Rails.logger` via `ApplicationService` implementations
- Pattern: Services log entry/success/failure with relevant IDs
- Example: `[Tasks::ApproveService] success id=#{@profile_task.id}`

**Validation:**
- Model-level: ActiveRecord validators (presence, numericality, inclusion)
- Service-level: Business rule checks (awaiting_approval status, sufficient points)
- Controller-level: Authorization checks (role, family ownership)

**Authentication:**
- Session-based: `session[:profile_id]` set by SessionsController
- No password/auth provider in MVP (profile selection only)
- Concern: `Authenticatable` provides `current_profile` helper
- Guards: `require_login`, `require_parent!`, `require_child!`, `authorize_family!`

**Broadcasting/Real-time Updates:**
- Framework: Turbo Streams via `ActionCable` backed by Solid Cable (Postgres)
- Triggers: Model callbacks (`after_update_commit`, `after_commit`)
- Channels: Implicit via model (e.g., `broadcast_update_to self, "notifications"`)
- Usage: Kid's wallet updates live when parent approves; approval count updates for all parents

**Form Handling:**
- Framework: Rails form helpers + ViewComponent form builders
- Pattern: Standard Rails params, no API layer in MVP
- Responses: Turbo Stream (partial) or HTML redirect

**Styling:**
- Framework: Tailwind CSS 4.0 with `@tailwindcss/forms` and `@tailwindcss/typography`
- Build: Vite (`vite_rails` gem) compiles CSS at dev/build time
- Components: Tailwind tokens in ViewComponent classes (colors, spacing, sizing)

---

*Architecture analysis: 2026-04-21*
