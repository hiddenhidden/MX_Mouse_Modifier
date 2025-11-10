import Foundation
import IOKit.hid

let vendorID: Int = 0x046d
let productID: Int = 0xb042

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matching = [
    kIOHIDVendorIDKey: vendorID,
    kIOHIDProductIDKey: productID
] as NSDictionary
IOHIDManagerSetDeviceMatching(manager, matching)

let callback: IOHIDValueCallback = { _, _, _, value in
    let element = IOHIDValueGetElement(value)
    let usagePage = IOHIDElementGetUsagePage(element)
    let usage = IOHIDElementGetUsage(element)
    let pressed = IOHIDValueGetIntegerValue(value)
    if pressed != 0 {
        print(String(format: "usagePage=0x%04x usage=0x%04x", usagePage, usage))
        fflush(stdout)
    }
}

IOHIDManagerRegisterInputValueCallback(manager, callback, nil)
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
guard openResult == kIOReturnSuccess else {
    fputs("Failed to open IOHIDManager: 0x\(String(openResult, radix: 16))\n", stderr)
    exit(1)
}

print("Listening for MX Master 4 button usages... Press Ctrl+C to stop.")
CFRunLoopRun()
