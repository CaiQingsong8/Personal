# Default Task Duration Design

## Problem

New checklist tasks were saved without a specific time. Calendar export represents those tasks as all-day events, whose exclusive end boundary is midnight on the next local calendar day. macOS Calendar can therefore draw the task across two date columns, even though the checklist item was created for one date.

## Decision

- New tasks use an explicit timed schedule by default.
- Start time follows the existing nearest half-hour alignment rule, applied to the selected task date.
- Default duration is two hours.
- Users can still turn off “指定具体时间” in the editor to make a task all-day, or change the start time and duration.
- Existing saved tasks are not migrated. In particular, old all-day tasks remain all-day until the user edits them.
- Calendar-imported events retain their imported times and durations.

## Verification

- Test the 14:27 -> 14:30 and 14:45 -> 15:00 alignment cases, with seconds cleared.
- Verify the shared default duration is 7,200 seconds.
- Build both macOS architectures and run the calendar semantics regression test.
