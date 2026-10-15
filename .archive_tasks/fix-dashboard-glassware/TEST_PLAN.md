# Test plan

## Cases and expected results

- Run existing Flutter tests to catch regressions in shared models and controllers.
- Format changed Dart code and run `flutter analyze`.
- Inspect the dashboard service to verify no dashboard cache access and no global asset limit remain.

## Coverage gaps

Live Supabase data and Windows runtime UI require manual environment verification.

Results: `dart format lib/features/dashboard/services/dashboard_service.dart` completed. `flutter test`, `flutter analyze`, and `dart analyze` did not emit output or complete normally in this environment; they were stopped after hanging. `git diff --check` is still pending.
