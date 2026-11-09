import simd
import Foundation

/// Condensed soup tin, 67 x 101 mm: tinplate body with double-seam rims top and bottom, countersunk easy-open
/// lid with a scored opening, expansion rings, a riveted ring-pull tab, and a printed paper label (invented
/// brand HEARTHWELL) wrapped with a glued overlap seam and rippled over the two rolling beads. The top rim
/// carries a dent and the bottom seam a patch of rust.
public struct CannedSoup: RealAsset {
    public static let id = "canned-soup"
    public static let summary = "Soup tin: double-seam rims, ring-pull lid, printed wrap label with overlap seam, dented rim."
    public static let tags = ["prop", "interior", "pantry", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, studio: true)

    /// Can outer diameter and height in meters.
    public var diameter: Float = 0.067
    public var height: Float = 0.101
    /// Tinplate.
    public var tin: MaterialKey = "metal.steel"
    /// Printed label (brand field tint).
    public var label: MaterialKey = "pkg.paper-label:B3141F"
    /// Wordmark ink.
    public var ink: MaterialKey = "paper.sheet:FFFFFF"
    /// Brand and product line.
    public var brand = "HEARTHWELL"
    public var line = "TOMATO SOUP"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(hi: true), make(hi: false)], switchDistances: [4])
    }

    func make(hi: Bool) -> Model {
        typealias K = GroceryKit
        var m = Model(name: Self.id)
        let r = diameter / 2, h = height, segs = hi ? 72 : 24
        let ly0: Float = 0.0062, ly1 = h - 0.0068
        // Body: recessed bottom panel, bottom double seam, straight wall, top double seam, countersunk lid.
        var prof: [V2] = [V2(0, 0.004), V2(r - 0.008, 0.004), V2(r - 0.0065, 0.0034), V2(r - 0.005, 0.0045), V2(r - 0.0032, 0.0046),
                          V2(r - 0.0022, 0.0012), V2(r - 0.0012, 0.0), V2(r + 0.0008, 0.0006), V2(r + 0.0012, 0.0028), V2(r + 0.0008, 0.0047),
                          V2(r, 0.0058), V2(r, h - 0.0062), V2(r + 0.0008, h - 0.0048), V2(r + 0.0012, h - 0.0025), V2(r + 0.0008, h - 0.0004),
                          V2(r - 0.0002, h), V2(r - 0.0012, h - 0.0006), V2(r - 0.0022, h - 0.0042), V2(r - 0.0034, h - 0.0048)]
        prof += [V2(r - 0.0048, h - 0.0048), V2(r - 0.005, h - 0.0052), V2(r - 0.0052, h - 0.0048), // score line
                 V2(r - 0.0075, h - 0.0048), V2(r - 0.0085, h - 0.0041), V2(r - 0.0095, h - 0.0048), // expansion ring
                 V2(r - 0.014, h - 0.0048), V2(r - 0.0152, h - 0.0043), V2(r - 0.0164, h - 0.0048), V2(0, h - 0.0048)]
        var body = Prim.lathe(prof, segments: segs, seamTile: 0.05, material: tin)
        // Dent in the top rim.
        body.displace { p, _ in
            guard p.y > h - 0.012 else { return 0 }
            let a = atan2(p.x, p.z)
            return -0.0012 * exp(-pow(a + 2.2, 2) / 0.02) * smoothstep(h - 0.012, h - 0.002, p.y)
        }
        m.add(body)
        // Label: one design around, seam at the back with a 7 mm glued overlap; ripples over the beads.
        let over: Float = 0.2
        func lr(_ y: Float, _ a: Float) -> Float {
            let bead = exp(-pow((y - 0.034) / 0.0018, 2)) + exp(-pow((y - 0.07) / 0.0018, 2))
            return r + 0.0004 - 0.00025 * bead + (a > .pi ? 0.00028 : 0)
        }
        m.add(K.revSheet(cols: hi ? 72 : 24, rows: hi ? 14 : 2, y0: ly0, y1: ly1, a0: -.pi, a1: .pi + over, uSpan: 0.25 * (1 + over / (2 * .pi)),
                         vSpan: -0.09, u0: 0.03, v0: 0.09, label, radius: lr))
        // Ring-pull: loop, nose plate, rivet.
        let lidY = h - 0.0048
        var loop: [V3] = []
        for k in 0..<24 {
            let t = Float(k) / 24 * 2 * .pi
            loop.append(V3(0.0085 * sin(t), lidY + 0.0012, 0.0065 + 0.0072 * cos(t)))
        }
        m.add(Prim.sweep(Shape2D.roundedRect(0.0042, 0.0009, radius: 0.0004, segments: 1), along: loop, up: V3(0, 1, 0), closedPath: true, material: "metal.aluminum"))
        m.add(Prim.extrude(Shape2D.roundedRect(0.012, 0.011, radius: 0.004, segments: 3), depth: 0.0008, bevel: 0.0003, bevelSegments: 1, material: "metal.aluminum"),
              Xform(translation: V3(0, lidY + 0.0007, -0.0035), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
        m.add(Prim.lathe([V2(0.0024, lidY), V2(0.0022, lidY + 0.0014), V2(0.0012, lidY + 0.0019), V2(0, lidY + 0.002)], segments: 16, seamTile: 0.05, material: tin))
        if hi {
            // Wordmark on the logo pill (design x 0.70) and product line under it.
            let aPill = (0.7 * 0.25 - 0.03) / (0.25 * (1 + over / (2 * .pi))) * (2 * .pi + over) - .pi
            K.wrapText(&m, brand, height: 0.0072, y: ly0 + 0.81 * (ly1 - ly0), at: aPill, ink, maxWidth: 0.075, weight: 1.25, lift: 0.0012) { _ in r }
            K.wrapText(&m, line, height: 0.0056, y: ly0 + 0.695 * (ly1 - ly0), at: aPill, ink, maxWidth: 0.07, weight: 1.05, lift: 0.0012) { _ in r }
            // Glue streak at the seam.
            m.add(K.revSheet(cols: 2, rows: 6, y0: ly0 + 0.004, y1: ly1 - 0.006, a0: .pi + over - 0.012, a1: .pi + over + 0.02, uSpan: 0.003, vSpan: 0.08,
                             "plastic.matte:E9DFC0") { _, _ in r + 0.0002 })
            // Rust at the bottom seam.
            m.add(K.revSheet(cols: 6, rows: 1, y0: 0.0009, y1: 0.0036, a0: 2.0, a1: 2.45, uSpan: 0.016, vSpan: 0.003, "metal.rust") { y, a in
                r + 0.0013 - 0.0004 * abs(y - 0.0024) / 0.0012 + 0.0002 * sin(a * 40) })
        }
        groundAO(&m, height: 0.02, floor: 0.75)
        return m
    }
}
