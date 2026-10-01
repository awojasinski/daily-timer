import AppKit
import SwiftUI
import ToastArt
import ToastCore

@main
struct ToastAssets {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Usage: ToastAssets <output-directory>")
        }
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let icon = ZStack {
            RoundedRectangle(cornerRadius: 210).fill(ToastPalette.cream)
            ToastArtwork(outcome: .nailed).padding(65)
        }.frame(width: 1024, height: 1024)
        let renderer = ImageRenderer(content: icon)
        renderer.scale = 1
        guard let image = renderer.cgImage else { fatalError("Could not render icon") }
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode icon") }
        try png.write(to: directory.appendingPathComponent("Icon.png"))
        for outcome in ToastOutcome.allCases {
            let preview = ImageRenderer(content: ToastArtwork(outcome: outcome).frame(width: 440, height: 280))
            guard let image = preview.cgImage,
                  let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
                fatalError("Could not render \(outcome.rawValue)")
            }
            try png.write(to: directory.appendingPathComponent("\(outcome.rawValue).png"))
        }
        for milliseconds in [0, 320, 640, 720, 920, 1600] {
            let frame = ToastArtwork(outcome: .burnt, ejectionElapsed: Double(milliseconds) / 1000,
                                     headroom: ToastGeometry.petHeadroom, showBadge: false)
                .frame(width: ToastGeometry.petSize.width, height: ToastGeometry.petSize.height)
            let preview = ImageRenderer(content: frame)
            preview.scale = 2
            guard let image = preview.cgImage,
                  let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
                fatalError("Could not render pop animation frame")
            }
            try png.write(to: directory.appendingPathComponent("POP-\(milliseconds).png"))
        }
    }
}
