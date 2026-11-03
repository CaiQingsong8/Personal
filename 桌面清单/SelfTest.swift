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
        let firstEnd = TaskScheduleDefaults.endDate(start: task.dueDate, duration: TaskScheduleDefaults.durationSeconds)
        precondition(chainedTask.dueDate == TaskScheduleDefaults.nextStart(after: firstEnd))
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

        let calendar = Calendar.current
        let day = calendar.date(from: DateComponents(year: 2026, month: 10, day: 22))!
        let ten = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day)!
        let fifteen = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: day)!
        store.applyTasks([TodoItem(title: "午间排期", dueDate: ten, hasSpecificTime: true, calendarDurationSeconds: 3 * 3600)])
        store.addTask(title: "午后任务", dueDate: day)
        precondition(store.tasks.last?.dueDate == fifteen)
        let seventeen = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: day)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: day)!
        let nine = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        store.applyTasks([TodoItem(title: "晚间排期", dueDate: seventeen, hasSpecificTime: true, calendarDurationSeconds: 2 * 3600)])
        store.addTask(title: "次日任务", dueDate: day)
        precondition(store.tasks.last?.dueDate == nine && calendar.isDate(store.selectedDate, inSameDayAs: tomorrow))
        store.addTask(title: "次日连续任务", dueDate: day)
        precondition(store.tasks.last?.dueDate == nine.addingTimeInterval(2 * 3600))

        let backupEncoder = JSONEncoder()
        backupEncoder.dateEncodingStrategy = .iso8601
        let importedTask = TodoItem(title: "导入任务", dueDate: ten, hasSpecificTime: true)
        let importedReminder = ReminderItem(title: "导入事项", dueDate: day)
        let taskBackup = try backupEncoder.encode(ChecklistBackup(kind: .tasks, tasks: [importedTask], reminderItems: nil))
        let reminderBackup = try backupEncoder.encode(ChecklistBackup(kind: .reminders, tasks: nil, reminderItems: [importedReminder]))
        let firstImport = try store.importChecklistData(taskBackup)
        precondition(firstImport.tasks == 1 && firstImport.reminders == 0)
        let repeatImport = try store.importChecklistData(taskBackup)
        precondition(repeatImport.tasks == 0 && repeatImport.skipped == 1)
        let reminderImport = try store.importChecklistData(reminderBackup)
        precondition(reminderImport.tasks == 0 && reminderImport.reminders == 1)
        let oldBackup = try backupEncoder.encode(PersistedData(tasks: [importedTask], reminderItems: [importedReminder]))
        let legacyImport = try store.importChecklistData(oldBackup)
        precondition(legacyImport.tasks == 0 && legacyImport.reminders == 0 && legacyImport.skipped == 2)
        let oldTask = TodoItem(title: "旧完整备份任务", dueDate: ten, hasSpecificTime: true, calendarEventIdentifier: "old-event-id")
        let oldReminder = ReminderItem(title: "旧完整备份事项", dueDate: day, reminderCalendarItemIdentifier: "old-reminder-id")
        let oldNewBackup = try backupEncoder.encode(PersistedData(tasks: [oldTask], reminderItems: [oldReminder]))
        let oldNewImport = try store.importChecklistData(oldNewBackup)
        precondition(oldNewImport.tasks == 1 && oldNewImport.reminders == 1)
        precondition(store.tasks.first(where: { $0.id == oldTask.id })?.calendarEventIdentifier == "old-event-id")
        precondition(store.reminderItems.first(where: { $0.id == oldReminder.id })?.reminderCalendarItemIdentifier == "old-reminder-id")
        let deletedBackup = try backupEncoder.encode(PersistedData(tasks: [updated], reminderItems: [linked]))
        let deletedImport = try store.importChecklistData(deletedBackup)
        precondition(deletedImport.tasks == 0 && deletedImport.reminders == 0 && deletedImport.skipped == 2)
        let savedAfterImport = try decoder.decode(PersistedData.self, from: Data(contentsOf: store.dataFile))
        precondition(savedAfterImport.tasks.contains(where: { $0.id == importedTask.id }))
        precondition(savedAfterImport.reminderItems.contains(where: { $0.id == importedReminder.id }))
        let beforeInvalid = try Data(contentsOf: store.dataFile)
        do {
            _ = try store.importChecklistData(Data("{}".utf8))
            fatalError("invalid JSON backup accepted")
        } catch { }
        let afterInvalid = try Data(contentsOf: store.dataFile)
        precondition(afterInvalid == beforeInvalid)

        let separateTask = TodoItem(title: "分类筛选任务", dueDate: ten)
        let separateReminder = ReminderItem(title: "分类筛选事项", dueDate: fifteen, hasSpecificTime: true)
        let both = try backupEncoder.encode(PersistedData(tasks: [separateTask], reminderItems: [separateReminder]))
        let tasksOnly = try store.importChecklistData(both, selection: .tasks)
        precondition(tasksOnly.tasks == 1 && tasksOnly.reminders == 0 && !store.reminderItems.contains(where: { $0.id == separateReminder.id }))
        let remindersOnly = try store.importChecklistData(both, selection: .reminders)
        precondition(remindersOnly.tasks == 0 && remindersOnly.reminders == 1)
        store.addReminderItem(title: "定时事项", dueDate: fifteen, hasSpecificTime: true)
        precondition(store.reminderItems.last?.dueDate == fifteen && store.reminderItems.last?.hasSpecificTime == true)
        store.addTask(title: "自选开始", dueDate: day, explicitStart: ten, duration: 1800)
        precondition(store.tasks.last?.dueDate == ten && store.tasks.last?.calendarDurationSeconds == 1800)

        print("SELF_TEST_OK tasks=\(persisted.tasks.count) reminders=\(persisted.reminderItems.count) focusRecords=\(persisted.focusRecords.count) data=\(store.dataFile.path)")
    }
}
