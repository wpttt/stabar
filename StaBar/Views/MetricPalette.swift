import SwiftUI
import AppKit

/// Single source of truth for the colours used by the hover detail panel and
/// the settings panel, so both always look like one system.
///
/// The palette is built from AppKit's semantic colours — the same family
/// Finder uses for its tags (red / orange / yellow / green / blue / purple).
/// They are appearance aware, so every tone stays vivid on the dark menu bar
/// while darkening automatically on a light background to keep small text
/// readable. No hand-tuned RGB pairs to keep in sync.
enum MetricPalette {

    /// Metric identity colours — badge icons and settings chips.
    enum Tint {
        static let cpu = Color(nsColor: .systemOrange)
        static let gpu = Color(nsColor: .systemPurple)
        static let ram = Color(nsColor: .systemBlue)
        static let disk = Color(nsColor: .systemTeal)
        static let net = Color(nsColor: .systemGreen)
    }

    /// Load level, used for the metric value text and the usage bar.
    /// Green and orange deliberately reuse the Net / CPU icon colours so the
    /// panel only ever shows one green and one orange.
    enum Status {
        /// < 60% — green (same as the Net icon)
        static let normal = Tint.net
        /// 60% … 85% — orange (same as the CPU icon)
        static let busy = Tint.cpu
        /// ≥ 85% — red
        static let hot = Color(nsColor: .systemRed)
    }

    /// Small indicators such as the "Live" dot use the normal/healthy tone.
    static let indicator = Status.normal

    /// Off state for settings chips.
    static let inactive = Color.secondary
}
