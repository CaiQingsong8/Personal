import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: AppStore

    private var todaySeconds: Int { store.focusSeconds(on: Date()) }
    private var weekStart: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date().startOfDay
    }
    private var weekEnd: Date { Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? Date() }
    private var weekSeconds: Int { store.focusSeconds(from: weekStart, to: weekEnd) }
    private var completedThisMonth: Int {
        guard let interval = Calendar.current.dateInterval(of: .month, for: Date()) else { return 0 }
        return store.tasks.filter { task in
            guard let date = task.completedAt else { return false }
            return date >= interval.start && date < interval.end
        }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 9) {
                    SummaryCard(title: "今日专注", value: duration(todaySeconds), icon: "timer", color: .indigo)
                    SummaryCard(title: "本周专注", value: duration(weekSeconds), icon: "chart.bar.fill", color: .orange)
                    SummaryCard(title: "本月完成", value: "\(completedThisMonth) 项", icon: "checkmark.circle.fill", color: .green)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("最近 7 天")
                        .font(.headline)
                    SevenDayChart()
                        .frame(height: 150)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("最近专注记录")
                            .font(.headline)
                        Spacer()
                        Text("共 \(store.focusRecords.count) 条")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if store.focusRecords.isEmpty {
                        Text("完成一个番茄后，记录会显示在这里。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 58)
                    } else {
                        ForEach(store.focusRecords.sorted(by: { $0.startedAt > $1.startedAt }).prefix(8)) { record in
                            HStack(spacing: 9) {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(Color.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.taskTitle)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(1)
                                    Text(Self.recordFormatter.string(from: record.startedAt))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(duration(record.durationSeconds))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .contextMenu {
                                Button("删除记录", role: .destructive) { store.deleteFocusRecord(record) }
                            }
                            if record.id != store.focusRecords.sorted(by: { $0.startedAt > $1.startedAt }).prefix(8).last?.id {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                }
                .cardStyle()
            }
            .padding(14)
        }
    }

    private func duration(_ seconds: Int) -> String {
        if seconds < 3600 { return "\(seconds / 60) 分" }
        let hours = Double(seconds) / 3600
        return String(format: "%.1f 小时", hours)
    }

    private static let recordFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SevenDayChart: View {
    @EnvironmentObject private var store: AppStore

    private var days: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0 - 6, to: Date().startOfDay) }
    }

    private var maximum: Int {
        max(days.map { store.focusSeconds(on: $0) }.max() ?? 0, 25 * 60)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(days, id: \.self) { day in
                VStack(spacing: 5) {
                    Spacer(minLength: 0)
                    Text(shortDuration(store.focusSeconds(on: day)))
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Calendar.current.isDateInToday(day) ? Color.accentColor.gradient : Color.accentColor.opacity(0.34).gradient)
                        .frame(height: max(4, 88 * CGFloat(store.focusSeconds(on: day)) / CGFloat(maximum)))
                    Text(Self.weekdayFormatter.string(from: day))
                        .font(.caption2)
                        .foregroundStyle(Calendar.current.isDateInToday(day) ? Color.accentColor : Color.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func shortDuration(_ seconds: Int) -> String {
        seconds == 0 ? "–" : "\(seconds / 60)m"
    }

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter
    }()
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(14)
            .background(Color.primary.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }
}
