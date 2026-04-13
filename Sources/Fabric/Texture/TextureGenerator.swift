import SwiftUI
import CoreGraphics

public enum TextureGenerator {

    private static let baseTilePoints: CGFloat = 64

    nonisolated(unsafe) private static let cache: NSCache<NSString, CGImage> = {
        let c = NSCache<NSString, CGImage>()
        c.countLimit = 8
        c.totalCostLimit = 4 * 1024 * 1024  // 4 MB
        return c
    }()

    /// Generate a tileable linen/fabric texture as an ImagePaint.
    ///
    /// The texture is a transparent RGBA overlay of subtle noise with weave modulation.
    /// Composited with normal blend mode over any base color.
    @MainActor
    public static func linenPaint(
        displayScale: CGFloat,
        intensity: CGFloat = 0.04,
        seed: Int = 42
    ) -> ImagePaint {
        let image = linenImage(displayScale: displayScale, intensity: intensity, seed: seed)
        return ImagePaint(image: image)
    }

    @MainActor
    public static func linenImage(
        displayScale: CGFloat,
        intensity: CGFloat = 0.04,
        seed: Int = 42
    ) -> Image {
        let cgImage = linenCGImage(displayScale: displayScale, intensity: intensity, seed: seed)
        return Image(cgImage, scale: displayScale, label: Text("Fabric texture"))
    }

    // MARK: - Core Generation

    public static func linenCGImage(
        displayScale: CGFloat,
        intensity: CGFloat = 0.04,
        seed: Int = 42
    ) -> CGImage {
        let pixelSize = max(1, min(512, Int(round(baseTilePoints * displayScale))))
        let key = "\(pixelSize)-\(intensity)-\(seed)" as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        let cgImage = generateTile(pixelSize: pixelSize, intensity: Float(intensity), seed: seed)
        cache.setObject(cgImage, forKey: key, cost: pixelSize * pixelSize * 4)
        return cgImage
    }

    // MARK: - Bitmap Generation

    private static func generateTile(pixelSize: Int, intensity: Float, seed: Int) -> CGImage {
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

                // Tileable noise: blend with wrapped samples near edges
                // so opposite edges produce matching values
                let n = tileableNoise(x: x, y: y, size: pixelSize, seed: seed)

                // Weave modulation: every 2nd row/col gets boosted.
                // Spacing 2 tiles seamlessly for even-sized tiles.
                let weave = weaveWeight(x: x, y: y, spacing: 2)

                // Signed deviation from 0.5 midpoint
                let deviation = (n - 0.5) * 2.0 * weave

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

    /// Tileable noise: near tile edges, cross-fade between the base sample
    /// and the wrapped sample so opposite edges produce matching values.
    /// Uses cosine interpolation for a smooth blend within a border margin.
    private static func tileableNoise(x: Int, y: Int, size: Int, seed: Int) -> Float {
        let margin = max(4, size / 8)
        let n00 = noise(x: x, y: y, seed: seed)
        let n10 = noise(x: x + size, y: y, seed: seed)
        let n01 = noise(x: x, y: y + size, seed: seed)
        let n11 = noise(x: x + size, y: y + size, seed: seed)

        // Blend factor: 0 at center, 1 at edge (cosine curve for smoothness)
        func blend(_ coord: Int) -> Float {
            if coord < margin {
                let t = Float(margin - coord) / Float(margin)
                return (1.0 - cosf(t * .pi)) * 0.5
            } else if coord >= size - margin {
                let t = Float(coord - (size - margin)) / Float(margin)
                return (1.0 - cosf(t * .pi)) * 0.5
            }
            return 0.0
        }

        let bx = blend(x)
        let by = blend(y)

        // Bilinear cross-fade between all four wrapped samples
        let top = n00 * (1.0 - bx) + n10 * bx
        let bottom = n01 * (1.0 - bx) + n11 * bx
        return top * (1.0 - by) + bottom * by
    }

    /// Weave modulation: every Nth row/col gets boosted intensity.
    /// Simulates warp/weft thread crossings in woven cloth.
    private static func weaveWeight(x: Int, y: Int, spacing: Int) -> Float {
        let rowThread: Float = (y % spacing == 0) ? 1.5 : 1.0
        let colThread: Float = (x % spacing == 0) ? 1.5 : 1.0
        return rowThread * colThread
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
