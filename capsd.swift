import Cocoa
import CoreGraphics
import IOKit
import IOKit.hid

let f18: Int64 = 79            // kVK_F18 (Caps Lock after the hidutil remap)
let holdThreshold = 0.35       // seconds: shorter than this = tap

var held = false
var usedAsModifier = false
var downTime = Date()
var tap: CFMachPort?

// --- Real Caps Lock toggle via IOKit ---
var hidConn: io_connect_t = 0

func openHID() {
    let svc = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
    guard svc != 0 else { print("Could not find IOHIDSystem"); return }
    IOServiceOpen(svc, mach_task_self_, UInt32(kIOHIDParamConnectType), &hidConn)
    IOObjectRelease(svc)
}

func toggleCapsLock() {
    let capsLockState: Int32 = 1   // kIOHIDCapsLockState
    var on = false
    IOHIDGetModifierLockState(hidConn, capsLockState, &on)
    IOHIDSetModifierLockState(hidConn, capsLockState, !on)
}

let callback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let t = tap { CGEvent.tapEnable(tap: t, enable: true) }
        return Unmanaged.passUnretained(event)
    }

    let code = event.getIntegerValueField(.keyboardEventKeycode)

    if code == f18 {
        if type == .keyDown && !held {           // ignores key-repeat events
            held = true
            usedAsModifier = false
            downTime = Date()
        } else if type == .keyUp {
            held = false
            if !usedAsModifier && Date().timeIntervalSince(downTime) < holdThreshold {
                toggleCapsLock()                 // quick tap alone = Caps Lock
            }
        }
        return nil                               // swallow F18 itself
    }

    if held {
        usedAsModifier = true
        let hyper: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
        event.flags = event.flags.union(hyper)   // hold + key = Hyper + key
    }
    return Unmanaged.passUnretained(event)
}

openHID()

let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
guard let t = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap,
                                options: .defaultTap, eventsOfInterest: CGEventMask(mask),
                                callback: callback, userInfo: nil) else {
    print("Failed: grant Accessibility / Input Monitoring to this program")
    exit(1)
}
tap = t
let source = CFMachPortCreateRunLoopSource(nil, t, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: t, enable: true)
CFRunLoopRun()
