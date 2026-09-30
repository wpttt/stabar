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

/// NSHostingView subclass embedded inside the status bar button.
/// - `hitTest` returns nil so every click falls through to the
///   underlying NSStatusBarButton (click-to-open popover).
/// - It also owns a tracking area (`.activeAlways`) which reports
///   pointer enter/exit, driving the hover detail panel.
class StatusItemHostingView<Content: View>: NSHostingView<Content> {
    /// Called whenever the pointer enters or leaves the status item area.
    var onPointerActivity: (() -> Void)?

    private var installedTrackingArea: NSTrackingArea?

    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        // Re-install when AppKit drops it (the status item is re-laid out
        // every time its width changes).
        if let area = installedTrackingArea, trackingAreas.contains(area) { return }
        if let area = installedTrackingArea { removeTrackingArea(area) }

        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        installedTrackingArea = area
    }

    override func mouseEntered(with event: NSEvent) { onPointerActivity?() }
    override func mouseExited(with event: NSEvent) { onPointerActivity?() }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Grace period before the detail panel closes, so moving the pointer
    /// from the status item into the panel never causes a flicker.
    private enum Timing {
        static let hideGrace: TimeInterval = 0.35
        static let minimumHoverDelay: TimeInterval = 0.2
    }

    // MARK: - UI
    private var statusItem: NSStatusItem!
    private var settingsPopover: NSPopover!
    private var settingsController: NSHostingController<MenuBarView>!
    private var detailPopover: NSPopover!
    private var detailController: NSHostingController<HoverDetailView>!
    private var hostingView: StatusItemHostingView<StatusBarContentView>!
    private var updateTimer: Timer?

    // MARK: - Hover State
    private var hoverTimer: Timer?
    private var hideTimer: Timer?
    private var eventMonitors: [Any] = []
    private var panelTrackingArea: NSTrackingArea?

    private var prefs: PreferencesStore { PreferencesStore.shared }

    // MARK: - Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Create status item with variable width
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Create SwiftUI hosting view for the status bar content
        let contentView = StatusBarContentView(viewModel: MetricsViewModel.shared)
        hostingView = StatusItemHostingView(rootView: contentView)
        hostingView.onPointerActivity = { [weak self] in
            self?.evaluatePointer()
        }

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

        setupSettingsPopover()
        setupDetailPopover()
        setupPointerMonitors()
        setupWorkspaceObservers()

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
        cancelHoverTimer()
        cancelHideTimer()
        eventMonitors.forEach { NSEvent.removeMonitor($0) }
        eventMonitors.removeAll()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Popovers
    private func setupSettingsPopover() {
        settingsController = NSHostingController(rootView: MenuBarView())
        settingsPopover = NSPopover()
        settingsPopover.behavior = .transient
        settingsPopover.contentViewController = settingsController
        settingsPopover.delegate = self
        settingsPopover.contentSize = NSSize(width: MenuBarView.panelWidth, height: 320)
    }

    private func setupDetailPopover() {
        detailController = NSHostingController(rootView: HoverDetailView())
        detailPopover = NSPopover()
        // Closing is driven entirely by pointer/click events so the panel
        // stays open while the pointer rests on it and never closes on its own.
        detailPopover.behavior = .applicationDefined
        detailPopover.contentViewController = detailController
        detailPopover.contentSize = NSSize(width: HoverDetailView.panelWidth, height: 300)
        refreshDetailContentSize()

        // Track the panel itself so leaving it (while StaBar is the active
        // application) also dismisses it.
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        detailController.view.addTrackingArea(area)
        panelTrackingArea = area
    }

    /// Matches the popover height to the SwiftUI content (rows change with preferences).
    private func refreshDetailContentSize() {
        detailController.view.layoutSubtreeIfNeeded()
        let fitting = detailController.view.fittingSize
        guard fitting.width > 1, fitting.height > 1 else { return }
        detailPopover.contentSize = NSSize(width: HoverDetailView.panelWidth, height: fitting.height)
    }

    /// Matches the popover height to the SwiftUI content, clamped so the panel
    /// never turns into a near full-screen sheet.
    private func refreshSettingsContentSize() {
        settingsController.view.layoutSubtreeIfNeeded()
        let fitting = settingsController.view.fittingSize
        guard fitting.width > 1, fitting.height > 1 else { return }
        let height = min(max(fitting.height, MenuBarView.minimumHeight), MenuBarView.maximumHeight)
        settingsPopover.contentSize = NSSize(width: MenuBarView.panelWidth, height: height)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if settingsPopover.isShown {
            settingsPopover.performClose(nil)
        } else {
            // The two panels are mutually exclusive.
            hideDetail()
            refreshSettingsContentSize()
            settingsPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Activate the app so the popover receives focus
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Pointer Monitoring
    private func setupPointerMonitors() {
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .rightMouseDown]

        // Events delivered to *other* applications — the usual case, since a
        // menu bar utility is almost never the active app.
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.pointerEvent(event.type)
        }

        // Events delivered to StaBar itself (e.g. right after the settings
        // popover has been used and the app stays active).
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.pointerEvent(event.type)
            return event
        }

        eventMonitors = [globalMonitor, localMonitor].compactMap { $0 }
    }

    private func setupWorkspaceObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeApplicationDidChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func activeApplicationDidChange(_ notification: Notification) {
        // Ignore our own activation (opening the settings popover).
        if NSWorkspace.shared.frontmostApplication?.processIdentifier == ProcessInfo.processInfo.processIdentifier {
            return
        }
        // Switching away means the user moved on — dismiss the detail panel.
        hideDetail()
    }

    /// Tracking-area callbacks (panel / status item) arrive on the main thread.
    @objc func mouseEntered(with event: NSEvent) { pointerEvent(.mouseMoved) }
    @objc func mouseExited(with event: NSEvent) { pointerEvent(.mouseMoved) }

    private func pointerEvent(_ type: NSEvent.EventType) {
        if Thread.isMainThread {
            handlePointerEvent(of: type)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handlePointerEvent(of: type)
            }
        }
    }

    private func handlePointerEvent(of type: NSEvent.EventType) {
        let overItem = isPointerOverStatusItem()
        let overDetail = detailPopover.isShown && isPointerOverDetailPopover()

        // A click outside the panel dismisses it immediately.
        if detailPopover.isShown,
           (type == .leftMouseDown || type == .rightMouseDown),
           !overItem, !overDetail {
            hideDetail()
            return
        }

        evaluatePointer(overItem: overItem, overDetail: overDetail)
    }

    // MARK: - Hover State Machine
    private func evaluatePointer() {
        evaluatePointer(
            overItem: isPointerOverStatusItem(),
            overDetail: detailPopover.isShown && isPointerOverDetailPopover()
        )
    }

    private func evaluatePointer(overItem: Bool, overDetail: Bool) {
        // Feature switched off (or settings panel open): never show the panel.
        guard prefs.hoverDetailEnabled, !settingsPopover.isShown else {
            cancelHoverTimer()
            if detailPopover.isShown { hideDetail() }
            return
        }

        if overItem {
            cancelHideTimer()
            if !detailPopover.isShown {
                startHoverTimer()
            }
        } else {
            cancelHoverTimer()
            if overDetail {
                cancelHideTimer()
            } else if detailPopover.isShown {
                scheduleHide()
            } else {
                cancelHideTimer()
            }
        }
    }

    /// Starts the "hover for N seconds" countdown.
    private func startHoverTimer() {
        guard hoverTimer == nil else { return }
        let timer = Timer(timeInterval: max(Timing.minimumHoverDelay, prefs.hoverDelay), repeats: false) { [weak self] _ in
            self?.hoverTimer = nil
            self?.showDetail()
        }
        RunLoop.main.add(timer, forMode: .common)
        hoverTimer = timer
    }

    private func showDetail() {
        guard prefs.hoverDetailEnabled,
              !settingsPopover.isShown,
              !detailPopover.isShown,
              isPointerOverStatusItem(),
              let button = statusItem.button else { return }

        refreshDetailContentSize()
        // Deliberately not activating the app: hovering must never steal focus.
        detailPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func scheduleHide() {
        guard hideTimer == nil else { return }
        let timer = Timer(timeInterval: Timing.hideGrace, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.hideTimer = nil
            let stillInside = self.isPointerOverStatusItem()
                || (self.detailPopover.isShown && self.isPointerOverDetailPopover())
            if !stillInside {
                self.hideDetail()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        hideTimer = timer
    }

    private func hideDetail() {
        cancelHoverTimer()
        cancelHideTimer()
        if detailPopover.isShown {
            detailPopover.close()
        }
    }

    private func cancelHoverTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }

    private func cancelHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    // MARK: - Geometry
    private func isPointerOverStatusItem() -> Bool {
        guard let button = statusItem?.button, let window = button.window else { return false }
        let cursor = NSEvent.mouseLocation
        let windowPoint = window.convertFromScreen(NSRect(origin: cursor, size: .zero)).origin
        let localPoint = button.convert(windowPoint, from: nil)
        // Small tolerance makes entering the panel below the item seamless.
        return button.bounds.insetBy(dx: -3, dy: -3).contains(localPoint)
    }

    private func isPointerOverDetailPopover() -> Bool {
        guard detailPopover.isShown,
              let window = detailPopover.contentViewController?.view.window else { return false }
        return window.frame.contains(NSEvent.mouseLocation)
    }
}

// MARK: - NSPopoverDelegate
extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        guard let closed = notification.object as? NSPopover, closed === settingsPopover else { return }
        // Re-arm hover detection once the settings panel is gone; the pointer
        // may already be resting on the status item.
        evaluatePointer()
    }
}
