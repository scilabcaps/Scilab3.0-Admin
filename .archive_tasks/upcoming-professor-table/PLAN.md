# Plan

## Desired outcome

## Acceptance criteria

## Impact and risks

## Approach
# PLAN

## Desired outcome

Make admin Upcoming Reservations table match the attached professor-style table. Upcoming rows should show Reservation #, Date, Time, and Resources with a dark green header and readable multi-line resource cells.

## Acceptance criteria

- Upcoming table header has exactly: Reservation #, Date, Time, Resources.
- Header uses dark green background and white readable text.
- Reservation rows show reservation ID, date, time, and each resource on its own line.
- Empty resources show a clear fallback.
- Search, pagination, details action, ongoing table, and reservation data loading remain unchanged.

## Impact

- `lib/features/reservations/ongoing_reservation/pages/ongoing_reservation_page.dart`: Upcoming table presentation only.
- Ongoing reservation model/service: read existing `reservationId`, `date`, `time`, and `items`; no data changes.

## Approach

Branch table header and row rendering on `widget.upcoming`. Preserve existing ongoing table implementation.
