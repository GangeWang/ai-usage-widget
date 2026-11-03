// Renders the AI 額度 app icon into App/Assets.xcassets/AppIcon.appiconset.
// Usage: swift tools/make-icon.swift   (run from the widget/ folder)
import AppKit
import SwiftUI

struct GaugeArc: View {
    let diameter: CGFloat
    let width: CGFloat
    let fill: Double          // 0...1 of the 270° sweep
    let colors: [Color]

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: width, lineCap: .round))
            Circle()
                .trim(from: 0, to: 0.75 * fill)
                .stroke(
                    AngularGradient(colors: colors, center: .center, startAngle: .degrees(0), endAngle: .degrees(270 * fill)),
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
        }
        .frame(width: diameter, height: diameter)
        .rotationEffect(.degrees(135))   // open at the bottom, like a gauge
    }
}

struct IconView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 185, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.20, green: 0.19, blue: 0.24), Color(red: 0.08, green: 0.08, blue: 0.10)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 185, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 3)
                )
                .frame(width: 824, height: 824)
                .shadow(color: .black.opacity(0.35), radius: 18, y: 12)
                .offset(y: -36)

            // Claude (outer) and Codex (inner) remaining-quota gauges.
            GaugeArc(diameter: 560, width: 70, fill: 0.72,
                     colors: [Color(red: 0.96, green: 0.62, blue: 0.48), Color(red: 0.85, green: 0.42, blue: 0.29)])
            GaugeArc(diameter: 360, width: 70, fill: 0.45,
                     colors: [Color(red: 0.36, green: 0.86, blue: 0.68), Color(red: 0.06, green: 0.64, blue: 0.50)])

            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 64, height: 64)
        }
        .offset(y: 36)   // the gauges open at the bottom; nudge down to look centered
        .frame(width: 1024, height: 1024)
    }
}

@MainActor func run() throws {
    let out = URL(fileURLWithPath: "App/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
    try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

    let renderer = ImageRenderer(content: IconView())
    renderer.scale = 1
    guard let master = renderer.cgImage else { fatalError("render failed") }

    var images: [[String: String]] = []
    for points in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let px = points * scale
            let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
            let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                                       samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                       colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
            NSGraphicsContext.saveGraphicsState()
            let ctx = NSGraphicsContext(bitmapImageRep: rep)!
            ctx.imageInterpolation = .high
            NSGraphicsContext.current = ctx
            ctx.cgContext.draw(master, in: CGRect(x: 0, y: 0, width: px, height: px))
            NSGraphicsContext.restoreGraphicsState()
            try rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
            images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
        }
    }
    let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
    try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
        .write(to: out.appendingPathComponent("Contents.json"))
    try #"{"info":{"author":"xcode","version":1}}"#.write(to: URL(fileURLWithPath: "App/Assets.xcassets/Contents.json"), atomically: true, encoding: .utf8)
    print("✓ wrote \(images.count) icons to \(out.path)")
}

try MainActor.assumeIsolated { try run() }
