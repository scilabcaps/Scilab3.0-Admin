# Plan

## Desired outcome

Upcoming Reservations shows only future reservations approved by both the professor and admin.

## Acceptance criteria

- A future reservation with pending professor approval does not appear in Upcoming.
- A future reservation with pending admin approval does not appear in Upcoming.
- A future reservation with both approvals set to `Approved` appears in Upcoming.
- Approval pages still show reservations awaiting admin approval.
- Ongoing and same-day reservation behavior remains unchanged.

## Impact and risks

- Affects Upcoming reservation query and count logic in `ongoing_reservation_service.dart`.
- May hide existing rows that were incorrectly visible before approval.
- No schema, navigation, or approval mutation changes needed.
- Existing unrelated working-tree changes must remain untouched.

## Approach

1. Add both approval filters to Upcoming fetch logic.
2. Keep existing date and active-status filters.
3. Make count logic use the same approval rules.
4. Add service-level tests or query-focused coverage if the project test setup supports mocking Supabase.
5. Run targeted tests, analyzer, and relevant UI QA.
