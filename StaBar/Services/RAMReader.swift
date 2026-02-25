import Foundation
import Darwin

// MARK: - RAM Reader
/// Reads RAM usage metrics from system statistics
class RAMReader: MetricReader {
    typealias Output = Double
    
    /// Reads system RAM usage percentage
    /// - Returns: RAM usage as a percentage (0.0-100.0)
    /// - Throws: MetricError if unable to read RAM stats
    func read() throws -> Double {
        var stats = vm_statistics64()
        var count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            throw MetricError.readFailed("Failed to get VM statistics")
        }
        
        // Get total physical memory
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        
        // Convert page counts to bytes using vm_page_size
        let pageSize = Double(vm_page_size)
        
        // Calculate used memory: (active + wired + purgeable + external)
        // Note: Using standard memory metrics from vm_statistics64
        let usedPages = Double(stats.active_count + stats.wire_count + stats.purgeable_count + stats.external_page_count)
        let usedMemory = usedPages * pageSize
        
        let usagePercentage = (usedMemory / totalMemory) * 100.0
        
        // Clamp to 0-100 range to handle edge cases
        return min(100.0, max(0.0, usagePercentage))
    }
}
