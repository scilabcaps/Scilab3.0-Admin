# Plan

## Desired outcome

Make the existing Ongoing Reservations view show only reservations whose scheduled start is in the future, so it functions as an Upcoming Reservations view rather than displaying past or currently active records.

## Proposed definition

- A reservation is upcoming when `reservation_date` is after today.
- A reservation scheduled for today is upcoming only when its `start_time` is later than the current local time.
- Reservations whose start time has arrived or passed are excluded, even if their database status is still `Ongoing`.
- The end time is not used to classify a reservation as upcoming; it is based on when the reservation starts.

## Acceptance criteria

- The database query or service filtering excludes all reservations with a start date/time at or before the current moment.
- Future reservations are sorted chronologically by reservation date, then start time, with the soonest first.
- Pagination and total counts use the same future-only filter, so page counts match displayed data.
- Refresh recomputes the cutoff using the current time.
- Existing return/completion actions remain available for reservations that are still shown.
- Empty state copy explains that there are no upcoming reservations.
- The page title and navigation label are reviewed; if this view is now strictly future-only, rename visible UI from `Ongoing Reservations` to `Upcoming Reservations` or document why the existing label is retained.

## Impact and risks

- Primary files: `ongoing_reservation_service.dart`, `ongoing_reservation_controller.dart`, and `ongoing_reservation_page.dart`.
- Tests: add service/controller coverage for yesterday, today-before-start, today-after-start, and tomorrow cases; verify pagination/count consistency.
- The current service filters only `status = 'Ongoing'`, so future admin-created reservations are included only if their status remains Ongoing. Status eligibility must be confirmed before implementation; recommended scope is to preserve the existing status filter and add the future start cutoff.
- Time-zone handling is a risk because the database stores a date and time separately. Convert the local cutoff into the same comparison basis used by the app/database, and avoid comparing date strings lexicographically without normalization.

## Approach

1. Add a single start-date/time comparison helper using the app’s local date/time semantics.
2. Apply the future predicate to fetched rows and the count query, or express an equivalent server-side filter where safe.
3. Order by `reservation_date` ascending and `start_time` ascending.
4. Update the empty state/title wording if the view is renamed.
5. Add focused tests and run Windows QA with `flutter run -d windows`.
