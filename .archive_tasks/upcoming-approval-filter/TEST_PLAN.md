# Test plan

## Cases and expected results

- Future reservation, professor pending, admin pending: excluded.
- Future reservation, professor approved, admin pending: excluded.
- Future reservation, professor approved, admin approved: included.
- Same-day reservation: existing Ongoing behavior unchanged.
- Approval-list query: admin-pending reservations remain visible for review.
- Pagination count matches filtered Upcoming rows.

## Coverage gaps

- Current repository has no tests for the Upcoming Supabase query.
- Runtime verification needs a working Flutter build and connected test data or a mock Supabase client.
