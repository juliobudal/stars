# Concerns and Focus Areas

## Authorization and Security
- **Role Isolation**: The architecture cleanly attempts to split features into `Parent::` and `Kid::` namespaces. We must ensure the `Authenticatable` module properly intercepts and redirects unauthorized requests to prevent a clever child from approving their own tasks.
- **Session Handling**: MVP simplifies authentication into picking a profile without true passwords. This must accurately map `session[:profile_id]` to `current_profile`.

## Complex UI State & Real-time Delivery
- **Turbo Stream Reliability**: Ensuring that broadcast events (e.g., `Turbo::StreamsChannel.broadcast_update_to`) trigger precisely when expected for real-time wallet update upon parent approval, sidestepping manual WebSocket implementation complexities.

## Ongoing Work / Technical Debt
- **Test Alignment**: The most recent work was focused on resolving `SessionsController` failures and ensuring `Authenticatable` acts as expected across different namespaces. Ensuring Request and System specs stay parallel with development flow.
