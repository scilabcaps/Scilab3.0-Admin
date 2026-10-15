# Development

## Decisions

- Only retry the exception raised by `flutter_dotenv` when `rootBundle.loadString` fails.
- Keep `.env` required; do not initialize Supabase with empty configuration.

## Files changed

- `lib/main.dart`
- `lib/core/config/environment_loader.dart`
- `test/core/environment_loader_test.dart`

## Progress and deviations

- Inspected project asset declarations, packaged Windows assets, and package source.
- Reproduced a successful initial launch and two successful hot restarts; the reported failure did not recur locally.
- Added three-attempt retry with 200 ms between attempts for `FileNotFoundError` only. Kept the `.env` asset required.
