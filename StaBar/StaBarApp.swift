import SwiftUI

@main
struct StaBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // All UI is managed by AppDelegate via NSStatusItem + NSPopover.
        // We need at least one Scene, so use an empty Settings scene.
        Settings {
            EmptyView()
        }
    }
}

/// Custom NSHostingView subclass that passes all mouse events through
/// to the underlying NSStatusBarButton, enabling click-to-open popover.
class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var hostingView: ClickThroughHostingView<StatusBarContentView>!
    private var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Create status item with variable width
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Create SwiftUI hosting view for the status bar content
        let contentView = StatusBarContentView(viewModel: MetricsViewModel.shared)
        hostingView = ClickThroughHostingView(rootView: contentView)

        if let button = statusItem.button {
            // Embed the hosting view inside the status bar button
            button.addSubview(hostingView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: button.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            ])

            button.frame.size = hostingView.fittingSize

            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create the popover for settings
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())

        // Periodically refresh the hosting view to reflect updated metrics
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.hostingView.rootView = StatusBarContentView(viewModel: MetricsViewModel.shared)
            if let button = self.statusItem.button {
                button.frame.size = self.hostingView.fittingSize
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Activate the app so the popover receives focus
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
