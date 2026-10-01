import AppKit
import SwiftUI
import ToastArt
import ToastCore

struct ToastCharacterView: View {
    @ObservedObject var store: ToastStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ToastArtwork(outcome: store.characterReading.outcome,
                     lowered: store.characterLowered,
                     motion: store.session.phase == .running,
                     progress: store.characterReading.progress,
                     ejectionElapsed: store.characterEjection,
                     headroom: ToastGeometry.petHeadroom, showBadge: false)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.65), value: store.characterLowered)
            .frame(width: ToastGeometry.petSize.width, height: ToastGeometry.petSize.height)
    }
}

struct ToastView: View {
    @ObservedObject var store: ToastStore

    private var active: Bool { store.session.phase == .running || store.session.phase == .paused }
    private var primary: (title: String, symbol: String) {
        switch store.session.phase {
        case .idle: ("Toast!", "play.fill")
        case .running: ("Pause", "pause.fill")
        case .paused: ("Resume", "play.fill")
        case .summary: ("New meeting", "arrow.counterclockwise")
        }
    }

    var body: some View {
        ZStack {
            WindowDragRegion().help(store.caption + " Drag the toaster body to move it.")
            VStack(spacing: 2) {
                if store.session.phase == .summary {
                    VStack(spacing: 1) {
                        Text(store.reading.text)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                            .accessibilityLabel("Total speaking time")
                            .accessibilityValue(store.reading.text)
                        HStack(spacing: 5) {
                            ForEach(ToastOutcome.allCases, id: \.self) { outcome in
                                Text("\(outcome.rawValue) \(store.session.tally[outcome, default: 0])")
                                    .font(.system(size: 7, weight: .black))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                            }
                        }
                    }
                    .frame(width: 126, height: 42)
                    .background(ToastPalette.cream, in: RoundedRectangle(cornerRadius: 9))
                } else if active {
                    Text(store.reading.text)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                        .frame(width: 126, height: 42)
                        .background(ToastPalette.cream, in: RoundedRectangle(cornerRadius: 9))
                        .accessibilityLabel(store.reading.text.hasPrefix("+") ? "Overtime" : "Time remaining")
                        .accessibilityValue(store.reading.text)
                        .overlay(WindowDragRegion())
                } else {
                    BudgetControl(store: store)
                    .frame(width: 126, height: 42)
                    .background(ToastPalette.cream, in: RoundedRectangle(cornerRadius: 9))
                }

                HStack(spacing: 5) {
                    Text(store.session.phase == .idle ? "READY" : store.session.phase == .summary ? "SERVED" : store.reading.outcome.rawValue)
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .frame(width: 34)
                        .help(store.caption)
                    Button(action: store.primaryAction) {
                        Image(systemName: primary.symbol).frame(width: 28, height: 19)
                    }
                    .accessibilityLabel(primary.title).help(primary.title)
                    if active {
                        Button { store.finish() } label: {
                            Image(systemName: "checkmark").frame(width: 28, height: 19)
                        }
                        .accessibilityLabel("Finish and next").help("Serve this toast and start the next person")
                        Button { store.finish(endingMeeting: true) } label: {
                            Image(systemName: "stop.fill").frame(width: 28, height: 19)
                        }
                        .accessibilityLabel("End meeting").help("Finish this person and show meeting totals")
                    } else {
                        Text(primary.title)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .frame(width: store.session.phase == .summary ? 65 : 28)
                    }
                }
                .buttonStyle(ToasterControlStyle())
                .frame(height: 19)
            }
            .foregroundStyle(ToastPalette.ink)
        }
        .frame(width: ToastGeometry.controls.width, height: ToastGeometry.controls.height)
        .preferredColorScheme(.light)
    }
}

private struct BudgetControl: View {
    @ObservedObject var store: ToastStore

    var body: some View {
        HStack(spacing: 2) {
            ForEach([-1, 1], id: \.self) { direction in
                if direction == 1 {
                    Text(String(format: "%02d:%02d", store.session.budgetSeconds / 60, store.session.budgetSeconds % 60))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .accessibilityLabel("Time budget")
                        .accessibilityValue("\(store.session.budgetSeconds) seconds")
                }
                Button {
                    store.setBudget(seconds: store.session.budgetSeconds + direction * 15)
                } label: {
                    Image(systemName: direction > 0 ? "chevron.right" : "chevron.left")
                        .font(.system(size: 11, weight: .black))
                        .frame(width: 22, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!ToastSession.budgetRange.contains(store.session.budgetSeconds + direction * 15))
                .accessibilityLabel("\(direction > 0 ? "Increase" : "Decrease") time by 15 seconds")
                .help("\(direction > 0 ? "Add" : "Subtract") 15 seconds")
            }
        }
    }
}

private struct ToasterControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(ToastPalette.cream)
            .background(ToastPalette.ink.opacity(configuration.isPressed ? 0.6 : 1), in: RoundedRectangle(cornerRadius: 6))
    }
}

struct WindowDragRegion: NSViewRepresentable {
    final class DragView: NSView {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        private weak var draggedWindow: NSWindow?
        private var pointerOrigin = NSPoint.zero
        private var windowOrigin = NSPoint.zero

        override func mouseDown(with event: NSEvent) {
            draggedWindow = window?.parent ?? window
            pointerOrigin = NSEvent.mouseLocation
            windowOrigin = draggedWindow?.frame.origin ?? .zero
        }

        override func mouseDragged(with event: NSEvent) {
            let pointer = NSEvent.mouseLocation
            draggedWindow?.setFrameOrigin(NSPoint(x: windowOrigin.x + pointer.x - pointerOrigin.x,
                                                  y: windowOrigin.y + pointer.y - pointerOrigin.y))
        }

        override func mouseUp(with event: NSEvent) { draggedWindow = nil }
    }

    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ nsView: DragView, context: Context) {}
}
