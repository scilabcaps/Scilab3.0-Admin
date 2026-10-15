# Plan

## Desired outcome

## Acceptance criteria

## Impact and risks

## Approach
# PLAN

## Desired outcome

Make Reservation History clearly show who made each reservation and how it was created.

## Acceptance criteria

- Table shows reservator name.
- Table shows reservator role.
- Table shows explicit Reservation Source values: `Self Reservation`, `Reserved by Admin`, or `Not recorded`.
- Existing reservation type data remains available in receipts and exports.
- Search, filters, pagination, status, and receipt actions remain unchanged.

## Impact

- `lib/features/reservations/reservations_history/pages/reservations_history_page.dart`: table labels and source badge text.
- Existing model/service already provide `userName`, `role`, `createdByName`, and `createdByType`; no query changes needed.

## Approach

Rename `Full Name` to `Reservator`, rename `Created By` to `Reservation Source`, remove the ambiguous `Type` table column, and make source values explicit.
