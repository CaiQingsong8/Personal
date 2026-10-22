import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var newTaskTitle = ""
    @State private var editingTask: TodoItem?
    @State private var isSelecting = false
    @State private var selectedTaskIDs = Set<UUID>()
    @State private var confirmBatchDelete = false

    private var dayTasks: [TodoItem] { store.tasks(on: store.selectedDate) }
    private var recentTasks: [TodoItem] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        guard let start = calendar.date(byAdding: .day, value: -29, to: today),
              let end = calendar.date(byAdding: .day, value: 1, to: today) else { return [] }
        return store.tasks
            .filter { $0.dueDate >= start && $0.dueDate < end }
            .sorted {
                if !calendar.isDate($0.dueDate, inSameDayAs: $1.dueDate) { return $0.dueDate > $1.dueDate }
                if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
                return $0.createdAt < $1.createdAt
            }
    }
    private var recentTaskGroups: [TaskDayGroup] {
        let grouped = Dictionary(grouping: recentTasks) { $0.dueDate.startOfDay }
        return grouped.keys.sorted(by: >).map { date in
            TaskDayGroup(date: date, tasks: grouped[date] ?? [])
        }
    }
    private var allRecentTaskIDs: Set<UUID> { Set(recentTasks.map(\.id)) }

    var body: some View {
        VStack(spacing: 0) {
            if isSelecting {
                batchHeader
            } else {
                dateHeader
                quickAdd
            }
            selectionBar

            if isSelecting {
                if recentTaskGroups.isEmpty {
                    emptyRecentState
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(recentTaskGroups) { group in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(Self.groupDateFormatter.string(from: group.date))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(group.tasks.count) 项")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    ForEach(group.tasks) { task in
                                        TaskRow(task: task, editingTask: $editingTask,
                                                isSelecting: true, selectedTaskIDs: $selectedTaskIDs)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                }
            } else if dayTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(dayTasks) { task in
                            TaskRow(task: task, editingTask: $editingTask,
                                    isSelecting: false, selectedTaskIDs: $selectedTaskIDs)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }

            if isSelecting && !selectedTaskIDs.isEmpty {
                Button("删除已选 \(selectedTaskIDs.count) 项", role: .destructive) {
                    confirmBatchDelete = true
                }
                .padding(.bottom, 8)
            }

            Divider().opacity(0.6)
            if !isSelecting { FocusTimerView() }
        }
        .sheet(item: $editingTask) { task in
            TaskEditorView(task: task)
        }
        .confirmationDialog("删除已选任务？", isPresented: $confirmBatchDelete) {
            Button("删除 \(selectedTaskIDs.count) 项", role: .destructive) {
                store.deleteTasks(ids: selectedTaskIDs)
                selectedTaskIDs.removeAll()
                isSelecting = false
            }
        } message: {
            Text("将删除最近 30 天（含今天）所选的 \(selectedTaskIDs.count) 项任务。关联的 Mac 日历事项将在下次同步时一并删除。")
        }
        .onChange(of: store.selectedDate) { _ in
            if !isSelecting {
                selectedTaskIDs.removeAll()
            }
        }
        .onChange(of: store.tasks.map(\.id)) { taskIDs in
            selectedTaskIDs.formIntersection(Set(taskIDs))
        }
    }

    private var batchHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("批量选择任务")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text("最近 30 天（含今天） · 共 \(recentTasks.count) 项")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("取消") {
                isSelecting = false
                selectedTaskIDs.removeAll()
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var selectionBar: some View {
        HStack {
            if isSelecting {
                Button(selectedTaskIDs.isSuperset(of: allRecentTaskIDs) && !allRecentTaskIDs.isEmpty
                       ? "取消全选" : "全选最近30天") {
                    if selectedTaskIDs.isSuperset(of: allRecentTaskIDs) {
                        selectedTaskIDs.subtract(allRecentTaskIDs)
                    } else {
                        selectedTaskIDs.formUnion(allRecentTaskIDs)
                    }
                }
                .disabled(allRecentTaskIDs.isEmpty)
                Text("已选 \(selectedTaskIDs.count) 项")
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    isSelecting = true
                    selectedTaskIDs.removeAll()
                } label: {
                    Label("批量选择", systemImage: "checklist")
                }
                Text("最近 30 天")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .font(.caption)
        .buttonStyle(.borderless)
        .padding(.horizontal, 17)
        .padding(.top, 7)
    }

    private var emptyRecentState: some View {
        VStack(spacing: 7) {
            Spacer()
            Image(systemName: "checkmark.seal")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Color.accentColor.opacity(0.8))
            Text("最近 30 天没有任务")
                .font(.subheadline.weight(.medium))
            Text("可以取消批量选择，继续查看其他日期。")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var dateHeader: some View {
        HStack {
            Button {
                store.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: store.selectedDate) ?? store.selectedDate
            } label: { Image(systemName: "chevron.left") }
                .buttonStyle(.plain)

            Spacer()
            Button {
                store.selectedDate = Date().startOfDay
            } label: {
                VStack(spacing: 1) {
                    Text(Self.titleFormatter.string(from: store.selectedDate))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text(Self.weekdayFormatter.string(from: store.selectedDate))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            Spacer()

            Button {
                store.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: store.selectedDate) ?? store.selectedDate
            } label: { Image(systemName: "chevron.right") }
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var quickAdd: some View {
        HStack(spacing: 9) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 19))
            TextField("添加一件要做的事…", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .onSubmit(addTask)
            if !newTaskTitle.isEmpty {
                Button("添加", action: addTask)
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 42)
        .background(Color.primary.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "checkmark.seal")
                .font(.system(size: 31, weight: .light))
                .foregroundStyle(Color.accentColor.opacity(0.8))
            Text("这一天还没有任务")
                .font(.subheadline.weight(.medium))
            Text("在上方输入后按回车即可添加")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func addTask() {
        store.addTask(title: newTaskTitle, dueDate: store.selectedDate)
        newTaskTitle = ""
    }

    private static let titleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let groupDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()
}

private struct TaskDayGroup: Identifiable {
    let date: Date
    let tasks: [TodoItem]
    var id: Date { date }
}

struct TaskRow: View {
    @EnvironmentObject private var store: AppStore
    let task: TodoItem
    @Binding var editingTask: TodoItem?
    let isSelecting: Bool
    @Binding var selectedTaskIDs: Set<UUID>

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if isSelecting {
                    if !selectedTaskIDs.insert(task.id).inserted { selectedTaskIDs.remove(task.id) }
                } else {
                    store.toggleTask(task)
                }
            } label: {
                Image(systemName: isSelecting
                      ? (selectedTaskIDs.contains(task.id) ? "checkmark.square.fill" : "square")
                      : (task.isCompleted ? "checkmark.circle.fill" : "circle"))
                    .font(.system(size: 19))
                    .foregroundStyle((isSelecting ? selectedTaskIDs.contains(task.id) : task.isCompleted)
                                     ? Color.accentColor : Color.secondary.opacity(0.65))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(task.title)
                        .font(.system(size: 14.5, weight: .medium))
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .lineLimit(2)
                    if task.calendarEventIdentifier != nil {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                if task.hasSpecificTime ?? false {
                    Text("\(Self.timeFormatter.string(from: task.dueDate)) · \(Self.durationText(task.calendarDurationSeconds ?? 3600))")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isSelecting {
                    if !selectedTaskIDs.insert(task.id).inserted { selectedTaskIDs.remove(task.id) }
                } else {
                    editingTask = task
                }
            }

            Spacer(minLength: 4)

            if !isSelecting { Button {
                store.selectTaskForTimer(task)
            } label: {
                Image(systemName: store.timerTaskID == task.id ? "timer.circle.fill" : "timer")
                    .foregroundStyle(store.timerTaskID == task.id ? Color.accentColor : Color.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("绑定到番茄钟")

            Button { editingTask = task } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 32)
                    .background(Color.primary.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("编辑任务")
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(store.timerTaskID == task.id ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.028))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            if !isSelecting {
                Button("编辑") { editingTask = task }
                Button("绑定到番茄钟") { store.selectTaskForTimer(task) }
                Divider()
                Button("删除", role: .destructive) { store.deleteTask(task) }
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static func durationText(_ seconds: TimeInterval) -> String {
        let minutes = max(30, Int(seconds / 60))
        if minutes % 60 == 0 { return "\(minutes / 60)小时" }
        if minutes > 60 { return "\(minutes / 60)小时\(minutes % 60)分" }
        return "\(minutes)分钟"
    }
}

struct TaskEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: TodoItem
    @State private var hasSpecificTime: Bool
    @State private var durationMinutes: Int
    @State private var showDateCalendar = false

    init(task: TodoItem) {
        _draft = State(initialValue: task)
        _hasSpecificTime = State(initialValue: task.hasSpecificTime ?? false)
        _durationMinutes = State(initialValue: max(30, Int((task.calendarDurationSeconds ?? 3600) / 60)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("编辑任务")
                .font(.title3.weight(.semibold))

            TextField("任务名称", text: $draft.title)
                .textFieldStyle(.roundedBorder)

            Toggle("指定具体时间", isOn: $hasSpecificTime)

            Button {
                showDateCalendar.toggle()
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.accentColor)
                    Text("日期")
                    Spacer()
                    Text(Self.editorDateFormatter.string(from: draft.dueDate))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .frame(height: 36)
                .background(Color.primary.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDateCalendar, arrowEdge: .trailing) {
                VStack(spacing: 10) {
                    DatePicker("", selection: $draft.dueDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .labelsHidden()

                    HStack {
                        Button("今天") {
                            draft.dueDate = Self.replacingDay(of: draft.dueDate, with: Date())
                            showDateCalendar = false
                        }
                        Spacer()
                        Button("完成") { showDateCalendar = false }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding(14)
                .frame(width: 290)
            }

            if hasSpecificTime {
                DatePicker("时间", selection: $draft.dueDate, displayedComponents: [.hourAndMinute])

                Stepper(value: $durationMinutes, in: 30...720, step: 30) {
                    HStack {
                        Text("任务时长")
                        Spacer()
                        Text(durationText)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("备注")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $draft.notes)
                    .font(.body)
                    .frame(height: 90)
                    .padding(5)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Toggle("已完成", isOn: $draft.isCompleted)

            HStack {
                Button("删除", role: .destructive) {
                    store.deleteTask(draft)
                    dismiss()
                }
                Spacer()
                Button("取消") { dismiss() }
                Button("保存") {
                    let wasSpecificTime = draft.hasSpecificTime ?? false
                    draft.hasSpecificTime = hasSpecificTime
                    if hasSpecificTime {
                        draft.calendarDurationSeconds = TimeInterval(durationMinutes * 60)
                        draft.calendarAllDaySpanDays = nil
                    } else {
                        draft.dueDate = draft.dueDate.startOfDay
                        draft.calendarDurationSeconds = nil
                        if wasSpecificTime { draft.calendarAllDaySpanDays = 1 }
                    }
                    draft.completedAt = draft.isCompleted ? (draft.completedAt ?? Date()) : nil
                    store.updateTask(draft)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 380)
        .onChange(of: hasSpecificTime) { enabled in
            if enabled && !(draft.hasSpecificTime ?? false) {
                draft.dueDate = TaskScheduleDefaults.startDate(on: draft.dueDate)
                durationMinutes = Int(TaskScheduleDefaults.durationSeconds / 60)
            }
        }
    }

    private var durationText: String {
        if durationMinutes % 60 == 0 { return "\(durationMinutes / 60) 小时" }
        if durationMinutes > 60 { return "\(durationMinutes / 60) 小时 \(durationMinutes % 60) 分钟" }
        return "\(durationMinutes) 分钟"
    }

    private static func replacingDay(of date: Date, with newDay: Date) -> Date {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute, .second], from: date)
        var components = calendar.dateComponents([.year, .month, .day], from: newDay)
        components.hour = time.hour
        components.minute = time.minute
        components.second = time.second
        return calendar.date(from: components) ?? newDay
    }

    private static let editorDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter
    }()
}

struct FocusTimerView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("正在专注")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.timerTaskTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 4) {
                    durationButton(25)
                    durationButton(50)
                }
            }

            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.07), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .frame(width: 47, height: 47)

                Text(timeString)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button { store.toggleTimer() } label: {
                    Image(systemName: store.isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.accentColor.gradient)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Menu {
                    Button("完成并记录") { store.finishAndSaveTimer() }
                        .disabled(store.elapsedSeconds < 60)
                    Button("重新开始") { store.resetTimer() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 13)
        .background(Color.accentColor.opacity(0.045))
    }

    private func durationButton(_ minutes: Int) -> some View {
        Button("\(minutes)") { store.setSessionLength(minutes: minutes) }
            .font(.caption2.weight(.semibold))
            .buttonStyle(.plain)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(store.sessionLength == minutes * 60 ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.05))
            .foregroundStyle(store.sessionLength == minutes * 60 ? Color.accentColor : Color.secondary)
            .clipShape(Capsule())
            .disabled(store.isTimerRunning)
    }

    private var progress: CGFloat {
        guard store.sessionLength > 0 else { return 0 }
        return CGFloat(store.elapsedSeconds) / CGFloat(store.sessionLength)
    }

    private var timeString: String {
        String(format: "%02d:%02d", store.remainingSeconds / 60, store.remainingSeconds % 60)
    }
}
