# Plan

## Desired outcome

Show a student's course/program and year/section together in the Program & Year column on Ongoing and Upcoming Reservations.

## Acceptance criteria

- A student with course `BS Chemistry` and year/section `1B` shows `BS Chemistry · 1B`.
- If a reservation snapshot lacks either field, use the corresponding account profile value when available.
- If only one value exists, show that value without an extra separator.
- Professor rows remain blank as before.

## Impact and risks

- The shared ongoing/upcoming reservation service maps the column and details modal field. Querying two more profile fields is the only data impact.

## Approach

Combine the existing reservation course and year/section values, using profile values only as fallbacks.
