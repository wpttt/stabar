import SwiftUI

@main
struct StaBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = MetricsViewModel.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            Text(viewModel.menuBarText)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
