import ApplicationServices
import Foundation

public struct PermissionSnapshot: Codable, Equatable, Sendable {
    public let axIsProcessTrusted: Bool
    public let listenEventPreflight: Bool
    public let postEventPreflight: Bool
    public let liveTapCreates: Bool
    public let liveTapEnabled: Bool
    public let staleAxCacheSuspected: Bool
    public let readyForListen: Bool
    public let readyForInject: Bool
}

private func listenOnlyTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    Unmanaged.passUnretained(event)
}

public enum PermissionProbe {
    public static func snapshot() -> PermissionSnapshot {
        let axTrusted = AXIsProcessTrusted()
        let listenOK = CGPreflightListenEventAccess()
        let postOK = CGPreflightPostEventAccess()
        let tapState = liveTapProbe()

        return PermissionSnapshot(
            axIsProcessTrusted: axTrusted,
            listenEventPreflight: listenOK,
            postEventPreflight: postOK,
            liveTapCreates: tapState.created,
            liveTapEnabled: tapState.enabled,
            staleAxCacheSuspected: axTrusted && (!tapState.created || !tapState.enabled),
            readyForListen: listenOK && tapState.created && tapState.enabled,
            readyForInject: postOK
        )
    }

    private static func liveTapProbe() -> (created: Bool, enabled: Bool) {
        let mask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: listenOnlyTapCallback,
            userInfo: nil
        ) else {
            return (false, false)
        }

        let enabled = CGEvent.tapIsEnabled(tap: tap)
        CFMachPortInvalidate(tap)
        return (true, enabled)
    }
}
