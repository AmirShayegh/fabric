import SwiftUI
import CoreGraphics

public enum TextureGenerator {

    /// Which weave pattern to synthesize.
    /// - `linen`: isotropic warp/weft noise — the default surface grain.
    /// - `paper`: directional fibers + sparse warm flecks, reads as handmade paper
    ///   rather than cloth. Use under editorial long-form layouts.
    public enum Weave: Hashable {
        case linen
        case paper
    }

    private static let baseTilePoints: CGFloat = 128

    nonisolated(unsafe) private static let cache: NSCache<NSString, CGImage> = {
        let c = NSCache<NSString, CGImage>()
        c.countLimit = 12
        c.totalCostLimit = 6 * 1024 * 1024  // 6 MB — two weaves × a few scales
        return c
    }()

    /// Generate a tileable fabric texture as an ImagePaint.
    ///
    /// The texture is a transparent RGBA overlay composited with normal blend
    /// mode over any base color.
    @MainActor
    public static func linenPaint(
        displayScale: CGFloat,
        intensity: CGFloat = 0.04,
        seed: Int = 42,
        weave: Weave = .linen
    ) -> ImagePaint {
        let image = linenImage(displayScale: displayScale, intensity: intensity, seed: seed, weave: weave)
        return ImagePaint(image: image)
    }

    @MainActor
    public static func linenImage(
        displayScale: CGFloat,
        intensity: CGFloat = 0.04,
        seed: Int = 42,
        weave: Weave = .linen
    ) -> Image {
        let cgImage = linenCGImage(displayScale: displayScale, intensity: intensity, seed: seed, weave: weave)
        return Image(cgImage, scale: displayScale, label: Text("Fabric texture"))
    }

    // MARK: - Core Generation

    public static func linenCGImage(
        displayScale: CGFloat,
        intensity: CGFloat = 0.04,
        seed: Int = 42,
        weave: Weave = .linen
    ) -> CGImage {
        let pixelSize = max(1, min(512, Int(round(baseTilePoints * displayScale))))
        let key = "\(pixelSize)-\(intensity)-\(seed)-\(weave)" as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        let cgImage = generateTile(pixelSize: pixelSize, intensity: Float(intensity), seed: seed, weave: weave)
        cache.setObject(cgImage, forKey: key, cost: pixelSize * pixelSize * 4)
        return cgImage
    }

    // MARK: - Bitmap Generation

    private static func generateTile(pixelSize: Int, intensity: Float, seed: Int, weave: Weave) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let ctx = CGContext(
            data: nil,
            width: pixelSize,
            height: pixelSize,
            bitsPerComponent: 8,
            bytesPerRow: pixelSize * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ), let data = ctx.data else {
            // Fallback: 1x1 clear pixel
            return createFallbackImage()
        }

        let buffer = data.bindMemory(to: UInt8.self, capacity: pixelSize * pixelSize * 4)

        for y in 0..<pixelSize {
            for x in 0..<pixelSize {
                let offset = (y * pixelSize + x) * 4

                // Deterministic hash noise → 0...1
                let n = noise(x: x, y: y, seed: seed)

                // Modulation depends on weave pattern
                let modulation: Float
                switch weave {
                case .linen:
                    // Every 2nd row/col gets boosted — warp/weft crossings
                    modulation = weaveWeight(x: x, y: y, spacing: 2)
                case .paper:
                    // Long horizontal fibers + slow vertical drift. The `fiberRun`
                    // value is coherent across ~8-pixel runs so streaks read as
                    // handmade-paper grain rather than cloth weave.
                    modulation = paperWeight(x: x, y: y, seed: seed)
                }

                // Signed deviation from 0.5 midpoint
                let deviation = (n - 0.5) * 2.0 * modulation

                // Map to warm-tinted RGBA: cream highlights, warm brown shadows
                let alpha = abs(deviation) * intensity

                if deviation > 0 {
                    // Warm cream highlight (not pure white)
                    let a = UInt8(min(alpha * 255, 255))
                    buffer[offset + 0] = a       // R (full)
                    buffer[offset + 1] = UInt8(min(Float(a) * 0.96, 255))  // G (slightly less)
                    buffer[offset + 2] = UInt8(min(Float(a) * 0.90, 255))  // B (warm tint)
                    buffer[offset + 3] = a       // A
                } else {
                    // Warm brown shadow (not pure black)
                    let a = UInt8(min(alpha * 255, 255))
                    let tint = UInt8(min(Float(a) * 0.12, 255))
                    buffer[offset + 0] = tint    // R (slight warmth)
                    buffer[offset + 1] = UInt8(min(Float(tint) * 0.7, 255))  // G
                    buffer[offset + 2] = 0       // B
                    buffer[offset + 3] = a       // A
                }

                // Paper-only: sparse warm flecks — tiny amber specks from the pulp.
                // Only fire for ~0.3% of pixels, and only add, never overwrite.
                if weave == .paper {
                    let flk = noise(x: x &+ 9173, y: y &+ 4271, seed: seed &+ 7)
                    if flk > 0.997 {
                        let speckAlpha = UInt8(min(Float(60), 255))
                        buffer[offset + 0] = max(buffer[offset + 0], UInt8(min(Float(140), 255)))
                        buffer[offset + 1] = max(buffer[offset + 1], UInt8(min(Float(90),  255)))
                        buffer[offset + 2] = max(buffer[offset + 2], UInt8(min(Float(40),  255)))
                        buffer[offset + 3] = max(buffer[offset + 3], speckAlpha)
                    }
                }
            }
        }

        return ctx.makeImage() ?? createFallbackImage()
    }

    // MARK: - Noise

    /// Deterministic hash noise: maps (x, y, seed) to 0...1
    private static func noise(x: Int, y: Int, seed: Int) -> Float {
        var h = x &* 374761393 &+ y &* 668265263 &+ seed &* 1274126177
        h = (h ^ (h >> 13)) &* 1103515245
        h = h ^ (h >> 16)
        return Float(abs(h) % 10000) / 10000.0
    }

    /// Weave modulation: every Nth row/col gets boosted intensity.
    /// Simulates warp/weft thread crossings in woven cloth.
    private static func weaveWeight(x: Int, y: Int, spacing: Int) -> Float {
        let rowThread: Float = (y % spacing == 0) ? 1.5 : 1.0
        let colThread: Float = (x % spacing == 0) ? 1.5 : 1.0
        return rowThread * colThread
    }

    /// Paper modulation: strongly anisotropic. Produces horizontal fiber streaks
    /// (grain runs with a dominant direction in handmade paper), punctuated by
    /// mid-frequency clumps. Output ~0.6 … 2.2.
    private static func paperWeight(x: Int, y: Int, seed: Int) -> Float {
        // A row-coherent value: every ~8-pixel band shares a noise sample, so
        // fibers read as streaks instead of isotropic speckle.
        let bandY = y / 8
        let fiberRun = noise(x: x / 3, y: bandY, seed: seed &+ 101)

        // Slow vertical drift: low-freq modulation so the streak density varies
        // gently down the page rather than being uniform.
        let drift = noise(x: x / 16, y: y / 16, seed: seed &+ 211)

        // Strong horizontal bias (1.6) + variation from the streak + drift.
        return 1.6 * fiberRun + 0.5 * drift + 0.2
    }

    // MARK: - Fallback

    private static func createFallbackImage() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0))
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        return ctx.makeImage()!
    }
}
