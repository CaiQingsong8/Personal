import EventKit
import SwiftUI

struct MonthView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendarSync: CalendarSyncService
    @EnvironmentObject private var reminderSync: ReminderSyncService
    @AppStorage("DeskFlowShowMonthTasks") private var showsTasks = true
    @AppStorage("DeskFlowShowMonthCalendarEvents") private var showsCalendarEvents = true
    @AppStorage("DeskFlowShowMonthFocus") private var showsFocus = true
    @AppStorage("DeskFlowShowMonthReminders") private var showsReminders = true
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        VStack(spacing: 8) {
            monthHeader

            HStack(spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 5) {
                    ForEach(Array(monthGrid.enumerated()), id: \.offset) { _, date in
                        if let date {
                            DayCell(
                                date: date,
                                isCurrentMonth: isCurrentMonth(date),
                                showsTasks: showsTasks,
                                showsCalendarEvents: showsCalendarEvents,
                                showsFocus: showsFocus,
                                showsReminders: showsReminders
                            )
                        } else {
                            Color.clear.frame(minHeight: 54)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 7) {
                layerButton("任务", icon: "circle.fill", color: .accentColor, isOn: showsTasks) {
                    showsTasks.toggle()
                }
                layerButton("Mac 日历", icon: "calendar", color: .orange, isOn: showsCalendarEvents) {
                    showsCalendarEvents.toggle()
                }
                .help("显示或隐藏普通 Mac 日历事项；节日始终显示，已关联清单的事项只显示在清单中")
                layerButton("专注", icon: "leaf.fill", color: .green, isOn: showsFocus) {
                    showsFocus.toggle()
                }
                layerButton("提醒事项", icon: "checklist", color: .purple, isOn: showsReminders) {
                    showsReminders.toggle()
                }
                .help("显示或隐藏所选 Mac 提醒事项列表；已关联清单的事项只显示在任务中")
            }
            .padding(.horizontal, 12)

            CalendarSyncPanel()
                .padding(.horizontal, 10)

            ReminderSyncPanel()
                .padding(.horizontal, 10)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
        .onAppear {
            calendarSync.refreshCalendars()
            calendarSync.loadMonthEvents(containing: store.displayedMonth, appStore: store)
            reminderSync.refreshLists()
            reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
        }
        .onChange(of: store.displayedMonth) { month in
            calendarSync.loadMonthEvents(containing: month, appStore: store)
            reminderSync.loadMonthReminders(containing: month, appStore: store)
        }
        .onChange(of: store.tasks) { _ in
            calendarSync.loadMonthEvents(containing: store.displayedMonth, appStore: store)
            reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
        }
        .onChange(of: store.pendingCalendarDeletions) { _ in
            calendarSync.loadMonthEvents(containing: store.displayedMonth, appStore: store)
        }
        .onChange(of: store.pendingReminderDeletions) { _ in
            reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
        }
        .onChange(of: reminderSync.selectedListID) { _ in
            reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            calendarSync.loadMonthEvents(containing: store.displayedMonth, appStore: store)
            reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
        }
    }

    private func layerButton(
        _ title: String,
        icon: String,
        color: Color,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isOn ? color : Color.secondary)
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(isOn ? color.opacity(0.11) : Color.primary.opacity(0.035))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isOn ? color.opacity(0.25) : Color.primary.opacity(0.06), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? "显示" : "隐藏")
    }

    private var monthHeader: some View {
        HStack {
            Button {
                store.displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: store.displayedMonth) ?? store.displayedMonth
            } label: { Image(systemName: "chevron.left") }
                .buttonStyle(.plain)

            Spacer()
            Button {
                store.displayedMonth = Date().startOfDay
            } label: {
                Text(Self.monthFormatter.string(from: store.displayedMonth))
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.plain)
            Spacer()

            Button {
                store.displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: store.displayedMonth) ?? store.displayedMonth
            } label: { Image(systemName: "chevron.right") }
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
    }

    private var monthGrid: [Date?] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let interval = calendar.dateInterval(of: .month, for: store.displayedMonth),
              let days = calendar.range(of: .day, in: .month, for: store.displayedMonth) else { return [] }
        let first = interval.start
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday + 5) % 7
        var result = Array<Date?>(repeating: nil, count: leading)
        for day in days {
            result.append(calendar.date(byAdding: .day, value: day - 1, to: first))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: store.displayedMonth, toGranularity: .month)
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年 M月"
        return formatter
    }()
}

private struct CalendarSyncPanel: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendarSync: CalendarSyncService

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "calendar.badge.arrowtriangle.2.circlepath")
                    .foregroundStyle(Color.accentColor)
                Text("Mac 日历同步")
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 4)
                Text(calendarSync.isAuthorized ? "已连接" : "未连接")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(calendarSync.isAuthorized ? Color.green : Color.secondary)
            }

            if calendarSync.isAuthorized {
                HStack(spacing: 6) {
                    if calendarSync.calendars.isEmpty {
                        Text("没有找到可编辑的日历")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Picker("互传日历", selection: $calendarSync.selectedCalendarID) {
                            ForEach(calendarSync.calendars) { calendar in
                                Text(calendar.displayName).tag(calendar.id)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("选择互传日历")
                    }

                    Button {
                        calendarSync.createOrUseScheduleCalendar()
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .frame(width: 25, height: 25)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("创建或选择“\(calendarSync.scheduleCalendarName)”")
                    .accessibilityLabel("创建或使用专用日历")
                    .disabled(calendarSync.isWorking)
                }

                HStack(spacing: 6) {
                    Button {
                        Task { await calendarSync.importFromCalendar(into: store) }
                    } label: {
                        Label("导入行程", systemImage: "arrow.down.to.line")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        Task { await calendarSync.exportToCalendar(from: store) }
                    } label: {
                        Label("同步到日历", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .disabled(calendarSync.isWorking || calendarSync.calendars.isEmpty)
            } else {
                HStack(spacing: 8) {
                    Text(calendarSync.authorizationDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    if calendarSync.authorizationStatus == .denied || calendarSync.authorizationStatus == .restricted {
                        Button("打开权限设置") { calendarSync.openPrivacySettings() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    } else {
                        Button("允许访问") {
                            Task {
                                await calendarSync.requestAccess()
                                if calendarSync.isAuthorized {
                                    calendarSync.loadMonthEvents(containing: store.displayedMonth, appStore: store)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(calendarSync.isWorking)
                    }
                }
            }

            HStack(spacing: 5) {
                if calendarSync.isWorking {
                    ProgressView().controlSize(.mini)
                }
                Text(calendarSync.statusMessage)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("删除项会随本次同步从日历移除")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ReminderSyncPanel: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var reminderSync: ReminderSyncService

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "checklist")
                    .foregroundStyle(Color.purple)
                Text("Mac 提醒事项同步")
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 4)
                Text(reminderSync.isAuthorized ? "已连接" : "未连接")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(reminderSync.isAuthorized ? Color.green : Color.secondary)
            }

            if reminderSync.isAuthorized {
                HStack(spacing: 6) {
                    if reminderSync.lists.isEmpty {
                        Text("没有找到可编辑的提醒事项列表")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Picker("互传提醒事项", selection: $reminderSync.selectedListID) {
                            ForEach(reminderSync.lists) { list in
                                Text(list.displayName).tag(list.id)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("选择互传提醒事项列表")
                    }

                    Button {
                        reminderSync.createOrUseReminderList()
                    } label: {
                        Image(systemName: "checklist")
                            .frame(width: 25, height: 25)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("创建或选择“\(reminderSync.reminderListName)”")
                    .accessibilityLabel("创建或使用专用提醒事项列表")
                    .disabled(reminderSync.isWorking)
                }

                HStack(spacing: 6) {
                    Button {
                        Task { await reminderSync.importFromReminders(into: store) }
                    } label: {
                        Label("导入提醒事项", systemImage: "arrow.down.to.line")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        Task { await reminderSync.syncToReminders(from: store) }
                    } label: {
                        Label("同步到提醒事项", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .disabled(reminderSync.isWorking || reminderSync.lists.isEmpty)
            } else {
                HStack(spacing: 8) {
                    Text(reminderSync.authorizationDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    if reminderSync.authorizationStatus == .denied || reminderSync.authorizationStatus == .restricted {
                        Button("打开权限设置") { reminderSync.openPrivacySettings() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    } else {
                        Button("允许访问") {
                            Task {
                                await reminderSync.requestAccess()
                                if reminderSync.isAuthorized {
                                    reminderSync.loadMonthReminders(containing: store.displayedMonth, appStore: store)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(reminderSync.isWorking)
                    }
                }
            }

            HStack(spacing: 5) {
                if reminderSync.isWorking { ProgressView().controlSize(.mini) }
                Text(reminderSync.statusMessage)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("删除项会随同步从提醒事项移除")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct DayCell: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendarSync: CalendarSyncService
    @EnvironmentObject private var reminderSync: ReminderSyncService
    let date: Date
    let isCurrentMonth: Bool
    let showsTasks: Bool
    let showsCalendarEvents: Bool
    let showsFocus: Bool
    let showsReminders: Bool

    private var tasks: [TodoItem] { showsTasks ? store.tasks(on: date) : [] }
    private var calendarEvents: [CalendarDayEvent] {
        calendarSync.calendarEvents(on: date).filter {
            CalendarEventVisibility.shouldShow(
                isHoliday: $0.isHoliday,
                isChecklistLinked: $0.isChecklistLinked,
                showsCalendarEvents: showsCalendarEvents
            )
        }
    }
    private var focusSeconds: Int { showsFocus ? store.focusSeconds(on: date) : 0 }
    private var reminders: [CalendarDayReminder] {
        showsReminders ? reminderSync.reminders(on: date).filter { !$0.isChecklistLinked } : []
    }

    var body: some View {
        Button {
            store.selectedDate = date.startOfDay
            store.selectedTab = .tasks
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 3) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.caption.weight(isToday ? .bold : .medium))
                        .foregroundStyle(isToday ? Color.white : (isCurrentMonth ? Color.primary : Color.secondary.opacity(0.5)))
                        .frame(width: 22, height: 22)
                        .background(isToday ? Color.accentColor : Color.clear)
                        .clipShape(Circle())
                    Spacer(minLength: 0)
                    if focusSeconds > 0 {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.green)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(calendarEvents.prefix(1)) { event in
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 7.5, weight: .semibold))
                                .foregroundStyle(Color.orange)
                            Text(event.displayTitle)
                                .font(.system(size: 8.5, weight: .medium))
                                .lineLimit(1)
                                .foregroundStyle(Color.orange)
                        }
                        .help("\(event.calendarTitle)：\(event.title)")
                    }

                    ForEach(reminders.prefix(1)) { reminder in
                        HStack(spacing: 3) {
                            Image(systemName: "checklist")
                                .font(.system(size: 7.5, weight: .semibold))
                                .foregroundStyle(Color.purple)
                            Text(reminder.displayTitle)
                                .font(.system(size: 8.5, weight: .medium))
                                .lineLimit(1)
                                .foregroundStyle(reminder.isCompleted ? Color.secondary : Color.purple)
                        }
                        .help("\(reminder.listTitle)：\(reminder.title)")
                    }

                    ForEach(tasks.prefix(calendarEvents.isEmpty && reminders.isEmpty ? 2 : 1)) { task in
                        HStack(spacing: 3) {
                            Circle()
                                .fill(task.isCompleted ? Color.secondary.opacity(0.35) : Color.accentColor)
                                .frame(width: 4, height: 4)
                            Text(task.title)
                                .font(.system(size: 8.5))
                                .lineLimit(1)
                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        }
                    }
                    let hasOtherLayers = !calendarEvents.isEmpty || !reminders.isEmpty
                    let shownCount = (hasOtherLayers ? min(tasks.count, 1) : min(tasks.count, 2))
                        + min(calendarEvents.count, 1) + min(reminders.count, 1)
                    let remainingCount = tasks.count + calendarEvents.count + reminders.count - shownCount
                    if remainingCount > 0 {
                        Text("+\(remainingCount)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(5)
            .frame(
                maxWidth: .infinity,
                minHeight: 54,
                alignment: .topLeading
            )
            .background(isToday ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.025))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(isCurrentMonth ? 1 : 0.45)
        }
        .buttonStyle(.plain)
    }

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
}
