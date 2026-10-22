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
    var calendarAllDaySpanDays: Int?
    var calendarEventIdentifier: String?
    var calendarEventExternalIdentifier: String?
    var calendarIdentifier: String?
    var calendarSyncedAt: Date?
    var localUpdatedAt: Date?
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
    var tasks: [TodoItem] = []
    var focusRecords: [FocusRecord] = []
    var timer: TimerSnapshot?
    var pendingCalendarDeletions: [PendingCalendarDeletion] = []

    init(tasks: [TodoItem] = [], focusRecords: [FocusRecord] = [], timer: TimerSnapshot? = nil,
         pendingCalendarDeletions: [PendingCalendarDeletion] = []) {
        self.tasks = tasks
        self.focusRecords = focusRecords
        self.timer = timer
        self.pendingCalendarDeletions = pendingCalendarDeletions
    }

    private enum CodingKeys: String, CodingKey {
        case tasks, focusRecords, timer, pendingCalendarDeletions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tasks = try values.decodeIfPresent([TodoItem].self, forKey: .tasks) ?? []
        focusRecords = try values.decodeIfPresent([FocusRecord].self, forKey: .focusRecords) ?? []
        timer = try values.decodeIfPresent(TimerSnapshot.self, forKey: .timer)
        pendingCalendarDeletions = try values.decodeIfPresent([PendingCalendarDeletion].self, forKey: .pendingCalendarDeletions) ?? []
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

    static func isHolidayCalendar(named title: String) -> Bool {
        let normalizedTitle = title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return holidayCalendarTerms.contains { normalizedTitle.localizedCaseInsensitiveContains($0) }
    }

    static func shouldShow(isHoliday: Bool, isChecklistLinked: Bool, showsCalendarEvents: Bool) -> Bool {
        !isChecklistLinked && (isHoliday || showsCalendarEvents)
    }
}
