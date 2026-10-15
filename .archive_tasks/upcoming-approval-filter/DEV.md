# Development

## Decisions

- Plan only. No production code changed.
- Require `professor_approval == Approved` and `admin_approval == Approved` for Upcoming.

## Files changed

- Task notes only.

## Progress and deviations

- Initial inspection found Upcoming currently accepts `Pending`, `Approved`, and `Ongoing` status values without checking either approval column.
