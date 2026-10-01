import SwiftUI
import ToastCore

public enum ToastPalette {
    public static let ink = Color(red: 0.24, green: 0.18, blue: 0.15)
    public static let cream = Color(red: 1, green: 0.96, blue: 0.86)
    public static let coral = Color(red: 0.86, green: 0.31, blue: 0.20)

    public static func color(for outcome: ToastOutcome) -> Color {
        switch outcome {
        case .raw: Color(red: 0.60, green: 0.45, blue: 0.21)
        case .nailed: Color(red: 0.25, green: 0.46, blue: 0.33)
        case .burnt: coral
        }
    }
}

public struct ToastArtwork: View, Animatable {
    public var outcome: ToastOutcome
    public var motion: Bool
    nonisolated private var lowering: Double
    private var progress: Double
    private var ejectionElapsed: Double?
    private var headroom: CGFloat
    private var showBadge: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(outcome: ToastOutcome, lowered: Bool = false, motion: Bool = false, progress: Double? = nil,
                ejectionElapsed: Double? = nil, headroom: CGFloat = 0, showBadge: Bool = true) {
        self.outcome = outcome
        self.lowering = lowered ? 1 : 0
        self.motion = motion
        self.progress = progress ?? (outcome == .raw ? 0 : 0.9)
        self.ejectionElapsed = ejectionElapsed
        self.headroom = headroom
        self.showBadge = showBadge
    }

    nonisolated public var animatableData: Double {
        get { lowering }
        set { lowering = newValue }
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !motion || reduceMotion)) { timeline in
            Canvas { context, size in
                let height = 140 + headroom
                let scale = min(size.width / 220, size.height / height)
                context.translateBy(x: (size.width - 220 * scale) / 2, y: (size.height - height * scale) / 2 + headroom * scale)
                context.scaleBy(x: scale, y: scale)
                draw(in: &context, time: motion && !reduceMotion ? timeline.date.timeIntervalSinceReferenceDate : 0)
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, time: Double) {
        let ink = ToastPalette.ink
        let breadY: CGFloat = 4 + (ejectionElapsed.map { reduceMotion ? 0 : ToastPop.offset(at: $0) } ?? 20 * lowering)
        let shake: CGFloat = outcome == .burnt && motion && !reduceMotion ? sin(time * 8) * 1.2 : 0

        context.fill(Path(ellipseIn: CGRect(x: 35, y: 126, width: 152, height: 10)), with: .color(ink.opacity(0.12)))
        if outcome == .burnt {
            for index in 0..<3 {
                let drift = CGFloat(sin(time * 1.7 + Double(index) * 2)) * 5
                var smoke = Path()
                smoke.move(to: CGPoint(x: 84 + index * 24, y: 42))
                smoke.addCurve(to: CGPoint(x: 80 + CGFloat(index * 24) + drift, y: 1),
                               control1: CGPoint(x: 65 + CGFloat(index * 24) + drift, y: 27),
                               control2: CGPoint(x: 106 + index * 24, y: 20))
                context.stroke(smoke, with: .color(ink.opacity(0.25)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
        }

        let slot = Path(roundedRect: CGRect(x: 44, y: 48, width: 130, height: 23), cornerRadius: 11)
        context.fill(slot, with: .color(ink))

        let bread = ToastGeometry.bread(at: breadY, shake: shake)
        let warmth = min(1, max(0, progress))
        let breadColor = outcome == .burnt
            ? Color(red: 0.35, green: 0.25, blue: 0.22)
            : Color(red: 1 - 0.06 * warmth, green: 0.89 - 0.25 * warmth, blue: 0.62 - 0.34 * warmth)
        context.fill(bread, with: .color(breadColor))
        context.stroke(bread, with: .color(outcome == .burnt ? ink : Color(red: 0.66, green: 0.36, blue: 0.16)), style: StrokeStyle(lineWidth: 5, lineJoin: .round))

        let faceColor: Color = outcome == .burnt ? ToastPalette.cream : ink
        for eyeX: CGFloat in [94, 124] {
            let eye = Path(ellipseIn: CGRect(x: eyeX + shake, y: breadY + 23, width: 5, height: 7))
            context.fill(eye, with: .color(faceColor))
        }
        var mouth = Path()
        mouth.move(to: CGPoint(x: 104 + shake, y: breadY + 34))
        mouth.addQuadCurve(to: CGPoint(x: 116 + shake, y: breadY + 34), control: CGPoint(x: 110 + shake, y: breadY + (outcome == .burnt ? 29 : 43)))
        context.stroke(mouth, with: .color(faceColor), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        if outcome != .burnt {
            for cheekX: CGFloat in [83, 133] {
                context.fill(Path(ellipseIn: CGRect(x: cheekX + shake, y: breadY + 33, width: 8, height: 4)), with: .color(ToastPalette.coral.opacity(0.4)))
            }
        }

        for footX: CGFloat in [58, 150] {
            context.fill(Path(roundedRect: CGRect(x: footX, y: 117, width: 16, height: 12), cornerRadius: 4), with: .color(ink))
        }
        let body = Path(roundedRect: ToastGeometry.body, cornerRadius: 19)
        context.fill(body, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.69, blue: 0.47), ToastPalette.coral]), startPoint: CGPoint(x: 90, y: 58), endPoint: CGPoint(x: 110, y: 122)))
        context.stroke(body, with: .color(ink), lineWidth: 3)
        context.fill(Path(roundedRect: CGRect(x: 48, y: 66, width: 116, height: 4), cornerRadius: 2), with: .color(.white.opacity(0.4)))
        if showBadge {
            let badge = Path(roundedRect: CGRect(x: 78, y: 83, width: 65, height: 21), cornerRadius: 7)
            context.fill(badge, with: .color(ToastPalette.cream))
            context.draw(Text("TINY TOAST").font(.system(size: 8, weight: .black, design: .rounded)).tracking(0.7).foregroundColor(ink), at: CGPoint(x: 110, y: 94))
        }
        context.fill(Path(ellipseIn: CGRect(x: 156, y: 97, width: 7, height: 7)), with: .color(lowering > 0.5 ? Color.yellow : ink.opacity(0.4)))
        context.fill(Path(roundedRect: CGRect(x: 186, y: 65, width: 4, height: 40), cornerRadius: 2), with: .color(ink))
        context.fill(Path(roundedRect: CGRect(x: 177, y: 70 + 23 * lowering, width: 22, height: 9), cornerRadius: 4), with: .color(ink))
    }
}
