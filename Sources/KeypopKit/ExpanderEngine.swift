import ApplicationServices
import Foundation

public enum ExpanderEngineError: Error, LocalizedError {
    case listenNotReady
    case injectNotReady
    case tapCreateFailed

    public var errorDescription: String? {
        switch self {
        case .listenNotReady:
            return "Input Monitoring not granted. Enable KeyPop.app in System Settings → Input Monitoring."
        case .injectNotReady:
            return "Accessibility not granted. Enable KeyPop.app in System Settings → Accessibility."
        case .tapCreateFailed:
            return "Failed to create keyboard event tap."
        }
    }
}

fileprivate final class EngineState {
    var buffer = ""
    var matcher: KeywordMatcher
    var phrases: [String: String]
    let injector = ClipboardInjector()
    var enabled = true
    var isExpanding = false
    var debugKeys = false
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

    func processKeyDown(_ event: CGEvent) -> String? {
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        if shouldReset(forKeyCode: keyCode) {
            buffer = ""
            return nil
        }

        var length = 0
        var units = [UniChar](repeating: 0, count: 8)
        event.keyboardGetUnicodeString(maxStringLength: 8, actualStringLength: &length, unicodeString: &units)
        guard length > 0 else { return nil }

        let string = String(utf16CodeUnits: units, count: length)
        guard string.count == 1, let character = string.first else { return nil }

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

    func performExpansion(keyword: String) {
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

    if state.debugKeys {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        fputs("key_seen|keycode=\(keyCode)\n", stderr)
    }

    if let keyword = state.processKeyDown(event) {
        DispatchQueue.main.async {
            state.performExpansion(keyword: keyword)
        }
    }

    return Unmanaged.passUnretained(event)
}

public final class ExpanderEngine {
    private let state: EngineState
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var healthTimer: DispatchSourceTimer?
    private var healthCheckCount: UInt = 0
    private let healthConfig: TapHealthMonitorConfig
    private let debugKeys: Bool

    public init(phrases: [String: String], healthConfig: TapHealthMonitorConfig = .default) {
        state = EngineState(phrases: phrases)
        self.healthConfig = healthConfig
        debugKeys = ProcessInfo.processInfo.environment["KEYPOP_DEBUG"] == "1"
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
        guard snapshot.readyForInject else {
            PermissionProbe.logDiagnostics(snapshot, to: stderr)
            throw ExpanderEngineError.injectNotReady
        }
        guard snapshot.readyForListen else {
            PermissionProbe.logDiagnostics(snapshot, to: stderr)
            throw ExpanderEngineError.listenNotReady
        }

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

    private func installTap() throws {
        teardownTap()
        state.debugKeys = debugKeys
        state.onTapDisabled = { [weak self] reason in
            self?.reenableTap(reason: reason)
        }

        let installed = try CGEventTapListen.install(
            userInfo: Unmanaged.passUnretained(state).toOpaque(),
            callback: expanderTapCallback
        )
        eventTap = installed.tap
        runLoopSource = installed.source
        fputs("listen_ready|tap_installed\n", stderr)
    }

    private func teardownTap() {
        CGEventTapListen.teardown(tap: eventTap, source: runLoopSource)
        eventTap = nil
        runLoopSource = nil
    }

    private func reenableTap(reason: CGEventType) {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        let label = reason == .tapDisabledByTimeout ? "timeout" : "user_input"
        fputs("tap_reenabled|\(label)\n", stderr)
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

        let tapEnabled = eventTap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false
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
        } else if issues.contains(.staleTCCSuspected) {
            fputs("tap_health_hint|re-grant TCC or run ./scripts/fix-keypop-tcc.sh after rebuild\n", stderr)
        }
    }

    private func reinstallTapFromHealthCheck() {
        do {
            try installTap()
            fputs("tap_reinstalled|scheduled_health\n", stderr)
        } catch {
            fputs("tap_reinstall_failed|\(error.localizedDescription)\n", stderr)
            fputs("tap_reinstall_hint|re-grant Input Monitoring to KeyPop.app, then: ./scripts/launch-keypop.sh restart\n", stderr)
            exit(1)
        }
    }

    private func issueLabel(_ issue: TapHealthIssue) -> String {
        switch issue {
        case .tapDisabled: return "tap_disabled"
        case .listenPermissionLost: return "listen_lost"
        case .injectPermissionLost: return "inject_lost"
        case .staleTCCSuspected: return "stale_tcc"
        }
    }
}
