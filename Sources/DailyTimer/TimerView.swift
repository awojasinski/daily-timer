import SwiftUI
import TimerCore

struct TimerView: View {
    static let size = CGSize(width: 260, height: 150)
    @ObservedObject var store: TimerStore
    @ObservedObject var interaction: PanelInteraction
    var close: () -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var active: Bool { store.session.phase == .running || store.session.phase == .paused }
    private var statusColor: Color {
        guard active else { return .clear }
        switch store.reading.status {
        case .neutral: return .clear
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        }
    }
    private var timerLabel: String {
        switch store.session.phase {
        case .idle: "Time per person"
        case .paused: "Paused"
        case .running: store.reading.elapsed > Double(store.session.budgetSeconds) ? "Overtime" : "Time remaining"
        case .summary: "Meeting complete"
        }
    }
    private var primary: (title: String, symbol: String) {
        switch store.session.phase {
        case .idle: ("Start", "play.fill")
        case .running: ("Pause", "pause.fill")
        case .paused: ("Resume", "play.fill")
        case .summary: ("New meeting", "arrow.counterclockwise")
        }
    }

    var body: some View {
        ZStack {
            statusColor.opacity(reduceTransparency ? 0.24 : 0.12)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: statusColor)
            VStack(spacing: 3) {
                if store.session.phase == .summary {
                    Text(store.summary)
                        .font(.system(size: 17, weight: .medium))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(timerLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(store.reading.text)
                        .font(.system(size: 38, weight: .regular, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.identity)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .accessibilityLabel(timerLabel)
                        .accessibilityValue(store.reading.text)
                }
            }
            .padding(.horizontal, 24)
            .accessibilityElement(children: .contain)
            .accessibilityValue(active ? "\(Int(store.reading.progress * 100)) percent of allotted time used" : "")

            VStack(spacing: 0) {
                HStack {
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .frame(width: 18, height: 18)
                            .background(.primary.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Hide timer")
                    .accessibilityLabel("Close")
                    .keyboardShortcut("w", modifiers: .command)
                    Spacer()
                    Text("Daily timer")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Color.clear.frame(width: 18, height: 18)
                }
                Spacer()
                if #available(macOS 26, *) {
                    controls.buttonStyle(.glass)
                } else {
                    controls.buttonStyle(.bordered)
                }
            }
            .padding(12)
            .opacity(interaction.showsControls ? 1 : 0)
            .allowsHitTesting(interaction.showsControls)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: interaction.showsControls)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onHover { isInside in
            interaction.isPointerInside = isInside
            interaction.isKeyboardNavigating = false
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if !active && store.session.phase != .summary {
                budgetButton(direction: -1)
            } else if active {
                Button { store.finish(endingMeeting: true) } label: {
                    Label("End meeting", systemImage: "stop.fill").frame(width: 24, height: 22)
                }
                .help("Finish this person and end the meeting")
            }
            Button(action: store.primaryAction) {
                Label(primary.title, systemImage: primary.symbol).frame(width: 24, height: 22)
            }
            .help(primary.title)
            .keyboardShortcut(.space, modifiers: [])
            if !active && store.session.phase != .summary {
                budgetButton(direction: 1)
            } else if active {
                Button { store.finish() } label: {
                    Label("Next", systemImage: "forward.end.fill").frame(width: 24, height: 22)
                }
                .help("Finish this person and start the next")
            }
        }
        .buttonBorderShape(.circle)
        .labelStyle(.iconOnly)
        .controlSize(.regular)
    }

    private func budgetButton(direction: Int) -> some View {
        Button {
            store.setBudget(seconds: store.session.budgetSeconds + direction * 15)
        } label: {
            Label(direction > 0 ? "Increase time by 15 seconds" : "Decrease time by 15 seconds",
                  systemImage: direction > 0 ? "plus" : "minus")
                .frame(width: 24, height: 22)
        }
        .disabled(!TimerSession.budgetRange.contains(store.session.budgetSeconds + direction * 15))
        .help(direction > 0 ? "Add 15 seconds" : "Subtract 15 seconds")
    }
}
