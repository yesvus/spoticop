// SpotiCop: native macOS preferences window and application entry point.
import AppKit
import SwiftUI

final class PreferencesTabViewController: NSTabViewController {
    let config: ConfigManager
    var tabSizes: [String: NSSize] = [:]
    var initialSelected = false

    init(config: ConfigManager) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "SpotiCop"
        self.tabStyle = .toolbar
        self.transitionOptions = [] // No fade transition

        let generalVC = NSHostingController(rootView: GeneralTabView(config: config))
        let generalItem = NSTabViewItem(viewController: generalVC)
        generalItem.identifier = "general"
        generalItem.label = "General"
        generalItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General")

        let scheduleVC = NSHostingController(rootView: ScheduleTabView(config: config))
        let scheduleItem = NSTabViewItem(viewController: scheduleVC)
        scheduleItem.identifier = "schedule"
        scheduleItem.label = "Schedule"
        scheduleItem.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Schedule")

        let activityVC = NSHostingController(rootView: ActivityTabView(config: config))
        let activityItem = NSTabViewItem(viewController: activityVC)
        activityItem.identifier = "activity"
        activityItem.label = "Activity"
        activityItem.image = NSImage(systemSymbolName: "list.bullet", accessibilityDescription: "Activity")

        let aboutVC = NSHostingController(rootView: AboutTabView(config: config))
        let aboutItem = NSTabViewItem(viewController: aboutVC)
        aboutItem.identifier = "about"
        aboutItem.label = "About"
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")

        tabSizes["general"] = generalVC.view.fittingSize
        tabSizes["schedule"] = scheduleVC.view.fittingSize
        tabSizes["activity"] = activityVC.view.fittingSize
        tabSizes["about"] = aboutVC.view.fittingSize

        self.addTabViewItem(generalItem)
        self.addTabViewItem(scheduleItem)
        self.addTabViewItem(activityItem)
        self.addTabViewItem(aboutItem)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if let window = self.view.window,
           let item = self.tabView.selectedTabViewItem ?? self.tabView.tabViewItems.first,
           let id = item.identifier as? String,
           let size = tabSizes[id] {
            resizeWindow(to: size, in: window, animated: false)
        }
        self.view.window?.title = "SpotiCop"
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "SpotiCop"
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        self.view.window?.title = "SpotiCop"
        guard let item = tabViewItem,
              let id = item.identifier as? String,
              let size = tabSizes[id],
              let window = self.view.window else { return }

        resizeWindow(to: size, in: window, animated: initialSelected)
        initialSelected = true
    }

    func resizeWindow(to size: NSSize, in window: NSWindow, animated: Bool) {
        let currentWindowFrame = window.frame
        let targetContentRect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let newFrameRect = window.frameRect(forContentRect: targetContentRect)

        let heightDifference = newFrameRect.size.height - currentWindowFrame.size.height
        let widthDifference = newFrameRect.size.width - currentWindowFrame.size.width

        var newOrigin = NSPoint(
            x: currentWindowFrame.origin.x - round(0.5 * widthDifference),
            y: currentWindowFrame.origin.y - heightDifference
        )

        if let screen = window.screen?.visibleFrame {
            if newOrigin.x < screen.minX { newOrigin.x = screen.minX }
            if newOrigin.x + newFrameRect.width > screen.maxX { newOrigin.x = screen.maxX - newFrameRect.width }
            if newOrigin.y < screen.minY { newOrigin.y = screen.minY }
        }

        let newFrame = NSRect(origin: newOrigin, size: newFrameRect.size)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.20
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(newFrame, display: true)
            }
        } else {
            window.setFrame(newFrame, display: true)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    let config = ConfigManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let tabVC = PreferencesTabViewController(config: config)
        tabVC.title = "SpotiCop"
        let w = NSWindow(contentViewController: tabVC)
        w.title = "SpotiCop"
        w.styleMask = [.titled, .closable, .miniaturizable]
        w.toolbarStyle = .preference
        w.isReleasedWhenClosed = false
        w.collectionBehavior = [.fullScreenNone]
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = w
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window?.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct SpotiCopApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
