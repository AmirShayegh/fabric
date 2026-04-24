import XCTest
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
@testable import Fabric

/// Round-trip tests for the v1.4.0 editorial `FabricAccent` cases. Asserts
/// that `foreground` resolves to the exact designer hex on a light appearance
/// (the same hex tested in `FabricEditorialColorsTests`), so call sites like
/// `FabricTaskCard.Tag(accent: .editorialThread)` get brand-consistent color.
final class FabricEditorialAccentCasesTests: XCTestCase {

    private static let spec: [(name: String, accent: FabricAccent, lightHex: UInt32)] = [
        ("editorialOchre",  .editorialOchre,  0xC48A3E),
        ("editorialThread", .editorialThread, 0x905830),
        ("editorialMoss",   .editorialMoss,   0x5F6B4A),
        ("editorialRust",   .editorialRust,   0xA84F2E),
    ]

    func test_editorialAccentForeground_resolvesToHexInLightMode() {
        #if canImport(AppKit)
        guard let aqua = NSAppearance(named: .aqua) else {
            XCTFail("aqua appearance missing on host")
            return
        }
        for entry in Self.spec {
            var observed: (r: CGFloat, g: CGFloat, b: CGFloat)?
            aqua.performAsCurrentDrawingAppearance {
                guard let ns = NSColor(entry.accent.foreground).usingColorSpace(.sRGB) else {
                    XCTFail("\(entry.name): cannot convert to sRGB")
                    return
                }
                observed = (ns.redComponent, ns.greenComponent, ns.blueComponent)
            }
            guard let rgb = observed else {
                XCTFail("\(entry.name): drawing block did not populate components")
                continue
            }
            assertRGBMatches(name: entry.name, rgb: rgb, hex: entry.lightHex)
        }
        #elseif canImport(UIKit)
        let trait = UITraitCollection(userInterfaceStyle: .light)
        for entry in Self.spec {
            let ui = UIColor(entry.accent.foreground).resolvedColor(with: trait)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            ui.getRed(&r, green: &g, blue: &b, alpha: &a)
            assertRGBMatches(name: entry.name, rgb: (r, g, b), hex: entry.lightHex)
        }
        #endif
    }

    private func assertRGBMatches(name: String, rgb: (r: CGFloat, g: CGFloat, b: CGFloat), hex: UInt32) {
        let expected: (r: CGFloat, g: CGFloat, b: CGFloat) = (
            r: CGFloat((hex >> 16) & 0xFF) / 255.0,
            g: CGFloat((hex >> 8) & 0xFF) / 255.0,
            b: CGFloat(hex & 0xFF) / 255.0
        )
        let tolerance: CGFloat = 1.5 / 255.0
        XCTAssertEqual(rgb.r, expected.r, accuracy: tolerance,
                       "\(name) red expected #\(String(format: "%06X", hex))")
        XCTAssertEqual(rgb.g, expected.g, accuracy: tolerance,
                       "\(name) green expected #\(String(format: "%06X", hex))")
        XCTAssertEqual(rgb.b, expected.b, accuracy: tolerance,
                       "\(name) blue expected #\(String(format: "%06X", hex))")
    }
}
