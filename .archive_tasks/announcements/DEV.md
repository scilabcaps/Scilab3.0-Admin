# Development

## Decisions

- Use the existing `public.announcement` schema from `database/db.sql`.
- Use `SupabaseService.auth.currentUser?.id` for `created_by`.

## Files changed

- `lib/core/api/supabase_config.dart`
- `lib/core/models/navigation_item.dart`
- `lib/features/dashboard/pages/dashboard_screen.dart`
- `lib/features/room_and_resources/announcements/{models,controllers,pages}/`
- `test/core/navigation_item_test.dart`
- `test/features/announcements/announcement_model_test.dart`

## Progress and deviations

Implemented Supabase listing and insert flows, validation, empty/loading/error states, and navigation routing. Existing unrelated working-tree changes were preserved.
