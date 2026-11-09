import simd
import Foundation

/// Olive oil bottle, 77 x 300 mm (750 ml dorica): dark green moulded glass with a punt base, a long shoulder,
/// a neck with a finish bead and two mould seams, oil filled into the shoulder, a knurled gold aluminium
/// pilfer-proof cap over a perforated tamper band, a gold neck collar, and a printed paper label (invented
/// brand VERDOLIVA) wrapped with a glued seam at the back. An oil drip runs down the shoulder and the base
/// contact ring is scuffed frosty.
public struct OliveOilBottle: RealAsset {
    public static let id = "olive-oil-bottle"
    public static let summary = "Olive oil bottle: green glass with punt and seams, oil fill, knurled ROPP cap, wrapped printed label, drip."
    public static let tags = ["prop", "interior", "pantry", "glass"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Bottle diameter and overall height (m).
    public var diameter: Float = 0.077
    public var height: Float = 0.30
    public var glass: MaterialKey = "pkg.glass-oil"
    public var oil: MaterialKey = "plastic.gloss:4A5218"
    /// Oil drip on the glass.
    public var drip: MaterialKey = "food.oil"
    public var capMaterial: MaterialKey = "metal.aluminum-brushed:C8A24A"
    /// Printed label (brand field tint).
    public var label: MaterialKey = "pkg.paper-label:23361F"
    public var ink: MaterialKey = "paper.sheet:FFFFFF"
    public var brand = "VERDOLIVA"
    public var line = "EXTRA VIRGIN"
    public init() {}

    /// Outer glass radius at height y.
    func outer(_ y: Float) -> Float {
        let r = diameter / 2
        if y < 0.004 { return r - 0.0012 + 0.0012 * y / 0.004 }
        if y < 0.16 { return r }
        if y < 0.232 { let t = (y - 0.16) / 0.072; return 0.0146 + (r - 0.0146) * (0.5 + 0.5 * cos(t * .pi)) }
        return 0.0146
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(hi: true), make(hi: false)], switchDistances: [3])
    }

    func make(hi: Bool) -> Model {
        typealias K = GroceryKit
        var m = Model(name: Self.id)
        let r = diameter / 2, segs = hi ? 64 : 20
        let capY: Float = height - 0.034
        // Glass: punt dome, heel, wall, shoulder, neck, finish bead.
        var prof: [V2] = [V2(0, 0.011), V2(0.008, 0.0105), V2(0.016, 0.0085), V2(0.024, 0.005), V2(r - 0.006, 0.0012), V2(r - 0.003, 0), V2(r - 0.0012, 0.0008)]
        for k in 0...(hi ? 24 : 10) { let y = 0.003 + (capY - 0.006 - 0.003) * Float(k) / Float(hi ? 24 : 10); prof.append(V2(outer(y), y)) }
        prof += [V2(0.0162, capY - 0.004), V2(0.0164, capY - 0.0015), V2(0.0150, capY + 0.002), V2(0.0140, capY + 0.004)]
        m.add(Prim.lathe(prof, segments: segs, seamTile: 0.1, material: glass))
        // Oil, filled into the shoulder.
        let fillTop: Float = 0.212
        var oilP: [V2] = [V2(0, 0.013), V2(0.02, 0.0085), V2(r - 0.004, 0.004)]
        for k in 0...6 { let y = 0.006 + (fillTop - 0.006) * Float(k) / 6; oilP.append(V2(outer(y) - 0.003, y)) }
        oilP.append(V2(0, fillTop))
        m.add(Prim.lathe(oilP, segments: hi ? 32 : 12, seamTile: 0.1, material: oil))
        // Cap: perforated tamper band, then the knurled shell.
        var band = Prim.lathe([V2(0.0158, capY), V2(0.0161, capY + 0.0004), V2(0.0161, capY + 0.0068), V2(0.0158, capY + 0.0072)],
                              segments: hi ? 80 : 20, seamTile: 0.05, material: capMaterial)
        if hi { band.displace { p, nn in abs(nn.y) > 0.5 ? 0 : -0.00035 * smoothstep(0.8, 0.95, cos(atan2(p.z, p.x) * 16)) * smoothstep(0.002, 0.0, abs(p.y - capY - 0.0036)) } }
        m.add(band)
        m.add(K.knurledCap(r: 0.0162, h: height - capY - 0.0074, y0: capY + 0.0074, ribs: hi ? 44 : 12, depth: 0.00045, capMaterial))
        // Gold neck collar.
        m.add(Prim.lathe([V2(0.0152, 0.236), V2(0.0156, 0.2365), V2(0.0156, 0.2475), V2(0.0152, 0.248)], segments: segs, seamTile: 0.05,
                         material: "plastic.matte:B8913E"))
        // Label: one design around, glued seam at the back.
        let ly0: Float = 0.036, ly1: Float = 0.146, over: Float = 0.16
        let span = 0.25 * (1 + over / (2 * .pi))
        m.add(K.revSheet(cols: hi ? 64 : 20, rows: 2, y0: ly0, y1: ly1, a0: -.pi, a1: .pi + over, uSpan: span, vSpan: -0.09, u0: 0.03, v0: 0.09, label) { _, a in
            r + 0.0004 + (a > .pi ? 0.00028 : 0) })
        if hi {
            let aPill = (0.7 * 0.25 - 0.03) / span * (2 * .pi + over) - .pi
            K.wrapText(&m, brand, height: 0.0085, y: ly0 + 0.805 * (ly1 - ly0), at: aPill, ink, maxWidth: 0.085, weight: 1.25, lift: 0.0012) { _ in r }
            K.wrapText(&m, line, height: 0.0058, y: ly0 + 0.69 * (ly1 - ly0), at: aPill, ink, maxWidth: 0.075, weight: 1.05, lift: 0.0012) { _ in r }
            K.wrapText(&m, "750 ML", height: 0.0042, y: 0.151, at: aPill, "plastic.matte:D8C27A", weight: 0.9, lift: 0.0006) { _ in r }
            // Mould seams.
            for s: Float in [-1, 1] {
                let path = stride(from: Float(0.006), through: 0.226, by: 0.022).map { y in V3(s * (outer(y) + 0.0002), y, 0) }
                m.add(Prim.tube(path, radii: path.map { _ in 0.0004 }, sides: 4, seamTile: 0.01, material: glass))
            }
            // Oil drip from the finish down the shoulder.
            let dp = (0...10).map { k -> V3 in
                let y = capY - 0.003 - Float(k) * 0.0068, a: Float = -0.55 + 0.03 * sin(Float(k))
                return V3((outer(y) + 0.0006) * sin(a), y, (outer(y) + 0.0006) * cos(a))
            }
            m.add(Prim.tube(dp, radii: dp.indices.map { 0.0009 + 0.0006 * Float($0) / 10 }, sides: 6, seamTile: 0.01, material: drip))
            // Scuffed contact ring.
            m.add(Prim.lathe([V2(r - 0.0006, 0.0015), V2(r + 0.0002, 0.003), V2(r + 0.0002, 0.0045)], segments: segs, seamTile: 0.05, material: "glass.frosted"))
        }
        groundAO(&m, height: 0.02, floor: 0.7)
        return m
    }
}
