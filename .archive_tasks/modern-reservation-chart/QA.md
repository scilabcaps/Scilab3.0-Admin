# QA

## Evidence

## Outcome and gaps
# QA

- Current desktop screenshot defect addressed in source: no slice labels; legend now carries all text.
- Populated state: donut center shows total; legend shows Approved, Pending, Rejected counts and percentages.
- Zero status: omitted from donut geometry but remains visible in legend as `0` and `0%`.
- All-zero state: neutral empty ring renders; center shows `0`.
- Windows `flutter run -d windows`: build and app launch succeeded.
- Runtime screenshot inspection not completed. Current CUA session exposed browser APIs only, so native Flutter window could not be captured.
