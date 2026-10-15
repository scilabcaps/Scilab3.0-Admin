# Plan

## Desired outcome

Upcoming and Ongoing Reservations tables both expose a clearly labeled View Details action for every reservation row.

## Acceptance criteria

- Upcoming Reservations has an Actions column with a View Details button.
- Clicking the Upcoming button opens the existing reservation details dialog.
- Ongoing Reservations keeps its existing View Details button and details behavior, including Return Items in the dialog.
- Button styling and sizing match the existing Ongoing action button.

## Impact and risks

- Affects the shared Upcoming/Ongoing reservation page table layout only.
- No reservation data, routing, or return workflow changes are needed.
- The working tree contains existing reservation changes; only the missing Upcoming action is added.

## Approach

Add an Actions header and a View Details cell to the Upcoming table, wired to `_showUpcomingDetails`. Preserve the existing Ongoing action implementation.
