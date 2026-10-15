# Plan

## Desired outcome

Pressing Enter while focused on the login password field submits the login form using the same handler as the `LOG IN` button.

## Acceptance criteria

- The password field uses the Done/Enter action and invokes the existing `_handleLogin` handler.
- Existing form validation, loading behavior, error handling, and navigation remain unchanged.
- A widget test verifies that submitting the password field with Enter triggers form validation.

## Impact and risks

- Affects `lib/features/auth/pages/login_screen.dart` and its focused widget test coverage.
- No auth service, route, or platform configuration changes are needed.
- The working tree already contains unrelated user changes; they must remain untouched.

## Approach

Add `textInputAction: TextInputAction.done` and `onFieldSubmitted` to the password field, pointing to `_handleLogin`, then verify with Flutter tests and analysis.
