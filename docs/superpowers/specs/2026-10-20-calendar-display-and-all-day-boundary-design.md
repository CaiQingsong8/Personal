# Calendar Display and All-Day Boundary Design

> Approved by the user on 2026-10-20.

## Goals

- Stop a single all-day checklist task from appearing to extend into the next day after export to Mac Calendar.
- Keep holiday calendar items visible in the month grid at all times.
- Let the existing “Mac 日历” control show or hide ordinary Mac Calendar items.
- Avoid showing a checklist task twice when its linked Calendar event is also loaded into the month grid; the checklist representation takes precedence.

## Design

### Event date boundaries

For an all-day task, set the event start to the task's local start of day and set the end to the local start of the day after its all-day span. The end is an exclusive boundary, so do not subtract one second. Preserve the existing timed-event start and duration behavior. When importing all-day events, continue deriving the inclusive number of calendar days from the exclusive end.

### Calendar presentation

Classify holiday events from holiday calendar names using localized holiday terms (for example, “节日”, “假日”, “节假日”, and “holiday”). Holidays render regardless of the Mac Calendar visibility toggle. Ordinary calendar items follow the toggle. A checklist-linked event is filtered from Calendar presentation so the checklist item is the only displayed copy.

Match checklist links by task UUID in the `deskflow://task/<UUID>` URL first, then by EventKit event identifier. Use a matching external identifier only when it identifies one event within the same calendar; recurring or otherwise ambiguous external identifiers must not hide unrelated occurrences. Do not deduplicate by title or date.

### Loading and failure behavior

Load the selected month's calendar events even when ordinary Calendar items are hidden, because holiday items remain visible. If calendar access is unavailable, preserve the current empty-calendar behavior. Classification and deduplication affect only month-grid presentation; they do not delete, rewrite, or change sync behavior for Calendar events.

## Verification

- Build optimized universal macOS 13 app for arm64 and x86_64.
- Verify the all-day end boundary for one-day and multi-day spans, including DST-safe calendar-day arithmetic.
- Verify holiday visibility with the toggle on and off; verify ordinary events follow the toggle.
- Verify a task-linked event is hidden while the task remains visible, with UUID and event-ID matching; verify ambiguous external IDs do not suppress events.
- Run `git diff --check`. Real EventKit behavior still requires user-authorized Calendar access and is outside this local verification.

## Implementation sequence

1. Correct the all-day end boundary in the sync date conversion.
2. Add holiday and checklist-link metadata to month event presentation and filter linked copies by stable identity.
3. Keep holiday loading active independently of the ordinary Calendar toggle; update user-facing help text if needed.
4. Build, run the available regression checks, inspect the diff, and update `桌面清单/HANDOFF.md`.
