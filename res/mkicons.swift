import AppKit
func bitmap(_ w: Int, _ h: Int) -> NSBitmapImageRep { return NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)! }
func save(_ rep: NSBitmapImageRep, _ path: String) { try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path)) }
func dumbbell(_ s: CGFloat, _ color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: NSRect(x: s*0.30, y: s*0.44, width: s*0.40, height: s*0.12), xRadius: s*0.04, yRadius: s*0.04).fill()   // bar
    for x in [s*0.12, s*0.72] { NSBezierPath(roundedRect: NSRect(x: x, y: s*0.28, width: s*0.16, height: s*0.44), xRadius: s*0.05, yRadius: s*0.05).fill() }   // plates
    for x in [s*0.04, s*0.88] { NSBezierPath(roundedRect: NSRect(x: x, y: s*0.36, width: s*0.08, height: s*0.28), xRadius: s*0.03, yRadius: s*0.03).fill() }   // collars
}
func icon(_ size: Int, _ path: String) {
    let rep = bitmap(size, size); NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(size)
    NSGradient(starting: NSColor(deviceRed: 0.40, green: 0.43, blue: 0.48, alpha: 1), ending: NSColor(deviceRed: 0.22, green: 0.25, blue: 0.29, alpha: 1))!.draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: -90)
    let sh = NSShadow(); sh.shadowOffset = NSSize(width: 0, height: -s*0.02); sh.shadowBlurRadius = s*0.03; sh.shadowColor = NSColor(white: 0, alpha: 0.35); sh.set()
    dumbbell(s, NSColor.white)
    NSGraphicsContext.restoreGraphicsState(); save(rep, path)
}
icon(57, "Icon.png"); icon(114, "Icon@2x.png"); icon(256, "Icon-preview.png")
func glyph(_ name: String, _ draw: (CGFloat) -> Void) { for (sz, suf) in [(30, ""), (60, "@2x")] { let rep = bitmap(sz, sz); NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep); NSColor.white.set(); draw(CGFloat(sz)); NSGraphicsContext.restoreGraphicsState(); save(rep, "\(name)\(suf).png") } }
glyph("tab-workout") { s in dumbbell(s, .white) }
glyph("tab-routines") { s in for i in 0..<3 { let y = s*0.18 + CGFloat(i)*s*0.26; NSBezierPath(ovalIn: NSRect(x: s*0.1, y: y, width: s*0.14, height: s*0.14)).fill(); NSBezierPath(roundedRect: NSRect(x: s*0.32, y: y + s*0.02, width: s*0.58, height: s*0.1), xRadius: s*0.05, yRadius: s*0.05).fill() } }
glyph("tab-exercises") { s in NSBezierPath(ovalIn: NSRect(x: s*0.38, y: s*0.68, width: s*0.24, height: s*0.24)).fill(); let p = NSBezierPath(); p.lineWidth = s*0.12; p.lineCapStyle = .round; p.move(to: NSPoint(x: s*0.5, y: s*0.66)); p.line(to: NSPoint(x: s*0.5, y: s*0.36)); p.move(to: NSPoint(x: s*0.2, y: s*0.58)); p.line(to: NSPoint(x: s*0.8, y: s*0.58)); p.move(to: NSPoint(x: s*0.5, y: s*0.36)); p.line(to: NSPoint(x: s*0.28, y: s*0.08)); p.move(to: NSPoint(x: s*0.5, y: s*0.36)); p.line(to: NSPoint(x: s*0.72, y: s*0.08)); p.stroke() }
glyph("tab-history") { s in let p = NSBezierPath(ovalIn: NSRect(x: s*0.1, y: s*0.1, width: s*0.8, height: s*0.8)); p.lineWidth = s*0.1; p.stroke(); let h = NSBezierPath(); h.lineWidth = s*0.1; h.lineCapStyle = .round; h.move(to: NSPoint(x: s*0.5, y: s*0.5)); h.line(to: NSPoint(x: s*0.5, y: s*0.75)); h.move(to: NSPoint(x: s*0.5, y: s*0.5)); h.line(to: NSPoint(x: s*0.68, y: s*0.42)); h.stroke() }
glyph("tab-progress") { s in let p = NSBezierPath(); p.lineWidth = s*0.11; p.lineCapStyle = .round; p.lineJoinStyle = .round; p.move(to: NSPoint(x: s*0.1, y: s*0.22)); p.line(to: NSPoint(x: s*0.36, y: s*0.52)); p.line(to: NSPoint(x: s*0.56, y: s*0.36)); p.line(to: NSPoint(x: s*0.9, y: s*0.8)); p.stroke(); NSBezierPath(ovalIn: NSRect(x: s*0.78, y: s*0.68, width: s*0.24, height: s*0.24)).fill(); let ax = NSBezierPath(); ax.lineWidth = s*0.06; ax.move(to: NSPoint(x: s*0.06, y: s*0.08)); ax.line(to: NSPoint(x: s*0.94, y: s*0.08)); ax.stroke() }
print("icons ok")
