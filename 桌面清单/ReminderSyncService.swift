import AppKit
import EventKit
import Foundation

struct ReminderListChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let sourceTitle: String
    let allowsContentModifications: Bool
    let colorHex: UInt32

    var displayName: String { "\(title) · \(sourceTitle)\(allowsContentModifications ? "" : " · 只读")" }
}

struct CalendarDayReminder: Identifiable, Hashable {
    let id: String
    let title: String
    let dueDate: Date
    let hasSpecificTime: Bool
    let isCompleted: Bool
    let listTitle: String

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
        } else {
            statusMessage = authorizationDescription
        }
    }

    var isAuthorized: Bool { Self.hasReminderAccess(authorizationStatus) }

    var hasSelectedList: Bool {
        lists.contains { $0.id == selectedListID }
    }

    var canWriteToSelectedList: Bool {
        lists.first { $0.id == selectedListID }?.allowsContentModifications == true
    }

    var connectionStatus: String {
        guard isAuthorized else { return "未连接" }
        guard hasSelectedList else { return "已授权" }
        return canWriteToSelectedList ? "已连接" : "已连接（只读）"
    }

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
            refreshAuthorizationStatus()
            if granted && isAuthorized {
                statusMessage = accessStatusMessage
            } else {
                statusMessage = authorizationDescription
            }
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            refreshLists()
            statusMessage = "授权失败：\(error.localizedDescription)；\(authorizationDescription)"
        }
    }

    /// Re-checks privacy settings after the app becomes active.
    /// Returns true only when full reminder access was newly granted.
    @discardableResult
    func refreshAuthorizationStatus() -> Bool {
        let wasAuthorized = isAuthorized
        refreshLists()

        guard isAuthorized else {
            statusMessage = authorizationDescription
            return false
        }

        guard !wasAuthorized else { return false }
        statusMessage = accessStatusMessage
        return true
    }

    func refreshLists() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard isAuthorized else {
            lists = []
            monthRemindersByDay = [:]
            statusMessage = authorizationDescription
            return
        }

        lists = eventStore.calendars(for: .reminder)
            .map {
                ReminderListChoice(
                    id: $0.calendarIdentifier,
                    title: $0.title,
                    sourceTitle: $0.source.title,
                    allowsContentModifications: $0.allowsContentModifications,
                    colorHex: Self.colorHex(for: $0.color)
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
                ?? lists.first(where: \.allowsContentModifications)?.id
                ?? lists.first?.id
                ?? ""
        }
    }

    private static func colorHex(for color: NSColor?) -> UInt32 {
        guard let color, let rgb = color.usingColorSpace(.deviceRGB) else { return 0x1683FF }
        let red = UInt32((rgb.redComponent * 255).rounded())
        let green = UInt32((rgb.greenComponent * 255).rounded())
        let blue = UInt32((rgb.blueComponent * 255).rounded())
        return (red << 16) | (green << 8) | blue
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
            var result: [Date: [CalendarDayReminder]] = [:]
            for reminder in fetched {
                guard let title = reminder.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { continue }
                let due = ReminderDateSemantics.dueDate(
                    components: reminder.dueDateComponents,
                    creationDate: reminder.creationDate
                )
                let day = due.date.startOfDay
                guard day >= interval.start && day < interval.end else { continue }
                let item = CalendarDayReminder(
                    id: reminder.calendarItemIdentifier,
                    title: title,
                    dueDate: due.date,
                    hasSpecificTime: due.hasSpecificTime,
                    isCompleted: reminder.isCompleted,
                    listTitle: reminder.calendar?.title ?? Self.reminderListName
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
        refreshLists()

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
        guard prepareForTransfer(requireWritable: false) else { return }
        guard let list = selectedList else {
            statusMessage = "请先选择一个可访问的提醒事项列表"
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
        var items = appStore.reminderItems
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

            let itemIdentifier = reminder.calendarItemIdentifier
            let sourceID = taskID(in: reminder)
            let directIndex = sourceID.flatMap { itemID in items.firstIndex { $0.id == itemID } }
                ?? items.firstIndex { $0.reminderCalendarItemIdentifier == itemIdentifier }
            let externalID = reminder.calendarItemExternalIdentifier
            let listID = reminder.calendar?.calendarIdentifier
            let externalMatches = externalID.map { value in
                selected.filter { $0.calendarItemExternalIdentifier == value }.count
            } ?? 0
            let externalItemIndices = externalID.map { value in
                items.indices.filter { index in
                    items[index].reminderCalendarItemExternalIdentifier == value &&
                        (items[index].reminderListIdentifier == listID || externalMatches == 1)
                }
            } ?? []
            let externalIndex = externalItemIndices.count == 1 ? externalItemIndices.first : nil
            let index = directIndex ?? externalIndex

            if externalItemIndices.count > 1 || (externalMatches > 1 && items.contains(where: {
                $0.reminderCalendarItemExternalIdentifier == externalID &&
                    $0.reminderListIdentifier == listID
            })) {
                conflicts += 1
                continue
            }

            let itemID = index.map { items[$0].id } ?? sourceID ?? UUID()
            guard !processed.contains(itemID) else {
                conflicts += 1
                continue
            }
            _ = attachTaskIdentity(itemID, to: reminder)
            let freshIdentifier = reminder.calendarItemIdentifier

            if let index {
                items[index].title = reminder.title ?? items[index].title
                items[index].notes = reminder.notes ?? ""
                items[index].dueDate = due.date
                items[index].hasSpecificTime = due.hasSpecificTime
                items[index].isCompleted = reminder.isCompleted
                items[index].completedAt = reminder.isCompleted ? (reminder.completionDate ?? items[index].completedAt ?? now) : nil
                items[index].reminderCalendarItemIdentifier = freshIdentifier
                items[index].reminderCalendarItemExternalIdentifier = reminder.calendarItemExternalIdentifier
                items[index].reminderListIdentifier = reminder.calendar?.calendarIdentifier
                items[index].reminderSyncedAt = now
                updated += 1
            } else {
                items.append(ReminderItem(
                    id: itemID,
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
            processed.insert(itemID)
        }

        appStore.applyReminderItems(items)
        statusMessage = "已从“\(list.title)”导入：新增 \(added)，更新 \(updated)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)，冲突 \(conflicts)"
    }

    func syncToReminders(from appStore: AppStore) async {
        guard prepareForTransfer(requireWritable: true) else { return }
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
        var items = appStore.reminderItems
        var created = 0
        var updated = 0
        var moved = 0
        var conflicts = 0
        let now = Date()
        let range = transferRange
        let eligibleItemCount = items.filter { $0.dueDate >= range.start && $0.dueDate < range.end }.count
        var processedItemCount = 0

        for index in items.indices {
            let item = items[index]
            guard item.dueDate >= range.start && item.dueDate < range.end else { continue }
            processedItemCount += 1
            let matches = matchingReminders(for: item, in: all)
            guard matches.count <= 1 else { conflicts += 1; continue }
            let existing = matches.first
            if existing == nil && (item.reminderCalendarItemIdentifier != nil ||
                                   item.reminderCalendarItemExternalIdentifier != nil ||
                                   item.reminderListIdentifier != nil) {
                conflicts += 1
                continue
            }

            let reminder = existing ?? EKReminder(eventStore: eventStore)
            let shouldMove = existing.map { $0.calendar?.calendarIdentifier != destination.calendarIdentifier } ?? false
            reminder.calendar = destination
            reminder.title = item.title
            reminder.notes = item.notes.isEmpty ? nil : item.notes
            reminder.dueDateComponents = ReminderDateSemantics.components(
                from: item.dueDate,
                hasSpecificTime: item.hasSpecificTime ?? false
            )
            reminder.isCompleted = item.isCompleted
            reminder.completionDate = item.isCompleted ? (item.completedAt ?? now) : nil
            if reminder.url == nil || isDeskFlowReminderURL(reminder.url) {
                reminder.url = URL(string: "deskflow://reminder/\(item.id.uuidString)")
            }

            do {
                try eventStore.save(reminder, commit: true)
                items[index].reminderCalendarItemIdentifier = reminder.calendarItemIdentifier
                items[index].reminderCalendarItemExternalIdentifier = reminder.calendarItemExternalIdentifier
                items[index].reminderListIdentifier = reminder.calendar?.calendarIdentifier
                items[index].reminderSyncedAt = now
                if existing == nil { created += 1 }
                else if shouldMove { moved += 1 }
                else { updated += 1 }
            } catch {
                if created + updated + moved > 0 { appStore.applyReminderItems(items) }
                statusMessage = "写入中断：新增 \(created)，更新 \(updated)，移入所选列表 \(moved)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)；\(error.localizedDescription)"
                return
            }

            if processedItemCount.isMultiple(of: 10) {
                statusMessage = "正在同步到“\(destination.title)”：已检查 \(processedItemCount)/\(eligibleItemCount) 项…"
                await Task.yield()
            }
        }
        if created + updated + moved > 0 { appStore.applyReminderItems(items) }
        statusMessage = "已写入“\(destination.title)”：新增 \(created)，更新 \(updated)，移入所选列表 \(moved)，删除 \(deletionSummary.removed)，待重试 \(deletionSummary.pending)，未安全匹配 \(conflicts)"
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") else { return }
        NSWorkspace.shared.open(url)
    }

    private var selectedList: EKCalendar? {
        eventStore.calendars(for: .reminder).first { $0.calendarIdentifier == selectedListID }
    }

    private var accessStatusMessage: String {
        guard let list = selectedList else { return "已授权，但没有找到可访问的提醒事项列表" }
        return list.allowsContentModifications
            ? "已连接“\(list.title)”"
            : "已连接只读列表“\(list.title)”；可导入，不能写回"
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

    private func prepareForTransfer(requireWritable: Bool) -> Bool {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard isAuthorized else {
            statusMessage = "请先允许完整提醒事项访问权限"
            return false
        }
        refreshLists()
        guard hasSelectedList else {
            statusMessage = "没有可访问的提醒事项列表，请先选择或创建一个列表"
            return false
        }
        guard !requireWritable || canWriteToSelectedList else {
            statusMessage = "所选列表为只读；请选择可编辑列表后再同步写回"
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

    private func matchingReminders(for task: ReminderItem, in reminders: [EKReminder]) -> [EKReminder] {
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
