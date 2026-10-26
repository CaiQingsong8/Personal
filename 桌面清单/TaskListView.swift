import EventKit
import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var newTaskTitle = ""
    @State private var editingTask: TodoItem?
    @State private var isSelecting = false
    @State private var selectedTaskIDs = Set<UUID>()
    @State private var confirmBatchDelete = false
    @State private var todaySection = TodaySection.tasks

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
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Text("今日内容")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker("今日内容", selection: $todaySection) {
                    Text("任务").tag(TodaySection.tasks)
                    Text("事项").tag(TodaySection.reminders)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            if todaySection == .tasks {
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
            } else {
                ReminderTodayView()
            }

            Divider().opacity(0.6)
            if todaySection == .tasks {
                CalendarSyncPanel()
                    .padding(.horizontal, 10)
                TaskCalendarSyncPanel()
                    .padding(.horizontal, 10)
            }
            if todaySection == .reminders || !isSelecting { FocusTimerView() }
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
            Text("将删除最近 30 天（含今天）所选的 \(selectedTaskIDs.count) 项本地清单任务。")
        }
        .onChange(of: store.selectedDate) { _ in
            if !isSelecting {
                selectedTaskIDs.removeAll()
            }
        }
        .onChange(of: store.tasks.map(\.id)) { taskIDs in
            selectedTaskIDs.formIntersection(Set(taskIDs))
        }
        .onChange(of: todaySection) { section in
            if section == .reminders {
                isSelecting = false
                selectedTaskIDs.removeAll()
            }
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
            TextField("添加任务…", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .onSubmit(addTask)
            Button("添加", action: addTask)
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            Text("在上方输入后按回车或点“添加”")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
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

private enum TodaySection: Hashable {
    case tasks
    case reminders
}

private struct TaskCalendarSyncPanel: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendarSync: CalendarSyncService

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "calendar.badge.arrowtriangle.2.circlepath")
                    .foregroundStyle(Color.accentColor)
                Text("Mac 日历任务同步")
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 4)
                Text(calendarSync.connectionStatus)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(calendarSync.connectionStatus.hasPrefix("已连接") ? Color.green : Color.secondary)
            }

            Button {
                Task { await calendarSync.syncTasksToCalendar(from: store) }
            } label: {
                Label("同步任务到日历", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(calendarSync.isWorking || !calendarSync.canWriteToSelectedCalendar)

            Text("仅同步清单任务；Mac 日程与事项保持独立")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ReminderTodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var reminderSync: ReminderSyncService
    @State private var newTitle = ""
    @State private var editingItem: ReminderItem?

    private var items: [ReminderItem] { store.reminderItems(on: store.selectedDate) }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    store.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: store.selectedDate) ?? store.selectedDate
                } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.plain)
                Spacer()
                Button { store.selectedDate = Date().startOfDay } label: {
                    VStack(spacing: 1) {
                        Text(Self.dateFormatter.string(from: store.selectedDate))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
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
            .padding(.top, 11)

            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.purple)
                TextField("添加事项…", text: $newTitle)
                    .textFieldStyle(.plain)
                    .onSubmit(addItem)
                Button("添加", action: addItem)
                    .buttonStyle(.borderless)
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Color.primary.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 14)

            if items.isEmpty {
                VStack(spacing: 7) {
                    Spacer()
                    Image(systemName: "checklist")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.purple.opacity(0.8))
                    Text("这一天还没有事项")
                        .font(.subheadline.weight(.medium))
                    Text("导入 Mac 事项，或在上方创建一条。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(items) { item in
                            ReminderTodayRow(item: item, editingItem: $editingItem)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
            }

            ReminderSyncPanel()
                .padding(.horizontal, 10)
                .padding(.bottom, 5)
        }
        .sheet(item: $editingItem) { item in
            ReminderItemEditorView(item: item)
        }
        .onAppear {
            reminderSync.refreshAuthorizationStatus()
            if reminderSync.isAuthorized {
                reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
            }
        }
        .onChange(of: reminderSync.selectedListID) { _ in
            reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
        }
        .onChange(of: store.selectedDate) { date in
            reminderSync.loadMonthReminders(containing: date, appStore: store)
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            reminderSync.refreshAuthorizationStatus()
            if reminderSync.isAuthorized {
                reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            reminderSync.refreshLists()
            reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
        }
    }

    private func addItem() {
        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        store.addReminderItem(title: newTitle, dueDate: store.selectedDate)
        newTitle = ""
    }

    private static let dateFormatter: DateFormatter = {
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
}

private struct ReminderTodayRow: View {
    @EnvironmentObject private var store: AppStore
    let item: ReminderItem
    @Binding var editingItem: ReminderItem?

    var body: some View {
        HStack(spacing: 9) {
            Button { store.toggleReminderItem(item) } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19))
                    .foregroundStyle(item.isCompleted ? Color.purple : Color.secondary.opacity(0.65))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 14.5, weight: .medium))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                HStack(spacing: 5) {
                    if item.hasSpecificTime == true {
                        Text(Self.timeFormatter.string(from: item.dueDate))
                    } else {
                        Text("全天")
                    }
                    if item.reminderCalendarItemIdentifier != nil { Text("· Mac 事项") }
                }
                .font(.caption2)
                .foregroundStyle(Color.purple)
            }
            .contentShape(Rectangle())
            .onTapGesture { editingItem = item }
            Spacer(minLength: 4)
            Button { store.selectTaskForTimer(TodoItem(id: item.id, title: item.title, notes: item.notes, dueDate: item.dueDate)) } label: {
                Image(systemName: store.timerTaskID == item.id ? "timer.circle.fill" : "timer")
                    .foregroundStyle(store.timerTaskID == item.id ? Color.accentColor : Color.secondary)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            Button { editingItem = item } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 30)
                    .background(Color.primary.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            Button("编辑") { editingItem = item }
            Button("删除", role: .destructive) { store.deleteReminderItem(item) }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private struct ReminderItemEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ReminderItem
    @State private var hasSpecificTime: Bool

    init(item: ReminderItem) {
        _draft = State(initialValue: item)
        _hasSpecificTime = State(initialValue: item.hasSpecificTime ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("编辑事项").font(.title3.weight(.semibold))
            TextField("事项", text: $draft.title).textFieldStyle(.roundedBorder)
            DatePicker("日期", selection: $draft.dueDate, displayedComponents: [.date])
            Toggle("指定具体时间", isOn: $hasSpecificTime)
            if hasSpecificTime {
                DatePicker("时间", selection: $draft.dueDate, displayedComponents: [.hourAndMinute])
            }
            TextEditor(text: $draft.notes)
                .frame(height: 70)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15)))
            Toggle("已完成", isOn: $draft.isCompleted)
            HStack {
                Button("删除", role: .destructive) {
                    store.deleteReminderItem(draft)
                    dismiss()
                }
                Spacer()
                Button("取消") { dismiss() }
                Button("保存") {
                    draft.hasSpecificTime = hasSpecificTime
                    if !hasSpecificTime { draft.dueDate = draft.dueDate.startOfDay }
                    draft.completedAt = draft.isCompleted ? (draft.completedAt ?? Date()) : nil
                    store.updateReminderItem(draft)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 360)
        .onChange(of: hasSpecificTime) { enabled in
            if enabled && draft.hasSpecificTime != true {
                draft.dueDate = TaskScheduleDefaults.startDate(on: draft.dueDate)
            }
        }
    }
}

struct CalendarScheduleManagementView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendarSync: CalendarSyncService
    @Environment(\.dismiss) private var dismiss
    @State private var editingSchedule: CalendarSchedule?
    @State private var scheduleToDelete: CalendarSchedule?

    private var schedules: [CalendarSchedule] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: store.displayedMonth) else { return [] }
        return store.calendarSchedules
            .filter { $0.dueDate >= interval.start && $0.dueDate < interval.end }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("导入的 Mac 日程")
                        .font(.title3.weight(.semibold))
                    Text("可以在这里修改；清单任务与日程分开保存。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding(16)

            if schedules.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.orange)
                    Text("本月还没有导入的日程")
                        .font(.subheadline.weight(.medium))
                    Text("先在月历的 Mac 日历面板中点击“导入行程”。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(schedules) { schedule in
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(schedule.title).lineLimit(1)
                            Text(Self.scheduleFormatter.string(from: schedule.dueDate) + (schedule.hasSpecificTime == true ? "" : " · 全天"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("编辑") { editingSchedule = schedule }
                            .buttonStyle(.borderless)
                        Button(role: .destructive) { scheduleToDelete = schedule } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("删除本地日程并在同步时从 Mac 日历移除")
                    }
                    .padding(.vertical, 3)
                }
                .listStyle(.plain)
            }

            HStack {
                Text(calendarSync.statusMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
                Button {
                    Task {
                        await calendarSync.exportToCalendar(from: store)
                        calendarSync.loadMonthEvents(containing: store.displayedMonth, appStore: store)
                    }
                } label: {
                    Label("同步修改到 Mac 日历", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!calendarSync.isAuthorized || calendarSync.isWorking)
            }
            .padding(14)
        }
        .frame(width: 540, height: 500)
        .sheet(item: $editingSchedule) { schedule in
            CalendarScheduleEditorView(schedule: schedule)
                .environmentObject(store)
        }
        .confirmationDialog("删除这条日程？", isPresented: Binding(
            get: { scheduleToDelete != nil },
            set: { if !$0 { scheduleToDelete = nil } }
        ), presenting: scheduleToDelete) { schedule in
            Button("删除并在下次同步时从日历移除", role: .destructive) {
                store.deleteCalendarSchedules(ids: [schedule.id])
                scheduleToDelete = nil
            }
        } message: { _ in
            Text("删除的是导入的 Mac 日程，不会影响清单任务或提醒事项。")
        }
    }

    private static let scheduleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

private struct CalendarScheduleEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CalendarSchedule
    @State private var hasSpecificTime: Bool
    @State private var durationMinutes: Int

    init(schedule: CalendarSchedule) {
        _draft = State(initialValue: schedule)
        _hasSpecificTime = State(initialValue: schedule.hasSpecificTime ?? false)
        _durationMinutes = State(initialValue: max(30, Int((schedule.calendarDurationSeconds ?? 3600) / 60)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("编辑日程").font(.title3.weight(.semibold))
            TextField("日程名称", text: $draft.title).textFieldStyle(.roundedBorder)
            DatePicker("日期", selection: $draft.dueDate, displayedComponents: [.date])
            Toggle("指定具体时间", isOn: $hasSpecificTime)
            if hasSpecificTime {
                DatePicker("开始时间", selection: $draft.dueDate, displayedComponents: [.hourAndMinute])
                Stepper(value: $durationMinutes, in: 30...720, step: 30) {
                    HStack {
                        Text("日程时长")
                        Spacer()
                        Text(durationMinutes % 60 == 0 ? "\(durationMinutes / 60) 小时" : "\(durationMinutes) 分钟")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            TextEditor(text: $draft.notes)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15)))
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("保存修改") {
                    draft.hasSpecificTime = hasSpecificTime
                    if hasSpecificTime {
                        draft.calendarDurationSeconds = TimeInterval(durationMinutes * 60)
                        draft.calendarAllDaySpanDays = nil
                    } else {
                        draft.dueDate = draft.dueDate.startOfDay
                        draft.calendarDurationSeconds = nil
                    }
                    store.updateCalendarSchedule(draft)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 380)
    }
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
                    draft.hasSpecificTime = hasSpecificTime
                    if hasSpecificTime {
                        draft.calendarDurationSeconds = TimeInterval(durationMinutes * 60)
                    } else {
                        draft.dueDate = draft.dueDate.startOfDay
                        draft.calendarDurationSeconds = nil
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
