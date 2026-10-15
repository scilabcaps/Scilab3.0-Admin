# Test plan

## Cases and expected results

- Future reservation with status Ongoing: excluded from Ongoing and included in Upcoming.
- Today before start time: excluded from Ongoing and included in Upcoming.
- Current time between start and end: included in Ongoing only.
- End time passed: excluded from Ongoing.
- Counts and pagination match the filtered result set.

## Coverage gaps

- Live Supabase and Windows runtime verification require the configured environment.
