import SwiftUI

public enum ToastPop {
    public static let duration: Double = 1.6
    public static let loweredOffset: Double = 8

    public static func offset(at elapsed: Double) -> Double {
        guard elapsed > 0 else { return loweredOffset }
        guard elapsed < duration else { return 0 }
        if elapsed < 0.64 {
            let flight = elapsed / 0.64
            return loweredOffset * (1 - flight) - 344 * flight * (1 - flight)
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
