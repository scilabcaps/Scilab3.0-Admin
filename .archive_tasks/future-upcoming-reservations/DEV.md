# Development

## Decisions

- Implemented as a dedicated Upcoming Reservations mode using the shared reservation service/page with a future start-time predicate.
- Recommended semantic cutoff is the reservation start datetime, not merely the reservation date.

## Files changed

- Shared ongoing reservation service/controller/page, navigation model, and dashboard routing were updated.

## Progress and deviations

- Inspected the current service, controller, page, and model.
- Current implementation filters only `status = 'Ongoing'` and orders by newest creation time, so it does not enforce future-only behavior.
