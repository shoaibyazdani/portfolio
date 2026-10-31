import Foundation
import Vision
import CoreImage
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Cut the foreground subject out of a photo using the same on-device model
// Preview.app uses ("Remove Background"), then write a PNG with alpha.
// usage: swift cutout.swift <in.png> <out.png>

let args = CommandLine.arguments
guard args.count >= 3 else { FileHandle.standardError.write("usage: cutout <in> <out>\n".data(using: .utf8)!); exit(64) }
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])

guard let source = CGImageSourceCreateWithURL(inURL as CFURL, nil),
      let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    FileHandle.standardError.write("cannot read input image\n".data(using: .utf8)!); exit(65)
}

let ci = CIImage(cgImage: cg)
let handler = VNImageRequestHandler(ciImage: ci, options: [:])
let request = VNGenerateForegroundInstanceMaskRequest()

do { try handler.perform([request]) } catch {
    FileHandle.standardError.write("vision failed: \(error)\n".data(using: .utf8)!); exit(66)
}

guard let observation = request.results?.first else {
    FileHandle.standardError.write("no foreground subject found\n".data(using: .utf8)!); exit(67)
}

let maskBuffer: CVPixelBuffer
do {
    maskBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
} catch {
    FileHandle.standardError.write("mask failed: \(error)\n".data(using: .utf8)!); exit(68)
}

let mask = CIImage(cvPixelBuffer: maskBuffer)
guard let blend = CIFilter(name: "CIBlendWithMask") else { exit(69) }
blend.setValue(ci, forKey: kCIInputImageKey)
blend.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
blend.setValue(mask, forKey: kCIInputMaskImageKey)
guard let out = blend.outputImage else { exit(70) }

let ctx = CIContext(options: [.useSoftwareRenderer: false])
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(71) }
if let written = ctx.createCGImage(out, from: out.extent) {
    CGImageDestinationAddImage(dest, written, nil)
    if CGImageDestinationFinalize(dest) {
        print("wrote \(outURL.path)  \(written.width)x\(written.height)")
    } else { exit(72) }
} else { exit(73) }
