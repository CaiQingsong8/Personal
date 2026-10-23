import Foundation

struct TodoItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var dueDate: Date
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?
    // Optional fields keep older local JSON backups fully compatible.
    var hasSpecificTime: Bool?
    var calendarDurationSeconds: Double?
    var localUpdatedAt: Date?
}

struct CalendarSchedule: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var dueDate: Date
    var hasSpecificTime: Bool?
    var calendarDurationSeconds: Double?
    var calendarAllDaySpanDays: Int?
    var calendarEventIdentifier: String?
    var calendarEventExternalIdentifier: String?
    var calendarIdentifier: String?
    var calendarSyncedAt: Date?
    var localUpdatedAt: Date?

    init(id: UUID = UUID(), title: String, notes: String = "", dueDate: Date,
         hasSpecificTime: Bool? = nil, calendarDurationSeconds: Double? = nil,
         calendarAllDaySpanDays: Int? = nil, calendarEventIdentifier: String? = nil,
         calendarEventExternalIdentifier: String? = nil, calendarIdentifier: String? = nil,
         calendarSyncedAt: Date? = nil, localUpdatedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasSpecificTime = hasSpecificTime
        self.calendarDurationSeconds = calendarDurationSeconds
        self.calendarAllDaySpanDays = calendarAllDaySpanDays
        self.calendarEventIdentifier = calendarEventIdentifier
        self.calendarEventExternalIdentifier = calendarEventExternalIdentifier
        self.calendarIdentifier = calendarIdentifier
        self.calendarSyncedAt = calendarSyncedAt
        self.localUpdatedAt = localUpdatedAt
    }

    init(legacy: LegacyTodoItem) {
        id = legacy.id
        title = legacy.title
        notes = legacy.notes
        dueDate = legacy.dueDate
        hasSpecificTime = legacy.hasSpecificTime
        calendarDurationSeconds = legacy.calendarDurationSeconds
        calendarAllDaySpanDays = legacy.calendarAllDaySpanDays
        calendarEventIdentifier = legacy.calendarEventIdentifier
        calendarEventExternalIdentifier = legacy.calendarEventExternalIdentifier
        calendarIdentifier = legacy.calendarIdentifier
        calendarSyncedAt = legacy.calendarSyncedAt
        localUpdatedAt = legacy.localUpdatedAt
    }
}

struct ReminderItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var dueDate: Date
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?
    var hasSpecificTime: Bool?
    var reminderCalendarItemIdentifier: String?
    var reminderCalendarItemExternalIdentifier: String?
    var reminderListIdentifier: String?
    var reminderSyncedAt: Date?
    var localUpdatedAt: Date?

    init(id: UUID = UUID(), title: String, notes: String = "", dueDate: Date,
         isCompleted: Bool = false, createdAt: Date = Date(), completedAt: Date? = nil,
         hasSpecificTime: Bool? = nil, reminderCalendarItemIdentifier: String? = nil,
         reminderCalendarItemExternalIdentifier: String? = nil, reminderListIdentifier: String? = nil,
         reminderSyncedAt: Date? = nil, localUpdatedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.hasSpecificTime = hasSpecificTime
        self.reminderCalendarItemIdentifier = reminderCalendarItemIdentifier
        self.reminderCalendarItemExternalIdentifier = reminderCalendarItemExternalIdentifier
        self.reminderListIdentifier = reminderListIdentifier
        self.reminderSyncedAt = reminderSyncedAt
        self.localUpdatedAt = localUpdatedAt
    }

    init(legacy: LegacyTodoItem) {
        id = legacy.id
        title = legacy.title
        notes = legacy.notes
        dueDate = legacy.dueDate
        isCompleted = legacy.isCompleted
        createdAt = legacy.createdAt
        completedAt = legacy.completedAt
        hasSpecificTime = legacy.hasSpecificTime
        reminderCalendarItemIdentifier = legacy.reminderCalendarItemIdentifier
        reminderCalendarItemExternalIdentifier = legacy.reminderCalendarItemExternalIdentifier
        reminderListIdentifier = legacy.reminderListIdentifier
        reminderSyncedAt = legacy.reminderSyncedAt
        localUpdatedAt = legacy.localUpdatedAt
    }
}

struct LegacyTodoItem: Codable {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var hasSpecificTime: Bool?
    var calendarDurationSeconds: Double?
    var calendarAllDaySpanDays: Int?
    var calendarEventIdentifier: String?
    var calendarEventExternalIdentifier: String?
    var calendarIdentifier: String?
    var calendarSyncedAt: Date?
    var reminderCalendarItemIdentifier: String?
    var reminderCalendarItemExternalIdentifier: String?
    var reminderListIdentifier: String?
    var reminderSyncedAt: Date?
    var localUpdatedAt: Date?

    var hasCalendarIdentity: Bool {
        calendarEventIdentifier != nil || calendarEventExternalIdentifier != nil || calendarIdentifier != nil
    }

    var hasReminderIdentity: Bool {
        reminderCalendarItemIdentifier != nil || reminderCalendarItemExternalIdentifier != nil || reminderListIdentifier != nil
    }

    func localTask() -> TodoItem {
        TodoItem(
            id: id,
            title: title,
            notes: notes,
            dueDate: dueDate,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            hasSpecificTime: hasSpecificTime,
            calendarDurationSeconds: calendarDurationSeconds,
            localUpdatedAt: localUpdatedAt
        )
    }
}

struct CalendarEventIdentity: Hashable {
    var taskID: UUID?
    var eventIdentifier: String
    var externalIdentifier: String?
    var calendarIdentifier: String
}

enum CalendarEventIdentityMatcher {
    static func matchingIdentifiers(
        taskID: UUID,
        eventIdentifier: String?,
        externalIdentifier: String?,
        calendarIdentifier: String?,
        candidates: [CalendarEventIdentity]
    ) -> [String] {
        let taskMatches = candidates.filter { $0.taskID == taskID }
        if !taskMatches.isEmpty {
            return Array(Set(taskMatches.map(\.eventIdentifier))).sorted()
        }

        if let eventIdentifier {
            let identifierMatches = candidates.filter { $0.eventIdentifier == eventIdentifier }
            if !identifierMatches.isEmpty {
                return Array(Set(identifierMatches.map(\.eventIdentifier))).sorted()
            }
        }

        guard let externalIdentifier else { return [] }
        let externalMatches = candidates.filter { $0.externalIdentifier == externalIdentifier }
        if let calendarIdentifier {
            let calendarMatches = externalMatches.filter { $0.calendarIdentifier == calendarIdentifier }
            if !calendarMatches.isEmpty {
                return Array(Set(calendarMatches.map(\.eventIdentifier))).sorted()
            }
        }
        return Array(Set(externalMatches.map(\.eventIdentifier))).sorted()
    }
}

struct PendingCalendarDeletion: Codable, Hashable {
    var taskID: UUID
    var eventIdentifier: String?
    var externalIdentifier: String?
    var calendarIdentifier: String?
}

struct ReminderItemIdentity: Hashable {
    var taskID: UUID?
    var itemIdentifier: String
    var externalIdentifier: String?
    var listIdentifier: String
}

enum ReminderItemIdentityMatcher {
    static func matchingIdentifiers(
        taskID: UUID,
        itemIdentifier: String?,
        externalIdentifier: String?,
        listIdentifier: String?,
        candidates: [ReminderItemIdentity]
    ) -> [String] {
        let taskMatches = candidates.filter { $0.taskID == taskID }
        if !taskMatches.isEmpty {
            return Array(Set(taskMatches.map(\.itemIdentifier))).sorted()
        }

        if let itemIdentifier {
            let identifierMatches = candidates.filter { $0.itemIdentifier == itemIdentifier }
            if !identifierMatches.isEmpty {
                return Array(Set(identifierMatches.map(\.itemIdentifier))).sorted()
            }
        }

        guard let externalIdentifier else { return [] }
        let externalMatches = candidates.filter { $0.externalIdentifier == externalIdentifier }
        if let listIdentifier {
            let listMatches = externalMatches.filter { $0.listIdentifier == listIdentifier }
            if !listMatches.isEmpty {
                return Array(Set(listMatches.map(\.itemIdentifier))).sorted()
            }
        }
        return Array(Set(externalMatches.map(\.itemIdentifier))).sorted()
    }
}

struct PendingReminderDeletion: Codable, Hashable {
    var taskID: UUID
    var itemIdentifier: String?
    var externalIdentifier: String?
    var listIdentifier: String?
}

struct ReminderDueDate: Equatable {
    var date: Date
    var hasSpecificTime: Bool
}

enum ReminderDateSemantics {
    static func dueDate(
        components: DateComponents?,
        creationDate: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ReminderDueDate {
        if let components,
           components.year != nil,
           components.month != nil,
           components.day != nil,
           let date = (components.calendar ?? calendar).date(from: components) {
            return ReminderDueDate(
                date: date,
                hasSpecificTime: components.hour != nil || components.minute != nil
            )
        }

        let fallback = creationDate ?? now
        return ReminderDueDate(date: calendar.startOfDay(for: fallback), hasSpecificTime: false)
    }

    static func components(
        from date: Date,
        hasSpecificTime: Bool,
        calendar: Calendar = .current
    ) -> DateComponents {
        var keys: Set<Calendar.Component> = [.year, .month, .day]
        if hasSpecificTime {
            keys.formUnion([.hour, .minute])
        }
        var result = calendar.dateComponents(keys, from: date)
        result.calendar = calendar
        result.timeZone = calendar.timeZone
        return result
    }
}

struct FocusRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var taskID: UUID?
    var taskTitle: String
    var startedAt: Date
    var durationSeconds: Int
}

struct TimerSnapshot: Codable {
    var remainingSeconds: Int
    var sessionLength: Int
    var isRunning: Bool
    var endDate: Date?
    var startedAt: Date?
    var taskID: UUID?
}

struct PersistedData: Codable {
    var schemaVersion: Int = 2
    var tasks: [TodoItem] = []
    var calendarSchedules: [CalendarSchedule] = []
    var reminderItems: [ReminderItem] = []
    var focusRecords: [FocusRecord] = []
    var timer: TimerSnapshot?
    var pendingCalendarDeletions: [PendingCalendarDeletion] = []
    var pendingReminderDeletions: [PendingReminderDeletion] = []
    var didMigrateLegacyRecords = false

    init(tasks: [TodoItem] = [], calendarSchedules: [CalendarSchedule] = [], reminderItems: [ReminderItem] = [],
         focusRecords: [FocusRecord] = [], timer: TimerSnapshot? = nil,
         pendingCalendarDeletions: [PendingCalendarDeletion] = [],
         pendingReminderDeletions: [PendingReminderDeletion] = []) {
        self.schemaVersion = 2
        self.tasks = tasks
        self.calendarSchedules = calendarSchedules
        self.reminderItems = reminderItems
        self.focusRecords = focusRecords
        self.timer = timer
        self.pendingCalendarDeletions = pendingCalendarDeletions
        self.pendingReminderDeletions = pendingReminderDeletions
        self.didMigrateLegacyRecords = false
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, tasks, calendarSchedules, reminderItems, focusRecords, timer
        case pendingCalendarDeletions, pendingReminderDeletions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let version = try values.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        let oldTasks = try values.decodeIfPresent([LegacyTodoItem].self, forKey: .tasks) ?? []
        calendarSchedules = try values.decodeIfPresent([CalendarSchedule].self, forKey: .calendarSchedules) ?? []
        reminderItems = try values.decodeIfPresent([ReminderItem].self, forKey: .reminderItems) ?? []
        if version < 2 {
            tasks = []
            for oldTask in oldTasks {
                if oldTask.hasCalendarIdentity {
                    calendarSchedules.append(CalendarSchedule(legacy: oldTask))
                }
                if oldTask.hasReminderIdentity {
                    reminderItems.append(ReminderItem(legacy: oldTask))
                }
                if !oldTask.hasCalendarIdentity && !oldTask.hasReminderIdentity {
                    tasks.append(oldTask.localTask())
                }
            }
            didMigrateLegacyRecords = true
        } else {
            tasks = oldTasks.filter { !$0.hasCalendarIdentity && !$0.hasReminderIdentity }.map { $0.localTask() }
            didMigrateLegacyRecords = false
        }
        schemaVersion = 2
        focusRecords = try values.decodeIfPresent([FocusRecord].self, forKey: .focusRecords) ?? []
        timer = try values.decodeIfPresent(TimerSnapshot.self, forKey: .timer)
        pendingCalendarDeletions = try values.decodeIfPresent([PendingCalendarDeletion].self, forKey: .pendingCalendarDeletions) ?? []
        pendingReminderDeletions = try values.decodeIfPresent([PendingReminderDeletion].self, forKey: .pendingReminderDeletions) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schemaVersion, forKey: .schemaVersion)
        try values.encode(tasks, forKey: .tasks)
        try values.encode(calendarSchedules, forKey: .calendarSchedules)
        try values.encode(reminderItems, forKey: .reminderItems)
        try values.encode(focusRecords, forKey: .focusRecords)
        try values.encodeIfPresent(timer, forKey: .timer)
        try values.encode(pendingCalendarDeletions, forKey: .pendingCalendarDeletions)
        try values.encode(pendingReminderDeletions, forKey: .pendingReminderDeletions)
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case tasks = "今日"
    case month = "月历"
    case stats = "统计"

    var id: String { rawValue }
}

extension Calendar {
    func isDate(_ lhs: Date, inSameDayAs rhs: Date) -> Bool {
        isDate(lhs, equalTo: rhs, toGranularity: .day)
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}

enum TaskScheduleDefaults {
    static let durationSeconds: TimeInterval = 2 * 60 * 60

    static func startDate(on date: Date, now: Date = Date(), calendar: Calendar = .current) -> Date {
        let minute = calendar.component(.minute, from: now)
        let minutesToAdd = minute == 0 || minute == 30 ? 0 : (minute < 30 ? 30 - minute : 60 - minute)
        let alignedNow = calendar.date(byAdding: .minute, value: minutesToAdd, to: now) ?? now
        let time = calendar.dateComponents([.hour, .minute], from: alignedNow)
        var day = calendar.dateComponents([.year, .month, .day], from: date)
        day.hour = time.hour
        day.minute = time.minute
        day.second = 0
        return calendar.date(from: day) ?? date
    }
}

enum AllDayDateRange {
    static func exclusiveEnd(start: Date, spanDays: Int, calendar: Calendar = .current) -> Date? {
        calendar.date(
            byAdding: .day,
            value: max(1, spanDays),
            to: calendar.startOfDay(for: start)
        )
    }

    static func spanDays(start: Date, end: Date, calendar: Calendar = .current) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        let endParts = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: end)
        let endIsExclusiveBoundary = endParts.hour == 0 && endParts.minute == 0 &&
            endParts.second == 0 && (endParts.nanosecond ?? 0) == 0
        let exclusiveEnd = endIsExclusiveBoundary
            ? endDay
            : (calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay)
        let dayCount = calendar.dateComponents([.day], from: startDay, to: exclusiveEnd).day ?? 0
        return max(1, dayCount)
    }
}

enum CalendarEventVisibility {
    private static let holidayCalendarTerms = ["节日", "假日", "节假日", "holiday", "holidays"]
    private static let solarTermNames = [
        "立春", "雨水", "惊蛰", "春分", "清明", "谷雨", "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
        "立秋", "处暑", "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至", "小寒", "大寒"
    ]

    static func isHolidayCalendar(named title: String) -> Bool {
        let normalizedTitle = title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return holidayCalendarTerms.contains { normalizedTitle.localizedCaseInsensitiveContains($0) }
    }

    static func isSolarTerm(named title: String) -> Bool {
        solarTermNames.contains { title.localizedCaseInsensitiveContains($0) }
    }

    static func isSolarTermCalendar(named title: String) -> Bool {
        title.localizedCaseInsensitiveContains("节气") || title.localizedCaseInsensitiveContains("solar term")
    }

    static func shouldShow(isHoliday: Bool, isSolarTerm: Bool = false, showsCalendarEvents: Bool) -> Bool {
        isHoliday || isSolarTerm || showsCalendarEvents
    }
}
