import Foundation
import IOKit.hid
import Carbon.HIToolbox
import ApplicationServices

struct ButtonAction: Codable {
    let key: String?
    let keyCode: UInt16?
    let modifiers: [String]?
}

struct Config: Codable {
    let buttons: [String: ButtonAction]
}

enum ActionKind {
    case key(keyCode: CGKeyCode, flags: CGEventFlags)
    case missionControl
}

struct ResolvedAction {
    let usage: UInt32
    let kind: ActionKind
}

final class ButtonMapper {
    private let actions: [UInt32: ResolvedAction]
    private let eventSource = CGEventSource(stateID: .hidSystemState)

    init(actions: [UInt32: ResolvedAction]) {
        self.actions = actions
    }

    func handle(usagePage: UInt32, usage: UInt32, isPressed: Bool) {
        guard usagePage == kHIDPage_Button else { return }
        guard isPressed, let action = actions[usage] else { return }
        perform(action)
    }

    private func perform(_ action: ResolvedAction) {
        switch action.kind {
        case let .key(keyCode, flags):
            sendKeyStroke(keyCode: keyCode, flags: flags)
        case .missionControl:
            launchMissionControl()
        }
    }

    private func sendKeyStroke(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let source = eventSource else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
}

func launchMissionControl() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = ["/System/Applications/Mission Control.app"]
    try? process.run()
}

func waitForAccessibilityPermission() {
    let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [promptKey: true] as CFDictionary
    if AXIsProcessTrustedWithOptions(options) {
        return
    }

    fputs("mxmasterd needs Accessibility permission. Approve the prompt or add it in System Settings → Privacy & Security → Accessibility.\n", stderr)
    while !AXIsProcessTrusted() {
        Thread.sleep(forTimeInterval: 1)
    }
    fputs("Accessibility permission granted. Continuing…\n", stderr)
}

func modifierFlags(from names: [String]?) -> CGEventFlags {
    guard let names else { return [] }
    return names.reduce(into: CGEventFlags()) { flags, name in
        switch name.lowercased() {
        case "command", "cmd", "⌘": flags.insert(.maskCommand)
        case "shift", "⇧": flags.insert(.maskShift)
        case "option", "alt", "⌥": flags.insert(.maskAlternate)
        case "control", "ctrl", "⌃": flags.insert(.maskControl)
        case "fn": flags.insert(.maskSecondaryFn)
        default: break
        }
    }
}

let keyLookup: [String: CGKeyCode] = [
    "a": CGKeyCode(kVK_ANSI_A),
    "b": CGKeyCode(kVK_ANSI_B),
    "c": CGKeyCode(kVK_ANSI_C),
    "d": CGKeyCode(kVK_ANSI_D),
    "e": CGKeyCode(kVK_ANSI_E),
    "f": CGKeyCode(kVK_ANSI_F),
    "g": CGKeyCode(kVK_ANSI_G),
    "h": CGKeyCode(kVK_ANSI_H),
    "i": CGKeyCode(kVK_ANSI_I),
    "j": CGKeyCode(kVK_ANSI_J),
    "k": CGKeyCode(kVK_ANSI_K),
    "l": CGKeyCode(kVK_ANSI_L),
    "m": CGKeyCode(kVK_ANSI_M),
    "n": CGKeyCode(kVK_ANSI_N),
    "o": CGKeyCode(kVK_ANSI_O),
    "p": CGKeyCode(kVK_ANSI_P),
    "q": CGKeyCode(kVK_ANSI_Q),
    "r": CGKeyCode(kVK_ANSI_R),
    "s": CGKeyCode(kVK_ANSI_S),
    "t": CGKeyCode(kVK_ANSI_T),
    "u": CGKeyCode(kVK_ANSI_U),
    "v": CGKeyCode(kVK_ANSI_V),
    "w": CGKeyCode(kVK_ANSI_W),
    "x": CGKeyCode(kVK_ANSI_X),
    "y": CGKeyCode(kVK_ANSI_Y),
    "z": CGKeyCode(kVK_ANSI_Z),
    "1": CGKeyCode(kVK_ANSI_1),
    "2": CGKeyCode(kVK_ANSI_2),
    "3": CGKeyCode(kVK_ANSI_3),
    "4": CGKeyCode(kVK_ANSI_4),
    "5": CGKeyCode(kVK_ANSI_5),
    "6": CGKeyCode(kVK_ANSI_6),
    "7": CGKeyCode(kVK_ANSI_7),
    "8": CGKeyCode(kVK_ANSI_8),
    "9": CGKeyCode(kVK_ANSI_9),
    "0": CGKeyCode(kVK_ANSI_0),
    "space": CGKeyCode(kVK_Space),
    "spacebar": CGKeyCode(kVK_Space),
    "enter": CGKeyCode(kVK_Return),
    "return": CGKeyCode(kVK_Return),
    "escape": CGKeyCode(kVK_Escape),
    "esc": CGKeyCode(kVK_Escape),
    "tab": CGKeyCode(kVK_Tab),
    "delete": CGKeyCode(kVK_Delete),
    "forwarddelete": CGKeyCode(kVK_ForwardDelete),
    "left": CGKeyCode(kVK_LeftArrow),
    "right": CGKeyCode(kVK_RightArrow),
    "up": CGKeyCode(kVK_UpArrow),
    "uparrow": CGKeyCode(kVK_UpArrow),
    "down": CGKeyCode(kVK_DownArrow),
    "downarrow": CGKeyCode(kVK_DownArrow),
    "pageup": CGKeyCode(kVK_PageUp),
    "pagedown": CGKeyCode(kVK_PageDown),
    "home": CGKeyCode(kVK_Home),
    "end": CGKeyCode(kVK_End),
    "f1": CGKeyCode(kVK_F1),
    "f2": CGKeyCode(kVK_F2),
    "f3": CGKeyCode(kVK_F3),
    "f4": CGKeyCode(kVK_F4),
    "f5": CGKeyCode(kVK_F5),
    "f6": CGKeyCode(kVK_F6),
    "f7": CGKeyCode(kVK_F7),
    "f8": CGKeyCode(kVK_F8),
    "f9": CGKeyCode(kVK_F9),
    "f10": CGKeyCode(kVK_F10),
    "f11": CGKeyCode(kVK_F11),
    "f12": CGKeyCode(kVK_F12),
    "leftbracket": CGKeyCode(kVK_ANSI_LeftBracket),
    "rightbracket": CGKeyCode(kVK_ANSI_RightBracket),
    "semicolon": CGKeyCode(kVK_ANSI_Semicolon),
    "quote": CGKeyCode(kVK_ANSI_Quote),
    "comma": CGKeyCode(kVK_ANSI_Comma),
    "period": CGKeyCode(kVK_ANSI_Period),
    "slash": CGKeyCode(kVK_ANSI_Slash),
    "backslash": CGKeyCode(kVK_ANSI_Backslash),
    "minus": CGKeyCode(kVK_ANSI_Minus),
    "equal": CGKeyCode(kVK_ANSI_Equal),
    "grave": CGKeyCode(kVK_ANSI_Grave)
]

func resolveAction(usage: UInt32, action: ButtonAction) -> ResolvedAction? {
    if let raw = action.keyCode {
        return ResolvedAction(usage: usage, kind: .key(keyCode: CGKeyCode(raw), flags: modifierFlags(from: action.modifiers)))
    }
    guard let keyName = action.key else { return nil }
    let lookupKey = keyName.lowercased()
    if ["missioncontrol", "mission_control", "mission-control"].contains(lookupKey) {
        return ResolvedAction(usage: usage, kind: .missionControl)
    }
    guard let code = keyLookup[lookupKey] else {
        fputs("Unknown key name: \(keyName)\n", stderr)
        return nil
    }
    return ResolvedAction(usage: usage, kind: .key(keyCode: code, flags: modifierFlags(from: action.modifiers)))
}

func loadConfig(at url: URL) throws -> Config {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(Config.self, from: data)
}

func writeDefaultConfig(to url: URL) throws {
    let defaults = Config(buttons: [
        "0x0004": ButtonAction(key: "leftBracket", keyCode: nil, modifiers: ["command"]),
        "0x0005": ButtonAction(key: "rightBracket", keyCode: nil, modifiers: ["command"]),
        "0x0006": ButtonAction(key: "downArrow", keyCode: nil, modifiers: ["control"]),
        "0x0007": ButtonAction(key: "missioncontrol", keyCode: nil, modifiers: nil)
    ])
    let data = try JSONEncoder().encode(defaults)
    try data.write(to: url, options: .atomic)
}

func ensureConfigFile() -> URL {
    let fm = FileManager.default
    let configDir = fm.homeDirectoryForCurrentUser.appendingPathComponent(".config/mxmaster", isDirectory: true)
    let configURL = configDir.appendingPathComponent("mappings.json")

    if !fm.fileExists(atPath: configDir.path) {
        try? fm.createDirectory(at: configDir, withIntermediateDirectories: true)
    }
    if !fm.fileExists(atPath: configURL.path) {
        try? writeDefaultConfig(to: configURL)
    }
    return configURL
}

let configURL = ensureConfigFile()
let config: Config

do {
    config = try loadConfig(at: configURL)
} catch {
    fputs("Failed to load config: \(error)\n", stderr)
    exit(1)
}

var resolved: [UInt32: ResolvedAction] = [:]
for (key, action) in config.buttons {
    let usage: UInt32
    if key.lowercased().hasPrefix("0x"), let value = UInt32(key.dropFirst(2), radix: 16) {
        usage = value
    } else if let parsed = UInt32(key) {
        usage = parsed
    } else {
        fputs("Invalid usage key: \(key)\n", stderr)
        continue
    }
    if let resolvedAction = resolveAction(usage: usage, action: action) {
        resolved[usage] = resolvedAction
    }
}

if resolved.isEmpty {
    fputs("No valid button mappings loaded.\n", stderr)
    exit(1)
}

let mapper = ButtonMapper(actions: resolved)
waitForAccessibilityPermission()

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matching = [
    kIOHIDVendorIDKey: 0x046d,
    kIOHIDProductIDKey: 0xb042
] as NSDictionary
IOHIDManagerSetDeviceMatching(manager, matching)

let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(mapper).toOpaque())

let callback: IOHIDValueCallback = { context, _, _, value in
    guard let context else { return }
    let mapper = Unmanaged<ButtonMapper>.fromOpaque(context).takeUnretainedValue()
    let element = IOHIDValueGetElement(value)
    let usagePage = IOHIDElementGetUsagePage(element)
    let usage = IOHIDElementGetUsage(element)
    let pressed = IOHIDValueGetIntegerValue(value) != 0
    mapper.handle(usagePage: usagePage, usage: usage, isPressed: pressed)
}

IOHIDManagerRegisterInputValueCallback(manager, callback, context)
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
if openResult != kIOReturnSuccess {
    fputs("Failed to open IOHIDManager: 0x\(String(openResult, radix: 16))\n", stderr)
    exit(1)
}

print("mxmasterd running. Config: \(configURL.path)")
print("Mappings: \(resolved.keys.map { String(format: "0x%04x", $0) }.joined(separator: ", "))")

CFRunLoopRun()
