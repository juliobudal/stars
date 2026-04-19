# Directory Structure

The project follows standard Rails conventions with specific structural decisions for domain organization:

## `app/` Directory
- **`components/`**: Contains ViewComponents, namespaced into `kid/` and `parent/`. Used for modular UI elements.
- **`controllers/`**:
  - `kid/`: Controllers specifically catering to the child's interface (e.g., `MissionsController`, `WalletsController`).
  - `parent/`: Controllers catering to the parental management interface (e.g., `DashboardController`, `ApprovalsController`).
- **`javascript/controllers/`**: Stimulus controllers handling micro-interactions (e.g., `animated_counter_controller.js`, `celebration_controller.js`).
- **`models/`**: Core ActiveRecord objects (`Family`, `Profile`, `GlobalTask`, etc.).
- **`services/`**: Business logic classes organized by domain (`tasks/`, `rewards/`).
- **`views/`**: ERB templates following the structure of the controllers, including specific layouts `kid.html.erb` and `parent.html.erb`.

## Additional Important Directories
- **`spec/`**: Contains the RSpec test suite.
- **`.devcontainer/`**: Configurations for creating consistent development environments using VS Code/Cursor.
- **`config/`**: Routes and standard application settings.
