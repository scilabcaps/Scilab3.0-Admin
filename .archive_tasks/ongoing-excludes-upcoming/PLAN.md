# Plan

## Desired outcome

Prevent future-start reservations from appearing in Ongoing Reservations. Future reservations should appear only in the Upcoming Reservations view; Ongoing Reservations should represent reservations that have started and are still active.

## Proposed definition

- Ongoing: the reservation start datetime is at or before the current time, the reservation end datetime is after the current time, and the database status is active (`Ongoing`).
- Upcoming: the reservation start datetime is after the current time; it must not appear in Ongoing Reservations.
- Completed, Cancelled, Declined, and Unreturned records remain excluded from Ongoing Reservations according to the existing status rules.
- A reservation that has passed its end time should not remain in the active Ongoing list even if its database status is stale.

## Acceptance criteria

- A reservation dated tomorrow or later is excluded from Ongoing Reservations.
- A reservation later today, before its start time, is excluded from Ongoing Reservations.
- A reservation currently in progress is included when its status is `Ongoing`.
- A reservation whose end time has passed is excluded from Ongoing Reservations.
- The Ongoing count, pagination, stats cards, search, and role filters use the same active-time-filtered dataset.
- The Upcoming view owns future-start reservations and lists them chronologically.
- Existing return/detail actions remain available for reservations that are currently active.

## Impact and risks

- Primary files: `lib/features/reservations/ongoing_reservation/services/ongoing_reservation_service.dart`, its count query, controller, and page labels/empty state.
- Related dependency: the future-only Upcoming Reservations task in `.tasks/future-upcoming-reservations/` should use the complementary future predicate so records do not overlap.
- Time-zone handling is important because reservations store separate `date` and `time` values; use one consistent local-time comparison helper.
- Database status may be stale, so both status and start/end datetime need to be considered.

## Approach

1. Build a shared reservation start/end datetime comparison helper for the Ongoing service.
2. Apply `status = 'Ongoing'` plus the active interval predicate to fetch and count queries/results.
3. Sort active rows by nearest start/date as appropriate for operational use.
4. Update visible wording from any misleading “ongoing” counts/empty states only where needed, without changing the existing navigation label unless separately approved.
5. Add boundary tests for yesterday, future today, currently active, and ended reservations.
6. Verify the Windows UI with `flutter run -d windows` using the records shown in the supplied screenshot as a regression scenario.
