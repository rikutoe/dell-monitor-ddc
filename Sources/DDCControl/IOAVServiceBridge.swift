import Foundation
import IOKit

// MARK: - IOAVService Private API (loaded via dlsym)

/// Opaque handle for IOAVService (private CoreGraphics type).
/// Retained as AnyObject to prevent premature deallocation.
typealias IOAVServiceRef = AnyObject

private typealias CreateWithServiceFn = @convention(c) (
    CFAllocator?, io_service_t
) -> Unmanaged<IOAVServiceRef>?

private typealias WriteI2CFn = @convention(c) (
    IOAVServiceRef, UInt32, UInt32, UnsafeMutableRawPointer, UInt32
) -> IOReturn

private typealias ReadI2CFn = @convention(c) (
    IOAVServiceRef, UInt32, UInt32, UnsafeMutableRawPointer, UInt32
) -> IOReturn

private let _handle = dlopen(nil, RTLD_NOW)

private func loadFunc<T>(_ name: String) -> T? {
    guard let sym = dlsym(_handle, name) else {
        NSLog("DDCControl: symbol not found: %@", name)
        return nil
    }
    return unsafeBitCast(sym, to: T.self)
}

private let _createWithService: CreateWithServiceFn? = loadFunc("IOAVServiceCreateWithService")
private let _writeI2C: WriteI2CFn? = loadFunc("IOAVServiceWriteI2C")
private let _readI2C: ReadI2CFn? = loadFunc("IOAVServiceReadI2C")

// MARK: - Internal API wrappers

func avServiceCreateWithService(_ service: io_service_t) -> IOAVServiceRef? {
    guard let fn = _createWithService else {
        NSLog("DDCControl: IOAVServiceCreateWithService not available")
        return nil
    }
    return fn(kCFAllocatorDefault, service)?.takeRetainedValue()
}

func avServiceWriteI2C(
    _ service: IOAVServiceRef,
    chipAddress: UInt32,
    dataAddress: UInt32,
    buffer: inout [UInt8]
) -> IOReturn {
    guard let fn = _writeI2C else { return IOReturn(1) }
    return buffer.withUnsafeMutableBytes { ptr in
        fn(service, chipAddress, dataAddress, ptr.baseAddress!, UInt32(ptr.count))
    }
}

func avServiceReadI2C(
    _ service: IOAVServiceRef,
    chipAddress: UInt32,
    offset: UInt32,
    buffer: inout [UInt8]
) -> IOReturn {
    guard let fn = _readI2C else { return IOReturn(1) }
    return buffer.withUnsafeMutableBytes { ptr in
        fn(service, chipAddress, offset, ptr.baseAddress!, UInt32(ptr.count))
    }
}

// MARK: - Service Discovery

/// Find DCPAVServiceProxy entries in IORegistry for external displays.
func findExternalAVServices() -> [IOAVServiceRef] {
    var services: [IOAVServiceRef] = []
    var iterator: io_iterator_t = 0

    let matchDict = IOServiceMatching("DCPAVServiceProxy")
    let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchDict, &iterator)
    guard result == KERN_SUCCESS else {
        NSLog("DDCControl: IOServiceGetMatchingServices failed: %d", result)
        return services
    }
    defer { IOObjectRelease(iterator) }

    var entry: io_service_t = IOIteratorNext(iterator)
    while entry != 0 {
        defer {
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }

        // Check if Location is "External"
        guard let locationRef = IORegistryEntryCreateCFProperty(
            entry, "Location" as CFString, kCFAllocatorDefault, 0
        ) else { continue }

        let location = locationRef.takeRetainedValue()
        guard let locationStr = location as? String, locationStr == "External" else { continue }

        NSLog("DDCControl: Found external DCPAVServiceProxy")

        guard let avService = avServiceCreateWithService(entry) else {
            NSLog("DDCControl: Failed to create IOAVService for entry")
            continue
        }

        NSLog("DDCControl: IOAVService created successfully")
        services.append(avService)
    }

    if services.isEmpty {
        NSLog("DDCControl: No external displays found")
    }

    return services
}
