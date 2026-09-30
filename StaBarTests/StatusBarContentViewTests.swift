import XCTest
import SwiftUI
@testable import StaBar

final class StatusBarContentViewTests: XCTestCase {

    /// Menu bar items are right aligned, so the status item must keep a constant
    /// width no matter how long the individual numbers get — otherwise every
    /// icon further left in the menu bar shifts on each refresh.
    func testStatusBarWidthDoesNotChangeWithValues() {
        let prefs = PreferencesStore.shared
        let vm = MetricsViewModel.shared

        // Make sure every column is present for the measurement.
        let saved = (prefs.showCPU, prefs.showGPU, prefs.showRAM, prefs.showDisk, prefs.showNet)
        prefs.showCPU = true
        prefs.showGPU = true
        prefs.showRAM = true
        prefs.showDisk = true
        prefs.showNet = true
        defer {
            prefs.showCPU = saved.0
            prefs.showGPU = saved.1
            prefs.showRAM = saved.2
            prefs.showDisk = saved.3
            prefs.showNet = saved.4
        }

        func width(cpu: Double, gpu: Double?, ram: Double, disk: Double,
                   upload: Double, download: Double) -> CGFloat {
            vm.cpuUsage = cpu
            vm.gpuUsage = gpu
            vm.ramUsage = ram
            vm.diskUsage = disk
            vm.netUpload = upload
            vm.netDownload = download

            let hosting = NSHostingView(rootView: StatusBarContentView(viewModel: vm))
            hosting.layoutSubtreeIfNeeded()
            return hosting.fittingSize.width
        }

        let idle = width(cpu: 0, gpu: 0, ram: 0, disk: 0, upload: 0, download: 0)
        let single = width(cpu: 9, gpu: 5, ram: 7, disk: 3, upload: 12_500, download: 1_250_000)
        let full = width(cpu: 100, gpu: 100, ram: 100, disk: 100, upload: 1_250_000_000, download: 1_250_000_000)
        let gpuMissing = width(cpu: 42, gpu: nil, ram: 42, disk: 42, upload: 12_500, download: 12_500)

        XCTAssertGreaterThan(idle, 100, "Status item should still show every metric")
        XCTAssertEqual(idle, single, accuracy: 0.5, "One-digit values must not resize the item")
        XCTAssertEqual(idle, full, accuracy: 0.5, "Three-digit values must not resize the item")
        XCTAssertEqual(idle, gpuMissing, accuracy: 0.5, "A missing GPU reading must not resize the item")
    }
}
