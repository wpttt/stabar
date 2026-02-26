import SwiftUI

@main
struct StaBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = MetricsViewModel.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            CompactStatusView(
                preferences: PreferencesStore.shared,
                cpuUsage: viewModel.cpuUsage,
                gpuUsage: viewModel.gpuUsage,
                ramUsage: viewModel.ramUsage,
                diskUsage: viewModel.diskUsage,
                netUpload: viewModel.netUpload,
                netDownload: viewModel.netDownload
            )
        }
        .menuBarExtraStyle(.window)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
}
