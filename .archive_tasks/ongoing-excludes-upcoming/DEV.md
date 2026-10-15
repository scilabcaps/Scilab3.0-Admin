# Development

## Decisions

- Implemented complementary active-interval filtering in the shared service so future and ended reservations are excluded.
- Ongoing and Upcoming are complementary time-based views and must not overlap.

## Files changed

- Shared ongoing reservation service/controller/page, navigation model, and dashboard routing were updated together with the Upcoming task.

## Progress and deviations

- Screenshot inspection confirms future dates such as 2026-10-05, 2026-10-06, and 2026-10-16 currently appear in Ongoing Reservations.
- Current service filters only `status = 'Ongoing'`, which explains the overlap.
