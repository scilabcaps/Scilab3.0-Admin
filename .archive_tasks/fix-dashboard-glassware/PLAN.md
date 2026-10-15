# Plan

## Desired outcome

Dashboard Most Borrowed Items must show glassware whenever glassware assets exist, regardless of their stock ranking. Dashboard sections must reflect current backend data on each load without dashboard-specific stale caching.

## Acceptance criteria

- Asset results are not globally limited before Equipment and Glassware are categorized.
- The Glassware card receives matching `lab_assets` rows when present.
- Dashboard stats, courses, borrowed items, and recent activities do not read/write dashboard caches.
- Existing cache infrastructure and unrelated inventory caching remain unchanged.
- `dart format`, relevant tests, and `flutter analyze` are run and recorded.

## Impact and risks

Affected: dashboard service and its four dashboard data sections. Removing caching increases backend reads on dashboard loads; existing refresh and loading behavior remain unchanged. No schema or platform configuration changes.

## Approach

Remove dashboard cache reads/writes and the global `.limit(8)` from the lab-assets query. Keep category filtering in the existing controller/UI path.
