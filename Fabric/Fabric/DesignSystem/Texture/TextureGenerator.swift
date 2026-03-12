import SwiftUI
import CoreGraphics

enum TextureGenerator {

    private static let baseTilePoints: CGFloat = 64

    private static let cache: NSCache<NSString, CGImage> = {
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
    static func linenPaint(
        displayScale: CGFloat,
        intensity: CGFloat = 0.04,
        seed: Int = 42
    ) -> ImagePaint {
        let image = linenImage(displayScale: displayScale, intensity: intensity, seed: seed)
        return ImagePaint(image: image)
    }

    @MainActor
    static func linenImage(
        displayScale: CGFloat,
        intensity: CGFloat = 0.04,
        seed: Int = 42
    ) -> Image {
        let cgImage = linenCGImage(displayScale: displayScale, intensity: intensity, seed: seed)
        return Image(cgImage, scale: displayScale, label: Text("Fabric texture"))
    }

    // MARK: - Core Generation

    static func linenCGImage(
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

                // Deterministic hash noise → 0...1
                let n = noise(x: x, y: y, seed: seed)

                // Weave modulation: every 3rd row/col gets 1.3x intensity
                let weave = weaveWeight(x: x, y: y, spacing: 3)

                // Signed deviation from 0.5 midpoint
                let deviation = (n - 0.5) * 2.0 * weave

                // Map to RGBA: white pixels for positive deviation, black for negative
                let alpha = abs(deviation) * intensity

                if deviation > 0 {
                    // White pixel at low opacity
                    let premultiplied = UInt8(min(alpha * 255, 255))
                    buffer[offset + 0] = premultiplied  // R
                    buffer[offset + 1] = premultiplied  // G
                    buffer[offset + 2] = premultiplied  // B
                    buffer[offset + 3] = premultiplied  // A
                } else {
                    // Black pixel at low opacity
                    buffer[offset + 0] = 0  // R
                    buffer[offset + 1] = 0  // G
                    buffer[offset + 2] = 0  // B
                    buffer[offset + 3] = UInt8(min(alpha * 255, 255))  // A
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

    /// Weave modulation: every Nth row/col gets boosted intensity
    private static func weaveWeight(x: Int, y: Int, spacing: Int) -> Float {
        let rowThread: Float = (y % spacing == 0) ? 1.3 : 1.0
        let colThread: Float = (x % spacing == 0) ? 1.3 : 1.0
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
