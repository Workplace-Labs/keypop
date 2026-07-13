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
    let usageStore: UsageStore?
    let injector = ClipboardInjector()
    var enabled = true
    var isExpanding = false
    var observedKeyDowns = 0
    var onTapDisabled: ((CGEventType) -> Void)?

    init(phrases: [String: String], usageStore: UsageStore?) {
        self.phrases = phrases
        self.usageStore = usageStore
        self.matcher = KeywordMatcher(keywords: Array(phrases.keys))
    }

    func reload(phrases: [String: String]) {
        self.phrases = phrases
        self.matcher = KeywordMatcher(keywords: Array(phrases.keys))
        self.buffer = ""
    }

    func processKeyDown(_ event: CGEvent) -> String? {
        observedKeyDowns += 1
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

        let session = DiagnosticSession()
        let targetBundle = session.isEnabled ? KeypopDiagnostics.frontmostBundleID() : ""
        KeypopDiagnostics.debugEvent(session, "match", fields: [
            "keyword_length": String(keyword.count),
            "phrase_length": String(phrase.count),
            "target_bundle": targetBundle,
        ])

        do {
            KeypopDiagnostics.debugEvent(session, "inject", fields: ["stage": "delete_started"])
            try injector.deleteCharacters(count: keyword.count) { stage in
                KeypopDiagnostics.debugEvent(session, "inject", fields: ["stage": stage])
            }
            try injector.inject(phrase) { stage in
                KeypopDiagnostics.debugEvent(session, "inject", fields: ["stage": stage])
            }
            do {
                try usageStore?.recordUse(keyword: keyword)
            } catch {
                fputs("usage_error|record_failed\n", stderr)
                KeypopDiagnostics.event("usage_record_failed")
            }
            buffer = ""
            fputs("expanded|keyword_length=\(keyword.count)|phrase_length=\(phrase.count)|outcome=paste_posted\n", stderr)
            KeypopDiagnostics.debugEvent(session, "expansion", fields: ["outcome": "paste_posted"])
        } catch {
            let kind = errorKind(error)
            fputs("expand_error|error=\(kind)\n", stderr)
            KeypopDiagnostics.debugEvent(session, "inject", fields: ["outcome": "failed", "error": kind])
        }
    }

    private func errorKind(_ error: Error) -> String {
        switch error {
        case ClipboardInjectorError.postEventDenied: return "post_event_denied"
        case ClipboardInjectorError.pasteFailed: return "paste_failed"
        default: return "unknown"
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
        // Keep the callback minimal. Recovery and all logging happen on main.
        DispatchQueue.main.async { state.onTapDisabled?(type) }
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

public final class ExpanderEngine {
    private let state: EngineState
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var healthTimer: DispatchSourceTimer?
    private var diagnosticTimer: DispatchSourceTimer?
    private var healthCheckCount: UInt = 0
    private let healthConfig: TapHealthMonitorConfig
    private let diagnosticSession: DiagnosticSession
    private let startedAt = Date()

    public init(
        phrases: [String: String],
        usageStore: UsageStore? = nil,
        healthConfig: TapHealthMonitorConfig = .default
    ) {
        state = EngineState(phrases: phrases, usageStore: usageStore)
        self.healthConfig = healthConfig
        diagnosticSession = DiagnosticSession()
    }

    public func reload(phrases: [String: String]) {
        state.reload(phrases: phrases)
        fputs("reloaded|\(phrases.count) snippets\n", stderr)
        KeypopDiagnostics.event("watcher_reload", fields: ["snippet_count": String(phrases.count)])
    }

    public func setEnabled(_ enabled: Bool) {
        state.enabled = enabled
    }

    public func start() throws {
        let snapshot = PermissionProbe.snapshot()
        KeypopDiagnostics.event("permission_snapshot", fields: [
            "inject_ready": snapshot.readyForInject ? "true" : "false",
            "listen_ready": snapshot.readyForListen ? "true" : "false",
            "tap_enabled": snapshot.liveTapEnabled ? "true" : "false",
        ])
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
        startDiagnosticTimer()
        fputs("keypop running|\(state.phrases.count) snippets\n", stderr)
        KeypopDiagnostics.event("runtime_started", fields: [
            "diagnostics": diagnosticSession.isEnabled ? "enabled" : "disabled",
            "pid": String(ProcessInfo.processInfo.processIdentifier),
            "snippet_count": String(state.phrases.count),
            "session_until": diagnosticSession.expiresAt.map { String(Int($0.timeIntervalSince1970)) } ?? "off",
        ])
    }

    public func stop() {
        stopHealthMonitor()
        stopDiagnosticTimer()
        teardownTap()
        KeypopDiagnostics.event("runtime_stopped", fields: ["uptime_seconds": String(Int(Date().timeIntervalSince(startedAt)))])
    }

    public func run() {
        CFRunLoopRun()
    }

    private func installTap() throws {
        teardownTap()
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
        KeypopDiagnostics.event("tap_installed")
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
        KeypopDiagnostics.event("tap_reenabled", fields: ["reason": label])
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

    private func startDiagnosticTimer() {
        guard diagnosticSession.isEnabled else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 5, repeating: 5)
        timer.setEventHandler { [weak self] in self?.emitDiagnosticHeartbeat() }
        timer.resume()
        diagnosticTimer = timer
    }

    private func stopDiagnosticTimer() {
        diagnosticTimer?.cancel()
        diagnosticTimer = nil
    }

    private func emitDiagnosticHeartbeat() {
        guard diagnosticSession.isEnabled else {
            stopDiagnosticTimer()
            return
        }
        let count = state.observedKeyDowns
        state.observedKeyDowns = 0
        KeypopDiagnostics.debugEvent(diagnosticSession, "input_heartbeat", fields: [
            "frontmost_bundle": KeypopDiagnostics.frontmostBundleID(),
            "key_down_count": String(count),
        ])
    }

    private func performScheduledHealthCheck() {
        healthCheckCount += 1

        let tapEnabled = eventTap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false
        let permissionInterval = max(1, healthConfig.permissionProbeIntervalSeconds)
        let checksPerPermissionProbe = UInt(ceil(permissionInterval / healthConfig.checkIntervalSeconds))
        let includePermissionProbe = healthCheckCount % checksPerPermissionProbe == 0

        if !includePermissionProbe {
            KeypopDiagnostics.event("health_heartbeat", fields: ["tap_enabled": tapEnabled ? "true" : "false"])
            guard !tapEnabled else { return }
            fputs("tap_health|tap_disabled\n", stderr)
            KeypopDiagnostics.event("tap_health", fields: ["state": "disabled"])
            reinstallTapFromHealthCheck()
            return
        }

        let snapshot = PermissionProbe.snapshot()
        KeypopDiagnostics.event("health_heartbeat", fields: [
            "inject_ready": snapshot.readyForInject ? "true" : "false",
            "listen_ready": snapshot.readyForListen ? "true" : "false",
            "tap_enabled": tapEnabled ? "true" : "false",
        ])
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: tapEnabled,
            snapshot: snapshot,
            includePermissionProbe: true
        )

        guard !issues.isEmpty else { return }

        fputs("tap_health|\(issues.map(issueLabel).joined(separator: ","))\n", stderr)
        KeypopDiagnostics.event("tap_health", fields: ["issues": issues.map(issueLabel).joined(separator: ",")])

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
            KeypopDiagnostics.event("tap_reinstalled", fields: ["reason": "scheduled_health"])
        } catch {
            fputs("tap_reinstall_failed|\(error.localizedDescription)\n", stderr)
            KeypopDiagnostics.event("tap_reinstall_failed", fields: ["error": "install_failed"])
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
