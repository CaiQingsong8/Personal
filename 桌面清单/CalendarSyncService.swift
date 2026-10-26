import AppKit
import EventKit
import Foundation

struct CalendarChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let sourceTitle: String
    let allowsContentModifications: Bool

    var displayName: String { "\(title) · \(sourceTitle)\(allowsContentModifications ? "" : " · 只读")" }
}

struct CalendarDayEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let isAllDay: Bool
    let calendarTitle: String
    let isHoliday: Bool
    let isSolarTerm: Bool

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

private struct CalendarDeletionSummary {
    var removed = 0
    var pending = 0
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
        if Self.hasEventAccess(authorizationStatus) {
            refreshCalendars()
            statusMessage = "已获得日历访问权限"
        }
    }

    var isAuthorized: Bool { Self.hasEventAccess(authorizationStatus) }

    var hasSelectedCalendar: Bool {
        calendars.contains { $0.id == selectedCalendarID }
    }

    var canWriteToSelectedCalendar: Bool {
        calendars.first { $0.id == selectedCalendarID }?.allowsContentModifications == true
    }

    var connectionStatus: String {
        guard isAuthorized else { return "未连接" }
        guard hasSelectedCalendar else { return "已授权" }
        return canWriteToSelectedCalendar ? "已连接" : "已连接（只读）"
    }

    var scheduleCalendarName: String {
        let name = scheduleOwnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(name.isEmpty ? "小唐" : name)日程"
    }

    var authorizationDescription: String {
        if #available(macOS 14.0, *) {
            switch authorizationStatus {
            case .notDetermined: return "需要你允许访问 Mac 日历"
            case .restricted: return "系统限制了日历访问"
            case .denied: return "日历权限已关闭"
            case .writeOnly: return "只有写入权限，需要完整访问权限"
            case .fullAccess, .authorized: return "已允许访问 Mac 日历"
            @unknown default: return "日历权限状态未知"
            }
        }

        switch authorizationStatus {
        case .notDetermined: return "需要你允许访问 Mac 日历"
        case .restricted: return "系统限制了日历访问"
        case .denied: return "日历权限已关闭"
        case .authorized: return "已允许访问 Mac 日历"
        default: return "日历权限状态未知"
        }
    }

    func requestAccess() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            if granted && isAuthorized {
                refreshCalendars()
                statusMessage = accessStatusMessage
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
            .map {
                CalendarChoice(
                    id: $0.calendarIdentifier,
                    title: $0.title,
                    sourceTitle: $0.source.title,
                    allowsContentModifications: $0.allowsContentModifications
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
                ?? calendars.first(where: \.allowsContentModifications)?.id
                ?? calendars.first?.id
                ?? ""
        }
    }

    /// Re-checks EventKit authorization and calendar choices after returning from Settings.
    @discardableResult
    func refreshAuthorizationStatus() -> Bool {
        let wasAuthorized = isAuthorized
        let oldSelection = selectedCalendarID
        refreshCalendars()
        let newlyAuthorized = !wasAuthorized && isAuthorized
        if !isAuthorized {
            statusMessage = authorizationDescription
        } else if newlyAuthorized || oldSelection != selectedCalendarID {
            statusMessage = accessStatusMessage
        }
        return newlyAuthorized
    }

    func calendarEvents(on date: Date) -> [CalendarDayEvent] {
        monthEventsByDay[date.startOfDay] ?? []
    }

    func loadMonthEvents(containing month: Date, appStore: AppStore) {
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
            .filter { $0.status != .canceled && taskID(in: $0) == nil }

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
                    calendarTitle: event.calendar.title,
                    isHoliday: isHolidayCalendar(event.calendar),
                    isSolarTerm: CalendarEventVisibility.isSolarTerm(named: title)
                        || CalendarEventVisibility.isSolarTermCalendar(named: event.calendar.title)
                        || CalendarEventVisibility.isSolarTermCalendar(named: event.calendar.source.title)
                )
                result[day, default: []].append(item)
                day = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? interval.end
            }
        }

        monthEventsByDay = result.mapValues { items in
            items.sorted {
                if $0.isHoliday != $1.isHoliday { return $0.isHoliday }
                if $0.isSolarTerm != $1.isSolarTerm { return $0.isSolarTerm }
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
        guard prepareForTransfer(requireWritable: false) else { return }
        guard let calendar = selectedCalendar else {
            statusMessage = "请先选择一个可访问的日历"
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

        let pendingDeletions = appStore.pendingCalendarDeletions
        let deletionSummary = syncPendingDeletions(in: appStore, events: events, kind: .schedule)
        let scheduleEvents = events.filter { taskID(in: $0) == nil }
        var schedules = appStore.calendarSchedules

        var added = 0
        var updated = 0
        var conflicts = 0
        var processed = Set<UUID>()
        let now = Date()
        for event in scheduleEvents {
            guard let eventID = event.eventIdentifier else { continue }
            if isPendingDeletion(event, matching: pendingDeletions, among: events) { continue }
            let sourceID = scheduleID(in: event)
            let directIndex = schedules.firstIndex { schedule in
                (sourceID != nil && schedule.id == sourceID) ||
                schedule.calendarEventIdentifier == eventID
            }
            let externalMatches = event.calendarItemExternalIdentifier.map { externalID in
                events.filter { $0.calendarItemExternalIdentifier == externalID &&
                    $0.calendar.calendarIdentifier == calendar.calendarIdentifier }.count
            } ?? 0
            let externalScheduleID = externalMatches == 1 ? appStore.calendarSchedules.first(where: { schedule in
                schedule.calendarEventExternalIdentifier == event.calendarItemExternalIdentifier &&
                schedule.calendarIdentifier == calendar.calendarIdentifier
            })?.id : nil
            let externalIndex = externalScheduleID.flatMap { scheduleID in schedules.firstIndex { $0.id == scheduleID } }
            let index = directIndex ?? externalIndex
            if let index, !processed.contains(schedules[index].id) {
                attachScheduleIdentity(schedules[index].id, to: event)
                let linkedEventID = event.eventIdentifier ?? eventID
                schedules[index].title = event.title
                schedules[index].notes = event.notes ?? ""
                schedules[index].dueDate = event.isAllDay ? event.startDate.startOfDay : event.startDate
                schedules[index].hasSpecificTime = !event.isAllDay
                schedules[index].calendarDurationSeconds = event.isAllDay
                    ? nil : max(60, event.endDate.timeIntervalSince(event.startDate))
                schedules[index].calendarAllDaySpanDays = event.isAllDay ? allDaySpan(for: event) : nil
                schedules[index].calendarEventIdentifier = linkedEventID
                schedules[index].calendarEventExternalIdentifier = event.calendarItemExternalIdentifier
                schedules[index].calendarIdentifier = calendar.calendarIdentifier
                schedules[index].calendarSyncedAt = now
                processed.insert(schedules[index].id)
                updated += 1
            } else if index != nil {
                conflicts += 1
            } else if externalMatches > 1 && appStore.calendarSchedules.contains(where: {
                $0.calendarEventExternalIdentifier == event.calendarItemExternalIdentifier &&
                $0.calendarIdentifier == calendar.calendarIdentifier
            }) {
                // A shared series identifier cannot safely identify one occurrence.
                conflicts += 1
            } else {
                let scheduleID = sourceID ?? UUID()
                attachScheduleIdentity(scheduleID, to: event)
                let linkedEventID = event.eventIdentifier ?? eventID
                let schedule = CalendarSchedule(
                    id: scheduleID,
                    title: event.title,
                    notes: event.notes ?? "",
                    dueDate: event.isAllDay ? event.startDate.startOfDay : event.startDate,
                    hasSpecificTime: !event.isAllDay,
                    calendarDurationSeconds: event.isAllDay
                        ? nil : max(60, event.endDate.timeIntervalSince(event.startDate)),
                    calendarAllDaySpanDays: event.isAllDay ? allDaySpan(for: event) : nil,
                    calendarEventIdentifier: linkedEventID,
                    calendarEventExternalIdentifier: event.calendarItemExternalIdentifier,
                    calendarIdentifier: calendar.calendarIdentifier,
                    calendarSyncedAt: now,
                    localUpdatedAt: now
                )
                schedules.append(schedule)
                processed.insert(schedule.id)
                added += 1
            }
        }

        appStore.applyCalendarSchedules(schedules)
        statusMessage = "已从“\(calendar.title)”导入：新增 \(added)，更新 \(updated)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)，冲突 \(conflicts)"
    }

    func exportToCalendar(from appStore: AppStore) async {
        guard prepareForTransfer(requireWritable: true) else { return }
        guard let calendar = selectedCalendar else {
            statusMessage = "请先选择一个可编辑日历"
            return
        }

        isWorking = true
        defer { isWorking = false }

        statusMessage = "正在检查已关联的日历事项…"
        await Task.yield()

        let range = transferRange
        let predicate = eventStore.predicateForEvents(withStart: range.start, end: range.end, calendars: nil)
        let events = eventStore.events(matching: predicate).filter { $0.status != .canceled }
        let deletionSummary = syncPendingDeletions(in: appStore, events: events, kind: .schedule)
        var schedules = appStore.calendarSchedules
        var created = 0
        var updated = 0
        var moved = 0
        var conflicts = 0
        let now = Date()
        let eligibleScheduleCount = schedules.filter { $0.dueDate >= range.start && $0.dueDate < range.end }.count
        var processedScheduleCount = 0

        for index in schedules.indices {
            let schedule = schedules[index]
            guard schedule.dueDate >= range.start && schedule.dueDate < range.end else { continue }
            processedScheduleCount += 1
            let matches = matchingEvents(for: schedule, in: events)
            if matches.count > 1 { conflicts += 1; continue }
            let existingEvent = matches.first
            if existingEvent == nil && (schedule.calendarEventIdentifier != nil ||
                                     schedule.calendarEventExternalIdentifier != nil ||
                                     schedule.calendarIdentifier != nil) {
                // A missing linked event must not become a second event on retry.
                conflicts += 1
                continue
            }
            let event = existingEvent ?? EKEvent(eventStore: eventStore)
            let shouldMoveToSelectedCalendar = existingEvent.map {
                $0.calendar.calendarIdentifier != calendar.calendarIdentifier
            } ?? false
            if existingEvent == nil { event.calendar = calendar }
            else if shouldMoveToSelectedCalendar {
                // Move the uniquely identified schedule into the selected destination
                // instead of creating a second copy there.
                event.calendar = calendar
            }

            do {
                event.title = schedule.title
                event.notes = schedule.notes.isEmpty ? nil : schedule.notes
                if event.url == nil || (event.url?.scheme == "deskflow" && ["task", "schedule"].contains(event.url?.host ?? "")) {
                    event.url = URL(string: "deskflow://schedule/\(schedule.id.uuidString)")
                }
                applyDate(from: schedule, to: event)

                try eventStore.save(event, span: .thisEvent, commit: true)
                schedules[index].calendarEventIdentifier = event.eventIdentifier
                schedules[index].calendarEventExternalIdentifier = event.calendarItemExternalIdentifier
                schedules[index].calendarIdentifier = calendar.calendarIdentifier
                schedules[index].calendarSyncedAt = now
                if existingEvent == nil {
                    created += 1
                } else if shouldMoveToSelectedCalendar {
                    moved += 1
                } else {
                    updated += 1
                }
            } catch {
                if created + updated + moved > 0 { appStore.applyCalendarSchedules(schedules) }
                statusMessage = "写入中断：新增 \(created)，更新 \(updated)，移入所选日历 \(moved)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)；\(error.localizedDescription)"
                return
            }

            if processedScheduleCount.isMultiple(of: 10) {
                statusMessage = "正在同步到“\(calendar.title)”：已检查 \(processedScheduleCount)/\(eligibleScheduleCount) 项…"
                await Task.yield()
            }
        }
        if created + updated + moved > 0 { appStore.applyCalendarSchedules(schedules) }
        statusMessage = "已写入“\(calendar.title)”：新增 \(created)，更新 \(updated)，移入所选日历 \(moved)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)，未安全匹配 \(conflicts)"
    }

    func syncTasksToCalendar(from appStore: AppStore) async {
        guard prepareForTransfer(requireWritable: true) else { return }
        guard let calendar = selectedCalendar else {
            statusMessage = "请先选择一个可编辑日历"
            return
        }

        isWorking = true
        defer { isWorking = false }
        statusMessage = "正在检查已关联的任务日历事件…"
        await Task.yield()

        let range = transferRange
        let predicate = eventStore.predicateForEvents(withStart: range.start, end: range.end, calendars: nil)
        let events = eventStore.events(matching: predicate).filter { $0.status != .canceled }
        let deletionSummary = syncPendingDeletions(in: appStore, events: events, kind: .task)
        var tasks = appStore.tasks
        var created = 0
        var updated = 0
        var moved = 0
        var conflicts = 0
        let eligibleTaskCount = tasks.filter { $0.dueDate >= range.start && $0.dueDate < range.end }.count
        var processedTaskCount = 0

        for index in tasks.indices {
            let task = tasks[index]
            guard task.dueDate >= range.start && task.dueDate < range.end else { continue }
            processedTaskCount += 1
            let matches = matchingTaskEvents(for: task, in: events)
            if matches.count > 1 {
                conflicts += 1
                continue
            }
            let existingEvent = matches.first
            if existingEvent == nil && (task.calendarEventIdentifier != nil ||
                                        task.calendarEventExternalIdentifier != nil ||
                                        task.calendarIdentifier != nil) {
                // A missing linked event must not become a second event on retry.
                conflicts += 1
                continue
            }

            let event = existingEvent ?? EKEvent(eventStore: eventStore)
            let shouldMoveToSelectedCalendar = existingEvent.map {
                $0.calendar.calendarIdentifier != calendar.calendarIdentifier
            } ?? false
            if existingEvent == nil || shouldMoveToSelectedCalendar { event.calendar = calendar }

            do {
                event.title = task.title
                event.notes = task.notes.isEmpty ? nil : task.notes
                if event.url == nil || isDeskFlowTaskURL(event.url) {
                    event.url = URL(string: "deskflow://task/\(task.id.uuidString)")
                }
                applyDate(from: task, to: event)
                try eventStore.save(event, span: .thisEvent, commit: true)

                tasks[index].calendarEventIdentifier = event.eventIdentifier
                tasks[index].calendarEventExternalIdentifier = event.calendarItemExternalIdentifier
                tasks[index].calendarIdentifier = calendar.calendarIdentifier
                tasks[index].calendarSyncedAt = Date()
                if existingEvent == nil {
                    created += 1
                } else if shouldMoveToSelectedCalendar {
                    moved += 1
                } else {
                    updated += 1
                }
            } catch {
                if created + updated + moved > 0 { appStore.applyTasks(tasks) }
                statusMessage = "任务同步中断：新增 \(created)，更新 \(updated)，移入所选日历 \(moved)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)；\(error.localizedDescription)"
                return
            }

            if processedTaskCount.isMultiple(of: 10) {
                statusMessage = "正在同步任务到“\(calendar.title)”：已检查 \(processedTaskCount)/\(eligibleTaskCount) 项…"
                await Task.yield()
            }
        }

        if created + updated + moved > 0 { appStore.applyTasks(tasks) }
        loadMonthEvents(containing: appStore.displayedMonth, appStore: appStore)
        statusMessage = "任务已写入“\(calendar.title)”：新增 \(created)，更新 \(updated)，移入所选日历 \(moved)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)，未安全匹配 \(conflicts)"
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else { return }
        NSWorkspace.shared.open(url)
    }

    private var selectedCalendar: EKCalendar? {
        eventStore.calendars(for: .event).first { $0.calendarIdentifier == selectedCalendarID }
    }

    private var accessStatusMessage: String {
        guard let calendar = selectedCalendar else { return "已授权，但没有找到可访问的日历" }
        return calendar.allowsContentModifications
            ? "已连接“\(calendar.title)”"
            : "已连接只读日历“\(calendar.title)”；可导入，不能写回"
    }

    private static func hasEventAccess(_ status: EKAuthorizationStatus) -> Bool {
        if #available(macOS 14.0, *) {
            return status == .fullAccess
        }
        return status == .authorized
    }

    private var transferRange: (start: Date, end: Date) {
        let start = Calendar.current.date(byAdding: .year, value: -1, to: Date().startOfDay) ?? Date().startOfDay
        let end = Calendar.current.date(byAdding: .year, value: 2, to: Date().startOfDay) ?? Date().addingTimeInterval(730 * 86_400)
        return (start, end)
    }

    private func prepareForTransfer(requireWritable: Bool) -> Bool {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard isAuthorized else {
            statusMessage = "请先允许完整日历访问权限"
            return false
        }
        refreshCalendars()
        guard hasSelectedCalendar else {
            statusMessage = "没有可访问的日历，请先选择或创建一个日历"
            return false
        }
        guard !requireWritable || canWriteToSelectedCalendar else {
            statusMessage = "所选日历为只读；请选择可编辑日历后再同步写回"
            return false
        }
        return true
    }

    private func scheduleID(in event: EKEvent) -> UUID? {
        guard let url = event.url, url.scheme == "deskflow",
              url.host == "schedule" else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }

    private func taskID(in event: EKEvent) -> UUID? {
        guard isDeskFlowTaskURL(event.url), let url = event.url else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }

    private func isDeskFlowTaskURL(_ url: URL?) -> Bool {
        guard let url, url.scheme == "deskflow" else { return false }
        return url.host == "task" || url.host == "local-task"
    }

    private func linkedRecordID(in event: EKEvent) -> UUID? {
        scheduleID(in: event) ?? taskID(in: event)
    }

    private func externalIdentifierKey(calendarID: String, externalID: String) -> String {
        "\(calendarID)\u{1F}\(externalID)"
    }

    private func isHolidayCalendar(_ calendar: EKCalendar) -> Bool {
        CalendarEventVisibility.isHolidayCalendar(named: calendar.title) ||
            CalendarEventVisibility.isHolidayCalendar(named: calendar.source.title)
    }

    private func attachScheduleIdentity(_ scheduleID: UUID, to event: EKEvent) {
        guard event.url == nil else { return }
        event.url = URL(string: "deskflow://schedule/\(scheduleID.uuidString)")
        try? eventStore.save(event, span: .thisEvent, commit: true)
    }

    private func matchingEvents(for schedule: CalendarSchedule, in events: [EKEvent]) -> [EKEvent] {
        var candidates = events
        if let identifier = schedule.calendarEventIdentifier,
           let event = eventStore.event(withIdentifier: identifier) {
            candidates.append(event)
        }
        if let externalIdentifier = schedule.calendarEventExternalIdentifier {
            candidates += eventStore.calendarItems(withExternalIdentifier: externalIdentifier)
                .compactMap { $0 as? EKEvent }
        }

        var eventsByIdentifier: [String: EKEvent] = [:]
        var identities: [CalendarEventIdentity] = []
        for event in candidates where event.status != .canceled {
            guard taskID(in: event) == nil || event.eventIdentifier == schedule.calendarEventIdentifier else { continue }
            guard let identifier = event.eventIdentifier, eventsByIdentifier[identifier] == nil else { continue }
            eventsByIdentifier[identifier] = event
            identities.append(CalendarEventIdentity(
                taskID: scheduleID(in: event),
                eventIdentifier: identifier,
                externalIdentifier: event.calendarItemExternalIdentifier,
                calendarIdentifier: event.calendar.calendarIdentifier
            ))
        }

        return CalendarEventIdentityMatcher.matchingIdentifiers(
            taskID: schedule.id,
            eventIdentifier: schedule.calendarEventIdentifier,
            externalIdentifier: schedule.calendarEventExternalIdentifier,
            calendarIdentifier: schedule.calendarIdentifier,
            candidates: identities
        ).compactMap { eventsByIdentifier[$0] }
    }

    private func matchingTaskEvents(for task: TodoItem, in events: [EKEvent]) -> [EKEvent] {
        var candidates = events.filter { taskID(in: $0) != nil }
        if let identifier = task.calendarEventIdentifier,
           let event = eventStore.event(withIdentifier: identifier) {
            candidates.append(event)
        }
        if let externalIdentifier = task.calendarEventExternalIdentifier {
            candidates += eventStore.calendarItems(withExternalIdentifier: externalIdentifier)
                .compactMap { $0 as? EKEvent }
        }

        var eventsByIdentifier: [String: EKEvent] = [:]
        var identities: [CalendarEventIdentity] = []
        for event in candidates where event.status != .canceled {
            guard let identifier = event.eventIdentifier, eventsByIdentifier[identifier] == nil else { continue }
            eventsByIdentifier[identifier] = event
            identities.append(CalendarEventIdentity(
                taskID: taskID(in: event),
                eventIdentifier: identifier,
                externalIdentifier: event.calendarItemExternalIdentifier,
                calendarIdentifier: event.calendar.calendarIdentifier
            ))
        }

        return CalendarEventIdentityMatcher.matchingIdentifiers(
            taskID: task.id,
            eventIdentifier: task.calendarEventIdentifier,
            externalIdentifier: task.calendarEventExternalIdentifier,
            calendarIdentifier: task.calendarIdentifier,
            candidates: identities
        ).compactMap { eventsByIdentifier[$0] }
    }

    private func isPendingDeletion(_ event: EKEvent, matching deletions: [PendingCalendarDeletion], among events: [EKEvent]) -> Bool {
        deletions.contains { pending in
            guard (pending.kind ?? .schedule) == .schedule else { return false }
            let hasStrongMatch = events.contains { candidate in
                linkedRecordID(in: candidate) == pending.taskID ||
                (pending.eventIdentifier != nil && candidate.eventIdentifier == pending.eventIdentifier)
            }
            if hasStrongMatch {
                return linkedRecordID(in: event) == pending.taskID ||
                    (pending.eventIdentifier != nil && event.eventIdentifier == pending.eventIdentifier)
            }
            return pending.externalIdentifier != nil &&
                event.calendarItemExternalIdentifier == pending.externalIdentifier
        }
    }

    @discardableResult
    private func syncPendingDeletions(
        in store: AppStore,
        events: [EKEvent],
        kind: CalendarLinkedRecordKind
    ) -> CalendarDeletionSummary {
        var summary = CalendarDeletionSummary()
        for pending in store.pendingCalendarDeletions where (pending.kind ?? .schedule) == kind {
            var candidates = events.filter { event in
                linkedRecordID(in: event) == pending.taskID ||
                (pending.eventIdentifier != nil && event.eventIdentifier == pending.eventIdentifier)
            }
            if let identifier = pending.eventIdentifier,
               let event = eventStore.event(withIdentifier: identifier),
               !candidates.contains(where: { $0.eventIdentifier == event.eventIdentifier }) {
                candidates.append(event)
            }
            if candidates.isEmpty, let external = pending.externalIdentifier {
                candidates += eventStore.calendarItems(withExternalIdentifier: external).compactMap { $0 as? EKEvent }
            }
            var seen = Set<String>()
            let matches = candidates.filter { event in
                guard let identifier = event.eventIdentifier else { return false }
                return seen.insert(identifier).inserted
            }
            guard matches.count <= 1 else {
                summary.pending += 1
                continue
            }
            do {
                if let event = matches.first {
                    try eventStore.remove(event, span: .thisEvent, commit: true)
                    summary.removed += 1
                }
                // No matching event means it was already removed in Calendar.
                store.finishCalendarDeletion(taskID: pending.taskID)
            } catch {
                summary.pending += 1
            }
        }
        return summary
    }

    private func allDaySpan(for event: EKEvent) -> Int {
        AllDayDateRange.spanDays(start: event.startDate, end: event.endDate)
    }

    private func applyDate(from schedule: CalendarSchedule, to event: EKEvent) {
        if schedule.hasSpecificTime ?? false {
            event.isAllDay = false
            event.startDate = schedule.dueDate
            event.endDate = schedule.dueDate.addingTimeInterval(schedule.calendarDurationSeconds ?? 3600)
        } else {
            event.isAllDay = true
            event.startDate = schedule.dueDate.startOfDay
            let days = max(1, schedule.calendarAllDaySpanDays ?? 1)
            let nextDay = AllDayDateRange.exclusiveEnd(start: event.startDate, spanDays: days)
                ?? event.startDate.addingTimeInterval(TimeInterval(days * 86_400))
            event.endDate = nextDay
        }
    }

    private func applyDate(from task: TodoItem, to event: EKEvent) {
        if task.hasSpecificTime ?? true {
            event.isAllDay = false
            event.startDate = task.dueDate
            event.endDate = task.dueDate.addingTimeInterval(
                max(60, task.calendarDurationSeconds ?? TaskScheduleDefaults.durationSeconds)
            )
        } else {
            event.isAllDay = true
            event.startDate = task.dueDate.startOfDay
            event.endDate = AllDayDateRange.exclusiveEnd(start: event.startDate, spanDays: 1)
                ?? Calendar.current.date(byAdding: .day, value: 1, to: event.startDate)
                ?? event.startDate.addingTimeInterval(86_400)
        }
    }
}
