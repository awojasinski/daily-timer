import AppKit
import Testing
@testable import DailyTimer

@MainActor
private final class QuitObserver: NSObject, NSApplicationDelegate {
    var quitRequests = 0

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        quitRequests += 1
        return .terminateCancel
    }
}

@Test @MainActor func panelCommandQRequestsApplicationTermination() {
    let app = NSApplication.shared
    let previousDelegate = app.delegate
    let observer = QuitObserver()
    app.delegate = observer
    defer { app.delegate = previousDelegate }
    let panel = TimerPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                           backing: .buffered, defer: false)
    defer { panel.orderOut(nil) }

    let cases: [(NSEvent.ModifierFlags, String, Bool)] = [
        (.command, "q", true),
        ([.command, .capsLock], "Q", true),
        ([], "q", false),
        (.control, "q", false),
        ([.command, .shift], "q", false),
        ([.command, .option], "q", false),
        (.command, "w", false)
    ]
    for (modifiers, characters, shouldQuit) in cases {
        observer.quitRequests = 0
        let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers,
                                    timestamp: 0, windowNumber: panel.windowNumber, context: nil,
                                    characters: characters, charactersIgnoringModifiers: characters,
                                    isARepeat: false, keyCode: characters == "w" ? 13 : 12)!
        #expect(panel.performKeyEquivalent(with: event) == shouldQuit)
        #expect(observer.quitRequests == (shouldQuit ? 1 : 0))
    }
}

@Test @MainActor func pointerControlsRequireBothFocusAndHover() {
    let interaction = PanelInteraction()
    #expect(!interaction.showsControls)
    interaction.isPointerInside = true
    #expect(!interaction.showsControls)
    interaction.isFocused = true
    #expect(interaction.showsControls)
    interaction.isPointerInside = false
    #expect(!interaction.showsControls)
    interaction.isPointerInside = true
    interaction.isFocused = false
    #expect(!interaction.showsControls)
}

@Test @MainActor func keyboardNavigationRevealsControlsWithoutHoverUntilFocusIsLost() {
    let interaction = PanelInteraction()
    interaction.isFocused = true
    interaction.isKeyboardNavigating = true
    #expect(interaction.showsControls)
    interaction.isFocused = false
    #expect(!interaction.showsControls)
    #expect(!interaction.isKeyboardNavigating)
    interaction.isFocused = true
    #expect(!interaction.showsControls)
}

@Test @MainActor func clickingInsidePanelRefreshesPointerStateBeforeLeavingKeyboardMode() {
    _ = NSApplication.shared
    let panel = TimerPanel(contentRect: NSRect(x: -10000, y: -10000, width: 260, height: 150),
                           styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    defer { panel.orderOut(nil) }
    panel.interaction.isKeyboardNavigating = true
    let click = NSEvent.mouseEvent(with: .leftMouseDown, location: NSPoint(x: 130, y: 30),
                                   modifierFlags: [], timestamp: 0, windowNumber: panel.windowNumber,
                                   context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
    panel.sendEvent(click)
    #expect(panel.interaction.isPointerInside)
    #expect(!panel.interaction.isKeyboardNavigating)
}
