import AppKit
import SwiftUI

@main
struct TimerAssets {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Usage: TimerAssets <output-directory>")
        }
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let icon = ZStack {
            RoundedRectangle(cornerRadius: 210)
                .fill(LinearGradient(colors: [Color(red: 0.24, green: 0.61, blue: 1),
                                               Color(red: 0.08, green: 0.30, blue: 0.82)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "timer")
                .font(.system(size: 620, weight: .regular))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 12)
        }.frame(width: 1024, height: 1024)
        let renderer = ImageRenderer(content: icon)
        renderer.scale = 1
        guard let image = renderer.cgImage else { fatalError("Could not render icon") }
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode icon") }
        try png.write(to: directory.appendingPathComponent("Icon.png"))
    }
}
