import AppKit
import Combine
import SwiftUI
import ToastArt

@main
struct TinyToastApp {
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
final class ToastPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class ToastHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private let store = ToastStore()
    private var panel: ToastPanel!
    private var statusItem: NSStatusItem!
    private var artworkPanel: ToastPanel!
    private var breadPanel: ToastPanel!
    private var changes: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = ToastPanel(contentRect: NSRect(origin: .zero, size: ToastGeometry.controls.size),
                           styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "Tiny Toast"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        panel.delegate = self
        panel.contentView = ToastHostingView(rootView: ToastView(store: store))

        artworkPanel = ToastPanel(contentRect: NSRect(origin: .zero, size: ToastGeometry.petSize),
                                  styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        artworkPanel.title = "Tiny Toast Character"
        artworkPanel.level = .floating
        artworkPanel.isOpaque = false
        artworkPanel.backgroundColor = .clear
        artworkPanel.hasShadow = false
        artworkPanel.hidesOnDeactivate = false
        artworkPanel.isReleasedWhenClosed = false
        artworkPanel.collectionBehavior = panel.collectionBehavior
        // Separate input windows keep the transparent jump area click-through.
        artworkPanel.ignoresMouseEvents = true
        artworkPanel.contentView = NSHostingView(rootView: ToastCharacterView(store: store))
        panel.addChildWindow(artworkPanel, ordered: .below)

        breadPanel = ToastPanel(contentRect: .zero,
                                styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        breadPanel.title = "Tiny Toast Drag Handle"
        breadPanel.level = .floating
        breadPanel.isOpaque = false
        breadPanel.backgroundColor = .clear
        breadPanel.hasShadow = false
        breadPanel.hidesOnDeactivate = false
        breadPanel.isReleasedWhenClosed = false
        breadPanel.collectionBehavior = panel.collectionBehavior
        breadPanel.contentView = ToastHostingView(rootView: WindowDragRegion())
        panel.addChildWindow(breadPanel, ordered: .above)
        changes = store.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateBreadHandle()
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Tiny Toast")
        statusItem.button?.toolTip = "Tiny Toast — your daily bread"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        restorePosition()
        panel.orderFrontRegardless()
        updateBreadHandle()
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.orderFrontRegardless()
        artworkPanel.orderFrontRegardless()
        panel.orderFrontRegardless()
        updateBreadHandle()
        return true
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            breadPanel.orderOut(nil)
            artworkPanel.orderOut(nil)
            panel.orderOut(nil)
        } else {
            artworkPanel.orderFrontRegardless()
            panel.orderFrontRegardless()
            updateBreadHandle()
        }
    }

    @objc private func resetMeeting() { store.resetMeeting() }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let title = menu.addItem(withTitle: "Tiny Toast · daily bread", action: nil, keyEquivalent: "")
        title.isEnabled = false
        let tally = store.session.tally
        menu.addItem(withTitle: "RAW \(tally[.raw, default: 0])  ·  NAILED \(tally[.nailed, default: 0])  ·  BURNT \(tally[.burnt, default: 0])", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: store.caption, action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        for (title, action) in [(panel.isVisible ? "Hide Toaster" : "Show Toaster", #selector(togglePanel)),
                                ("Reset Meeting", #selector(resetMeeting)),
                                ("Timer and finish sounds", #selector(toggleSound))] {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: "")
            item.target = self
            if action == #selector(toggleSound) { item.state = store.soundEnabled ? .on : .off }
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Tiny Toast", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    @objc private func toggleSound() { store.soundEnabled.toggle() }

    private func updateBreadHandle() {
        let offset = store.characterEjection.map {
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : ToastPop.offset(at: $0)
        } ?? (store.characterLowered ? 20 : 0)
        let rect = ToastGeometry.breadDragRect(offset: offset)
        let origin = artworkFrame.origin
        breadPanel.setFrame(NSRect(x: origin.x + rect.minX,
                                  y: origin.y + ToastGeometry.petSize.height - rect.maxY,
                                  width: rect.width, height: rect.height), display: false)
        if panel.isVisible && rect.height > 0 { breadPanel.orderFrontRegardless() }
        else { breadPanel.orderOut(nil) }
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === panel else { return }
        UserDefaults.standard.set(NSStringFromPoint(artworkFrame.origin), forKey: "panelOrigin")
    }

    private var artworkFrame: NSRect {
        NSRect(x: panel.frame.minX - ToastGeometry.controlOffset.x,
               y: panel.frame.minY - ToastGeometry.controlOffset.y,
               width: ToastGeometry.petSize.width, height: ToastGeometry.petSize.height)
    }

    private func restorePosition() {
        let origin: NSPoint
        if let saved = UserDefaults.standard.string(forKey: "panelOrigin") {
            origin = NSPointFromString(saved)
        } else if let screen = NSScreen.main {
            origin = NSPoint(x: screen.visibleFrame.maxX - ToastGeometry.petSize.width - 24,
                             y: screen.visibleFrame.maxY - ToastGeometry.petSize.height - 24)
        } else {
            origin = .zero
        }
        panel.setFrameOrigin(NSPoint(x: origin.x + ToastGeometry.controlOffset.x,
                                     y: origin.y + ToastGeometry.controlOffset.y))
        artworkPanel.setFrameOrigin(origin)
        screensChanged()
        artworkPanel.orderFrontRegardless()
    }

    @objc private func screensChanged() {
        let frame = artworkFrame
        guard let target = NSScreen.screens.max(by: {
            $0.visibleFrame.intersection(frame).area < $1.visibleFrame.intersection(frame).area
        }) else { return }
        let visible = target.visibleFrame
        let x = min(max(frame.minX, visible.minX), max(visible.minX, visible.maxX - frame.width))
        let y = min(max(frame.minY, visible.minY), max(visible.minY, visible.maxY - frame.height))
        panel.setFrameOrigin(NSPoint(x: x + ToastGeometry.controlOffset.x,
                                     y: y + ToastGeometry.controlOffset.y))
        artworkPanel.setFrameOrigin(NSPoint(x: x, y: y))
        updateBreadHandle()
    }

}

private extension NSRect {
    var area: CGFloat { isNull ? 0 : width * height }
}
