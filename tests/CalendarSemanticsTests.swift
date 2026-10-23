import Foundation

@main
struct CalendarSemanticsTests {
    static func main() throws {
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

        let reminderCreatedAt = makeDate(2026, 10, 22, hour: 17, minute: 45, second: 0, calendar: calendar)
        let reminderWithoutDueDate = ReminderDateSemantics.dueDate(
            components: nil,
            creationDate: reminderCreatedAt,
            calendar: calendar
        )
        precondition(reminderWithoutDueDate.date == makeDate(2026, 10, 22, calendar: calendar))
        precondition(!reminderWithoutDueDate.hasSpecificTime)

        let reminderWithoutDates = ReminderDateSemantics.dueDate(
            components: nil,
            creationDate: nil,
            now: nowAt1427,
            calendar: calendar
        )
        precondition(reminderWithoutDates.date == selectedDay)
        precondition(!reminderWithoutDates.hasSpecificTime)

        let reminderTimedDate = makeDate(2026, 10, 22, hour: 9, minute: 30, second: 0, calendar: calendar)
        let dateOnlyComponents = ReminderDateSemantics.components(
            from: reminderTimedDate,
            hasSpecificTime: false,
            calendar: calendar
        )
        precondition(dateOnlyComponents.year == 2026 && dateOnlyComponents.month == 10 && dateOnlyComponents.day == 22)
        precondition(dateOnlyComponents.hour == nil && dateOnlyComponents.minute == nil)

        let timedComponents = ReminderDateSemantics.components(
            from: reminderTimedDate,
            hasSpecificTime: true,
            calendar: calendar
        )
        precondition(timedComponents.hour == 9 && timedComponents.minute == 30)

        let legacyDataJSON = """
        {
          "tasks": [
            {"id":"00000000-0000-0000-0000-000000000001","title":"本地","notes":"","dueDate":"2026-10-22T00:00:00Z","isCompleted":false,"createdAt":"2026-10-21T00:00:00Z"},
            {"id":"00000000-0000-0000-0000-000000000002","title":"日程","notes":"","dueDate":"2026-10-22T09:00:00Z","isCompleted":false,"createdAt":"2026-10-21T00:00:00Z","calendarEventIdentifier":"event-2","calendarIdentifier":"calendar-2"},
            {"id":"00000000-0000-0000-0000-000000000003","title":"提醒","notes":"","dueDate":"2026-10-22T00:00:00Z","isCompleted":false,"createdAt":"2026-10-21T00:00:00Z","reminderCalendarItemIdentifier":"reminder-3","reminderListIdentifier":"list-3"},
            {"id":"00000000-0000-0000-0000-000000000004","title":"双关联","notes":"","dueDate":"2026-10-22T00:00:00Z","isCompleted":false,"createdAt":"2026-10-21T00:00:00Z","calendarEventIdentifier":"event-4","calendarIdentifier":"calendar-4","reminderCalendarItemIdentifier":"reminder-4","reminderListIdentifier":"list-4"}
          ],
          "focusRecords": [],
          "timer": null,
          "pendingCalendarDeletions": [{"taskID":"00000000-0000-0000-0000-000000000002","eventIdentifier":"event-2","externalIdentifier":null,"calendarIdentifier":"calendar-2"}],
          "pendingReminderDeletions": [{"taskID":"00000000-0000-0000-0000-000000000003","itemIdentifier":"reminder-3","externalIdentifier":null,"listIdentifier":"list-3"}]
        }
        """
        let legacyDecoder = JSONDecoder()
        legacyDecoder.dateDecodingStrategy = .iso8601
        let legacyData = try legacyDecoder.decode(PersistedData.self, from: Data(legacyDataJSON.utf8))
        precondition(legacyData.didMigrateLegacyRecords)
        precondition(legacyData.tasks.count == 1 && legacyData.tasks[0].title == "本地")
        precondition(legacyData.calendarSchedules.count == 2)
        precondition(legacyData.reminderItems.count == 2)
        precondition(legacyData.pendingCalendarDeletions.count == 1)
        precondition(legacyData.pendingReminderDeletions.count == 1)
        let dualID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        precondition(legacyData.calendarSchedules.contains(where: { $0.id == dualID }))
        precondition(legacyData.reminderItems.contains(where: { $0.id == dualID }))
        precondition(!legacyData.tasks.contains(where: { $0.id == dualID }))
        let legacyEncoder = JSONEncoder()
        legacyEncoder.dateEncodingStrategy = .iso8601
        let migratedData = try legacyEncoder.encode(legacyData)
        let reloadedData = try legacyDecoder.decode(PersistedData.self, from: migratedData)
        precondition(!reloadedData.didMigrateLegacyRecords)
        precondition(reloadedData.tasks.count == 1 && reloadedData.calendarSchedules.count == 2 && reloadedData.reminderItems.count == 2)

        let nowAt1445 = makeDate(2026, 10, 22, hour: 14, minute: 45, second: 10, calendar: calendar)
        let nextHourStart = TaskScheduleDefaults.startDate(on: selectedDay, now: nowAt1445, calendar: calendar)
        let nextHour = calendar.dateComponents([.hour, .minute], from: nextHourStart)
        precondition(nextHour.hour == 15 && nextHour.minute == 0)

        precondition(CalendarEventVisibility.isHolidayCalendar(named: "中国大陆节假日"))
        precondition(CalendarEventVisibility.isHolidayCalendar(named: "US Holidays"))
        precondition(!CalendarEventVisibility.isHolidayCalendar(named: "Team Projects"))
        precondition(CalendarEventVisibility.shouldShow(isHoliday: true, showsCalendarEvents: false))
        precondition(CalendarEventVisibility.shouldShow(isHoliday: false, isSolarTerm: true, showsCalendarEvents: false))
        precondition(!CalendarEventVisibility.shouldShow(isHoliday: false, showsCalendarEvents: false))
        precondition(CalendarEventVisibility.shouldShow(isHoliday: false, showsCalendarEvents: true))
        precondition(CalendarEventVisibility.isSolarTerm(named: "霜降"))

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

        let reminderLinkedItem = ReminderItemIdentity(
            taskID: taskID,
            itemIdentifier: "linked-reminder",
            externalIdentifier: "reminder-external",
            listIdentifier: "reminder-list"
        )
        precondition(ReminderItemIdentityMatcher.matchingIdentifiers(
            taskID: taskID,
            itemIdentifier: nil,
            externalIdentifier: nil,
            listIdentifier: nil,
            candidates: [reminderLinkedItem]
        ) == ["linked-reminder"])

        let sameTitleOtherTask = ReminderItemIdentity(
            taskID: UUID(),
            itemIdentifier: "same-title-different-task",
            externalIdentifier: nil,
            listIdentifier: "reminder-list"
        )
        precondition(ReminderItemIdentityMatcher.matchingIdentifiers(
            taskID: taskID,
            itemIdentifier: nil,
            externalIdentifier: nil,
            listIdentifier: nil,
            candidates: [sameTitleOtherTask]
        ).isEmpty)

        let duplicatedReminderIdentity = ReminderItemIdentity(
            taskID: taskID,
            itemIdentifier: "duplicate-linked-reminder",
            externalIdentifier: "other-external",
            listIdentifier: "other-list"
        )
        precondition(ReminderItemIdentityMatcher.matchingIdentifiers(
            taskID: taskID,
            itemIdentifier: nil,
            externalIdentifier: nil,
            listIdentifier: nil,
            candidates: [reminderLinkedItem, duplicatedReminderIdentity]
        ).count == 2)

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
