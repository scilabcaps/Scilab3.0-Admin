# Plan

## Desired outcome

Add an Announcements page under Room & Resources that reads from and creates records in the Supabase `announcement` table.

## Acceptance criteria

- Room & Resources contains an Announcements submenu item.
- The page lists announcements from `announcement`, newest first, including title, content, publish date, and status.
- An Add Announcement action validates title/content and inserts a published announcement using the signed-in user's id as `created_by`.
- Loading, empty, error, and successful-save states are visible and recoverable.
- Existing navigation and neighboring pages remain unchanged.

## Impact and risks

Affected navigation, dashboard content routing, and new announcement feature files. Supabase insert requires an authenticated user and table RLS policies permitting the operation; runtime verification depends on the configured environment.

## Approach

Follow the existing feature/controller/page patterns, add the table constant, create a typed model and controller, then add widget tests for navigation and model parsing where practical.
