# Plan

## Desired outcome

An intermittent `.env` asset read failure during Windows hot restart should not terminate startup.

## Acceptance criteria

- Startup retries `FileNotFoundError` from the bundled `.env` asset a small, bounded number of times.
- Other errors propagate immediately; a persistently missing `.env` still fails clearly.
- The existing Supabase initialization continues after a successful load.
- No environment values are logged, committed, or embedded differently.

## Impact and risks

- Affects startup in `lib/main.dart` and a small loader helper; login and dashboard initialization depend on this path.
- The project and built Windows debug bundle both contain `.env`, and initial launch works. Two local hot restarts also worked, so the failure is intermittent and its exact trigger remains unconfirmed.
- Retrying a truly missing asset delays its error briefly. Existing unrelated working-tree edits must be preserved.

## Approach

Wrap the existing dotenv load with a bounded retry for `FileNotFoundError`, keep the asset declaration unchanged, and test transient and persistent failure paths without reading credential values.
