# QA

## Evidence

- Source inspection showed the reservation query fetched `course` but the mapping displayed only `year_section`.
- The Windows app built and launched with `flutter run -d windows`; Supabase initialization completed. The available computer interface did not expose the native window for visual inspection.
- A read-only Supabase aggregate found three current/future active-status reservations with both saved course and year/section populated.
- `git diff --check` passed. Focused analyzer reported four existing `avoid_print` information notices and no errors.

## Outcome and gaps

- Build and startup verified. Visual verification of the table cell remains pending because the native app window was not exposed to the inspection tool.
