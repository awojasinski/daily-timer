import AppKit
import SwiftUI
import Testing
@testable import DailyTimer

@Test(.enabled(if: ProcessInfo.processInfo.environment["DAILY_TIMER_RENDER_DIR"] != nil))
@MainActor func renderReadmePreviews() throws {
    let output = URL(fileURLWithPath: ProcessInfo.processInfo.environment["DAILY_TIMER_RENDER_DIR"]!)
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    for (name, elapsed, summary, controls) in [
        ("setup", -1.0, false, true),
        ("running", 24.0, false, false),
        ("overtime", 68.0, false, true),
        ("summary", 68.0, true, true)
    ] {
        let domain = "io.dailytimer.previews.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        var now = 0.0
        let store = TimerStore(defaults: defaults, clock: { now }, playSound: { _ in })
        if elapsed >= 0 {
            store.primaryAction()
            now = elapsed
            store.refresh()
            if summary { store.finish(endingMeeting: true) }
        }
        let interaction = PanelInteraction()
        interaction.isFocused = controls
        interaction.isPointerInside = controls
        let preview = TimerView(store: store, interaction: interaction, close: {})
            .background(Color(red: 0.19, green: 0.21, blue: 0.25))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.15)))
            .padding(20)
            .background(Color(red: 0.10, green: 0.12, blue: 0.16))
            .transaction { $0.disablesAnimations = true }
            .environment(\.colorScheme, .dark)
        let host = NSHostingView(rootView: preview)
        let frame = NSRect(x: -10000, y: -10000, width: 300, height: 190)
        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        host.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let png = try #require(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: output.appendingPathComponent("\(name).png"))
    }
}
