import AppKit
import SwiftUI

@main
struct DailyTimerApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class TimerPanel: NSPanel {
    let interaction = PanelInteraction()
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func becomeKey() {
        super.becomeKey()
        interaction.isFocused = true
    }

    override func resignKey() {
        super.resignKey()
        interaction.isFocused = false
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        if event.type == .keyDown, modifiers == .command,
           event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(self)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            if let contentView {
                interaction.isPointerInside = contentView.bounds.contains(
                    contentView.convert(event.locationInWindow, from: nil))
            }
            interaction.isKeyboardNavigating = false
            if !isKeyWindow {
                makeKeyAndOrderFront(nil)
                return
            }
        } else if event.type == .keyDown, event.keyCode == 48 {
            interaction.isKeyboardNavigating = true
        }
        super.sendEvent(event)
    }
}

@MainActor
final class TimerHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private let store = TimerStore()
    private var panel: TimerPanel!
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = TimerPanel(contentRect: NSRect(origin: .zero, size: TimerView.size),
                           styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView], backing: .buffered, defer: false)
        panel.title = "Daily timer"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            panel.standardWindowButton(button)?.isHidden = true
        }
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenNone]
        panel.delegate = self

        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        let content = TimerHostingView(rootView: TimerView(store: store, interaction: panel.interaction,
                                                         close: { [weak panel] in panel?.performClose(nil) }))
        content.sizingOptions = []
        content.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            content.topAnchor.constraint(equalTo: background.topAnchor),
            content.bottomAnchor.constraint(equalTo: background.bottomAnchor)
        ])
        panel.contentView = background
        panel.setFrame(NSRect(origin: .zero, size: TimerView.size), display: false)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Daily timer")
        statusItem.button?.toolTip = "Daily timer"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        restorePosition()
        panel.orderFrontRegardless()
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.makeKeyAndOrderFront(nil)
        return true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        panel.orderOut(nil)
        return false
    }

    @objc private func togglePanel() {
        if panel.isVisible { panel.orderOut(nil) }
        else { panel.makeKeyAndOrderFront(nil) }
    }

    @objc private func resetMeeting() { store.resetMeeting() }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(withTitle: "Daily timer", action: nil, keyEquivalent: "")
        if store.session.phase == .summary {
            menu.addItem(withTitle: store.summary, action: nil, keyEquivalent: "")
        }
        menu.addItem(.separator())
        for (title, action) in [(panel.isVisible ? "Hide Timer" : "Show Timer", #selector(togglePanel)),
                                ("Reset Meeting", #selector(resetMeeting)),
                                ("Sound", #selector(toggleSound))] {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: "")
            item.target = self
            if action == #selector(toggleSound) { item.state = store.soundEnabled ? .on : .off }
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Daily timer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    @objc private func toggleSound() { store.soundEnabled.toggle() }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === panel else { return }
        UserDefaults.standard.set(NSStringFromPoint(panel.frame.origin), forKey: "timerPanelOrigin")
    }

    private func restorePosition() {
        if let saved = UserDefaults.standard.string(forKey: "timerPanelOrigin") {
            panel.setFrameOrigin(NSPointFromString(saved))
        } else if let screen = NSScreen.main {
            panel.setFrameTopLeftPoint(NSPoint(x: screen.visibleFrame.maxX - panel.frame.width - 24,
                                               y: screen.visibleFrame.maxY - 24))
        }
        screensChanged()
    }

    @objc private func screensChanged() {
        let frame = panel.frame
        guard let target = NSScreen.screens.max(by: {
            $0.visibleFrame.intersection(frame).area < $1.visibleFrame.intersection(frame).area
        }) else { return }
        let visible = target.visibleFrame
        panel.setFrameOrigin(NSPoint(
            x: min(max(frame.minX, visible.minX), max(visible.minX, visible.maxX - frame.width)),
            y: min(max(frame.minY, visible.minY), max(visible.minY, visible.maxY - frame.height))))
    }
}

private extension NSRect {
    var area: CGFloat { isNull ? 0 : width * height }
}
