# Test plan

## Cases and expected results

- Open Add Announcement: redesigned modal appears.
- Submit blank title/message: validation prevents save.
- Edit: fields are prefilled and save updates the row.
- Delete: confirmation appears; confirm removes the row.
- Cancel/close: no data changes.

## Coverage gaps

Live Supabase RLS and desktop runtime require the Flutter toolchain and configured backend.
