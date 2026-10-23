import AppKit
import Foundation
import UniformTypeIdentifiers
import UserNotifications

@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore()

    @Published private(set) var tasks: [TodoItem] = []
    @Published private(set) var calendarSchedules: [CalendarSchedule] = []
    @Published private(set) var reminderItems: [ReminderItem] = []
    @Published private(set) var focusRecords: [FocusRecord] = []
    @Published private(set) var pendingCalendarDeletions: [PendingCalendarDeletion] = []
    @Published private(set) var pendingReminderDeletions: [PendingReminderDeletion] = []

    @Published var selectedDate: Date = Date().startOfDay
    @Published var selectedTab: AppTab = .month
    @Published var displayedMonth: Date = Date().startOfDay

    @Published var sessionLength: Int = 25 * 60
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isTimerRunning = false
    @Published var timerTaskID: UUID?

    private var timer: Timer?
    private var timerEndDate: Date?
    private var sessionStartedAt: Date?
    private var persistenceBlockedByDecodeFailure = false

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private init() {
        load()
        restoreTimerIfNeeded()
    }

    deinit {
        timer?.invalidate()
    }

    var dataDirectory: URL {
        if let override = ProcessInfo.processInfo.environment["DESKFLOW_DATA_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("DeskFlow", isDirectory: true)
    }

    var dataFile: URL { dataDirectory.appendingPathComponent("data.json") }

    var timerTaskTitle: String {
        guard let id = timerTaskID else { return "未绑定任务" }
        return tasks.first(where: { $0.id == id })?.title
            ?? reminderItems.first(where: { $0.id == id })?.title
            ?? calendarSchedules.first(where: { $0.id == id })?.title
            ?? "未绑定任务"
    }

    var elapsedSeconds: Int {
        max(0, sessionLength - remainingSeconds)
    }

    func tasks(on date: Date) -> [TodoItem] {
        tasks
            .filter { Calendar.current.isDate($0.dueDate, inSameDayAs: date) }
            .sorted {
                if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
                return $0.createdAt < $1.createdAt
            }
    }

    func reminderItems(on date: Date) -> [ReminderItem] {
        reminderItems
            .filter { Calendar.current.isDate($0.dueDate, inSameDayAs: date) }
            .sorted {
                if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
                return $0.dueDate < $1.dueDate
            }
    }

    func addTask(title: String, dueDate: Date? = nil) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        tasks.append(TodoItem(
            title: clean,
            dueDate: TaskScheduleDefaults.startDate(on: dueDate ?? selectedDate),
            hasSpecificTime: true,
            calendarDurationSeconds: TaskScheduleDefaults.durationSeconds,
            localUpdatedAt: Date()
        ))
        save()
    }

    func updateTask(_ task: TodoItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updated = task
        updated.localUpdatedAt = Date()
        tasks[index] = updated
        save()
    }

    func toggleTask(_ task: TodoItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
        tasks[index].localUpdatedAt = Date()
        save()
    }

    func addReminderItem(title: String, dueDate: Date? = nil) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let date = dueDate ?? selectedDate
        reminderItems.append(ReminderItem(title: clean, dueDate: date.startOfDay, createdAt: Date()))
        save()
    }

    func updateReminderItem(_ item: ReminderItem) {
        guard let index = reminderItems.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.localUpdatedAt = Date()
        reminderItems[index] = updated
        save()
    }

    func toggleReminderItem(_ item: ReminderItem) {
        guard let index = reminderItems.firstIndex(where: { $0.id == item.id }) else { return }
        reminderItems[index].isCompleted.toggle()
        reminderItems[index].completedAt = reminderItems[index].isCompleted ? Date() : nil
        reminderItems[index].localUpdatedAt = Date()
        save()
    }

    func deleteReminderItem(_ item: ReminderItem) { deleteReminderItems(ids: [item.id]) }

    func deleteReminderItems(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        for item in reminderItems where ids.contains(item.id) {
            if item.reminderCalendarItemIdentifier != nil || item.reminderCalendarItemExternalIdentifier != nil || item.reminderListIdentifier != nil,
               !pendingReminderDeletions.contains(where: { $0.taskID == item.id }) {
                pendingReminderDeletions.append(PendingReminderDeletion(
                    taskID: item.id,
                    itemIdentifier: item.reminderCalendarItemIdentifier,
                    externalIdentifier: item.reminderCalendarItemExternalIdentifier,
                    listIdentifier: item.reminderListIdentifier
                ))
            }
        }
        reminderItems.removeAll { ids.contains($0.id) }
        if let timerTaskID, ids.contains(timerTaskID) { self.timerTaskID = nil }
        save()
    }

    func deleteCalendarSchedules(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        for schedule in calendarSchedules where ids.contains(schedule.id) {
            if schedule.calendarEventIdentifier != nil || schedule.calendarEventExternalIdentifier != nil || schedule.calendarIdentifier != nil,
               !pendingCalendarDeletions.contains(where: { $0.taskID == schedule.id }) {
                pendingCalendarDeletions.append(PendingCalendarDeletion(
                    taskID: schedule.id,
                    eventIdentifier: schedule.calendarEventIdentifier,
                    externalIdentifier: schedule.calendarEventExternalIdentifier,
                    calendarIdentifier: schedule.calendarIdentifier
                ))
            }
        }
        calendarSchedules.removeAll { ids.contains($0.id) }
        save()
    }

    func applyCalendarSchedules(_ schedules: [CalendarSchedule]) {
        calendarSchedules = schedules
        save()
    }

    func updateCalendarSchedule(_ schedule: CalendarSchedule) {
        guard let index = calendarSchedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        var updated = schedule
        updated.localUpdatedAt = Date()
        calendarSchedules[index] = updated
        save()
    }

    func deleteTask(_ task: TodoItem) {
        deleteTasks(ids: [task.id])
    }

    func deleteTasks(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        tasks.removeAll { ids.contains($0.id) }
        if let timerTaskID, ids.contains(timerTaskID) { self.timerTaskID = nil }
        save()
    }

    func finishCalendarDeletion(taskID: UUID) {
        pendingCalendarDeletions.removeAll { $0.taskID == taskID }
        save()
    }

    func finishReminderDeletion(taskID: UUID) {
        pendingReminderDeletions.removeAll { $0.taskID == taskID }
        save()
    }

    func applyReminderItems(_ items: [ReminderItem]) {
        reminderItems = items
        save()
    }

    func selectTaskForTimer(_ task: TodoItem) {
        if isTimerRunning { pauseTimer() }
        if elapsedSeconds > 0 { resetTimer() }
        timerTaskID = task.id
        persist()
    }

    func setSessionLength(minutes: Int) {
        guard !isTimerRunning else { return }
        sessionLength = minutes * 60
        remainingSeconds = sessionLength
        persist()
    }

    func toggleTimer() {
        isTimerRunning ? pauseTimer() : startTimer()
    }

    func startTimer() {
        guard !isTimerRunning, remainingSeconds > 0 else { return }
        isTimerRunning = true
        if sessionStartedAt == nil { sessionStartedAt = Date() }
        timerEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        installTimer()
        persist()
    }

    func pauseTimer() {
        guard isTimerRunning else { return }
        updateRemainingFromEndDate()
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        timerEndDate = nil
        persist()
    }

    func resetTimer() {
        clearTimerState()
        persist()
    }

    func finishAndSaveTimer() {
        if isTimerRunning { updateRemainingFromEndDate() }
        let duration = elapsedSeconds
        guard duration >= 60 else {
            resetTimer()
            return
        }
        completeTimerRecording(duration: duration, notify: false)
    }

    func deleteFocusRecord(_ record: FocusRecord) {
        focusRecords.removeAll { $0.id == record.id }
        save()
    }

    func focusSeconds(on date: Date) -> Int {
        focusRecords
            .filter { Calendar.current.isDate($0.startedAt, inSameDayAs: date) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    func focusSeconds(from start: Date, to end: Date) -> Int {
        focusRecords
            .filter { $0.startedAt >= start && $0.startedAt < end }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    func exportJSON() {
        if isTimerRunning { updateRemainingFromEndDate() }
        let panel = NSSavePanel()
        panel.title = "导出桌面清单备份"
        panel.nameFieldStringValue = "桌面清单备份-\(Self.fileDateFormatter.string(from: Date())).json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try encoder.encode(currentPersistedData())
            try data.write(to: url, options: .atomic)
        } catch {
            showError("导出失败", detail: error.localizedDescription)
        }
    }

    func exportCSV() {
        let panel = NSSavePanel()
        panel.title = "导出本地清单任务"
        panel.nameFieldStringValue = "桌面清单-本地任务-\(Self.fileDateFormatter.string(from: Date())).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        var rows = ["状态,任务,日期时间,是否指定时间,备注"]
        for task in tasks.sorted(by: { $0.dueDate < $1.dueDate }) {
            rows.append([
                task.isCompleted ? "已完成" : "未完成",
                task.title,
                (task.hasSpecificTime ?? false) ? Self.dateTimeFormatter.string(from: task.dueDate) : Self.dayFormatter.string(from: task.dueDate),
                (task.hasSpecificTime ?? false) ? "是" : "否",
                task.notes,
            ].map(Self.csvField).joined(separator: ","))
        }
        do {
            try ("\u{FEFF}" + rows.joined(separator: "\n")).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            showError("导出失败", detail: error.localizedDescription)
        }
    }

    func prepareForTermination() {
        if isTimerRunning { updateRemainingFromEndDate() }
        persist()
    }

    private func makeFocusRecord(duration: Int) -> FocusRecord {
        let title = timerTaskID.flatMap { id in
            tasks.first(where: { $0.id == id })?.title
                ?? reminderItems.first(where: { $0.id == id })?.title
                ?? calendarSchedules.first(where: { $0.id == id })?.title
        } ?? "自由专注"
        return FocusRecord(
            taskID: timerTaskID,
            taskTitle: title,
            startedAt: sessionStartedAt ?? Date().addingTimeInterval(TimeInterval(-duration)),
            durationSeconds: duration
        )
    }

    private func completeTimerRecording(duration: Int, notify: Bool) {
        let record = makeFocusRecord(duration: duration)
        clearTimerState()
        focusRecords.append(record)
        persist()
        if notify { notifyTimerFinished(duration: duration) }
    }

    private func clearTimerState() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        timerEndDate = nil
        sessionStartedAt = nil
        remainingSeconds = sessionLength
    }

    private func installTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func tick() {
        updateRemainingFromEndDate()
        if remainingSeconds <= 0 {
            completeTimerRecording(duration: sessionLength, notify: true)
        }
    }

    private func updateRemainingFromEndDate() {
        guard let end = timerEndDate else { return }
        remainingSeconds = max(0, Int(ceil(end.timeIntervalSinceNow)))
    }

    private func notifyTimerFinished(duration: Int) {
        let content = UNMutableNotificationContent()
        content.title = "一个番茄完成了"
        let title = focusRecords.last?.taskTitle ?? "自由专注"
        content.body = title == "自由专注" ? "休息一下，再继续。" : "“\(title)”已记录 \(duration / 60) 分钟。"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func load() {
        do {
            let data = try Data(contentsOf: dataFile)
            let decoded = try decoder.decode(PersistedData.self, from: data)
            tasks = decoded.tasks
            calendarSchedules = decoded.calendarSchedules
            reminderItems = decoded.reminderItems
            focusRecords = decoded.focusRecords
            pendingCalendarDeletions = decoded.pendingCalendarDeletions
            pendingReminderDeletions = decoded.pendingReminderDeletions
            if let snapshot = decoded.timer {
                remainingSeconds = snapshot.remainingSeconds
                sessionLength = snapshot.sessionLength
                isTimerRunning = snapshot.isRunning
                timerEndDate = snapshot.endDate
                sessionStartedAt = snapshot.startedAt
                timerTaskID = snapshot.taskID
            }
            if decoded.didMigrateLegacyRecords { persist() }
        } catch {
            if (error as NSError).code != NSFileReadNoSuchFileError {
                persistenceBlockedByDecodeFailure = true
                NSLog("DeskFlow data load failed: %@", error.localizedDescription)
            }
        }
    }

    private func restoreTimerIfNeeded() {
        guard isTimerRunning, let end = timerEndDate else { return }
        remainingSeconds = max(0, Int(ceil(end.timeIntervalSinceNow)))
        if remainingSeconds > 0 {
            installTimer()
        } else {
            isTimerRunning = false
            remainingSeconds = sessionLength
            timerEndDate = nil
            sessionStartedAt = nil
            persist()
        }
    }

    private func currentPersistedData() -> PersistedData {
        PersistedData(
            tasks: tasks,
            calendarSchedules: calendarSchedules,
            reminderItems: reminderItems,
            focusRecords: focusRecords,
            timer: TimerSnapshot(
                remainingSeconds: remainingSeconds,
                sessionLength: sessionLength,
                isRunning: isTimerRunning,
                endDate: timerEndDate,
                startedAt: sessionStartedAt,
                taskID: timerTaskID
            ),
            pendingCalendarDeletions: pendingCalendarDeletions,
            pendingReminderDeletions: pendingReminderDeletions
        )
    }

    private func save() { persist() }

    private func persist() {
        guard !persistenceBlockedByDecodeFailure else { return }
        do {
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
            let data = try encoder.encode(currentPersistedData())
            try data.write(to: dataFile, options: .atomic)
        } catch {
            NSLog("DeskFlow data save failed: %@", error.localizedDescription)
        }
    }

    private func showError(_ title: String, detail: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.alertStyle = .warning
        alert.runModal()
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter
    }()

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private static func csvField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
