# PLAN

## Desired outcome

Make dashboard Top Courses by Reservations bar chart readable and modern using the attached screenshot as the problem reference.

## Acceptance criteria

- Small reservation counts use a compact dynamic Y-axis instead of wasting most chart height.
- Header shows the actual total reservation count.
- Grid lines and axis labels are subtle but readable.
- Course labels support longer names without clipping the chart.
- Bars remain interactive with existing tooltips.
- Course data and loading behavior remain unchanged.

## Impact

- `lib/features/dashboard/pages/dashboard_page.dart`: bar chart presentation only.
- Dashboard service, model, pie chart, and navigation: no changes expected.

## Approach

Use dynamic five-step Y-axis scaling, stronger bar geometry, improved spacing, readable axis typography, and a real total count in the chart header.
