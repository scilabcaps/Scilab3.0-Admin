# Development

## Decisions

- Use the existing `_handleLogin` callback for both the button and Enter submission so behavior cannot diverge.
- Scope Enter submission to the password field, where the user has completed the credentials.

## Files changed

- `lib/features/auth/pages/login_screen.dart`
- `test/features/auth/login_screen_test.dart`

## Progress and deviations

- Added the password field's Done/Enter submission callback and focused widget test.
- Preserved the pre-existing `DLSP` text change and unrelated working-tree edits.
- No implementation deviation from the plan.
