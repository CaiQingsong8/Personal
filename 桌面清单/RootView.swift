import AppKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var windowManager: WindowManager
    @EnvironmentObject private var calendarSync: CalendarSyncService
    @State private var showDataMenu = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.55)
            Group {
                switch store.selectedTab {
                case .tasks: TaskListView()
                case .month: MonthView()
                case .stats: StatsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .padding(7)
    }

    private var header: some View {
        VStack(spacing: 11) {
            ZStack {
                WindowDragHandle()
                    .frame(height: 38)

                HStack(spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color.accentColor.gradient)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 34, height: 34)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(calendarSync.scheduleCalendarName)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                            Text(windowManager.isFloating ? "普通窗口" : "固定在桌面")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .allowsHitTesting(false)

                    Spacer()

                    Button {
                        windowManager.isFloating.toggle()
                    } label: {
                        Image(systemName: windowManager.isFloating ? "pin.slash" : "pin.fill")
                    }
                    .buttonStyle(HeaderButtonStyle(active: !windowManager.isFloating))
                    .help(windowManager.isFloating ? "固定到桌面" : "切换为普通窗口")

                    Button {
                        showDataMenu.toggle()
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .buttonStyle(HeaderButtonStyle())
                    .popover(isPresented: $showDataMenu, arrowEdge: .top) {
                        DataMenuView()
                    }
                }
            }

            Picker("", selection: $store.selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }
}

struct WindowDragHandle: NSViewRepresentable {
    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }

    func makeNSView(context: Context) -> DragView {
        let view = DragView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    func updateNSView(_ nsView: DragView, context: Context) {}
}

struct HeaderButtonStyle: ButtonStyle {
    var active = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 30, height: 30)
            .background(active ? Color.accentColor.opacity(0.16) : Color.primary.opacity(configuration.isPressed ? 0.12 : 0.06))
            .foregroundStyle(active ? Color.accentColor : Color.primary.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DataMenuView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendarSync: CalendarSyncService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("清单名称")
                .font(.headline)

            TextField("名字", text: $calendarSync.scheduleOwnerName)
                .textFieldStyle(.roundedBorder)

            Text("当前显示：\(calendarSync.scheduleCalendarName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Text("本地数据")
                .font(.headline)
            Text("所有内容只保存在这台 Mac 上。建议偶尔导出 JSON 备份。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("导出完整备份（JSON）") { store.exportJSON() }
                .buttonStyle(.borderedProminent)
            Button("导出任务表（CSV）") { store.exportCSV() }
                .buttonStyle(.bordered)
            Button("打开数据目录") {
                try? FileManager.default.createDirectory(at: store.dataDirectory, withIntermediateDirectories: true)
                NSWorkspace.shared.open(store.dataDirectory)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)

            Text(store.dataFile.path)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
                .frame(maxWidth: 270, alignment: .leading)

            Divider()

            HStack {
                Image(systemName: "calendar.badge.arrowtriangle.2.circlepath")
                    .foregroundStyle(Color.accentColor)
                Text("Mac 日历互传")
                    .font(.headline)
            }

            Text(calendarSync.authorizationDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            if calendarSync.isAuthorized {
                Button {
                    calendarSync.createOrUseScheduleCalendar()
                } label: {
                    Label("创建/使用“\(calendarSync.scheduleCalendarName)”", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(.bordered)
                .disabled(calendarSync.isWorking)

                if calendarSync.calendars.isEmpty {
                    Text("没有找到可编辑的日历")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("互传日历", selection: $calendarSync.selectedCalendarID) {
                        ForEach(calendarSync.calendars) { calendar in
                            Text(calendar.displayName).tag(calendar.id)
                        }
                    }

                    HStack {
                        Button {
                            Task { await calendarSync.importFromCalendar(into: store) }
                        } label: {
                            Label("导入行程", systemImage: "arrow.down.to.line")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task { await calendarSync.exportToCalendar(from: store) }
                        } label: {
                            Label("写入日历", systemImage: "arrow.up.to.line")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .disabled(calendarSync.isWorking)
                }
            } else if calendarSync.authorizationStatus == .denied || calendarSync.authorizationStatus == .restricted {
                Button("打开系统日历权限设置") { calendarSync.openPrivacySettings() }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("允许访问 Mac 日历") {
                    Task { await calendarSync.requestAccess() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(calendarSync.isWorking)
            }

            if calendarSync.isWorking {
                ProgressView()
                    .controlSize(.small)
            }

            Text(calendarSync.statusMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("互传范围：过去 1 年至未来 2 年；不会自动删除任一边的数据。")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 350)
        .onAppear { calendarSync.refreshCalendars() }
    }
}
