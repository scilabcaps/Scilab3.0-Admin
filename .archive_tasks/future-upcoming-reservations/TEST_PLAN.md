# Test plan

## Cases and expected results

- Yesterday at any time: excluded.
- Today before the current time: excluded.
- Today after the current time: included.
- Tomorrow or later: included.
- Exactly at the current cutoff: excluded to avoid showing a reservation as upcoming once it starts.
- Count and pagination: match the same future-only result set.
- Results: sorted soonest first.

## Coverage gaps

- Manual Windows verification requires the configured Supabase environment and current clock/time zone.
