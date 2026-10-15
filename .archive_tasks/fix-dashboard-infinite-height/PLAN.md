# Plan

## Desired outcome

Opening the dashboard should render without the `BoxConstraints forces an infinite height` assertion.

## Acceptance criteria

- The dashboard’s chart/activity row no longer requests an unbounded height inside the vertical scroll view.
- Existing dashboard content and the recent chart/pie/activity changes remain intact.
- Relevant analysis and tests pass, with any unrelated existing failures recorded.

## Impact and risks

- Affects the layout alignment of the dashboard’s pie-chart and recent-activities row.
- The fix is limited to the row constraint behavior; data loading and chart calculations are unchanged.
- The working tree contains unrelated user changes that must remain untouched.

## Approach

Use the row’s content-sized cross-axis alignment (`CrossAxisAlignment.start`) instead of stretching children against the scroll view’s unbounded height, then verify with targeted analysis/tests and a Windows build.
