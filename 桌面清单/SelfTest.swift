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

        let testMorning = Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 1, hour: 9))!
        store.addTask(title: "验证本地保存", dueDate: testMorning, explicitStart: testMorning)
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
        precondition(store.tasks.last?.title == "① 次日任务")
        store.addTask(title: "次日连续任务", dueDate: day)
        precondition(store.tasks.last?.dueDate == nine.addingTimeInterval(2 * 3600))
        precondition(store.tasks.last?.title == "② 次日连续任务")

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

        store.applyTasks([])
        store.addTask(title: "第一项", dueDate: day, explicitStart: ten)
        store.addTask(title: "第二项", dueDate: day, explicitStart: ten)
        precondition(store.tasks.map(\.title) == ["① 第一项", "② 第二项"])
        store.addTask(title: "7. 自定义", dueDate: day, explicitStart: ten)
        store.addTask(title: "继续", dueDate: day, explicitStart: ten)
        precondition(store.tasks.suffix(2).map(\.title) == ["③ 自定义", "④ 继续"])
        store.deleteTask(store.tasks[1])
        store.addTask(title: "删除后", dueDate: day, explicitStart: ten)
        precondition(store.tasks.last?.title == "④ 删除后")
        store.addTask(title: "新的一天", dueDate: tomorrow, explicitStart: nine)
        precondition(store.tasks.last?.title == "① 新的一天")
        precondition(store.reminderItems.contains(where: { $0.title == "定时事项" }))

        func at(_ d: Date, _ h: Int, _ m: Int = 0) -> Date {
            calendar.date(bySettingHour: h, minute: m, second: 0, of: d)!
        }
        func timed(_ name: String, _ date: Date, _ hours: Double, done: Bool = false) -> TodoItem {
            TodoItem(title: name, dueDate: date, isCompleted: done, hasSpecificTime: true, calendarDurationSeconds: hours * 3600)
        }
        let first = timed("第一", at(day, 9), 1, done: true)
        let second = timed("第二", ten, 2)
        var third = timed("第三", at(day, 14), 3)
        third.calendarEventIdentifier = "linked-third"
        store.applyTasks([first, second, third])
        store.toggleTask(third)
        let ordered = store.tasks(on: day)
        precondition(ordered.map(\.title) == ["① 第一", "② 第三", "③ 第二"])
        precondition(ordered[1].dueDate == ten && ordered[2].dueDate == fifteen)
        precondition(ordered[1].id == third.id && ordered[1].calendarEventIdentifier == "linked-third")
        var secondLinked = ordered[2]
        secondLinked.calendarEventIdentifier = "linked-second"
        let existing = timed("明日已有", at(tomorrow, 10), 1)
        let distant = timed("无关日期", at(calendar.date(byAdding: .day, value: 2, to: day)!, 9), 2)
        store.applyTasks([ordered[0], ordered[1], secondLinked, existing, distant])
        let beforeReminders = store.reminderItems
        let beforeDeletes = store.pendingCalendarDeletions
        let scope = try store.moveUnfinished(on: day)
        precondition(scope?.start == day && scope?.end == distant.dueDate.startOfDay)
        precondition(store.tasks(on: tomorrow).map(\.title) == ["① 第二", "② 明日已有"])
        precondition(store.tasks(on: tomorrow)[0].dueDate == nine && store.tasks(on: tomorrow)[1].dueDate == at(tomorrow, 11))
        precondition(store.tasks(on: tomorrow)[0].calendarEventIdentifier == "linked-second")
        precondition(store.tasks(on: day).allSatisfy(\.isCompleted))
        let retry = try store.moveUnfinished(on: day)
        precondition(retry == nil && store.pendingCalendarDeletions == beforeDeletes && store.reminderItems == beforeReminders)
        let savedMove = try decoder.decode(PersistedData.self, from: Data(contentsOf: store.dataFile))
        precondition(savedMove.tasks.map(\.id) == store.tasks.map(\.id))
        for (hour, minute, length, rolls) in [(18, 0, 3, false), (18, 1, 3, true), (18, 30, 2, false), (18, 31, 1, true)] {
            var fixture: [TodoItem] = []
            TaskPlanner.add(timed("边界", at(day, hour, minute), Double(length)), explicit: true, to: &fixture, now: ten)
            precondition(fixture[0].dueDate == (rolls ? nine : at(day, hour, minute)))
        }
        for length in [2.0, 3.0] {
            var fixture = [timed("原11点", at(tomorrow, 11), 1)]
            TaskPlanner.add(timed("补位", at(day, 19), length), explicit: true, to: &fixture, now: ten)
            precondition(fixture[1].dueDate == nine)
            precondition(fixture[0].dueDate == at(tomorrow, length == 2 ? 11 : 14))
        }
        var protected = [timed("已完成", at(tomorrow, 11), 1, done: true)]
        TaskPlanner.add(timed("后补", at(day, 19), 3), explicit: true, to: &protected, now: ten)
        precondition(protected[0].dueDate == at(tomorrow, 11) && protected[1].dueDate == at(tomorrow, 14))
        var late = [first]
        TaskPlanner.add(timed("晚间打开", day, 2), explicit: false, to: &late, now: at(day, 19))
        precondition(late.last?.dueDate == nine)
        store.applyTasks([timed("超长", ten, 20)])
        let beforeOverflow = try Data(contentsOf: store.dataFile)
        do { _ = try store.moveUnfinished(on: day); fatalError("overfull move accepted") } catch { }
        let afterOverflow = try Data(contentsOf: store.dataFile)
        precondition(beforeOverflow == afterOverflow && store.tasks.count == 1)

        let historical = calendar.date(byAdding: .day, value: -2, to: day)!
        let previous = timed("历史一", at(historical, 9), 1)
        let previousTwo = timed("历史二", at(historical, 10), 2)
        let dayExisting = timed("今天已排", at(day, 16), 1)
        let nextExisting = timed("明日已有", at(tomorrow, 9), 1)
        store.applyTasks([previous, previousTwo, dayExisting, nextExisting])
        let historicScope = try store.moveHistoricalTasks(on: historical, now: at(day, 15))
        precondition(historicScope?.start == historical)
        let movedOne = store.tasks.first { $0.id == previous.id }!
        let movedTwo = store.tasks.first { $0.id == previousTwo.id }!
        precondition(movedOne.dueDate == at(day, 15))
        precondition(movedTwo.dueDate == at(tomorrow, 10))
        precondition(store.tasks.first { $0.id == dayExisting.id }?.dueDate == at(day, 16))
        precondition(store.tasks.first { $0.id == nextExisting.id }?.dueDate == at(tomorrow, 9))
        let afterMove = try store.moveHistoricalTasks(on: historical, now: at(day, 15))
        precondition(afterMove == nil)
        let pastReminder = ReminderItem(title: "过去事项", dueDate: at(historical, 10), hasSpecificTime: true, reminderCalendarItemIdentifier: "keep-reminder")
        let doneReminder = ReminderItem(title: "已完成事项", dueDate: historical, isCompleted: true)
        store.applyReminderItems([pastReminder, doneReminder])
        let movedIDs = try store.moveHistoricalReminders(on: historical, to: day, now: at(day, 15, 11))
        precondition(movedIDs == [pastReminder.id])
        precondition(store.reminderItems.first { $0.id == pastReminder.id }?.dueDate == at(day, 15, 30))
        precondition(store.reminderItems.first { $0.id == pastReminder.id }?.reminderCalendarItemIdentifier == "keep-reminder")
        precondition(store.reminderItems.first { $0.id == doneReminder.id }?.dueDate == historical)
        let lateReminder = ReminderItem(title: "夜间事项", dueDate: at(historical, 10), hasSpecificTime: true)
        store.applyReminderItems([lateReminder])
        _ = try store.moveHistoricalReminders(on: historical, to: day, now: at(day, 23, 59))
        precondition(store.reminderItems[0].dueDate == tomorrow)

        precondition(TaskPlanner.titleWithoutNumber("② 任务名称") == "任务名称")
        precondition(TaskPlanner.titleWithoutNumber("12. 旧版任务") == "旧版任务")
        precondition(TaskPlanner.titleWithoutNumber("① 3. 会议") == "3. 会议")
        store.applyTasks([timed("① 原名称", ten, 1)])
        var renamed = store.tasks[0]
        renamed.title = "① 3. 会议"
        store.updateTask(renamed)
        precondition(store.tasks[0].title == "① 3. 会议")
        precondition(TaskPlanner.titleWithoutNumber(store.tasks[0].title) == "3. 会议")

        let nextDay = calendar.date(byAdding: .day, value: 1, to: Date().startOfDay)!
        let beforeCutoff = calendar.date(bySettingHour: 0, minute: 59, second: 0, of: nextDay)!
        let cutoff = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: nextDay)!
        precondition(DailyRollover.periodStart(at: beforeCutoff) < DailyRollover.periodStart(at: cutoff))
        precondition(DailyRollover.nextCutoff(after: beforeCutoff) == cutoff)
        store.showDay(day, section: .reminders)
        precondition(store.selectedDate == day.startOfDay && store.todaySection == .reminders && store.selectedTab == .tasks)
        store.refreshDayIfNeeded(now: cutoff)
        precondition(store.selectedDate == nextDay && store.todaySection == .tasks && store.selectedTab == .tasks)
        store.showDay(day, section: .reminders)
        store.refreshDayIfNeeded(now: cutoff.addingTimeInterval(60))
        precondition(store.selectedDate == day.startOfDay && store.todaySection == .reminders)

        print("SELF_TEST_OK tasks=\(persisted.tasks.count) reminders=\(persisted.reminderItems.count) focusRecords=\(persisted.focusRecords.count) data=\(store.dataFile.path)")
    }
}
