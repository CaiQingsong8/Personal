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
}
