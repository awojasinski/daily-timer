import Combine

@MainActor
final class PanelInteraction: ObservableObject {
    @Published var isFocused = false {
        didSet {
            if !isFocused { isKeyboardNavigating = false }
        }
    }
    @Published var isPointerInside = false
    @Published var isKeyboardNavigating = false

    var showsControls: Bool { isFocused && (isPointerInside || isKeyboardNavigating) }
}
