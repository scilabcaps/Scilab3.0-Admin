# Development

## Decisions

- Reuse the existing `ReservationDetailsDialog` and button styling.
- Keep the Ongoing action unchanged because it already opens details and exposes Return Items.

## Files changed

- `lib/features/reservations/ongoing_reservation/pages/ongoing_reservation_page.dart`

## Progress and deviations

- Added an Actions header and View Details button to Upcoming reservation rows.
- Wired the new button to the existing `_showUpcomingDetails` dialog.
- Confirmed the existing Ongoing View Details action remains wired to `_showOngoingDetails`.
