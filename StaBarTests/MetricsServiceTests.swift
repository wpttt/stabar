import XCTest
@testable import StaBar

final class MetricsServiceTests: XCTestCase {
    
    func testCPUReaderReturnsValidPercentage() throws {
        let reader = CPUReader()
        _ = try reader.read()  // First call returns 0
        let cpu = try reader.read()
        XCTAssertGreaterThanOrEqual(cpu, 0.0)
        XCTAssertLessThanOrEqual(cpu, 100.0)
    }
    
    func testGPUReaderReturnsValidPercentageOrNil() {
        let reader = GPUReader()
        let gpu = reader.read()
        if let value = gpu {
            XCTAssertGreaterThanOrEqual(value, 0.0)
            XCTAssertLessThanOrEqual(value, 100.0)
        }
        // nil is acceptable (GPU unavailable)
    }
    
    func testRAMReaderReturnsValidPercentage() throws {
        let reader = RAMReader()
        let ram = try reader.read()
        XCTAssertGreaterThanOrEqual(ram, 0.0)
        XCTAssertLessThanOrEqual(ram, 100.0)
    }
    
    func testDiskReaderReturnsValidPercentage() throws {
        let reader = DiskReader()
        let disk = try reader.read()
        XCTAssertGreaterThanOrEqual(disk, 0.0)
        XCTAssertLessThanOrEqual(disk, 100.0)
    }
    
    func testNetReaderReturnsNonNegativeValues() throws {
        let reader = NetReader()
        let net = try reader.read()
        XCTAssertGreaterThanOrEqual(net.upload, 0.0)
        XCTAssertGreaterThanOrEqual(net.download, 0.0)
    }
}
