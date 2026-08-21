import EventKit
import SwiftUI

struct MonthView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendarSync: CalendarSyncService
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        VStack(spacing: 12) {
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

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 5) {
                ForEach(Array(monthGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(date: date, isCurrentMonth: isCurrentMonth(date))
                    } else {
                        Color.clear.frame(minHeight: calendarSync.isAuthorized ? 70 : 64)
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 0)

            HStack(spacing: 11) {
                Label("任务", systemImage: "circle.fill")
                if calendarSync.isAuthorized {
                    Label("Mac 节日/行程", systemImage: "calendar")
                } else {
                    Button {
                        if calendarSync.authorizationStatus == .denied || calendarSync.authorizationStatus == .restricted {
                            calendarSync.openPrivacySettings()
                        } else {
                            Task {
                                await calendarSync.requestAccess()
                                calendarSync.loadMonthEvents(containing: store.displayedMonth)
                            }
                        }
                    } label: {
                        Label("显示 Mac 节日", systemImage: "calendar.badge.plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(calendarSync.isWorking)
                }
                Label("专注", systemImage: "leaf.fill")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            if calendarSync.isWorking {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 12)
        .onAppear {
            calendarSync.loadMonthEvents(containing: store.displayedMonth)
        }
        .onChange(of: store.displayedMonth) { _, month in
            calendarSync.loadMonthEvents(containing: month)
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            calendarSync.loadMonthEvents(containing: store.displayedMonth)
        }
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

struct DayCell: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendarSync: CalendarSyncService
    let date: Date
    let isCurrentMonth: Bool

    private var tasks: [TodoItem] { store.tasks(on: date) }
    private var calendarEvents: [CalendarDayEvent] { calendarSync.calendarEvents(on: date) }
    private var focusSeconds: Int { store.focusSeconds(on: date) }

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

                    ForEach(tasks.prefix(calendarEvents.isEmpty ? 2 : 1)) { task in
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
                    let shownCount = (calendarEvents.isEmpty ? min(tasks.count, 2) : min(tasks.count, 1))
                        + min(calendarEvents.count, 1)
                    let remainingCount = tasks.count + calendarEvents.count - shownCount
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
                minHeight: calendarSync.isAuthorized ? 70 : 64,
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
