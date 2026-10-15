# Plan

## Desired outcome

Make colored status, role, and creator badges use only the width needed by their labels in every affected table.

## Acceptance criteria

- Badge tint ends after the label and its horizontal padding.
- The badge is left aligned within its table column.
- Existing colors, text, and table column widths remain unchanged.

## Impact and risks

- Reservation History, Ongoing/Upcoming, Student Reservations, Professor Reservations, and the inventory report table use the same expanded-cell pattern.

## Approach

Wrap each affected badge container in left alignment so its child receives loose width constraints.
