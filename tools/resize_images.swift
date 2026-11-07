import Foundation
import ImageIO
import CoreGraphics
// ImageIO avoids AppKit's offscreen drawing path, which produced blank JPEGs.
let fm = FileManager.default
let source = URL(fileURLWithPath: "test-build/exercise-images")
let target = URL(fileURLWithPath: "res/exercises")
func range(_ image: CGImage) -> Int {
 var bytes = [UInt8](repeating: 0, count: 16 * 16 * 4)
 return bytes.withUnsafeMutableBytes { raw in
  guard let c = CGContext(data: raw.baseAddress, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 64, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return 0 }
  c.draw(image, in: CGRect(x:0,y:0,width:16,height:16))
  let p = raw.bindMemory(to: UInt8.self)
  var lo = 255, hi = 0
  for i in 0..<256 { for channel in 0..<3 { let v = Int(p[i*4+channel]);lo=min(lo,v);hi=max(hi,v) } }
  return hi-lo
 }
}
if CommandLine.arguments.contains("--verify-only") {
 var checked=0
 for url in try fm.contentsOfDirectory(at: target, includingPropertiesForKeys:nil) where url.pathExtension == "jpg" {
  try autoreleasepool {
   guard let input=CGImageSourceCreateWithURL(url as CFURL,nil),let image=CGImageSourceCreateImageAtIndex(input,0,nil),range(image)>20 else { throw NSError(domain:"blank-image",code:4,userInfo:[NSFilePathErrorKey:url.path]) }
  }
  checked+=1
 }
 print("Verified \(checked) bundled exercise photos")
 exit(0)
}
var count = 0
for url in try fm.contentsOfDirectory(at: source, includingPropertiesForKeys: nil).sorted(by: { $0.path < $1.path }) where url.pathExtension == "jpg" {
 try autoreleasepool {
  guard let input = CGImageSourceCreateWithURL(url as CFURL,nil),
        let image = CGImageSourceCreateThumbnailAtIndex(input,0,[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceThumbnailMaxPixelSize:640,kCGImageSourceCreateThumbnailWithTransform:true] as CFDictionary), range(image)>20 else { throw NSError(domain:"decode-or-blank",code:1,userInfo:[NSFilePathErrorKey:url.path]) }
  let data=NSMutableData()
  guard let output=CGImageDestinationCreateWithData(data,"public.jpeg" as CFString,1,nil) else { throw NSError(domain:"encode",code:2) }
  CGImageDestinationAddImage(output,image,[kCGImageDestinationLossyCompressionQuality:0.72] as CFDictionary)
  guard CGImageDestinationFinalize(output), let check=CGImageSourceCreateWithData(data,nil),let decoded=CGImageSourceCreateImageAtIndex(check,0,nil),range(decoded)>20 else { throw NSError(domain:"verify",code:3) }
  try (data as Data).write(to:target.appendingPathComponent(url.lastPathComponent),options:.atomic)
 }
 count+=1
}
print("Converted and verified \(count) exercise photos; decoded pixels are not blank")
