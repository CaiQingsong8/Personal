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
    var calendarEventIdentifier: String?
    var calendarSyncedAt: Date?
    var localUpdatedAt: Date?
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
