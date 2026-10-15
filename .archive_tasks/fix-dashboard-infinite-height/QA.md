# QA

## Evidence

- The reported assertion identifies the row at `dashboard_page.dart:73`; the row was requesting stretched height inside `SingleChildScrollView`.
- The row now uses content-sized vertical alignment.
- `flutter build windows` passed and produced `build/windows/x64/runner/Release/admin_scalib.exe`.
- Targeted analysis completed with only existing warnings/deprecations in the dashboard file.
- The new loaded-dashboard widget test passed at 1920×1080 with two courses and a recent activity, with no Flutter layout exception.
- The second user trace explicitly reports `crossAxisAlignment: stretch`, while the current source at the reported row uses `start`; that trace reflects the old layout.
- `flutter build windows --debug` passed after the regression test and testability change.
- `dart analyze test/features/dashboard/dashboard_page_test.dart` passed with no issues.

## Outcome and gaps

- The infinite-height constraint request is removed at its source.
- Live interaction in the Windows dashboard was not performed in this turn; backend data loading and the build remain verified.
- The widget test confirms the loaded page layout but does not prove which source revision the user's running process loaded.
