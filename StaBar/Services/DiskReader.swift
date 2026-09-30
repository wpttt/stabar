import Foundation
import Darwin

// MARK: - Disk Reader
/// Reads disk usage metrics for the boot volume
public class DiskReader: MetricReader {
    public typealias Output = Double
    
    /// Detailed disk figures (bytes) used by the hover detail panel
    public struct Detail {
        public let used: Double
        public let total: Double
    }
    
    /// Reads boot volume disk usage percentage
    /// - Returns: Disk usage as a percentage (0.0-100.0)
    /// - Throws: MetricError if unable to read disk stats
    public func read() throws -> Double {
        let detail = try readDetail()
        guard detail.total > 0 else { return 0 }
        let percentage = (detail.used / detail.total) * 100.0
        return min(100.0, max(0.0, percentage))
    }
    
    /// Reads used / total capacity of the boot volume in bytes
    /// - Returns: used and total capacity in bytes
    /// - Throws: MetricError if unable to read disk stats
    public func readDetail() throws -> Detail {
        var stats = statfs()
        
        // Get filesystem stats for root (boot volume)
        guard statfs("/", &stats) == 0 else {
            throw MetricError.readFailed("Failed to get filesystem stats")
        }
        
        // Calculate usage
        let blockSize = Double(stats.f_bsize)
        let totalBlocks = Double(stats.f_blocks)
        let availableBlocks = Double(stats.f_bavail)
        
        let totalBytes = totalBlocks * blockSize
        let availableBytes = availableBlocks * blockSize
        let usedBytes = max(0, totalBytes - availableBytes)
        
        return Detail(used: usedBytes, total: totalBytes)
    }
}
