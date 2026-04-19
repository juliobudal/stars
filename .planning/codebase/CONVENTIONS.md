# Coding Conventions

## Ruby & Rails
- **Style Guide**: Strict adherence to standard formatting (`.standard.yml`).
- **Business Logic**: Never in controllers or views. Use Service Objects inside `app/services/` that return success/failure constructs (e.g., `OpenStruct`) and handle `ActiveRecord::Base.transaction`.
- **Database Logic**: Complex queries should be implemented as scopes within Models.

## Frontend
- **UI Components**: Prefer `ViewComponent` and the `JetRockets UI` library over generic view helpers for reusable UI pieces.
- **CSS**: Use TailwindCSS utility classes directly.
- **Interactivity**: 
  - Use `Turbo Frames` for lazy loading or targeted DOM replacements.
  - Use `Turbo Streams` for real-time reactivity without fully reloading pages.
  - Use `Stimulus` for cosmetic DOM modifications (confetti, dynamic counters). No heavy JS frameworks.

## Data & Associations
- Strict use of Foreign Keys.
- Required columns must include `null: false` migrations and basic validations.
- Use PostgreSQL enums or simple integer enums for state properties (e.g., `status`, `role`).
