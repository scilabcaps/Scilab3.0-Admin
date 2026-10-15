# Plan

## Desired outcome

## Acceptance criteria

## Impact and risks

## Approach
# PLAN

## Desired outcome

Classify reservations with missing creator metadata as self reservations.

## Acceptance criteria

- Missing creator metadata displays `Self Reservation` in History, Upcoming, and Ongoing.
- Admin-created reservations still display `Reserved by Admin`.
- Existing recorded self reservations remain `Self Reservation`.
- No reservation data is mutated.

## Impact

- Reservation history and ongoing reservation source classification only.

## Approach

Use the reservator as the fallback creator name in history and classify a missing creator record as self-submitted.
