import AppKit
import Foundation
let fm = FileManager.default
let source = URL(fileURLWithPath: "test-build/exercise-images")
let target = URL(fileURLWithPath: "res/exercises")
var count = 0
for url in try fm.contentsOfDirectory(at: source, includingPropertiesForKeys: nil) where url.pathExtension == "jpg" {
 let dest = target.appendingPathComponent(url.lastPathComponent)
 if fm.fileExists(atPath: dest.path) { continue }
 try autoreleasepool {
  guard let image = NSImage(contentsOf: url) else { throw NSError(domain: "decode", code: 1) }
  let ratio = min(1, 640 / max(image.size.width, image.size.height))
  let w = Int(image.size.width * ratio), h = Int(image.size.height * ratio)
  let bitmap = NSBitmapImageRep(bitmapDataPlanes:nil, pixelsWide:w, pixelsHigh:h, bitsPerSample:8, samplesPerPixel:3, hasAlpha:false, isPlanar:false, colorSpaceName:.deviceRGB, bytesPerRow:0, bitsPerPixel:0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep:bitmap)
  image.draw(in:NSRect(x:0,y:0,width:w,height:h))
  NSGraphicsContext.restoreGraphicsState()
  try bitmap.representation(using:.jpeg, properties:[.compressionFactor:0.72])!.write(to:dest, options:.atomic)
 }
 count += 1
}
print("Resized \(count) new exercise photos")
