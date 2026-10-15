# Plan

## Desired outcome

## Acceptance criteria

## Impact and risks

## Approach
# PLAN

## Desired outcome

Fix dashboard Recent Activities card shown beside the taller Reservation Status card. Make both cards align cleanly and give the recent-activity empty state a clear message.

## Acceptance criteria

- Recent Activities card stretches to the height of its adjacent card row.
- Existing activity data, icons, descriptions, and timestamps remain unchanged.
- Empty activity data shows `No recent activities` instead of a blank card.
- Dashboard layout remains stable at current desktop width.

## Impact

- `lib/features/dashboard/pages/dashboard_page.dart`: dashboard row alignment and Recent Activities empty state only.
- Dashboard service and models: no changes.

## Approach

Use row stretch alignment so the two cards share the row height. Add a compact empty state for zero activities.
