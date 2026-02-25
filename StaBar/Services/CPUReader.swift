import Foundation
import Darwin

// MARK: - CPU Reader
/// Reads CPU usage using host_statistics (HOST_CPU_LOAD_INFO)
/// Note: host_statistics() returns a pointer to a static structure, NOT dynamically allocated.
/// Therefore, vm_deallocate is NOT needed (unlike host_processor_info which DOES require it).
final class CPUReader: MetricReader {
    typealias Output = Double
    
    /// Previous CPU tick counts for delta calculation
    private var previousTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?
    
    /// Read current CPU usage percentage (0.0-100.0)
    /// Returns delta-based usage since last read. First call returns 0.0.
    func read() throws -> Double {
        var cpuLoadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        
        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            throw MetricError.readFailed("Failed to get CPU stats: kern_return \(result)")
        }
        
        // Extract tick counts from tuple
        let user = cpuLoadInfo.cpu_ticks.0
        let system = cpuLoadInfo.cpu_ticks.1
        let idle = cpuLoadInfo.cpu_ticks.2
        let nice = cpuLoadInfo.cpu_ticks.3
        
        // Store current for next delta, return previous-based calculation
        defer { previousTicks = (user: user, system: system, idle: idle, nice: nice) }
        
        // First call: no previous data, return 0
        guard let prev = previousTicks else { return 0.0 }
        
        // Calculate deltas
        let userDelta = user &- prev.user
        let systemDelta = system &- prev.system
        let idleDelta = idle &- prev.idle
        let niceDelta = nice &- prev.nice
        
        let totalDelta = userDelta &+ systemDelta &+ idleDelta &+ niceDelta
        guard totalDelta > 0 else { return 0.0 }
        
        let activeDelta = userDelta &+ systemDelta &+ niceDelta
        let usage = Double(activeDelta) / Double(totalDelta) * 100.0
        
        return min(100.0, max(0.0, usage))
    }
}
