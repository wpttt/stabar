import SwiftUI

struct MenuBarView: View {
    @State private var isSettingsPresented = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row with compact metrics display (placeholder)
            HStack {
                Text("C --% G --% R --% D --% ↑-- ↓--")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Settings panel placeholder
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.headline)
                Toggle("Show CPU", isOn: .constant(true))
                Toggle("Show GPU", isOn: .constant(true))
            }
            .padding(12)
        }
        .frame(width: 280)
        .background(.regularMaterial)
    }
}

#Preview {
    MenuBarView()
}
