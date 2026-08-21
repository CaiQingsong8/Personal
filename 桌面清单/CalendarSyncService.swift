import AppKit
import EventKit
import Foundation

struct CalendarChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let sourceTitle: String

    var displayName: String { "\(title) · \(sourceTitle)" }
}

struct CalendarDayEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let isAllDay: Bool
    let calendarTitle: String

    var displayTitle: String {
        isAllDay ? title : "\(Self.timeFormatter.string(from: startDate)) \(title)"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

@MainActor
final class CalendarSyncService: ObservableObject {
    static let shared = CalendarSyncService()

    @Published private(set) var authorizationStatus: EKAuthorizationStatus
    @Published private(set) var calendars: [CalendarChoice] = []
    @Published var selectedCalendarID: String {
        didSet {
            if !selectedCalendarID.isEmpty {
                UserDefaults.standard.set(selectedCalendarID, forKey: Self.selectedCalendarKey)
            }
        }
    }
    @Published var scheduleOwnerName: String {
        didSet {
            UserDefaults.standard.set(scheduleOwnerName, forKey: Self.scheduleOwnerNameKey)
        }
    }
    @Published private(set) var monthEventsByDay: [Date: [CalendarDayEvent]] = [:]
    @Published private(set) var isWorking = false
    @Published private(set) var statusMessage = "尚未连接 Mac 日历"

    private let eventStore = EKEventStore()
    private static let selectedCalendarKey = "DeskFlowSelectedCalendarID"
    private static let scheduleOwnerNameKey = "DeskFlowScheduleOwnerName"

    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        selectedCalendarID = UserDefaults.standard.string(forKey: Self.selectedCalendarKey) ?? ""
        scheduleOwnerName = UserDefaults.standard.string(forKey: Self.scheduleOwnerNameKey) ?? "小唐"
        if authorizationStatus == .fullAccess {
            refreshCalendars()
            statusMessage = "已获得日历访问权限"
        }
    }

    var isAuthorized: Bool { authorizationStatus == .fullAccess }

    var scheduleCalendarName: String {
        let name = scheduleOwnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(name.isEmpty ? "小唐" : name)日程"
    }

    var authorizationDescription: String {
        switch authorizationStatus {
        case .notDetermined: return "需要你允许访问 Mac 日历"
        case .restricted: return "系统限制了日历访问"
        case .denied: return "日历权限已关闭"
        case .writeOnly: return "只有写入权限，需要完整访问权限"
        case .fullAccess, .authorized: return "已允许访问 Mac 日历"
        @unknown default: return "日历权限状态未知"
        }
    }

    func requestAccess() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            if granted {
                refreshCalendars()
                statusMessage = "权限已开启，请选择要互传的日历"
            } else {
                statusMessage = "未获得日历权限"
            }
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            statusMessage = "授权失败：\(error.localizedDescription)"
        }
    }

    func refreshCalendars() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard isAuthorized else {
            calendars = []
            return
        }

        calendars = eventStore.calendars(for: .event)
            .filter(\.allowsContentModifications)
            .map {
                CalendarChoice(
                    id: $0.calendarIdentifier,
                    title: $0.title,
                    sourceTitle: $0.source.title
                )
            }
            .sorted {
                if $0.sourceTitle != $1.sourceTitle { return $0.sourceTitle < $1.sourceTitle }
                return $0.title < $1.title
            }

        if !calendars.contains(where: { $0.id == selectedCalendarID }) {
            let preferred = eventStore.defaultCalendarForNewEvents?.calendarIdentifier
            selectedCalendarID = calendars.first(where: { $0.title == scheduleCalendarName })?.id
                ?? calendars.first(where: { $0.id == preferred })?.id
                ?? calendars.first?.id
                ?? ""
        }
    }

    func calendarEvents(on date: Date) -> [CalendarDayEvent] {
        monthEventsByDay[date.startOfDay] ?? []
    }

    func loadMonthEvents(containing month: Date) {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard isAuthorized,
              let interval = Calendar.current.dateInterval(of: .month, for: month) else {
            monthEventsByDay = [:]
            return
        }

        let predicate = eventStore.predicateForEvents(
            withStart: interval.start,
            end: interval.end,
            calendars: nil
        )
        let events = eventStore.events(matching: predicate)
            .filter { $0.status != .canceled }

        var result: [Date: [CalendarDayEvent]] = [:]
        for event in events {
            guard let title = event.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { continue }
            let eventStart = max(event.startDate, interval.start)
            let eventEnd = min(event.endDate, interval.end)
            let firstDay = eventStart.startOfDay
            let lastMoment = max(eventStart, eventEnd.addingTimeInterval(-1))
            let lastDay = lastMoment.startOfDay
            let baseID = event.eventIdentifier
                ?? "\(event.calendar.calendarIdentifier)-\(event.startDate.timeIntervalSince1970)-\(title)"

            var day = firstDay
            while day <= lastDay && day < interval.end {
                let item = CalendarDayEvent(
                    id: "\(baseID)-\(day.timeIntervalSince1970)",
                    title: title,
                    startDate: event.startDate,
                    isAllDay: event.isAllDay,
                    calendarTitle: event.calendar.title
                )
                result[day, default: []].append(item)
                day = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? interval.end
            }
        }

        monthEventsByDay = result.mapValues { items in
            items.sorted {
                if $0.isAllDay != $1.isAllDay { return $0.isAllDay }
                if $0.startDate != $1.startDate { return $0.startDate < $1.startDate }
                return $0.title < $1.title
            }
        }
    }

    func createOrUseScheduleCalendar() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard isAuthorized else {
            statusMessage = "请先允许完整日历访问权限"
            return
        }
        guard !isWorking else { return }

        isWorking = true
        defer { isWorking = false }
        refreshCalendars()

        if let existing = eventStore.calendars(for: .event).first(where: {
            $0.allowsContentModifications && $0.title == scheduleCalendarName
        }) {
            selectedCalendarID = existing.calendarIdentifier
            statusMessage = "已选择“\(scheduleCalendarName)”"
            return
        }

        guard let source = eventStore.defaultCalendarForNewEvents?.source
                ?? eventStore.calendars(for: .event).first(where: \.allowsContentModifications)?.source else {
            statusMessage = "没有找到可用于创建日历的账户"
            return
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = scheduleCalendarName
        calendar.source = source

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            refreshCalendars()
            selectedCalendarID = calendar.calendarIdentifier
            statusMessage = "已创建并选择“\(scheduleCalendarName)”"
        } catch {
            statusMessage = "创建日历失败：\(error.localizedDescription)"
        }
    }

    func importFromCalendar(into appStore: AppStore) async {
        guard prepareForTransfer() else { return }
        guard let calendar = selectedCalendar else {
            statusMessage = "请先选择一个可编辑日历"
            return
        }

        isWorking = true
        defer { isWorking = false }

        let range = transferRange
        let predicate = eventStore.predicateForEvents(
            withStart: range.start,
            end: range.end,
            calendars: [calendar]
        )
        let events = eventStore.events(matching: predicate)
            .filter { $0.status != .canceled && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var tasks = appStore.tasks
        var taskIndexByEventID: [String: Int] = [:]
        for (index, task) in tasks.enumerated() {
            if let eventID = task.calendarEventIdentifier {
                taskIndexByEventID[eventID] = index
            }
        }

        var added = 0
        var updated = 0
        let now = Date()
        for event in events {
            guard let eventID = event.eventIdentifier else { continue }
            if let index = taskIndexByEventID[eventID] {
                tasks[index].title = event.title
                tasks[index].notes = event.notes ?? ""
                tasks[index].dueDate = event.startDate
                tasks[index].hasSpecificTime = !event.isAllDay
                tasks[index].calendarDurationSeconds = max(60, event.endDate.timeIntervalSince(event.startDate))
                tasks[index].calendarSyncedAt = now
                updated += 1
            } else {
                let task = TodoItem(
                    title: event.title,
                    notes: event.notes ?? "",
                    dueDate: event.startDate,
                    hasSpecificTime: !event.isAllDay,
                    calendarDurationSeconds: max(60, event.endDate.timeIntervalSince(event.startDate)),
                    calendarEventIdentifier: eventID,
                    calendarSyncedAt: now,
                    localUpdatedAt: now
                )
                tasks.append(task)
                taskIndexByEventID[eventID] = tasks.count - 1
                added += 1
            }
        }

        appStore.applyCalendarTasks(tasks)
        statusMessage = "已从“\(calendar.title)”导入：新增 \(added)，更新 \(updated)"
    }

    func exportToCalendar(from appStore: AppStore) async {
        guard prepareForTransfer() else { return }
        guard let calendar = selectedCalendar else {
            statusMessage = "请先选择一个可编辑日历"
            return
        }

        isWorking = true
        defer { isWorking = false }

        let range = transferRange
        var tasks = appStore.tasks
        var created = 0
        var updated = 0
        let now = Date()

        do {
            for index in tasks.indices {
                let task = tasks[index]
                guard task.dueDate >= range.start && task.dueDate < range.end else { continue }

                let fetchedEvent = task.calendarEventIdentifier.flatMap { eventStore.event(withIdentifier: $0) }
                let existingEvent = fetchedEvent?.calendar.calendarIdentifier == selectedCalendarID ? fetchedEvent : nil
                let event = existingEvent ?? EKEvent(eventStore: eventStore)
                if existingEvent == nil { event.calendar = calendar }

                event.title = task.title
                event.notes = task.notes.isEmpty ? nil : task.notes
                applyDate(from: task, to: event)

                try eventStore.save(event, span: .thisEvent, commit: true)
                tasks[index].calendarEventIdentifier = event.eventIdentifier
                tasks[index].calendarSyncedAt = now
                if existingEvent == nil { created += 1 } else { updated += 1 }
            }

            appStore.applyCalendarTasks(tasks)
            statusMessage = "已写入“\(calendar.title)”：新增 \(created)，更新 \(updated)"
        } catch {
            statusMessage = "写入失败：\(error.localizedDescription)"
        }
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else { return }
        NSWorkspace.shared.open(url)
    }

    private var selectedCalendar: EKCalendar? {
        eventStore.calendars(for: .event).first { $0.calendarIdentifier == selectedCalendarID }
    }

    private var transferRange: (start: Date, end: Date) {
        let start = Calendar.current.date(byAdding: .year, value: -1, to: Date().startOfDay) ?? Date().startOfDay
        let end = Calendar.current.date(byAdding: .year, value: 2, to: Date().startOfDay) ?? Date().addingTimeInterval(730 * 86_400)
        return (start, end)
    }

    private func prepareForTransfer() -> Bool {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard isAuthorized else {
            statusMessage = "请先允许完整日历访问权限"
            return false
        }
        refreshCalendars()
        return !selectedCalendarID.isEmpty
    }

    private func applyDate(from task: TodoItem, to event: EKEvent) {
        if task.hasSpecificTime ?? false {
            event.isAllDay = false
            event.startDate = task.dueDate
            event.endDate = task.dueDate.addingTimeInterval(task.calendarDurationSeconds ?? 3600)
        } else {
            event.isAllDay = true
            event.startDate = task.dueDate.startOfDay
            if let duration = task.calendarDurationSeconds {
                event.endDate = task.dueDate.startOfDay.addingTimeInterval(duration)
            } else {
                event.endDate = Calendar.current.date(byAdding: .day, value: 1, to: task.dueDate.startOfDay) ?? task.dueDate.addingTimeInterval(86_400)
            }
        }
    }
}
