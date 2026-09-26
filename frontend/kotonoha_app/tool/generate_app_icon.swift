// Run from frontend/kotonoha_app: swift tool/generate_app_icon.swift
// One vector drawing supplies the home mark and all platform icon sizes.
import AppKit
import Foundation

func writeIcon(_ size: Int, to path: String) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Cannot create icon bitmap")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)

    NSColor(calibratedRed: 33 / 255, green: 150 / 255, blue: 243 / 255, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()

    NSColor.white.setFill()
    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: 330, y: 310))
    tail.line(to: NSPoint(x: 260, y: 150))
    tail.line(to: NSPoint(x: 480, y: 310))
    tail.close()
    tail.fill()
    NSBezierPath(roundedRect: NSRect(x: 150, y: 280, width: 724, height: 560),
                 xRadius: 150, yRadius: 150).fill()

    NSColor(calibratedRed: 20 / 255, green: 80 / 255, blue: 138 / 255, alpha: 1).setFill()
    for x in [352, 512, 672] {
        NSBezierPath(ovalIn: NSRect(x: x - 47, y: 513 - 47, width: 94, height: 94)).fill()
    }
    NSGraphicsContext.restoreGraphicsState()

    // iOS app icons must be RGB PNGs without an alpha channel.
    guard let opaque = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ), let source = bitmap.bitmapData, let target = opaque.bitmapData else {
        fatalError("Cannot create opaque icon bitmap")
    }
    for y in 0..<size {
        for x in 0..<size {
            let from = y * bitmap.bytesPerRow + x * 4
            let to = y * opaque.bytesPerRow + x * 3
            for channel in 0..<3 {
                target[to + channel] = source[from + channel]
            }
        }
    }
    guard let data = opaque.representation(using: .png, properties: [:]) else {
        fatalError("Cannot encode icon PNG")
    }
    try FileManager.default.createDirectory(
        atPath: (path as NSString).deletingLastPathComponent,
        withIntermediateDirectories: true
    )
    try data.write(to: URL(fileURLWithPath: path))
}

try writeIcon(1024, to: "assets/images/kotonoha_icon.png")

let ios = "ios/Runner/Assets.xcassets/AppIcon.appiconset/"
for (name, size) in [
    ("Icon-App-20x20@1x.png", 20), ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60), ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58), ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40), ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120), ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180), ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152), ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024)
] {
    try writeIcon(size, to: ios + name)
}

let android = "android/app/src/main/res/"
for (density, size) in [
    ("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
    ("xxhdpi", 144), ("xxxhdpi", 192)
] {
    try writeIcon(size, to: android + "mipmap-\(density)/ic_launcher.png")
}
