# QA

## Evidence

- Current query uses `status = 'Ongoing'` and `created_at desc`; it does not filter by reservation start date/time.
- Current page is labeled `Ongoing Reservations` and includes return-oriented actions.

## Outcome and gaps

- Found and fixed Flutter state reuse between the two sidebar destinations by giving each page mode a distinct key. Upcoming rows now display `Upcoming` rather than the hard-coded `Ongoing` status.
- `git diff --check` passed. `flutter analyze --no-pub` produced no output within 60 seconds and was interrupted, so analyzer and Windows runtime QA remain unverified.
- Implementation is complete. Windows runtime QA was attempted with `flutter run -d windows`, but Flutter produced no output and no app window appeared before the process was interrupted.
