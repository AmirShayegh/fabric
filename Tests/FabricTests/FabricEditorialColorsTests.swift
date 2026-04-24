import XCTest
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
@testable import Fabric

/// Round-trip tests for the editorial palette tokens.
///
/// Source of truth: `web/src/app/globals.css` in the CPM repo -- light-mode block
/// and the `@media (prefers-color-scheme: dark)` block. Each token resolves to a
/// distinct hex per appearance; these tests catch hex typos and light/dark swaps.
final class FabricEditorialColorsTests: XCTestCase {

    // (token keyPath, light hex, dark hex) -- every light value verified against
    // globals.css lines 66-79 and dark against lines 140-153.
    private static let spec: [(name: String, color: Color, light: UInt32, dark: UInt32)] = [
        ("editorialInk",             FabricColors.editorialInk,             0x1C1A17, 0xF4EDE0),
        ("editorialInkSoft",         FabricColors.editorialInkSoft,         0x2B2722, 0xDFD3BA),
        ("editorialParchment",       FabricColors.editorialParchment,       0xF4EDE0, 0x1C1A17),
        ("editorialParchmentDeep",   FabricColors.editorialParchmentDeep,   0xEADFC9, 0x26221E),
        ("editorialParchmentDim",    FabricColors.editorialParchmentDim,    0xDFD3BA, 0x2B2722),
        ("editorialOchre",           FabricColors.editorialOchre,           0xC48A3E, 0xD9A055),
        ("editorialOchreDeep",       FabricColors.editorialOchreDeep,       0x9A6A2C, 0xBD8338),
        ("editorialThread",          FabricColors.editorialThread,          0x905830, 0xC48568),
        ("editorialMoss",            FabricColors.editorialMoss,            0x5F6B4A, 0x8A9668),
        ("editorialRust",            FabricColors.editorialRust,            0xA84F2E, 0xC76A4A),
        ("editorialColdBg",          FabricColors.editorialColdBg,          0xE4E2DD, 0x2A2D31),
        ("editorialColdInk",         FabricColors.editorialColdInk,         0x3B3E42, 0xD1D3D6),
    ]

    func test_editorialTokens_roundTripLightHex() {
        for entry in Self.spec {
            assertColor(entry.color, matchesHex: entry.light, appearance: .light, name: entry.name)
        }
    }

    func test_editorialTokens_roundTripDarkHex() {
        for entry in Self.spec {
            assertColor(entry.color, matchesHex: entry.dark, appearance: .dark, name: entry.name)
        }
    }

    // MARK: - Helpers

    private enum Appearance { case light, dark }

    private func assertColor(
        _ color: Color,
        matchesHex hex: UInt32,
        appearance: Appearance,
        name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expected = components(of: hex)
        let actual = resolve(color, in: appearance, name: name, file: file, line: line)
        guard let actual else { return }

        // 1/255 tolerance -- hex -> RGB is lossless, but sRGB/display-RGB
        // conversions inside NSColor/UIColor can introduce sub-ULP drift.
        let tolerance: CGFloat = 1.5 / 255.0
        XCTAssertEqual(actual.r, expected.r, accuracy: tolerance,
                       "\(name) red (\(appearance)) expected #\(String(format: "%06X", hex))", file: file, line: line)
        XCTAssertEqual(actual.g, expected.g, accuracy: tolerance,
                       "\(name) green (\(appearance)) expected #\(String(format: "%06X", hex))", file: file, line: line)
        XCTAssertEqual(actual.b, expected.b, accuracy: tolerance,
                       "\(name) blue (\(appearance)) expected #\(String(format: "%06X", hex))", file: file, line: line)
    }

    private func components(of hex: UInt32) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        (
            r: CGFloat((hex >> 16) & 0xFF) / 255.0,
            g: CGFloat((hex >> 8) & 0xFF) / 255.0,
            b: CGFloat(hex & 0xFF) / 255.0
        )
    }

    #if canImport(AppKit)
    private func resolve(
        _ color: Color,
        in appearance: Appearance,
        name: String,
        file: StaticString,
        line: UInt
    ) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
        let appearanceName: NSAppearance.Name = (appearance == .dark) ? .darkAqua : .aqua
        guard let namedAppearance = NSAppearance(named: appearanceName) else {
            XCTFail("\(appearanceName.rawValue) appearance missing on host", file: file, line: line)
            return nil
        }
        var components: (r: CGFloat, g: CGFloat, b: CGFloat)?
        namedAppearance.performAsCurrentDrawingAppearance {
            let ns = NSColor(color).usingColorSpace(.sRGB)
            guard let ns else {
                XCTFail("\(name): cannot convert to sRGB", file: file, line: line)
                return
            }
            components = (r: ns.redComponent, g: ns.greenComponent, b: ns.blueComponent)
        }
        if components == nil {
            XCTFail("\(name): drawing block did not populate components", file: file, line: line)
        }
        return components
    }
    #elseif canImport(UIKit)
    private func resolve(
        _ color: Color,
        in appearance: Appearance,
        name: String,
        file: StaticString,
        line: UInt
    ) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
        let style: UIUserInterfaceStyle = (appearance == .dark) ? .dark : .light
        let traits = UITraitCollection(userInterfaceStyle: style)
        var components: (r: CGFloat, g: CGFloat, b: CGFloat)?
        traits.performAsCurrent {
            let resolved = UIColor(color).resolvedColor(with: traits)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else {
                XCTFail("\(name): getRed failed", file: file, line: line)
                return
            }
            components = (r: r, g: g, b: b)
        }
        if components == nil {
            XCTFail("\(name): trait block did not populate components", file: file, line: line)
        }
        return components
    }
    #endif
}
