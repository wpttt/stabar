import SwiftUI

/// Panel shown when the status item is clicked.
/// Mirrors `HoverDetailView` so both popovers share width and background.
struct MenuBarView: View {
    static let panelWidth = HoverDetailView.panelWidth
    /// The compact layout is meant to fit on one page; these bounds only act as
    /// a safety net should a future setting need more room.
    static let minimumHeight: CGFloat = 240
    static let maximumHeight: CGFloat = 360

    var body: some View {
        SettingsView(preferences: PreferencesStore.shared)
            .frame(width: Self.panelWidth)
            .background { PanelBackground() }
    }
}

#Preview {
    MenuBarView()
        .padding(.vertical, 4)
}
