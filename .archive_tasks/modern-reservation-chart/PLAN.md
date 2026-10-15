# Plan

## Desired outcome

## Acceptance criteria

## Impact and risks

## Approach
# PLAN

## Desired outcome

Modernize dashboard Reservation Status donut chart. Keep existing reservation counts and status colors. Remove overlapping labels from chart slices. Show total in donut center and readable legend rows with count and percentage.

## Acceptance criteria

- Chart labels never overlap or render inside slices.
- Approved, Pending, and Rejected counts remain accurate and visible.
- Zero-value statuses do not create fake chart slices; all-zero data shows a neutral empty ring.
- Existing dashboard data loading and layout remain unchanged outside this chart.
- UI remains readable on the current desktop dashboard width.

## Impact

- `lib/features/dashboard/pages/dashboard_page.dart`: chart presentation only.
- Dashboard model, service, navigation, and database queries: no changes expected.

## Risks and approach

Use existing `fl_chart` dependency. Render a clean donut with no slice text, center total, and a compact legend. Add semantics label for the chart. Verify with format, analyze, tests, and Windows runtime QA if available.
