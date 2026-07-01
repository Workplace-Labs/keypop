import ApplicationServices
import Foundation

public enum ExpanderEngineError: Error, LocalizedError {
    case listenNotReady
    case injectNotReady
    case tapCreateFailed

    public var errorDescription: String? {
        switch self {
        case .listenNotReady:
            return "Input Monitoring not granted. Enable keypop in System Settings → Input Monitoring."
        case .injectNotReady:
            return "Post-event access not granted. Enable keypop in System Settings → Accessibility."
        case .tapCreateFailed:
            return "Failed to create keyboard event tap."
        }
    }
}

private let keyboardEventMask: CGEventMask = {
    let keyDown = 1 << CGEventType.keyDown.rawValue
    let timeout = 1 << CGEventType.tapDisabledByTimeout.rawValue
    let userInput = 1 << CGEventType.tapDisabledByUserInput.rawValue
    return CGEventMask(keyDown | timeout | userInput)
}()

private final class EngineState {
    var buffer = ""
    var matcher: KeywordMatcher
    var phrases: [String: String]
    let injector = ClipboardInjector()
    var enabled = true
    var isExpanding = false
    var onTapDisabled: ((CGEventType) -> Void)?

    init(phrases: [String: String]) {
        self.phrases = phrases
        self.matcher = KeywordMatcher(keywords: Array(phrases.keys))
    }

    func reload(phrases: [String: String]) {
        self.phrases = phrases
        self.matcher = KeywordMatcher(keywords: Array(phrases.keys))
        self.buffer = ""
    }
}

private func expanderTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let state = Unmanaged<EngineState>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        state.onTapDisabled?(type)
        return nil
    }

    guard state.enabled, !state.isExpanding, type == .keyDown else {
        return Unmanaged.passUnretained(event)
    }

    if let keyword = state.processKeyDown(event) {
        DispatchQueue.main.async {
            state.performExpansion(keyword: keyword)
        }
    }

    return Unmanaged.passUnretained(event)
}

extension EngineState {
    fileprivate func processKeyDown(_ event: CGEvent) -> String? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        if shouldReset(forKeyCode: Int(keyCode)) {
            buffer = ""
            return nil
        }

        guard let character = character(from: event) else {
            return nil
        }

        if matcher.shouldResetBuffer(for: character) {
            buffer = ""
            return nil
        }

        buffer.append(character)
        if buffer.count > matcher.bufferCapacity {
            buffer = String(buffer.suffix(matcher.bufferCapacity))
        }

        return matcher.match(in: buffer)
    }

    fileprivate func performExpansion(keyword: String) {
        guard !isExpanding, let phrase = phrases[keyword] else {
            return
        }

        isExpanding = true
        defer { isExpanding = false }

        do {
            try injector.deleteCharacters(count: keyword.count)
            try injector.inject(phrase)
            buffer = ""
            fputs("expanded|\(keyword)|\(phrase.count) chars\n", stderr)
        } catch {
            fputs("expand_error|\(keyword)|\(error.localizedDescription)\n", stderr)
        }
    }

    private func shouldReset(forKeyCode keyCode: Int) -> Bool {
        switch keyCode {
        case 0x7B, 0x7C, 0x7D, 0x7E,
             0x75, 0x73, 0x77, 0x74, 0x79, 0x71,
             0x35, 0x33,
             0x30, 0x24:
            return true
        default:
            return false
        }
    }

    private func character(from event: CGEvent) -> Character? {
        var length = 0
        var units = [UniChar](repeating: 0, count: 8)
        event.keyboardGetUnicodeString(maxStringLength: 8, actualStringLength: &length, unicodeString: &units)
        guard length > 0 else { return nil }
        let string = String(utf16CodeUnits: units, count: length)
        guard string.count == 1, let character = string.first else { return nil }
        return character
    }
}

public final class ExpanderEngine {
    private let state: EngineState
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var healthTimer: DispatchSourceTimer?
    private var healthCheckCount: UInt = 0
    private let healthConfig: TapHealthMonitorConfig

    public init(phrases: [String: String], healthConfig: TapHealthMonitorConfig = .default) {
        state = EngineState(phrases: phrases)
        self.healthConfig = healthConfig
        state.onTapDisabled = { [weak self] reason in
            self?.reenableTap(reason: reason)
        }
    }

    public func reload(phrases: [String: String]) {
        state.reload(phrases: phrases)
        fputs("reloaded|\(phrases.count) snippets\n", stderr)
    }

    public func setEnabled(_ enabled: Bool) {
        state.enabled = enabled
    }

    public func start() throws {
        let snapshot = PermissionProbe.snapshot()
        guard snapshot.readyForListen else { throw ExpanderEngineError.listenNotReady }
        guard snapshot.readyForInject else { throw ExpanderEngineError.injectNotReady }

        try installTap()
        startHealthMonitor()
        fputs("keypop running|\(state.phrases.count) snippets\n", stderr)
    }

    public func stop() {
        stopHealthMonitor()
        teardownTap()
    }

    public func run() {
        CFRunLoopRun()
    }

    private func reenableTap(reason: CGEventType) {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
        let label = reason == .tapDisabledByTimeout ? "timeout" : "user_input"
        fputs("tap_reenabled|\(label)\n", stderr)
    }

    private func installTap() throws {
        teardownTap()

        let userInfo = Unmanaged.passUnretained(state).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: keyboardEventMask,
            callback: expanderTapCallback,
            userInfo: userInfo
        ) else {
            throw ExpanderEngineError.tapCreateFailed
        }

        self.tap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func teardownTap() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
    }

    private func startHealthMonitor() {
        stopHealthMonitor()
        healthCheckCount = 0

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(
            deadline: .now() + healthConfig.checkIntervalSeconds,
            repeating: healthConfig.checkIntervalSeconds
        )
        timer.setEventHandler { [weak self] in
            self?.performScheduledHealthCheck()
        }
        timer.resume()
        healthTimer = timer
    }

    private func stopHealthMonitor() {
        healthTimer?.cancel()
        healthTimer = nil
    }

    private func performScheduledHealthCheck() {
        healthCheckCount += 1

        let tapEnabled = tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false
        let permissionInterval = max(1, healthConfig.permissionProbeIntervalSeconds)
        let checksPerPermissionProbe = UInt(ceil(permissionInterval / healthConfig.checkIntervalSeconds))
        let includePermissionProbe = healthCheckCount % checksPerPermissionProbe == 0

        if !includePermissionProbe {
            guard !tapEnabled else { return }
            fputs("tap_health|tap_disabled\n", stderr)
            reinstallTapFromHealthCheck()
            return
        }

        let snapshot = PermissionProbe.snapshot()
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: tapEnabled,
            snapshot: snapshot,
            includePermissionProbe: true
        )

        guard !issues.isEmpty else { return }

        fputs("tap_health|\(issues.map(issueLabel).joined(separator: ","))\n", stderr)

        if issues.contains(.tapDisabled) || issues.contains(.listenPermissionLost) {
            reinstallTapFromHealthCheck()
        } else if issues.contains(.staleAxCacheSuspected) {
            fputs("tap_health_hint|restart keypop after macOS update or re-sign\n", stderr)
        }
    }

    private func reinstallTapFromHealthCheck() {
        do {
            try installTap()
            fputs("tap_reinstalled|scheduled_health\n", stderr)
        } catch {
            fputs("tap_reinstall_failed|\(error.localizedDescription)\n", stderr)
        }
    }

    private func issueLabel(_ issue: TapHealthIssue) -> String {
        switch issue {
        case .tapDisabled: return "tap_disabled"
        case .listenPermissionLost: return "listen_lost"
        case .injectPermissionLost: return "inject_lost"
        case .staleAxCacheSuspected: return "stale_ax_cache"
        }
    }
}
