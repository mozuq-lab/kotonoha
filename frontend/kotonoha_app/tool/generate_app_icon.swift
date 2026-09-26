// Run from frontend/kotonoha_app: swift tool/generate_app_icon.swift
// One vector drawing supplies the home mark and all platform icon sizes.
import AppKit
import Foundation

func writeIcon(_ size: Int, to path: String, markScale: CGFloat = 1) throws {
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

    let jade = NSColor(calibratedRed: 57 / 255, green: 176 / 255, blue: 155 / 255, alpha: 1)
    let petrol = NSColor(calibratedRed: 0, green: 70 / 255, blue: 76 / 255, alpha: 1)
    NSGradient(starting: jade, ending: petrol)!.draw(
        in: NSRect(x: 0, y: 0, width: 1024, height: 1024), angle: -45
    )

    context.cgContext.translateBy(x: 512, y: 512)
    context.cgContext.scaleBy(x: markScale, y: markScale)
    context.cgContext.translateBy(x: -512, y: -512)

    // A single silhouette combines a leaf with a soft speech-bubble tail.
    let leaf = NSBezierPath()
    leaf.move(to: NSPoint(x: 819, y: 813))
    leaf.curve(to: NSPoint(x: 842, y: 797),
               controlPoint1: NSPoint(x: 830, y: 815),
               controlPoint2: NSPoint(x: 840, y: 809))
    leaf.curve(to: NSPoint(x: 409, y: 219),
               controlPoint1: NSPoint(x: 863, y: 462),
               controlPoint2: NSPoint(x: 676, y: 199))
    leaf.curve(to: NSPoint(x: 232, y: 162),
               controlPoint1: NSPoint(x: 359, y: 221),
               controlPoint2: NSPoint(x: 286, y: 183))
    leaf.curve(to: NSPoint(x: 207, y: 187),
               controlPoint1: NSPoint(x: 208, y: 152),
               controlPoint2: NSPoint(x: 195, y: 166))
    leaf.line(to: NSPoint(x: 232, y: 255))
    leaf.curve(to: NSPoint(x: 237, y: 361),
               controlPoint1: NSPoint(x: 249, y: 288),
               controlPoint2: NSPoint(x: 249, y: 317))
    leaf.curve(to: NSPoint(x: 819, y: 813),
               controlPoint1: NSPoint(x: 185, y: 588),
               controlPoint2: NSPoint(x: 415, y: 765))
    leaf.close()

    let vein = NSBezierPath()
    vein.move(to: NSPoint(x: 353, y: 312))
    vein.curve(to: NSPoint(x: 650, y: 645),
               controlPoint1: NSPoint(x: 372, y: 504),
               controlPoint2: NSPoint(x: 515, y: 574))
    vein.curve(to: NSPoint(x: 353, y: 312),
               controlPoint1: NSPoint(x: 545, y: 560),
               controlPoint2: NSPoint(x: 436, y: 441))
    vein.close()
    leaf.append(vein)
    leaf.windingRule = .evenOdd
    NSColor(calibratedRed: 1, green: 253 / 255, blue: 247 / 255, alpha: 1).setFill()
    leaf.fill()
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

try writeIcon(32, to: "web/favicon.png")
for size in [192, 512] {
    try writeIcon(size, to: "web/icons/Icon-\(size).png")
    // Keep the entire mark inside the maskable icon's central safe circle.
    try writeIcon(size, to: "web/icons/Icon-maskable-\(size).png", markScale: 0.88)
}
