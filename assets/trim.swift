import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Trim fully transparent margins from a PNG, keeping a small padding.
// usage: swift trim.swift <in.png> <out.png> [pad]

let args = CommandLine.arguments
guard args.count >= 3 else { exit(64) }
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])
let pad = args.count > 3 ? Int(args[3]) ?? 0 : 0

guard let src = CGImageSourceCreateWithURL(inURL as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { exit(65) }

let w = img.width, h = img.height
var data = [UInt8](repeating: 0, count: w * h * 4)
guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8,
                          bytesPerRow: w * 4, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(66) }
ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))

var minX = w, minY = h, maxX = -1, maxY = -1
for y in 0..<h {
    let row = y * w * 4
    for x in 0..<w where data[row + x * 4 + 3] > 8 {
        if x < minX { minX = x }
        if x > maxX { maxX = x }
        if y < minY { minY = y }
        if y > maxY { maxY = y }
    }
}
guard maxX >= minX, maxY >= minY else { exit(67) }

// CoreGraphics origin is bottom-left; convert to top-left cropping coords
let cropTop = max(0, h - 1 - maxY - pad)
let cropHeight = min(h - cropTop, (maxY - minY + 1) + pad * 2)
let cropLeft = max(0, minX - pad)
let cropWidth = min(w - cropLeft, (maxX - minX + 1) + pad * 2)

guard let cropped = img.cropping(to: CGRect(x: cropLeft, y: cropTop, width: cropWidth, height: cropHeight)) else { exit(68) }
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(69) }
CGImageDestinationAddImage(dest, cropped, nil)
if CGImageDestinationFinalize(dest) {
    print("trimmed to \(cropped.width)x\(cropped.height) (from \(w)x\(h))")
} else { exit(70) }
