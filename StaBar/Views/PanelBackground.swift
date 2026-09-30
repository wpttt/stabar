import SwiftUI
import AppKit

/// Shared background for the settings and hover popovers.
///
/// SwiftUI's `.regularMaterial` follows the window's active state. The hover
/// panel is shown without activating the app (so it never steals focus) while
/// the settings panel does activate it, which made AppKit render the same
/// material dimmer in one panel than the other — a visible colour jump when
/// switching between them.
///
/// Forcing the visual effect state to `.active` makes both panels render
/// identically no matter which one is currently frontmost.
struct PanelBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effect = NSVisualEffectView()
        effect.material = .contentBackground
        effect.blendingMode = .behindWindow
        effect.state = .active
        return effect
    }

    func updateNSView(_ effect: NSVisualEffectView, context: Context) {
        effect.state = .active
    }
}

#Preview {
    PanelBackground()
        .frame(width: 120, height: 60)
        .overlay(Text("Panel").font(.caption))
}
