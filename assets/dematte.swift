import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Remove a leftover near-white matte from a PNG that already has alpha:
// pixels that are both light and desaturated become fully transparent, and the
// remaining alpha gets a small gain so soft edges survive without a grey halo.
// usage: swift dematte.swift <in.png> <out.png>

let args = CommandLine.arguments
guard args.count >= 3 else { exit(64) }
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])

guard let src = CGImageSourceCreateWithURL(inURL as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { exit(65) }

let w = img.width, h = img.height
var data = [UInt8](repeating: 0, count: w * h * 4)
guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8,
                          bytesPerRow: w * 4, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(66) }
ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))

var cleared = 0
for i in stride(from: 0, to: data.count, by: 4) {
    let a = data[i + 3]
    guard a > 0 else { continue }
    // premultiplied, so un-premultiply before judging colour
    let af = Double(a) / 255.0
    let r = Double(data[i]) / af, g = Double(data[i + 1]) / af, b = Double(data[i + 2]) / af
    let maxc = max(r, max(g, b)), minc = min(r, min(g, b))
    let light = minc > 232                       // near-white
    let flat = (maxc - minc) < 14                 // near-grey (no colour in the subject)
    if light && flat {
        data[i] = 0; data[i + 1] = 0; data[i + 2] = 0; data[i + 3] = 0
        cleared += 1
        continue
    }
    if a < 250 {                                   // firm up the soft edge
        let boosted = min(255.0, Double(a) * 1.25)
        let f = boosted / Double(a)
        data[i] = UInt8(min(255, Double(data[i]) * f))
        data[i + 1] = UInt8(min(255, Double(data[i + 1]) * f))
        data[i + 2] = UInt8(min(255, Double(data[i + 2]) * f))
        data[i + 3] = UInt8(boosted)
    }
}

guard let out = ctx.makeImage() else { exit(67) }
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(68) }
CGImageDestinationAddImage(dest, out, nil)
if CGImageDestinationFinalize(dest) {
    print("cleared \(cleared) matte pixels → \(outURL.path)")
} else { exit(69) }
