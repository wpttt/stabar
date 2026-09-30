import XCTest
import SwiftUI
@testable import StaBar

final class HoverDetailViewTests: XCTestCase {

    /// Renders the hover detail panel off-screen so layout problems (zero
    /// height, truncated values, missing rows) show up immediately.
    func testHoverDetailViewRendersToImage() throws {
        try renderHoverDetail(appearance: nil, to: "/tmp/stabar_hover_detail.png")
        try renderHoverDetail(appearance: NSAppearance(named: .darkAqua), to: "/tmp/stabar_hover_detail_dark.png")
    }

    private func renderHoverDetail(appearance: NSAppearance?, to path: String) throws {
        let hosting = NSHostingView(rootView: HoverDetailView())
        hosting.appearance = appearance
        hosting.layoutSubtreeIfNeeded()

        let ideal = hosting.fittingSize
        XCTAssertEqual(ideal.width, HoverDetailView.panelWidth, "Panel width must stay stable")
        XCTAssertGreaterThan(ideal.height, 150, "Panel needs room for header + rows + footer")
        XCTAssertLessThan(ideal.height, 300, "Panel should stay compact")

        try render(hosting, size: ideal, appearance: appearance, to: path)
    }

    /// Renders the settings panel so its compact one-page layout can be reviewed.
    func testSettingsPanelRendersToImage() throws {
        for (appearance, path) in [
            (nil, "/tmp/stabar_settings.png"),
            (NSAppearance(named: .darkAqua), "/tmp/stabar_settings_dark.png")
        ] {
            let hosting = NSHostingView(rootView: MenuBarView())
            hosting.appearance = appearance
            hosting.layoutSubtreeIfNeeded()
            let ideal = hosting.fittingSize
            try render(hosting, size: ideal, appearance: appearance, to: path)
        }
    }

    private func render(_ hosting: NSView, size: NSSize, appearance: NSAppearance?, to path: String) throws {
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.layoutSubtreeIfNeeded()

        let scale = 2.0
        let pixelWidth = Int(size.width * scale)
        let pixelHeight = Int(size.height * scale)

        guard let viewRep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            return XCTFail("Could not create bitmap")
        }
        hosting.cacheDisplay(in: hosting.bounds, to: viewRep)

        guard let outRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return XCTFail("Could not create output bitmap")
        }
        outRep.size = size

        // Opaque backdrop so the material background is visible in the snapshot,
        // then composite the rendered panel on top of it.
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: outRep) else {
            NSGraphicsContext.restoreGraphicsState()
            return XCTFail("Could not create graphics context")
        }
        NSGraphicsContext.current = context
        // Stand-ins for the popover material, which cannot be rendered off-screen.
        let backdrop = appearance == nil
            ? NSColor(srgbRed: 0.93, green: 0.93, blue: 0.95, alpha: 1)
            : NSColor(srgbRed: 0.16, green: 0.16, blue: 0.18, alpha: 1)
        backdrop.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        viewRep.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()

        let png = try XCTUnwrap(outRep.representation(using: .png, properties: [:]))
        try png.write(to: URL(fileURLWithPath: path))
    }

    /// Capacity strings must always fit the detail rows.
    func testFormatCapacity() {
        let vm = MetricsViewModel.shared

        // Disks use 1000-based units (as shown by Finder)
        XCTAssertEqual(vm.formatCapacity(used: 8_000_000_000, total: 16_000_000_000), "8.0/16 GB")
        XCTAssertEqual(vm.formatCapacity(used: 225_000_000_000, total: 500_000_000_000), "225/500 GB")
        XCTAssertEqual(vm.formatCapacity(used: 0, total: 0), "—")
        XCTAssertTrue(vm.formatCapacity(used: 1e12, total: 2e12).hasSuffix("TB"))

        // Memory uses 1024-based units (as shown by About This Mac)
        let gib = 1_073_741_824.0
        XCTAssertEqual(vm.formatCapacity(used: 8 * gib, total: 32 * gib, binary: true), "8.0/32 GB")
    }

    func testFormatUptime() {
        let vm = MetricsViewModel.shared

        XCTAssertEqual(vm.formatUptime(42), "42s")
        XCTAssertEqual(vm.formatUptime(3_600 + 15 * 60), "1h 15m")
        XCTAssertEqual(vm.formatUptime(3 * 86_400 + 4 * 3_600), "3d 4h")
    }

    /// The settings panel must fit on a single page (no scrolling) and stay
    /// aligned with the hover detail panel.
    func testSettingsPanelFitsOnOnePage() {
        let hosting = NSHostingView(rootView: MenuBarView())
        hosting.layoutSubtreeIfNeeded()
        let fitting = hosting.fittingSize

        XCTAssertEqual(fitting.width, HoverDetailView.panelWidth, "Both panels share one width")
        XCTAssertLessThanOrEqual(fitting.height, MenuBarView.maximumHeight,
                                 "Settings must not need scrolling")
        XCTAssertGreaterThan(fitting.height, 200, "Settings should still hold all sections")
    }
}
