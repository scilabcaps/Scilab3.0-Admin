# Plan

## Desired outcome

## Acceptance criteria

## Impact and risks

## Approach
# PLAN

## Desired outcome

Add the same reservator details to Upcoming Reservations as Reservation History.

## Acceptance criteria

- Upcoming table shows Reservator name.
- Upcoming table shows Role.
- Upcoming table shows Reservation Source: `Self Reservation`, `Reserved by Admin`, or `Not recorded`.
- Existing reservation number, date, time, and resources remain visible.
- Ongoing table, filters, pagination, and details behavior remain unchanged.

## Impact

- Upcoming reservation model/service/page: add creator metadata and columns.
- Database data is read only; no schema or reservation mutation changes.

## Approach

Fetch `created_by` and creator role for the current page, classify source, store it on `OngoingReservation`, and render upcoming-only columns.
