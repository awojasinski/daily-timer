import SwiftUI

public enum ToastPop {
    public static let duration: Double = 1.6

    public static func offset(at elapsed: Double) -> Double {
        guard elapsed > 0 else { return 20 }
        guard elapsed < duration else { return 0 }
        if elapsed < 0.64 {
            let flight = elapsed / 0.64
            return 20 * (1 - flight) - 344 * flight * (1 - flight)
        }
        let landing = elapsed - 0.64
        return 18 * exp(-6 * landing) * sin(18 * landing)
    }
}

public enum ToastGeometry {
    public static let petScale: CGFloat = 1.3
    public static let petHeadroom: CGFloat = 80
    public static let petSize = CGSize(width: 286, height: 286)
    public static let body = CGRect(x: 38, y: 58, width: 143, height: 64)

    public static func bread(at y: CGFloat, shake: CGFloat = 0) -> Path {
        var bread = Path()
        bread.move(to: CGPoint(x: 70 + shake, y: y + 64))
        bread.addLine(to: CGPoint(x: 70 + shake, y: y + 23))
        bread.addCurve(to: CGPoint(x: 62 + shake, y: y + 15), control1: CGPoint(x: 59 + shake, y: y + 23), control2: CGPoint(x: 59 + shake, y: y + 19))
        bread.addCurve(to: CGPoint(x: 155 + shake, y: y + 15), control1: CGPoint(x: 70 + shake, y: y - 3), control2: CGPoint(x: 148 + shake, y: y - 3))
        bread.addCurve(to: CGPoint(x: 147 + shake, y: y + 23), control1: CGPoint(x: 161 + shake, y: y + 19), control2: CGPoint(x: 160 + shake, y: y + 23))
        bread.addLine(to: CGPoint(x: 147 + shake, y: y + 64))
        bread.closeSubpath()
        return bread
    }

    public static func breadDragRect(offset: Double) -> CGRect {
        let top = 4 + offset + 12
        let bottom = min(4 + offset + 63, body.minY)
        return CGRect(x: 72 * petScale, y: (petHeadroom + top) * petScale,
                      width: 73 * petScale, height: max(0, bottom - top) * petScale)
    }

    public static let controls = CGRect(x: 45 * petScale, y: (petHeadroom + 65) * petScale,
                                        width: 129 * petScale, height: 50 * petScale)
    public static let controlOffset = CGPoint(x: controls.minX, y: petSize.height - controls.maxY)
}
