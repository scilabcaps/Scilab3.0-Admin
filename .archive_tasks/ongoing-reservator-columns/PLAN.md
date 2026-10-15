# Plan

## Desired outcome

## Acceptance criteria

## Impact and risks

## Approach
# PLAN

## Desired outcome

Show the same reservator identity fields in Ongoing Reservations as in Upcoming Reservations.

## Acceptance criteria

- Ongoing table shows Reservator, Role, and Reservation Source.
- Source values are `Self Reservation`, `Reserved by Admin`, or `Not recorded`.
- Existing program/year, professor, date, time, status, and actions remain.
- Ongoing data loading and return actions remain unchanged.

## Impact

- `lib/features/reservations/ongoing_reservation/pages/ongoing_reservation_page.dart`: ongoing table columns only.
- Model/service already contain the required creator metadata from the preceding Upcoming change.

## Approach

Reuse existing role and source badge builders. Add the fields to the ongoing header and row.
