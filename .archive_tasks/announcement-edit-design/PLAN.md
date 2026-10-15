# Plan

## Desired outcome

Improve the announcement add/edit dialog and add per-announcement Edit and Delete actions.

## Acceptance criteria

- Dialog has clear visual hierarchy, accessible labels, close/cancel actions, and distinct publish/save actions.
- Each announcement exposes a vertical overflow menu with Edit and Delete.
- Edit updates the existing Supabase `announcement` row.
- Delete requires confirmation and removes the row from Supabase and the visible list.

## Impact and risks

Announcement page and controller only. Delete behavior depends on Supabase RLS permissions.

## Approach

Preserve the existing green application identity while improving spacing, field styling, and action hierarchy. Reuse the existing announcement model and table.
