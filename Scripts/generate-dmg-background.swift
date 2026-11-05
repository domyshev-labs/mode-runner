import AppKit
import Foundation

// Finder reads the logical size from the TIFF; include both standard and Retina representations.
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 640, height: 480)
let image = NSImage(size: size)
for scale in [1, 2] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width) * scale,
                                  pixelsHigh: Int(size.height) * scale, bitsPerSample: 8,
                                  samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                  colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    bitmap.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGradient(starting: NSColor(calibratedRed: 0.97, green: 0.98, blue: 1, alpha: 1),
               ending: NSColor(calibratedRed: 0.88, green: 0.92, blue: 0.97, alpha: 1))!
        .draw(in: NSRect(origin: .zero, size: size), angle: -90)

    func text(_ value: String, x: CGFloat, top: CGFloat, font: NSFont, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let height = (value as NSString).size(withAttributes: attributes).height
        (value as NSString).draw(at: NSPoint(x: x, y: size.height - top - height), withAttributes: attributes)
    }
    let ink = NSColor(calibratedRed: 0.12, green: 0.18, blue: 0.28, alpha: 1)
    let secondary = NSColor(calibratedRed: 0.32, green: 0.39, blue: 0.49, alpha: 1)
    let accent = NSColor(calibratedRed: 0.08, green: 0.43, blue: 0.85, alpha: 1)
    text("MODE RUNNER", x: 40, top: 27, font: .systemFont(ofSize: 10, weight: .bold), color: secondary)
    text("Install Mode Runner", x: 40, top: 48, font: .systemFont(ofSize: 28, weight: .semibold), color: ink)
    text("Drag the app into Applications to install.", x: 40, top: 90,
         font: .systemFont(ofSize: 14), color: secondary)

    for x: CGFloat in [168, 472] {
        let slot = NSBezierPath(roundedRect: NSRect(x: x - 70, y: 480 - 208 - 66, width: 140, height: 132),
                                xRadius: 24, yRadius: 24)
        NSColor.white.withAlphaComponent(0.55).setFill()
        slot.fill()
        NSColor.white.withAlphaComponent(0.85).setStroke()
        slot.lineWidth = 1
        slot.stroke()
    }
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 284, y: 272))
    arrow.line(to: NSPoint(x: 356, y: 272))
    arrow.move(to: NSPoint(x: 342, y: 286))
    arrow.line(to: NSPoint(x: 356, y: 272))
    arrow.line(to: NSPoint(x: 342, y: 258))
    arrow.lineWidth = 4
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    accent.setStroke()
    arrow.stroke()

    let divider = NSBezierPath()
    divider.move(to: NSPoint(x: 40, y: 160))
    divider.line(to: NSPoint(x: 600, y: 160))
    divider.lineWidth = 1
    secondary.withAlphaComponent(0.15).setStroke()
    divider.stroke()
    text("After copying", x: 40, top: 350, font: .systemFont(ofSize: 14, weight: .semibold), color: ink)
    text("Eject this disk, then open Mode Runner", x: 40, top: 378,
         font: .systemFont(ofSize: 13), color: secondary)
    text("from Applications.", x: 40, top: 398, font: .systemFont(ofSize: 13), color: secondary)
    NSGraphicsContext.restoreGraphicsState()
    image.addRepresentation(bitmap)
}
try image.tiffRepresentation!.write(to: output)
