# Architecture

## High-Level Architecture
LittleStars follows a standard monolithic Ruby on Rails MVC pattern augmented with modern SPA-like capabilities using Hotwire (Turbo + Stimulus) and encapsulating business rules in Service Objects.

## Layers
1. **Routing & Controllers**: 
   - Root `SessionsController` for profile selection (auth).
   - Namespaced controllers for distinct roles: `Parent::` and `Kid::`.
2. **Business Logic (Services)**:
   - Extracted into Service Objects (`app/services/`) to encapsulate complex or transactional logic (e.g., `ApproveService`, `RedeemService`, `DailyResetService`).
3. **Views & UI**:
   - Leverages `ViewComponent` and ERB.
   - `Turbo Frames` are used for partial updates (e.g., wallet balances, approval lists).
   - `Turbo Streams` are used for real-time broadcasts (e.g., updating a child's wallet when a parent approves a task).
4. **Data Access (Models)**:
   - ActiveRecord manages associations and database interactions. Core entities include `Family`, `Profile`, `GlobalTask`, `ProfileTask`, `Reward`, and `ActivityLog`.

## State Management
- Session-based profile selection sets the current context (`session[:profile_id]`).
- Real-time updates rely on `Turbo::StreamsChannel.broadcast_update_to`.
