import Foundation

@main
struct CalendarSemanticsTests {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!

        let springForwardStart = makeDate(2026, 3, 8, calendar: calendar)
        let oneDayEnd = AllDayDateRange.exclusiveEnd(start: springForwardStart, spanDays: 1, calendar: calendar)!
        precondition(calendar.isDate(oneDayEnd, inSameDayAs: makeDate(2026, 3, 9, calendar: calendar)))
        precondition(oneDayEnd.timeIntervalSince(springForwardStart) == 23 * 60 * 60)
        precondition(AllDayDateRange.spanDays(start: springForwardStart, end: oneDayEnd, calendar: calendar) == 1)
        precondition(AllDayDateRange.spanDays(start: springForwardStart, end: oneDayEnd.addingTimeInterval(-1), calendar: calendar) == 1)

        let multiDayStart = makeDate(2026, 3, 7, calendar: calendar)
        let multiDayEnd = AllDayDateRange.exclusiveEnd(start: multiDayStart, spanDays: 2, calendar: calendar)!
        precondition(AllDayDateRange.spanDays(start: multiDayStart, end: multiDayEnd, calendar: calendar) == 2)

        let selectedDay = makeDate(2026, 10, 22, calendar: calendar)
        let nowAt1427 = makeDate(2026, 10, 22, hour: 14, minute: 27, second: 45, calendar: calendar)
        let defaultStart = TaskScheduleDefaults.startDate(on: selectedDay, now: nowAt1427, calendar: calendar)
        let defaultComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: defaultStart)
        precondition(defaultComponents.year == 2026 && defaultComponents.month == 10 && defaultComponents.day == 22)
        precondition(defaultComponents.hour == 14 && defaultComponents.minute == 30 && defaultComponents.second == 0)
        precondition(TaskScheduleDefaults.durationSeconds == 2 * 60 * 60)

        let nowAt1445 = makeDate(2026, 10, 22, hour: 14, minute: 45, second: 10, calendar: calendar)
        let nextHourStart = TaskScheduleDefaults.startDate(on: selectedDay, now: nowAt1445, calendar: calendar)
        let nextHour = calendar.dateComponents([.hour, .minute], from: nextHourStart)
        precondition(nextHour.hour == 15 && nextHour.minute == 0)

        precondition(CalendarEventVisibility.isHolidayCalendar(named: "中国大陆节假日"))
        precondition(CalendarEventVisibility.isHolidayCalendar(named: "US Holidays"))
        precondition(!CalendarEventVisibility.isHolidayCalendar(named: "Team Projects"))
        precondition(CalendarEventVisibility.shouldShow(isHoliday: true, isChecklistLinked: false, showsCalendarEvents: false))
        precondition(!CalendarEventVisibility.shouldShow(isHoliday: false, isChecklistLinked: false, showsCalendarEvents: false))
        precondition(CalendarEventVisibility.shouldShow(isHoliday: false, isChecklistLinked: false, showsCalendarEvents: true))
        precondition(!CalendarEventVisibility.shouldShow(isHoliday: true, isChecklistLinked: true, showsCalendarEvents: true))

        let taskID = UUID()
        let linkedInOldCalendar = CalendarEventIdentity(
            taskID: taskID,
            eventIdentifier: "old-calendar-event",
            externalIdentifier: "shared-external-id",
            calendarIdentifier: "old-calendar"
        )
        precondition(CalendarEventIdentityMatcher.matchingIdentifiers(
            taskID: taskID,
            eventIdentifier: nil,
            externalIdentifier: "shared-external-id",
            calendarIdentifier: nil,
            candidates: [linkedInOldCalendar]
        ) == ["old-calendar-event"])

        let duplicateInAnotherCalendar = CalendarEventIdentity(
            taskID: taskID,
            eventIdentifier: "duplicate-calendar-event",
            externalIdentifier: "another-external-id",
            calendarIdentifier: "target-calendar"
        )
        precondition(CalendarEventIdentityMatcher.matchingIdentifiers(
            taskID: taskID,
            eventIdentifier: nil,
            externalIdentifier: nil,
            calendarIdentifier: nil,
            candidates: [linkedInOldCalendar, duplicateInAnotherCalendar]
        ).count == 2)

        let fallbackByEventIdentifier = CalendarEventIdentity(
            taskID: nil,
            eventIdentifier: "stored-event-id",
            externalIdentifier: nil,
            calendarIdentifier: "old-calendar"
        )
        precondition(CalendarEventIdentityMatcher.matchingIdentifiers(
            taskID: taskID,
            eventIdentifier: "stored-event-id",
            externalIdentifier: nil,
            calendarIdentifier: nil,
            candidates: [fallbackByEventIdentifier]
        ) == ["stored-event-id"])

        let duplicateExternalInTarget = CalendarEventIdentity(
            taskID: nil,
            eventIdentifier: "external-duplicate",
            externalIdentifier: "shared-external-id",
            calendarIdentifier: "target-calendar"
        )
        precondition(CalendarEventIdentityMatcher.matchingIdentifiers(
            taskID: taskID,
            eventIdentifier: nil,
            externalIdentifier: "shared-external-id",
            calendarIdentifier: "old-calendar",
            candidates: [linkedInOldCalendar, duplicateExternalInTarget]
        ) == ["old-calendar-event"])

        print("CALENDAR_SEMANTICS_TESTS_OK")
    }

    private static func makeDate(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private static func makeDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
    }
}
