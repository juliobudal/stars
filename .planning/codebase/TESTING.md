# Testing

## Framework and Tools
- **Test Framework**: `rspec-rails`
- **Data Generation**: `factory_bot_rails` + `faker`
- **Browser/E2E**: `capybara` + `selenium-webdriver`
- **Matchers**: `shoulda-matchers`

## Strategy and Coverage
The testing strategy covers multiple dimensions to ensure data integrity and workflow stability:
- **Model Specs**: Focus on validations, scopes, enums, and database associations.
- **Service Specs**: Crucial for testing atomic transactions, edge cases, racing conditions, and ensuring that balance logic never drifts negative.
- **Request Specs**: Focus on endpoints, JSON/HTML responses, and basic authorization boundaries (e.g., separating parent from child roles).
- **System Specs**: Full-flow E2E tests simulating interactions like creating a task, assigning it, submitting it, and verifying its approval via Capybara.

## Critical Test Paths
- Service Object limits and Rollbacks (e.g., concurrent redeem requests preventing negative wallet balances).
- Request Spec authorization restrictions maintaining routing walls between `Parent::` and `Kid::` namespaces.
