import Foundation

@main
struct DeskFlowSelfTest {
    @MainActor
    static func main() throws {
        let legacyJSON = """
        {"id":"00000000-0000-0000-0000-000000000001","title":"旧版任务","notes":"","dueDate":"2026-08-20T00:00:00Z","isCompleted":false,"createdAt":"2026-08-20T00:00:00Z"}
        """
        let legacyDecoder = JSONDecoder()
        legacyDecoder.dateDecodingStrategy = .iso8601
        let legacyTask = try legacyDecoder.decode(TodoItem.self, from: Data(legacyJSON.utf8))
        precondition(legacyTask.hasSpecificTime == nil)
        let legacyDeletionJSON = """
        {"taskID":"00000000-0000-0000-0000-000000000002","eventIdentifier":"legacy-calendar-event"}
        """
        let legacyDeletion = try legacyDecoder.decode(PendingCalendarDeletion.self, from: Data(legacyDeletionJSON.utf8))
        precondition(legacyDeletion.kind == nil)

        let store = AppStore.shared
        precondition(store.tasks.isEmpty)
        precondition(store.focusRecords.isEmpty)

        store.addTask(title: "验证本地保存", dueDate: Date())
        guard var task = store.tasks.first else { fatalError("task creation failed") }
        store.addTask(title: "验证连续任务", dueDate: task.dueDate.startOfDay)
        guard let chainedTask = store.tasks.last else { fatalError("second task creation failed") }
        precondition(chainedTask.dueDate == task.dueDate.addingTimeInterval(TaskScheduleDefaults.durationSeconds))
        store.addReminderItem(title: "验证独立事项", dueDate: task.dueDate)
        precondition(store.reminderItems.count == 1)
        precondition(store.tasks.count == 2)
        task.notes = "JSON + CSV"
        task.hasSpecificTime = true
        task.calendarEventIdentifier = "self-test-event-id"
        task.calendarEventExternalIdentifier = "self-test-external-id"
        task.calendarIdentifier = "self-test-calendar-id"
        task.calendarSyncedAt = Date()
        task.dueDate = Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: task.dueDate) ?? task.dueDate
        store.updateTask(task)
        store.toggleTask(task)

        guard let updated = store.tasks.first else { fatalError("task update failed") }
        precondition(updated.isCompleted)
        precondition(updated.notes == "JSON + CSV")
        precondition(updated.hasSpecificTime == true)
        precondition(updated.calendarEventIdentifier == "self-test-event-id")

        store.selectTaskForTimer(updated)
        store.sessionLength = 61
        store.remainingSeconds = 1
        store.finishAndSaveTimer()

        precondition(store.focusRecords.count == 1)
        precondition(FileManager.default.fileExists(atPath: store.dataFile.path))

        let data = try Data(contentsOf: store.dataFile)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let persisted = try decoder.decode(PersistedData.self, from: data)
        precondition(persisted.tasks.count == 2)
        precondition(persisted.reminderItems.count == 1)
        precondition(persisted.focusRecords.count == 1)
        precondition(persisted.tasks.first(where: { $0.id == updated.id })?.calendarEventIdentifier == "self-test-event-id")
        precondition(persisted.reminderItems.first?.reminderCalendarItemIdentifier == nil)

        store.deleteTask(updated)
        precondition(store.pendingCalendarDeletions.first(where: { $0.taskID == updated.id })?.kind == .task)
        let postDeleteData = try Data(contentsOf: store.dataFile)
        let postDeletePersisted = try decoder.decode(PersistedData.self, from: postDeleteData)
        precondition(postDeletePersisted.pendingCalendarDeletions.first(where: { $0.taskID == updated.id })?.kind == .task)

        let linked = ReminderItem(title: "已关联事项", dueDate: Date(),
                                  reminderCalendarItemIdentifier: "reminder-id",
                                  reminderCalendarItemExternalIdentifier: "reminder-external",
                                  reminderListIdentifier: "reminder-list")
        let local = ReminderItem(title: "本地事项", dueDate: Date())
        let retained = ReminderItem(title: "保留事项", dueDate: Date())
        store.applyReminderItems([linked, local, retained])
        store.deleteReminderItems(ids: [linked.id, local.id])
        precondition(store.reminderItems.map(\.id) == [retained.id])
        precondition(store.pendingReminderDeletions.count == 1)
        let deletion = store.pendingReminderDeletions[0]
        precondition(deletion.taskID == linked.id && deletion.itemIdentifier == "reminder-id")
        precondition(deletion.externalIdentifier == "reminder-external" && deletion.listIdentifier == "reminder-list")
        precondition(store.tasks.count == 1)
        let persistedDeletion = try decoder.decode(PersistedData.self, from: Data(contentsOf: store.dataFile))
        precondition(persistedDeletion.pendingReminderDeletions == [deletion])
        precondition(persistedDeletion.reminderItems.map(\.id) == [retained.id])

        print("SELF_TEST_OK tasks=\(persisted.tasks.count) reminders=\(persisted.reminderItems.count) focusRecords=\(persisted.focusRecords.count) data=\(store.dataFile.path)")
    }
}
