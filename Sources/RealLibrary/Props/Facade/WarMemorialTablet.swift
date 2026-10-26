import simd
import Foundation

/// Civic war memorial tablet: a honed marble slab with a moulded cornice and a pedimented head carrying a
/// bronze laurel wreath, cast bronze dates and name lines, on a two-step granite plinth. A poppy wreath
/// leans at the foot. Soot gathers on the cornice returns and algae at the plinth.
public struct WarMemorialTablet: RealAsset {
    public static let id = "war-memorial-tablet"
    public static let summary = "Civic memorial tablet 0.8 x 1.2 m: marble slab with pediment, cast bronze names, wreath, plinth."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 1.2)

    /// Dates under the wreath.
    public var dates = "1914 1918"
    /// Name lines, top to bottom (A-Z, 0-9).
    public var names = ["ADAMS W", "BAKER T H", "CARTER J", "DAVIES R", "ELLIS G A", "FOSTER H", "GRANT S", "HALL E J", "IRVING P", "JONES D"]
    public var marble: MaterialKey = "stone.marble"
    public var granite: MaterialKey = "stone.granite-curb"
    public var bronze: MaterialKey = "metal.bronze-weathered"
    public var bronzeBright: MaterialKey = "metal.bronze-cast"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Two-step granite plinth: 0.8 x 0.06 then 0.74 x 0.07.
        FA.box(&m, V3(0.8, 0.06, 0.12), V3(0, 0.03, 0.06), granite, r: 0.004)
        FA.box(&m, V3(0.74, 0.09, 0.1), V3(0, 0.105, 0.06), granite, r: 0.004)
        // Slab 0.68 x 0.86, 55 mm thick, on a 4 mm reveal; honed face with a polished 12 mm arris.
        let slabY: Float = 0.15, slabH: Float = 0.86, sz: Float = 0.0875
        FA.box(&m, V3(0.68, slabH, 0.05), V3(0, slabY + slabH / 2, 0.0625), marble, r: 0.003)
        // Moulded cornice: profile (out, up) run across the slab head.
        let cy = slabY + slabH
        FA.run(&m, [V2(0, 0), V2(0.1, 0), V2(0.1, 0.012), V2(0.09, 0.02), V2(0.09, 0.028), V2(0.078, 0.04), V2(0.078, 0.05), V2(0, 0.05)],
               length: 0.76, at: V3(0, cy, 0.0), marble, bevel: 0.002)
        // Pediment: triangular head with a raised tympanum panel.
        let tri: [V2] = [V2(-0.37, 0), V2(0.37, 0), V2(0, 0.14)]
        m.add(Prim.extrude(tri, depth: 0.07, bevel: 0.003, bevelSegments: 1, material: marble), Xform(translation: V3(0, cy + 0.05, 0.05)))
        m.add(Prim.extrude([V2(-0.3, 0), V2(0.3, 0), V2(0, 0.108)], depth: 0.008, bevel: 0.0015, bevelSegments: 1, material: marble), Xform(translation: V3(0, cy + 0.056, 0.0895)))
        // Bronze laurel wreath on the tympanum: ring of leaf pairs and a tie.
        let wc = V3(0, cy + 0.098, 0.096)
        for k in 0..<22 {
            let a = Float(k) / 22 * 2 * .pi
            let p = wc + V3(cos(a) * 0.036, sin(a) * 0.036, 0)
            m.add(Prim.superellipsoid(V3(0.018, 0.006, 0.004), exponent: 2, subdivisions: 3, material: k % 3 == 0 ? bronzeBright : bronze),
                  Xform(translation: p, rotation: FA.q(a * 57.3 + 90 + (k % 2 == 0 ? 25 : -25), FA.Z)))
        }
        m.add(Prim.torus(major: 0.036, minor: 0.0018, segments: 24, sides: 5, material: bronze), Xform(translation: wc, rotation: FA.q(90, FA.X)))
        FG.dome(&m, at: wc + V3(0, -0.037, 0.001), r: 0.006, mat: bronzeBright)
        // Cast bronze dates and name lines, raised 3 mm, bright where rubbed.
        let sc = V3(0, 0, sz - 0.0008)
        FG.text(&m, dates, h: 0.05, stroke: 0.0085, depth: 0.004, at: sc + V3(0, 0.92, 0), bronze)
        FG.text(&m, "LEST WE FORGET", h: 0.026, stroke: 0.0042, depth: 0.003, at: sc + V3(0, 0.86, 0), bronze)
        FA.box(&m, V3(0.4, 0.004, 0.003), V3(0, 0.83, sz + 0.0008), bronzeBright, r: 0.001)
        for (i, n) in names.enumerated() {
            let y = 0.775 - Float(i) * 0.054
            FG.text(&m, n, h: 0.032, stroke: 0.005, depth: 0.0032, at: sc + V3(0, y, 0), i % 4 == 2 ? "metal.brass-aged" : bronze)
        }
        // Bronze dowel caps top and bottom corners of the slab.
        for sx: Float in [-1, 1] { for yy: Float in [slabY + 0.04, slabY + slabH - 0.04] {
            FG.dome(&m, at: V3(sx * 0.3, yy, sz + 0.0005), r: 0.007, mat: bronzeBright)
        }}
        // Poppy wreath leaning at the foot: foliage ring tipped back 12 degrees, red poppies with black centres.
        let pc = V3(0.15, 0.204, 0.093), th: Float = 78 * .pi / 180
        m.add(Prim.torus(major: 0.05, minor: 0.01, segments: 28, sides: 8, material: "paint.stucco:2C4527"), Xform(translation: pc, rotation: FA.q(78, FA.X)))
        for k in 0..<14 {
            let a = Float(k) / 14 * 2 * .pi, r: Float = 0.05
            let p = pc + V3(cos(a) * r, -sin(a) * r * sin(th), sin(a) * r * cos(th)) + V3(0, 0, 0.012)
            FC.bead(&m, r: 0.008, at: p, "sign.red:A81C20")
            FC.bead(&m, r: 0.0026, at: p + V3(0, 0, 0.007), "plastic.black")
        }
        FG.flat(&m, V3(0.04, 0.03, 0.002), V3(0.23, 0.12, 0.115), "sign.white:E8E1CF", rot: FA.q(-8, FA.Z))
        // Soot streaks from the cornice, algae at the plinth, grime on the step.
        for _ in 0..<8 {
            let len = rng.float(0.08...0.3), x = rng.float(-0.33...0.33)
            if abs(x) < 0.2 && cy - 0.01 - len < 0.9 { continue }
            FG.flat(&m, V3(rng.float(0.005...0.014), len, 0.0006), V3(x, cy - 0.01 - len / 2, sz + 0.0004), "stone.marble-dark")
        }
        FG.flat(&m, V3(0.72, 0.02, 0.0008), V3(0, 0.025, 0.121), "paint.stucco:5E5A50")
        groundAO(&m, height: 0.2, floor: 0.85)
        return LODModel(FC.place(m))
    }
}

private extension Array where Element == V2 {
    /// Drops repeated consecutive points (the cornice profile has a doubled origin).
    func dropFirstDuplicate() -> [V2] {
        var out: [V2] = []
        for p in self where out.last.map({ simd_distance($0, p) > 1e-6 }) ?? true { out.append(p) }
        return out
    }
}
