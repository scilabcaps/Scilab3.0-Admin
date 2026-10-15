# QA

## Evidence

- The supplied screenshot shows future reservations dated October 5, October 6, and October 16 listed as Ongoing.
- Current Ongoing query uses only `status = 'Ongoing'` and does not filter by start/end datetime.

## Outcome and gaps

- Verified navigation had been reusing the Ongoing page state for Upcoming. Distinct widget keys now force the correct mode to initialize when switching.
- `git diff --check` passed. Analyzer and Windows runtime QA remain unverified because Flutter tooling stalled without output.
- Implementation is complete. Windows runtime QA was attempted with `flutter run -d windows`, but Flutter produced no output and no app window appeared before the process was interrupted.
