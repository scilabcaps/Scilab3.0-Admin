# Test plan

## Cases and expected results

- A loader that fails once with `FileNotFoundError` then succeeds is retried and completes.
- A loader that always raises `FileNotFoundError` fails after the bounded number of attempts.
- A non-asset error propagates without retry.
- The real `.env` asset remains listed in `pubspec.yaml` and present in the Windows debug asset bundle.
- Targeted tests, analysis, and a Windows debug build complete.

## Coverage gaps

- The intermittent Windows asset read failure could not be reproduced on demand; live retry behavior will be inferred from the deterministic test.
