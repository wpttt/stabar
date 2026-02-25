import SwiftUI

struct MenuBarView: View {
    @State private var viewModel = MetricsViewModel.shared
    @State private var isSettingsPresented = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact status view with live metrics
            CompactStatusView(
                preferences: PreferencesStore.shared,
                cpuUsage: viewModel.cpuUsage,
                gpuUsage: viewModel.gpuUsage,
                ramUsage: viewModel.ramUsage,
                diskUsage: viewModel.diskUsage,
                netUpload: viewModel.netUpload,
                netDownload: viewModel.netDownload
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Settings panel
            SettingsView(preferences: PreferencesStore.shared)
            .padding(12)
        }
        .frame(width: 280)
        .background(.regularMaterial)
    }
}

#Preview {
    MenuBarView()
}
