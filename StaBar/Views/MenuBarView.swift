import SwiftUI

struct MenuBarView: View {
    @State private var viewModel = MetricsViewModel.shared
    @State private var isSettingsPresented = false
    
    var body: some View {
        SettingsView(preferences: PreferencesStore.shared)
            .padding(12)
            .frame(width: 280)
            .background(.regularMaterial)
    }
}

#Preview {
    MenuBarView()
}
