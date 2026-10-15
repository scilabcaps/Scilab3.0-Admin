# Plan

## Desired outcome

## Acceptance criteria

## Impact and risks

## Approach
# PLAN

## Desired outcome

Create one reusable Reservation Details dialog matching the professor-side visual reference and use it for view-only reservation buttons.

## Acceptance criteria

- Shared dialog shows Reservation ID, Date, Time, Status, and Resources.
- Dialog uses green header, summary cards, resource cards, close button, and responsive layout.
- All reservation view buttons open the shared dialog.
- Existing data remains unchanged.
- Approval, return, and PDF export actions remain available from the shared dialog.

## Impact

- New shared dialog widget.
- Professor, Student, and Upcoming reservation page view handlers.
- Approval and return modal files remain available for action workflows.

## Approach

Normalize each page's existing reservation data into shared dialog fields. Parse newline resource strings into reusable resource cards.
