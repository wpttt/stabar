import SwiftUI

struct MenuBarView: View {

    var body: some View {
        VStack(spacing: 0) {
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
