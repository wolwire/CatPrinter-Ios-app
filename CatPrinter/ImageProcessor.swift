import CoreImage
import UIKit

/// Image processing utilities: resize, grayscale, dithering
final class ImageProcessor {
  let printWidth = 384

  func preview(uiImage: UIImage, algorithm: String) throws -> UIImage? {
    guard let bin = try binarizeForPrint(uiImage: uiImage, algorithm: algorithm) else { return nil }
    // Convert Bool 2D array to UIImage for preview
    return imageFromBoolArray(bin)
  }

  func binarizeForPrint(uiImage: UIImage, algorithm: String) throws -> [[Bool]]? {
    guard let gray = uiImage.toGrayscale() else { return nil }
    // Resize to print width
    let scaled = gray.resizeMaintainingAspect(width: printWidth)
    guard var pixels = scaled.pixelBuffer() else { return nil }
    let h = pixels.count
    let w = pixels[0].count

    switch algorithm {
    case "mean-threshold":
      // Compute mean as Int to avoid UInt8/Int mixing
      let sum = pixels.flatMap { row in row.map { Int($0) } }.reduce(0, +)
      let mean = sum / (h * w)
      var out = Array(repeating: Array(repeating: false, count: w), count: h)
      for y in 0..<h { for x in 0..<w { out[y][x] = Int(pixels[y][x]) < mean } }
      return out
    case "floyd-steinberg":
      // apply in-place
      floydSteinberg(&pixels)
      return boolArrayFromPixels(pixels)
    case "atkinson":
      atkinson(&pixels)
      return boolArrayFromPixels(pixels)
    case "none":
      // Only valid if width == printWidth
      if w == printWidth {
        return boolArrayFromPixels(pixels)
      }
      return nil
    default:
      return nil
    }
  }

  /// Applies contrast and brightness adjustments using Core Image and returns a new UIImage.
  /// - contrast: 0.5..2.0 (1.0 = no change)
  /// - brightness: -1.0..1.0 (0 = no change)
  func applyContrastBrightness(uiImage: UIImage, contrast: Double, brightness: Double) throws
    -> UIImage
  {
    guard let cg = uiImage.cgImage else { return uiImage }
    let ciImage = CIImage(cgImage: cg)
    guard let filter = CIFilter(name: "CIColorControls") else { return uiImage }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(contrast, forKey: kCIInputContrastKey)
    filter.setValue(brightness, forKey: kCIInputBrightnessKey)

    let context = CIContext(options: nil)
    guard let output = filter.outputImage else { return uiImage }
    guard let outCG = context.createCGImage(output, from: output.extent) else { return uiImage }
    return UIImage(cgImage: outCG, scale: uiImage.scale, orientation: uiImage.imageOrientation)
  }

  // MARK: - Pixel helpers
  private func boolArrayFromPixels(_ pixels: [[UInt8]]) -> [[Bool]] {
    let h = pixels.count
    let w = pixels[0].count
    var out = Array(repeating: Array(repeating: false, count: w), count: h)
    for y in 0..<h { for x in 0..<w { out[y][x] = pixels[y][x] < 128 } }
    return out
  }

  private func imageFromBoolArray(_ arr: [[Bool]]) -> UIImage? {
    let h = arr.count
    let w = arr[0].count
    let colorSpace = CGColorSpaceCreateDeviceGray()
    var data = Data(count: w * h)
    data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
      guard let base = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
      for y in 0..<h {
        for x in 0..<w {
          let idx = y * w + x
          base[idx] = arr[y][x] ? 0 : 255
        }
      }
    }
    guard let provider = CGDataProvider(data: data as CFData) else { return nil }
    guard
      let cg = CGImage(
        width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: w,
        space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: 0), provider: provider, decode: nil,
        shouldInterpolate: false, intent: .defaultIntent)
    else { return nil }
    return UIImage(cgImage: cg)
  }

  // MARK: - Dithering algorithms
  private func floydSteinberg(_ img: inout [[UInt8]]) {
    let h = img.count
    let w = img[0].count
    func adjust(_ y: Int, _ x: Int, _ delta: Int) {
      if y < 0 || y >= h || x < 0 || x >= w { return }
      let val = Int(img[y][x]) + delta
      img[y][x] = UInt8(max(0, min(255, val)))
    }
    for y in 0..<h {
      for x in 0..<w {
        let old = Int(img[y][x])
        let newv = old > 127 ? 255 : 0
        let err = old - newv
        img[y][x] = UInt8(newv)
        adjust(y, x + 1, Int(Double(err) * 7.0 / 16.0))
        adjust(y + 1, x - 1, Int(Double(err) * 3.0 / 16.0))
        adjust(y + 1, x, Int(Double(err) * 5.0 / 16.0))
        adjust(y + 1, x + 1, Int(Double(err) * 1.0 / 16.0))
      }
    }
  }

  private func atkinson(_ img: inout [[UInt8]]) {
    let h = img.count
    let w = img[0].count
    func adjust(_ y: Int, _ x: Int, _ delta: Int) {
      if y < 0 || y >= h || x < 0 || x >= w { return }
      let val = Int(img[y][x]) + delta
      img[y][x] = UInt8(max(0, min(255, val)))
    }
    for y in 0..<h {
      for x in 0..<w {
        let old = Int(img[y][x])
        let newv = old > 127 ? 255 : 0
        let err = old - newv
        img[y][x] = UInt8(newv)
        let share = Int(Double(err) / 8.0)
        adjust(y, x + 1, share)
        adjust(y, x + 2, share)
        adjust(y + 1, x - 1, share)
        adjust(y + 1, x, share)
        adjust(y + 1, x + 1, share)
        adjust(y + 2, x, share)
      }
    }
  }
}

// MARK: - UIImage helpers
extension UIImage {
  func toGrayscale() -> UIImage? {
    guard let cg = self.cgImage else { return nil }
    let colorSpace = CGColorSpaceCreateDeviceGray()
    guard
      let ctx = CGContext(
        data: nil, width: cg.width, height: cg.height, bitsPerComponent: 8, bytesPerRow: cg.width,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
    else { return nil }
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
    guard let cgImage = ctx.makeImage() else { return nil }
    return UIImage(cgImage: cgImage)
  }

  func resizeMaintainingAspect(width: Int) -> UIImage {
    guard let cg = self.cgImage else { return self }
    let h = Int(Double(cg.height) * Double(width) / Double(cg.width))
    let size = CGSize(width: width, height: h)
    UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
    self.draw(in: CGRect(origin: .zero, size: size))
    let out = UIGraphicsGetImageFromCurrentImageContext() ?? self
    UIGraphicsEndImageContext()
    return out
  }

  /// Returns a 2D array of UInt8 grayscale pixels (0..255)
  func pixelBuffer() -> [[UInt8]]? {
    guard let cg = self.cgImage else { return nil }
    let w = cg.width
    let h = cg.height
    let bytesPerRow = w
    var data = Data(count: h * bytesPerRow)
    let colorSpace = CGColorSpaceCreateDeviceGray()
    data.withUnsafeMutableBytes { ptr in
      if let base = ptr.baseAddress {
        let ctx = CGContext(
          data: base, width: w, height: h, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
          space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        ctx?.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
      }
    }
    var rows: [[UInt8]] = []
    data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
      let base = ptr.bindMemory(to: UInt8.self).baseAddress!
      for y in 0..<h {
        var row: [UInt8] = []
        row.reserveCapacity(w)
        for x in 0..<w {
          row.append(base[y * bytesPerRow + x])
        }
        rows.append(row)
      }
    }
    return rows
  }

  /// Rotate image by degrees (clockwise positive)
  func rotated(byDegrees degrees: CGFloat) -> UIImage {
    let radians = degrees * .pi / 180
    var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(
      CGAffineTransform(rotationAngle: radians)
    ).integral.size
    // Avoid odd sized contexts which can cause issues
    if Int(newSize.width) % 2 != 0 { newSize.width += 1 }
    if Int(newSize.height) % 2 != 0 { newSize.height += 1 }

    UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
    guard let ctx = UIGraphicsGetCurrentContext() else { return self }
    // Move origin to middle
    ctx.translateBy(x: newSize.width / 2, y: newSize.height / 2)
    // Rotate around middle
    ctx.rotate(by: radians)
    // Draw the image centered
    self.draw(
      in: CGRect(
        x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width,
        height: self.size.height))
    let rotated = UIGraphicsGetImageFromCurrentImageContext() ?? self
    UIGraphicsEndImageContext()
    return rotated
  }
}
