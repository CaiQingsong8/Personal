import AppKit

guard CommandLine.arguments.count == 2 else { exit(1) }
let output = CommandLine.arguments[1]
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
let rect = NSRect(origin: .zero, size: size)
let background = NSBezierPath(roundedRect: rect.insetBy(dx: 42, dy: 42), xRadius: 220, yRadius: 220)
let gradient = NSGradient(colors: [
    NSColor(red: 0.38, green: 0.42, blue: 0.95, alpha: 1),
    NSColor(red: 0.25, green: 0.29, blue: 0.78, alpha: 1),
])!
gradient.draw(in: background, angle: -55)

NSColor.white.withAlphaComponent(0.20).setFill()
NSBezierPath(ovalIn: NSRect(x: 210, y: 210, width: 604, height: 604)).fill()

let check = NSBezierPath()
check.move(to: NSPoint(x: 290, y: 510))
check.line(to: NSPoint(x: 445, y: 355))
check.line(to: NSPoint(x: 735, y: 690))
check.lineWidth = 88
check.lineCapStyle = .round
check.lineJoinStyle = .round
NSColor.white.setStroke()
check.stroke()
image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else { exit(2) }
try png.write(to: URL(fileURLWithPath: output), options: .atomic)
