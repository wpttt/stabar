import Foundation
import Observation

/// Observable view model that collects metrics from all readers and binds them to UI
@Observable
final class MetricsViewModel {
    static let shared = MetricsViewModel()
    
    // MARK: - Published Metrics
    var cpuUsage: Double = 0
    var gpuUsage: Double? = nil
    var ramUsage: Double = 0
    var diskUsage: Double = 0
    var netUpload: Double = 0
    var netDownload: Double = 0

    // Detailed figures backing the hover detail panel
    var ramUsed: Double = 0
    var ramTotal: Double = Double(ProcessInfo.processInfo.physicalMemory)
    var diskUsed: Double = 0
    var diskTotal: Double = 0

    var menuBarText: String {
        let prefs = PreferencesStore.shared
        var topParts: [String] = []
        var bottomParts: [String] = []

        if prefs.showCPU {
            topParts.append("cpu")
            bottomParts.append("\(Int(cpuUsage))%")
        }
        if prefs.showGPU, let gpu = gpuUsage {
            topParts.append("gpu")
            bottomParts.append("\(Int(gpu))%")
        }
        if prefs.showRAM {
            topParts.append("ram")
            bottomParts.append("\(Int(ramUsage))%")
        }
        if prefs.showDisk {
            topParts.append("dsk")
            bottomParts.append("\(Int(diskUsage))%")
        }
        if prefs.showNet {
            let upStr = formatSpeed(netUpload, unit: prefs.netUnit)
            let downStr = formatSpeed(netDownload, unit: prefs.netUnit)
            topParts.append("↑\(upStr)")
            bottomParts.append("↓\(downStr)")
        }

        if topParts.isEmpty { return "StaBar" }

        let top = topParts.joined(separator: "  ")
        let bottom = bottomParts.joined(separator: "  ")
        return "\(top)\n\(bottom)"
    }

    /// Formats a byte count as a human readable capacity, e.g. "10.0 GB".
    /// - Parameter binary: use 1024-based units (memory) instead of 1000-based (disks)
    func formatCapacity(used: Double, total: Double, binary: Bool = false) -> String {
        guard total > 0 else { return "—" }

        let mb = binary ? 1_048_576.0 : 1_000_000.0
        let gb = binary ? 1_073_741_824.0 : 1_000_000_000.0
        let tb = binary ? 1_099_511_627_776.0 : 1_000_000_000_000.0

        if total >= tb {
            return String(format: "%.1f/%.1f TB", used / tb, total / tb)
        }
        if total >= gb {
            let format = total >= 100 * gb ? "%.0f/%.0f GB" : "%.1f/%.0f GB"
            return String(format: format, used / gb, total / gb)
        }
        if total >= mb {
            return String(format: "%.0f/%.0f MB", used / mb, total / mb)
        }
        return String(format: "%.0f/%.0f B", used, total)
    }

    /// Formats system uptime, e.g. "3d 4h" / "2h 15m" / "42s"
    func formatUptime(_ interval: TimeInterval? = nil) -> String {
        let uptime = max(0, interval ?? ProcessInfo.processInfo.systemUptime)
        let totalSeconds = Int(uptime)
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m \(seconds)s" }
        return "\(seconds)s"
    }

    func formatSpeed(_ bytesPerSec: Double, unit: String) -> String {
        let value: Double
        if unit == "Kbps" {
            value = bytesPerSec * 8 / 1_000
        } else {
            // Default: Mbps
            value = bytesPerSec * 8 / 1_000_000
        }

        if unit == "Kbps" {
            if value < 1 { return "—" }
            if value < 1000 { return String(format: "%.0f", value) }
            return "999+"
        } else {
            if value < 0.1 { return "—" }
            if value < 10 { return String(format: "%.1f", value) }
            return String(format: "%.0f", value)
        }
    }

    // MARK: - Private Properties
    private let cpuReader = CPUReader()
    private let gpuReader = GPUReader()
    private let ramReader = RAMReader()
    private let diskReader = DiskReader()
    private let netReader = NetReader()
    
    private var timer: Timer?
    private var intervalCheckTimer: Timer?
    
    // MARK: - Init
    init() {
        setupTimerObservation()
        // Initial collection
        collectMetrics()
    }
    
    deinit {
        timer?.invalidate()
        intervalCheckTimer?.invalidate()
    }
    
    // MARK: - Timer Management
    private func setupTimerObservation() {
        // Watch for refreshInterval changes and reschedule timer
        var lastInterval = PreferencesStore.shared.refreshInterval
        
        // Use a periodic check for interval changes
        intervalCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentInterval = PreferencesStore.shared.refreshInterval
            if currentInterval != lastInterval {
                lastInterval = currentInterval
                self.rescheduleTimer()
            }
        }
        
        rescheduleTimer()
    }
    
    private func rescheduleTimer() {
        timer?.invalidate()
        
        let interval = PreferencesStore.shared.refreshInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.collectMetrics()
        }
    }
    
    // MARK: - Metric Collection
    func collectMetrics() {
        // Dispatch to background queue for collection
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var cpuValue: Double = 0
            var gpuValue: Double? = nil
            var ramValue: Double = 0
            var ramUsedValue: Double = 0
            var ramTotalValue: Double = Double(ProcessInfo.processInfo.physicalMemory)
            var diskValue: Double = 0
            var diskUsedValue: Double = 0
            var diskTotalValue: Double = 0
            var netUploadValue: Double = 0
            var netDownloadValue: Double = 0
            
            // Collect CPU
            do {
                cpuValue = try self.cpuReader.read()
            } catch {
                cpuValue = 0
            }
            
            // Collect GPU
            gpuValue = self.gpuReader.read()
            
            // Collect RAM
            do {
                let detail = try self.ramReader.readDetail()
                ramUsedValue = detail.used
                ramTotalValue = detail.total
                ramValue = detail.total > 0 ? min(100.0, max(0.0, detail.used / detail.total * 100.0)) : 0
            } catch {
                ramValue = 0
                ramUsedValue = 0
            }
            
            // Collect Disk
            do {
                let detail = try self.diskReader.readDetail()
                diskUsedValue = detail.used
                diskTotalValue = detail.total
                diskValue = detail.total > 0 ? min(100.0, max(0.0, detail.used / detail.total * 100.0)) : 0
            } catch {
                diskValue = 0
                diskUsedValue = 0
            }
            
            // Collect Network
            do {
                let netMetric = try self.netReader.read()
                netUploadValue = netMetric.upload
                netDownloadValue = netMetric.download
            } catch {
                netUploadValue = 0
                netDownloadValue = 0
            }
            
            // Update on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.cpuUsage = cpuValue
                self.gpuUsage = gpuValue
                self.ramUsage = ramValue
                self.ramUsed = ramUsedValue
                self.ramTotal = ramTotalValue
                self.diskUsage = diskValue
                self.diskUsed = diskUsedValue
                self.diskTotal = diskTotalValue
                self.netUpload = netUploadValue
                self.netDownload = netDownloadValue
            }
        }
    }
}
