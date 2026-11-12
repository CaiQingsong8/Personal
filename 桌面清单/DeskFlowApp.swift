import AppKit
import CoreGraphics
import SwiftUI
import UserNotifications

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()

    @Published var isFloating = false {
        didSet { configureWindow(placeAtTopLeft: false) }
    }

    private init() {}

    func configureWindow(placeAtTopLeft: Bool) {
        guard let window = NSApp.windows.first(where: { $0.canBecomeKey }) ?? NSApp.windows.first else { return }
        window.title = "桌面清单"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        let frameAutosaveName = "DeskFlowMainWindow"
        let restoredSavedFrame = placeAtTopLeft ? window.setFrameUsingName(frameAutosaveName) : true
        window.setFrameAutosaveName(frameAutosaveName)

        if ProcessInfo.processInfo.environment["DESKFLOW_QA"] == "1" {
            window.level = .floating
        } else if isFloating {
            // Unpinned mode behaves like a normal Mac window: it can come to
            // the front while in use, but never stays above other apps.
            window.level = .normal
        } else {
            // Above Finder's desktop/icons so the app receives clicks, while still
            // remaining far below normal application windows (level 0).
            let interactiveDesktopLevel = Int(CGWindowLevelForKey(.desktopIconWindow)) + 1
            window.level = NSWindow.Level(rawValue: interactiveDesktopLevel)
        }

        if placeAtTopLeft, !restoredSavedFrame, let screen = NSScreen.main {
            let frame = window.frame
            let x = screen.visibleFrame.minX + 22
            let y = screen.visibleFrame.maxY - frame.height - 22
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var rolloverTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wokeFromSleep), name: NSWorkspace.didWakeNotification, object: nil)
        scheduleDailyRollover()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            WindowManager.shared.configureWindow(placeAtTopLeft: true)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        Task { @MainActor in
            AppStore.shared.refreshDayIfNeeded()
            self.scheduleDailyRollover()
        }
    }

    @objc private func wokeFromSleep() {
        Task { @MainActor in
            AppStore.shared.refreshDayIfNeeded()
            self.scheduleDailyRollover()
        }
    }

    @MainActor private func scheduleDailyRollover() {
        rolloverTimer?.invalidate()
        let timer = Timer(fire: DailyRollover.nextCutoff(after: Date()), interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                AppStore.shared.refreshDayIfNeeded()
                self?.scheduleDailyRollover()
            }
        }
        rolloverTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in AppStore.shared.prepareForTermination() }
    }
}

@main
struct DeskFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStore.shared
    @StateObject private var windowManager = WindowManager.shared
    @StateObject private var calendarSync = CalendarSyncService.shared
    @StateObject private var reminderSync = ReminderSyncService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(windowManager)
                .environmentObject(calendarSync)
                .environmentObject(reminderSync)
                .frame(minWidth: 410, idealWidth: 430, maxWidth: 560,
                       minHeight: 620, idealHeight: 690, maxHeight: 900)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("数据") {
                Button("导出备份（JSON）") { store.exportJSON() }
                Button("导出任务（JSON）") { store.exportChecklistJSON(.tasks) }
                Button("导出事项（JSON）") { store.exportChecklistJSON(.reminders) }
                Button("导入任务或事项（JSON）") { store.importChecklistJSON() }
                Button("导出任务（CSV）") { store.exportCSV() }
                Divider()
                Button("打开数据目录") {
                    try? FileManager.default.createDirectory(at: store.dataDirectory, withIntermediateDirectories: true)
                    NSWorkspace.shared.open(store.dataDirectory)
                }
            }
        }
    }
}
