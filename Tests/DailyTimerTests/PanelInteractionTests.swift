import AppKit
import Testing
@testable import DailyTimer

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
