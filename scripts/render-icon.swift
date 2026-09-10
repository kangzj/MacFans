import AppKit

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(red: r, green: g, blue: b, alpha: a) }
let space = CGColorSpaceCreateDeviceRGB()

func render(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    let s = size
    let inset = s * 0.0625
    let rect = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let radius = rect.width * 0.2237
    let squircle = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    let center = CGPoint(x: rect.midX, y: rect.midY)
    func pt(_ angle: CGFloat, _ r: CGFloat, from c: CGPoint = center) -> CGPoint { CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r) }

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.035, color: CGColor(gray: 0, alpha: 0.4))
    ctx.addPath(squircle); ctx.setFillColor(rgb(0.05, 0.1, 0.25)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(squircle); ctx.clip()
    let base = CGGradient(colorsSpace: space, colors: [rgb(0.04, 0.11, 0.30), rgb(0.08, 0.36, 0.80), rgb(0.16, 0.66, 0.96)] as CFArray, locations: [0, 0.5, 1])!
    ctx.drawLinearGradient(base, start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
    let bloom = CGGradient(colorsSpace: space, colors: [rgb(0.55, 0.92, 1, 0.55), rgb(0.3, 0.8, 1, 0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(bloom, startCenter: CGPoint(x: rect.maxX * 0.82, y: rect.maxY * 0.88), startRadius: 0, endCenter: CGPoint(x: rect.maxX * 0.82, y: rect.maxY * 0.88), endRadius: rect.width * 0.75, options: [])
    let vignette = CGGradient(colorsSpace: space, colors: [rgb(0, 0, 0, 0), rgb(0, 0, 0.1, 0.35)] as CFArray, locations: [0.55, 1])!
    ctx.drawRadialGradient(vignette, startCenter: center, startRadius: 0, endCenter: center, endRadius: rect.width * 0.78, options: [])

    let ringR = rect.width * 0.405
    ctx.setLineCap(.round)
    for (start, length, alpha) in [(CGFloat(0.35), CGFloat(0.9), CGFloat(0.22)), (2.45, 0.9, 0.22), (4.55, 0.9, 0.22)] {
        ctx.setStrokeColor(rgb(1, 1, 1, alpha))
        ctx.setLineWidth(s * 0.018)
        ctx.addArc(center: center, radius: ringR, startAngle: start, endAngle: start + length, clockwise: false)
        ctx.strokePath()
    }

    let outer = rect.width * 0.345
    let hub = rect.width * 0.105
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.03, color: rgb(0, 0.05, 0.2, 0.45))
    let bladeFill = CGGradient(colorsSpace: space, colors: [rgb(1, 1, 1), rgb(0.86, 0.96, 1)] as CFArray, locations: [0, 1])!
    for blade in 0..<4 {
        let a = CGFloat(blade) * (.pi / 2) + .pi / 2 + 0.2
        let p = CGMutablePath()
        p.move(to: pt(a, hub * 0.95))
        p.addCurve(to: pt(a + 0.72, outer), control1: pt(a - 0.02, outer * 0.5), control2: pt(a + 0.3, outer * 0.92))
        p.addArc(center: center, radius: outer, startAngle: a + 0.72, endAngle: a + 1.2, clockwise: false)
        p.addCurve(to: pt(a + 0.62, hub * 0.95), control1: pt(a + 1.12, outer * 0.62), control2: pt(a + 0.85, outer * 0.3))
        p.addArc(center: center, radius: hub * 0.95, startAngle: a + 0.62, endAngle: a, clockwise: true)
        p.closeSubpath()
        ctx.saveGState()
        ctx.addPath(p); ctx.clip()
        ctx.drawLinearGradient(bladeFill, start: pt(a + 0.4, hub), end: pt(a + 0.95, outer), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
    }
    ctx.setFillColor(rgb(1, 1, 1))
    ctx.addEllipse(in: CGRect(x: center.x - hub, y: center.y - hub, width: hub * 2, height: hub * 2)); ctx.fillPath()
    ctx.restoreGState()

    let core = hub * 0.52
    let coreFill = CGGradient(colorsSpace: space, colors: [rgb(1, 0.72, 0.30), rgb(1, 0.38, 0.22)] as CFArray, locations: [0, 1])!
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: center.x - core, y: center.y - core, width: core * 2, height: core * 2)); ctx.clip()
    ctx.drawLinearGradient(coreFill, start: CGPoint(x: center.x, y: center.y + core), end: CGPoint(x: center.x, y: center.y - core), options: [])
    ctx.restoreGState()
    ctx.setStrokeColor(rgb(0.08, 0.36, 0.80, 0.35)); ctx.setLineWidth(s * 0.006)
    ctx.addEllipse(in: CGRect(x: center.x - core, y: center.y - core, width: core * 2, height: core * 2)); ctx.strokePath()

    let sheen = CGGradient(colorsSpace: space, colors: [rgb(1, 1, 1, 0.16), rgb(1, 1, 1, 0.0)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(sheen, start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.midY), options: [])
    ctx.restoreGState()

    ctx.addPath(squircle); ctx.setStrokeColor(rgb(1, 1, 1, 0.12)); ctx.setLineWidth(max(1, s * 0.004)); ctx.strokePath()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let out = CommandLine.arguments[1]
for (name, px) in [("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64), ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512), ("icon_512x512", 512), ("icon_512x512@2x", 1024)] {
    try! render(size: CGFloat(px)).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
}
