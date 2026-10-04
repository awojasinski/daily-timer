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
    private var onFire: Bool
    private var ejectionElapsed: Double?
    private var headroom: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(outcome: ToastOutcome, lowered: Bool = false, motion: Bool = false,
                onFire: Bool = false, ejectionElapsed: Double? = nil, headroom: CGFloat = 0) {
        self.outcome = outcome
        self.onFire = onFire
        self.lowering = lowered ? 1 : 0
        self.motion = motion
        self.ejectionElapsed = ejectionElapsed
        self.headroom = headroom
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
        let breadY: CGFloat = 4 + (ejectionElapsed.map { reduceMotion ? 0 : ToastPop.offset(at: $0) } ?? ToastPop.loweredOffset * lowering)
        let shake: CGFloat = outcome == .burnt && motion && !reduceMotion ? sin(time * 8) * 1.2 : 0
        context.drawLayer { shadow in
            shadow.addFilter(.blur(radius: 3))
            shadow.fill(Path(ellipseIn: CGRect(x: 43, y: 126, width: 133, height: 5)), with: .color(ToastPalette.ink.opacity(0.22)))
        }

        if onFire {
            drawFire(in: &context, breadY: breadY, time: time)
        } else if outcome == .burnt {
            for index in 0..<3 {
                let x = CGFloat(83 + index * 25)
                let drift = CGFloat(sin(time * 1.7 + Double(index) * 2)) * 5
                var smoke = Path()
                smoke.move(to: CGPoint(x: x, y: breadY + 12))
                smoke.addCurve(to: CGPoint(x: x + drift, y: breadY - 19),
                               control1: CGPoint(x: x - 12 + drift, y: breadY + 1),
                               control2: CGPoint(x: x + 14, y: breadY - 7))
                context.stroke(smoke, with: .linearGradient(Gradient(colors: [ToastPalette.ink.opacity(0.2), .clear]),
                                                            startPoint: CGPoint(x: x, y: breadY + 12), endPoint: CGPoint(x: x, y: breadY - 19)),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
        let toaster = Image(decorative: ToastSprites.frames[0], scale: 1)
        let toasterRect = CGRect(x: 38, y: 48, width: 161, height: 81)
        context.draw(toaster, in: toasterRect)
        let breadIndex = outcome == .raw ? 1 : outcome == .nailed ? 2 : 3
        context.draw(Image(decorative: ToastSprites.frames[breadIndex], scale: 1),
                     in: CGRect(x: 60 + shake, y: breadY, width: 98, height: 64))
        context.drawLayer { front in
            front.clip(to: Path(CGRect(x: 38, y: 58, width: 161, height: 71)))
            front.draw(toaster, in: toasterRect)
        }
    }

    private func drawFire(in context: inout GraphicsContext, breadY: CGFloat, time: Double) {
        context.drawLayer { glow in
            glow.addFilter(.blur(radius: 9))
            glow.fill(Path(ellipseIn: CGRect(x: 60, y: breadY - 20, width: 99, height: 58)), with: .color(.orange.opacity(0.32)))
        }
        let heights: [CGFloat] = [23, 39, 27, 44, 21]
        for index in 0..<5 {
            let x = CGFloat(70 + index * 19)
            let phase = time * 6 + Double(index) * 1.9
            let base = breadY + 29
            let tip = max(-headroom + 5, breadY - heights[index] - sin(phase) * 4)
            let lean = CGFloat(sin(phase * 0.7)) * 7
            var flame = Path()
            flame.move(to: CGPoint(x: x - 12, y: base))
            flame.addCurve(to: CGPoint(x: x + lean + 3, y: tip),
                           control1: CGPoint(x: x - 24, y: base - 20), control2: CGPoint(x: x + 14, y: tip + 20))
            flame.addCurve(to: CGPoint(x: x + 12, y: base),
                           control1: CGPoint(x: x - 4 + lean, y: tip + 24), control2: CGPoint(x: x + 30, y: base - 20))
            flame.closeSubpath()
            context.fill(flame, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.31, blue: 0.16), Color(red: 1, green: 0.66, blue: 0.17), Color(red: 1, green: 0.87, blue: 0.43)]),
                                                       startPoint: CGPoint(x: x, y: tip), endPoint: CGPoint(x: x, y: base)))
            let core = flame.applying(CGAffineTransform(translationX: -x, y: -base)
                .concatenating(CGAffineTransform(scaleX: 0.48, y: 0.7))
                .concatenating(CGAffineTransform(translationX: x, y: base)))
            context.fill(core, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.86, blue: 0.45), ToastPalette.cream]),
                                                      startPoint: CGPoint(x: x, y: tip + 15), endPoint: CGPoint(x: x, y: base)))
            if index % 2 == 1 {
                let sparkY = max(-headroom + 2, tip - 9 - CGFloat(sin(phase)) * 4)
                context.fill(Path(ellipseIn: CGRect(x: x + lean, y: sparkY, width: 2.5, height: 4)), with: .color(.orange.opacity(0.65)))
            }
        }
    }

}
