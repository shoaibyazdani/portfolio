import Foundation
import CoreGraphics
import ImageIO

// Report whether the background is really transparent: corner alphas + alpha bbox.
// usage: swift alphacheck.swift <image>
let path = CommandLine.arguments[1]
guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { exit(65) }
let w = img.width, h = img.height
var data = [UInt8](repeating: 0, count: w * h * 4)
guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8,
                          bytesPerRow: w * 4, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(66) }
ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))

func alpha(_ x: Int, _ y: Int) -> UInt8 { data[(y * w + x) * 4 + 3] }
var transparent = 0, opaque = 0
for y in stride(from: 0, to: h, by: 4) {
    for x in stride(from: 0, to: w, by: 4) {
        let a = alpha(x, y)
        if a < 16 { transparent += 1 } else if a > 239 { opaque += 1 }
    }
}
print("size \(w)x\(h) alphaInfo=\(img.alphaInfo.rawValue)")
print("corners: TL=\(alpha(2,2)) TR=\(alpha(w-3,2)) BL=\(alpha(2,h-3)) BR=\(alpha(w-3,h-3))")
print("sampled: transparent=\(transparent) opaque=\(opaque)")
print("transparent share: \(String(format: "%.1f", 100.0 * Double(transparent) / Double(transparent + opaque)))%")
