import CoreGraphics
import ImageIO
import SwiftUI

@MainActor
enum ToastSprites {
    static let frames: [CGImage] = {
        let url = Bundle.main.url(forResource: "PaintedToast", withExtension: "png")
            ?? Bundle.module.url(forResource: "PaintedToast", withExtension: "png")
        guard let url, let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let atlas = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            fatalError("Missing PaintedToast sprite atlas")
        }
        // The lever extends slightly past the atlas midpoint; keep it with the toaster.
        let regions = [CGRect(x: 0, y: 0, width: 0.525, height: 0.5),
                       CGRect(x: 0.525, y: 0, width: 0.475, height: 0.5),
                       CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5),
                       CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)]
        return regions.map { region in
            let rect = region.applying(CGAffineTransform(scaleX: CGFloat(atlas.width), y: CGFloat(atlas.height))).integral
            guard let sprite = atlas.cropping(to: rect),
                  let bitmap = CGContext(data: nil, width: sprite.width, height: sprite.height,
                                         bitsPerComponent: 8, bytesPerRow: sprite.width * 4,
                                         space: CGColorSpaceCreateDeviceRGB(),
                                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
                  let data = bitmap.data else { fatalError("Cannot decode toast sprite") }
            bitmap.draw(sprite, in: CGRect(x: 0, y: 0, width: sprite.width, height: sprite.height))
            let pixels = data.assumingMemoryBound(to: UInt8.self)
            var minX = sprite.width, minY = sprite.height, maxX = 0, maxY = 0
            for y in 0..<sprite.height {
                for x in 0..<sprite.width where pixels[(y * sprite.width + x) * 4 + 3] > 8 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
            guard minX <= maxX, minY <= maxY,
                  let cropped = bitmap.makeImage()?.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)) else {
                fatalError("Empty toast sprite")
            }
            return cropped
        }
    }()
}
