import AppKit
import EventKit
import Foundation

struct ReminderListChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let sourceTitle: String

    var displayName: String { "\(title) · \(sourceTitle)" }
}

struct CalendarDayReminder: Identifiable, Hashable {
    let id: String
    let title: String
    let dueDate: Date
    let hasSpecificTime: Bool
    let isCompleted: Bool
    let listTitle: String
    let isChecklistLinked: Bool

    var displayTitle: String {
        guard hasSpecificTime else { return title }
        return "\(Self.timeFormatter.string(from: dueDate)) \(title)"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private struct ReminderDeletionSummary {
    var removed = 0
    var pending = 0
}

@MainActor
final class ReminderSyncService: ObservableObject {
    static let shared = ReminderSyncService()

    @Published private(set) var authorizationStatus: EKAuthorizationStatus
    @Published private(set) var lists: [ReminderListChoice] = []
    @Published var selectedListID: String {
        didSet {
            if !selectedListID.isEmpty {
                UserDefaults.standard.set(selectedListID, forKey: Self.selectedListKey)
            }
        }
    }
    @Published private(set) var monthRemindersByDay: [Date: [CalendarDayReminder]] = [:]
    @Published private(set) var isWorking = false
    @Published private(set) var statusMessage = "尚未连接 Mac 提醒事项"

    private let eventStore = EKEventStore()
    private var monthLoadToken = UUID()
    private static let selectedListKey = "DeskFlowSelectedReminderListID"
    private static let reminderListName = "小唐提醒事项"

    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        selectedListID = UserDefaults.standard.string(forKey: Self.selectedListKey) ?? ""
        if Self.hasReminderAccess(authorizationStatus) {
            refreshLists()
            statusMessage = "已获得提醒事项访问权限"
        }
    }

    var isAuthorized: Bool { Self.hasReminderAccess(authorizationStatus) }

    var authorizationDescription: String {
        if #available(macOS 14.0, *) {
            switch authorizationStatus {
            case .notDetermined: return "需要你允许访问 Mac 提醒事项"
            case .restricted: return "系统限制了提醒事项访问"
            case .denied: return "提醒事项权限已关闭"
            case .writeOnly: return "只有写入权限，需要完整访问权限"
            case .fullAccess, .authorized: return "已允许访问 Mac 提醒事项"
            @unknown default: return "提醒事项权限状态未知"
            }
        }

        switch authorizationStatus {
        case .notDetermined: return "需要你允许访问 Mac 提醒事项"
        case .restricted: return "系统限制了提醒事项访问"
        case .denied: return "提醒事项权限已关闭"
        case .authorized: return "已允许访问 Mac 提醒事项"
        default: return "提醒事项权限状态未知"
        }
    }

    var reminderListName: String { Self.reminderListName }

    func requestAccess() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToReminders()
            } else {
                granted = try await eventStore.requestAccess(to: .reminder)
            }
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            if granted {
                refreshLists()
                statusMessage = "权限已开启，请选择要互传的提醒事项列表"
            } else {
                statusMessage = "未获得提醒事项权限"
            }
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            statusMessage = "授权失败：\(error.localizedDescription)"
        }
    }

    func refreshLists() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard isAuthorized else {
            lists = []
            monthRemindersByDay = [:]
            return
        }

        lists = eventStore.calendars(for: .reminder)
            .filter(\.allowsContentModifications)
            .map {
                ReminderListChoice(
                    id: $0.calendarIdentifier,
                    title: $0.title,
                    sourceTitle: $0.source.title
                )
            }
            .sorted {
                if $0.sourceTitle != $1.sourceTitle { return $0.sourceTitle < $1.sourceTitle }
                return $0.title < $1.title
            }

        if !lists.contains(where: { $0.id == selectedListID }) {
            let preferred = eventStore.defaultCalendarForNewReminders()?.calendarIdentifier
            selectedListID = lists.first(where: { $0.title == Self.reminderListName })?.id
                ?? lists.first(where: { $0.id == preferred })?.id
                ?? lists.first?.id
                ?? ""
        }
    }

    func reminders(on date: Date) -> [CalendarDayReminder] {
        monthRemindersByDay[date.startOfDay] ?? []
    }

    func loadMonthReminders(containing month: Date, appStore: AppStore) {
        monthLoadToken = UUID()
        let token = monthLoadToken
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        refreshLists()
        guard isAuthorized,
              let interval = Calendar.current.dateInterval(of: .month, for: month),
              let list = selectedList else {
            monthRemindersByDay = [:]
            return
        }

        Task {
            let fetched = await fetchReminders(in: [list])
            guard token == monthLoadToken else { return }
            let tasks = appStore.tasks
            let pendingDeletions = appStore.pendingReminderDeletions
            let linkedItemIdentifiers = Set(
                tasks.compactMap(\.reminderCalendarItemIdentifier) +
                    pendingDeletions.compactMap(\.itemIdentifier)
            )
            var linkedExternalIdentifiers = Set<String>()
            for task in tasks {
                if let listID = task.reminderListIdentifier,
                   let externalID = task.reminderCalendarItemExternalIdentifier {
                    linkedExternalIdentifiers.insert(externalKey(listID: listID, externalID: externalID))
                }
            }
            for deletion in pendingDeletions {
                if let listID = deletion.listIdentifier, let externalID = deletion.externalIdentifier {
                    linkedExternalIdentifiers.insert(externalKey(listID: listID, externalID: externalID))
                }
            }

            var externalCounts: [String: Int] = [:]
            for reminder in fetched {
                guard let externalID = reminder.calendarItemExternalIdentifier,
                      let listID = reminder.calendar?.calendarIdentifier else { continue }
                externalCounts[externalKey(listID: listID, externalID: externalID), default: 0] += 1
            }

            var result: [Date: [CalendarDayReminder]] = [:]
            for reminder in fetched {
                guard let title = reminder.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { continue }
                let due = ReminderDateSemantics.dueDate(
                    components: reminder.dueDateComponents,
                    creationDate: reminder.creationDate
                )
                let day = due.date.startOfDay
                guard day >= interval.start && day < interval.end else { continue }
                let linkedByTaskURL = taskID(in: reminder) != nil
                let linkedByItemIdentifier = linkedItemIdentifiers.contains(reminder.calendarItemIdentifier)
                var linkedByExternalIdentifier = false
                if let externalID = reminder.calendarItemExternalIdentifier,
                   let listID = reminder.calendar?.calendarIdentifier {
                    let key = externalKey(listID: listID, externalID: externalID)
                    linkedByExternalIdentifier = externalCounts[key] == 1 && linkedExternalIdentifiers.contains(key)
                }
                let item = CalendarDayReminder(
                    id: reminder.calendarItemIdentifier,
                    title: title,
                    dueDate: due.date,
                    hasSpecificTime: due.hasSpecificTime,
                    isCompleted: reminder.isCompleted,
                    listTitle: reminder.calendar?.title ?? Self.reminderListName,
                    isChecklistLinked: linkedByTaskURL || linkedByItemIdentifier || linkedByExternalIdentifier
                )
                result[day, default: []].append(item)
            }

            monthRemindersByDay = result.mapValues { items in
                items.sorted {
                    if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
                    if $0.dueDate != $1.dueDate { return $0.dueDate < $1.dueDate }
                    return $0.title < $1.title
                }
            }
        }
    }

    func createOrUseReminderList() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard isAuthorized else {
            statusMessage = "请先允许完整提醒事项访问权限"
            return
        }
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        if let existing = eventStore.calendars(for: .reminder).first(where: {
            $0.allowsContentModifications && $0.title == Self.reminderListName
        }) {
            selectedListID = existing.calendarIdentifier
            statusMessage = "已选择“\(Self.reminderListName)”"
            return
        }

        guard let source = eventStore.defaultCalendarForNewReminders()?.source
                ?? eventStore.calendars(for: .reminder).first(where: \.allowsContentModifications)?.source else {
            statusMessage = "没有找到可用于创建提醒事项列表的账户"
            return
        }

        let list = EKCalendar(for: .reminder, eventStore: eventStore)
        list.title = Self.reminderListName
        list.source = source
        do {
            try eventStore.saveCalendar(list, commit: true)
            refreshLists()
            selectedListID = list.calendarIdentifier
            statusMessage = "已创建并选择“\(Self.reminderListName)”"
        } catch {
            statusMessage = "创建提醒事项列表失败：\(error.localizedDescription)"
        }
    }

    func importFromReminders(into appStore: AppStore) async {
        guard prepareForTransfer() else { return }
        guard let list = selectedList else {
            statusMessage = "请先选择一个可编辑的提醒事项列表"
            return
        }
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        let range = transferRange
        let all = await fetchReminders(in: eventStore.calendars(for: .reminder))
        let pendingDeletions = appStore.pendingReminderDeletions
        let identifiersBeingDeleted = Set(pendingDeletions.flatMap {
            matchingReminderIdentifiers(for: $0, in: all)
        })
        let deletionSummary = syncPendingDeletions(in: appStore, reminders: all)
        let selected = all.filter { $0.calendar?.calendarIdentifier == list.calendarIdentifier }
            .filter { !identifiersBeingDeleted.contains($0.calendarItemIdentifier) }
            .filter { $0.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
        var tasks = appStore.tasks
        var added = 0
        var updated = 0
        var conflicts = 0
        var processed = Set<UUID>()
        let now = Date()

        for reminder in selected {
            let due = ReminderDateSemantics.dueDate(
                components: reminder.dueDateComponents,
                creationDate: reminder.creationDate,
                now: now
            )
            guard due.date >= range.start && due.date < range.end else { continue }
            if isPendingDeletion(reminder, matching: appStore.pendingReminderDeletions, among: all) { continue }

            let itemID = reminder.calendarItemIdentifier
            let sourceID = taskID(in: reminder)
            let directIndex = sourceID.flatMap { taskID in tasks.firstIndex { $0.id == taskID } }
                ?? tasks.firstIndex { $0.reminderCalendarItemIdentifier == itemID }
            let externalID = reminder.calendarItemExternalIdentifier
            let listID = reminder.calendar?.calendarIdentifier
            let externalMatches = externalID.map { value in
                selected.filter { $0.calendarItemExternalIdentifier == value }.count
            } ?? 0
            let externalTaskIndices = externalID.map { value in
                tasks.indices.filter { index in
                    tasks[index].reminderCalendarItemExternalIdentifier == value &&
                        (tasks[index].reminderListIdentifier == listID || externalMatches == 1)
                }
            } ?? []
            let externalIndex = externalTaskIndices.count == 1 ? externalTaskIndices.first : nil
            let index = directIndex ?? externalIndex

            if externalTaskIndices.count > 1 || (externalMatches > 1 && tasks.contains(where: {
                $0.reminderCalendarItemExternalIdentifier == externalID &&
                    $0.reminderListIdentifier == listID
            })) {
                conflicts += 1
                continue
            }

            let taskID = index.map { tasks[$0].id } ?? sourceID ?? UUID()
            guard !processed.contains(taskID) else {
                conflicts += 1
                continue
            }
            _ = attachTaskIdentity(taskID, to: reminder)
            let freshIdentifier = reminder.calendarItemIdentifier

            if let index {
                tasks[index].title = reminder.title ?? tasks[index].title
                tasks[index].notes = reminder.notes ?? ""
                tasks[index].dueDate = due.date
                tasks[index].hasSpecificTime = due.hasSpecificTime
                tasks[index].isCompleted = reminder.isCompleted
                tasks[index].completedAt = reminder.isCompleted ? (reminder.completionDate ?? tasks[index].completedAt ?? now) : nil
                tasks[index].reminderCalendarItemIdentifier = freshIdentifier
                tasks[index].reminderCalendarItemExternalIdentifier = reminder.calendarItemExternalIdentifier
                tasks[index].reminderListIdentifier = reminder.calendar?.calendarIdentifier
                tasks[index].reminderSyncedAt = now
                updated += 1
            } else {
                tasks.append(TodoItem(
                    id: taskID,
                    title: reminder.title ?? "提醒事项",
                    notes: reminder.notes ?? "",
                    dueDate: due.date,
                    isCompleted: reminder.isCompleted,
                    createdAt: reminder.creationDate ?? now,
                    completedAt: reminder.isCompleted ? (reminder.completionDate ?? now) : nil,
                    hasSpecificTime: due.hasSpecificTime,
                    reminderCalendarItemIdentifier: freshIdentifier,
                    reminderCalendarItemExternalIdentifier: reminder.calendarItemExternalIdentifier,
                    reminderListIdentifier: reminder.calendar?.calendarIdentifier,
                    reminderSyncedAt: now,
                    localUpdatedAt: now
                ))
                added += 1
            }
            processed.insert(taskID)
        }

        appStore.applyReminderTasks(tasks)
        statusMessage = "已从“\(list.title)”导入：新增 \(added)，更新 \(updated)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)，冲突 \(conflicts)"
    }

    func syncToReminders(from appStore: AppStore) async {
        guard prepareForTransfer() else { return }
        guard let destination = selectedList else {
            statusMessage = "请先选择一个可编辑的提醒事项列表"
            return
        }
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        statusMessage = "正在检查已关联的提醒事项…"
        await Task.yield()

        let all = await fetchReminders(in: eventStore.calendars(for: .reminder))
        let deletionSummary = syncPendingDeletions(in: appStore, reminders: all)
        var tasks = appStore.tasks
        var created = 0
        var updated = 0
        var moved = 0
        var conflicts = 0
        let now = Date()
        let range = transferRange
        let eligibleTaskCount = tasks.filter { $0.dueDate >= range.start && $0.dueDate < range.end }.count
        var processedTaskCount = 0

        for index in tasks.indices {
            let task = tasks[index]
            guard task.dueDate >= range.start && task.dueDate < range.end else { continue }
            processedTaskCount += 1
            let matches = matchingReminders(for: task, in: all)
            guard matches.count <= 1 else { conflicts += 1; continue }
            let existing = matches.first
            if existing == nil && (task.reminderCalendarItemIdentifier != nil ||
                                   task.reminderCalendarItemExternalIdentifier != nil ||
                                   task.reminderListIdentifier != nil) {
                conflicts += 1
                continue
            }

            let reminder = existing ?? EKReminder(eventStore: eventStore)
            let shouldMove = existing.map { $0.calendar?.calendarIdentifier != destination.calendarIdentifier } ?? false
            reminder.calendar = destination
            reminder.title = task.title
            reminder.notes = task.notes.isEmpty ? nil : task.notes
            reminder.dueDateComponents = ReminderDateSemantics.components(
                from: task.dueDate,
                hasSpecificTime: task.hasSpecificTime ?? false
            )
            reminder.isCompleted = task.isCompleted
            reminder.completionDate = task.isCompleted ? (task.completedAt ?? now) : nil
            if reminder.url == nil || isDeskFlowReminderURL(reminder.url) {
                reminder.url = URL(string: "deskflow://reminder/\(task.id.uuidString)")
            }

            do {
                try eventStore.save(reminder, commit: true)
                tasks[index].reminderCalendarItemIdentifier = reminder.calendarItemIdentifier
                tasks[index].reminderCalendarItemExternalIdentifier = reminder.calendarItemExternalIdentifier
                tasks[index].reminderListIdentifier = reminder.calendar?.calendarIdentifier
                tasks[index].reminderSyncedAt = now
                if existing == nil { created += 1 }
                else if shouldMove { moved += 1 }
                else { updated += 1 }
            } catch {
                if created + updated + moved > 0 { appStore.applyReminderTasks(tasks) }
                statusMessage = "写入中断：新增 \(created)，更新 \(updated)，移入所选列表 \(moved)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)；\(error.localizedDescription)"
                return
            }

            if processedTaskCount.isMultiple(of: 10) {
                statusMessage = "正在同步到“\(destination.title)”：已检查 \(processedTaskCount)/\(eligibleTaskCount) 项…"
                await Task.yield()
            }
        }
        if created + updated + moved > 0 { appStore.applyReminderTasks(tasks) }
        statusMessage = "已写入“\(destination.title)”：新增 \(created)，更新 \(updated)，移入所选列表 \(moved)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)，未安全匹配 \(conflicts)"
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") else { return }
        NSWorkspace.shared.open(url)
    }

    private var selectedList: EKCalendar? {
        eventStore.calendars(for: .reminder).first { $0.calendarIdentifier == selectedListID }
    }

    private static func hasReminderAccess(_ status: EKAuthorizationStatus) -> Bool {
        if #available(macOS 14.0, *) { return status == .fullAccess }
        return status == .authorized
    }

    private var transferRange: (start: Date, end: Date) {
        let start = Calendar.current.date(byAdding: .year, value: -1, to: Date().startOfDay) ?? Date().startOfDay
        let end = Calendar.current.date(byAdding: .year, value: 2, to: Date().startOfDay)
            ?? Date().addingTimeInterval(730 * 86_400)
        return (start, end)
    }

    private func prepareForTransfer() -> Bool {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard isAuthorized else {
            statusMessage = "请先允许完整提醒事项访问权限"
            return false
        }
        refreshLists()
        guard !selectedListID.isEmpty else {
            statusMessage = "没有可写入的提醒事项列表，请先选择或创建一个列表"
            return false
        }
        return true
    }

    private func fetchReminders(in calendars: [EKCalendar]) async -> [EKReminder] {
        guard !calendars.isEmpty else { return [] }
        let predicate = eventStore.predicateForReminders(in: calendars)
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private func taskID(in reminder: EKReminder) -> UUID? {
        guard let url = reminder.url, isDeskFlowReminderURL(url) else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }

    private func isDeskFlowReminderURL(_ url: URL?) -> Bool {
        url?.scheme == "deskflow" && url?.host == "reminder"
    }

    private func attachTaskIdentity(_ taskID: UUID, to reminder: EKReminder) -> Bool {
        if let url = reminder.url, !isDeskFlowReminderURL(url) { return false }
        let expected = URL(string: "deskflow://reminder/\(taskID.uuidString)")
        guard reminder.url != expected else { return true }
        reminder.url = expected
        do {
            try eventStore.save(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }

    private func externalKey(listID: String, externalID: String) -> String {
        "\(listID)\u{1F}\(externalID)"
    }

    private func matchingReminders(for task: TodoItem, in reminders: [EKReminder]) -> [EKReminder] {
        var candidates = reminders
        if let identifier = task.reminderCalendarItemIdentifier,
           let item = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder {
            candidates.append(item)
        }
        if let externalIdentifier = task.reminderCalendarItemExternalIdentifier {
            candidates += eventStore.calendarItems(withExternalIdentifier: externalIdentifier)
                .compactMap { $0 as? EKReminder }
        }

        var byIdentifier: [String: EKReminder] = [:]
        var identities: [ReminderItemIdentity] = []
        for reminder in candidates {
            let identifier = reminder.calendarItemIdentifier
            guard byIdentifier[identifier] == nil else { continue }
            byIdentifier[identifier] = reminder
            identities.append(ReminderItemIdentity(
                taskID: taskID(in: reminder),
                itemIdentifier: identifier,
                externalIdentifier: reminder.calendarItemExternalIdentifier,
                listIdentifier: reminder.calendar?.calendarIdentifier ?? ""
            ))
        }
        return ReminderItemIdentityMatcher.matchingIdentifiers(
            taskID: task.id,
            itemIdentifier: task.reminderCalendarItemIdentifier,
            externalIdentifier: task.reminderCalendarItemExternalIdentifier,
            listIdentifier: task.reminderListIdentifier,
            candidates: identities
        ).compactMap { byIdentifier[$0] }
    }

    private func isPendingDeletion(
        _ reminder: EKReminder,
        matching deletions: [PendingReminderDeletion],
        among reminders: [EKReminder]
    ) -> Bool {
        deletions.contains { pending in
            let matches = matchingReminderIdentifiers(for: pending, in: reminders)
            return matches.contains(reminder.calendarItemIdentifier)
        }
    }

    private func matchingReminderIdentifiers(
        for pending: PendingReminderDeletion,
        in reminders: [EKReminder]
    ) -> [String] {
        let candidates = reminders.map {
            ReminderItemIdentity(
                taskID: taskID(in: $0),
                itemIdentifier: $0.calendarItemIdentifier,
                externalIdentifier: $0.calendarItemExternalIdentifier,
                listIdentifier: $0.calendar?.calendarIdentifier ?? ""
            )
        }
        return ReminderItemIdentityMatcher.matchingIdentifiers(
            taskID: pending.taskID,
            itemIdentifier: pending.itemIdentifier,
            externalIdentifier: pending.externalIdentifier,
            listIdentifier: pending.listIdentifier,
            candidates: candidates
        )
    }

    @discardableResult
    private func syncPendingDeletions(in appStore: AppStore, reminders: [EKReminder]) -> ReminderDeletionSummary {
        var summary = ReminderDeletionSummary()
        for pending in appStore.pendingReminderDeletions {
            let identifiers = matchingReminderIdentifiers(for: pending, in: reminders)
            guard identifiers.count <= 1 else {
                summary.pending += 1
                continue
            }
            do {
                if let identifier = identifiers.first,
                   let reminder = reminders.first(where: { $0.calendarItemIdentifier == identifier }) {
                    try eventStore.remove(reminder, commit: true)
                    summary.removed += 1
                }
                appStore.finishReminderDeletion(taskID: pending.taskID)
            } catch {
                summary.pending += 1
            }
        }
        return summary
    }
}
