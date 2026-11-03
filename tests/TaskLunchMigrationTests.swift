import Foundation

@main
struct TaskLunchMigrationTests {
    @MainActor
    static func main() throws {
        guard let path = ProcessInfo.processInfo.environment["DESKFLOW_DATA_DIR"] else { fatalError("missing test directory") }
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("data.json")
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        let two = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!
        let timed = TodoItem(title: "需要修正", dueDate: noon, hasSpecificTime: true, calendarDurationSeconds: 21600)
        let completed = TodoItem(title: "已完成", dueDate: noon, isCompleted: true, hasSpecificTime: true)
        let reminder = ReminderItem(title: "提醒事项", dueDate: noon)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(PersistedData(tasks: [timed, completed], reminderItems: [reminder])).write(to: file)

        let store = AppStore.shared
        precondition(store.tasks[0].id == timed.id && store.tasks[0].dueDate == two)
        precondition(store.tasks[1].dueDate == noon && store.reminderItems[0].dueDate == noon)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let saved = try decoder.decode(PersistedData.self, from: Data(contentsOf: file))
        precondition(saved.tasks[0].dueDate == two && saved.tasks[0].calendarDurationSeconds == 21600)
        precondition(saved.tasks[1].dueDate == noon && saved.reminderItems[0].dueDate == noon)
        var edited = store.tasks[0]
        edited.dueDate = noon
        store.updateTask(edited)
        precondition(store.tasks[0].dueDate == two)
        print("TASK_LUNCH_MIGRATION_OK")
    }
}
