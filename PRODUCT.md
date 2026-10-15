# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Laboratory administrators managing reservations, users, rooms, chemicals, equipment, glassware, and inventory records.

## Product Purpose

Scilab Admin centralizes laboratory administration. Success means administrators can review reservations and maintain accurate resource records without losing approval or inventory context.

## Operating Context

The Flutter application targets desktop administration and retains mobile platform support. Workflows include reservation approval, schedule monitoring, inventory editing, reporting, and audit logging backed by Supabase.

## Capabilities and Constraints

- Preserve existing Flutter navigation, Supabase schema, green visual identity, and desktop-oriented admin workflows.
- Chemical expiration is recorded and displayed but must not be editable from the inventory edit modal.
- Existing reservation-details presentation is the visual reference for inventory modal refinement.
- Do not expose credentials or alter production data during verification.

## Evidence on Hand

- Existing Flutter implementation under `lib/`.
- Shared reservation-details dialog under `lib/features/reservations/shared/`.
- Current inventory edit dialog under `lib/features/room_and_resources/inventory/pages/`.

## Product Principles

- Protect authoritative inventory data from unintended edits.
- Make administrative actions clear before submission.
- Keep related detail and edit experiences visually consistent.
- Preserve accessible labels, keyboard operation, and responsive layout.

## Accessibility & Inclusion

Controls must provide clear labels, visible focus behavior, readable contrast, keyboard access, and layouts that tolerate text scaling.
