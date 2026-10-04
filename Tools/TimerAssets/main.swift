import AppKit

@main
struct TimerAssets {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Usage: TimerAssets <output-directory>")
        }
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024,
                                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                            isPlanar: false, colorSpaceName: .deviceRGB,
                                            bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap),
              let symbol = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)?
                .withSymbolConfiguration(.init(pointSize: 620, weight: .regular))?
                .withSymbolConfiguration(.init(paletteColors: [.white])),
              let gradient = NSGradient(starting: NSColor(red: 0.24, green: 0.61, blue: 1, alpha: 1),
                                        ending: NSColor(red: 0.08, green: 0.30, blue: 0.82, alpha: 1)) else {
            fatalError("Could not create icon drawing resources")
        }
        // Bitmap-backed AppKit drawing also works on CI machines without a Metal device.
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        let bounds = NSRect(x: 0, y: 0, width: 1024, height: 1024)
        gradient.draw(in: NSBezierPath(roundedRect: bounds, xRadius: 210, yRadius: 210), angle: -45)
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.12)
        shadow.shadowBlurRadius = 12
        shadow.shadowOffset = NSSize(width: 0, height: -12)
        shadow.set()
        let scale = 650 / max(symbol.size.width, symbol.size.height)
        let size = NSSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
        symbol.draw(in: NSRect(x: (1024 - size.width) / 2, y: (1024 - size.height) / 2,
                               width: size.width, height: size.height))
        NSGraphicsContext.restoreGraphicsState()
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Could not encode icon")
        }
        try png.write(to: directory.appendingPathComponent("Icon.png"))
    }
}
