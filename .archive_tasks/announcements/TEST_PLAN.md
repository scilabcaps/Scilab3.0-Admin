# Test plan

## Cases and expected results

- Navigation contains Announcements under Room & Resources.
- Announcement model parses Supabase rows and formats optional dates safely.
- Static analysis and Flutter tests pass.
- Manual UI verification covers loading, empty, error, populated, and add form validation states.

## Coverage gaps

Live Supabase persistence and RLS behavior require the configured app environment.
