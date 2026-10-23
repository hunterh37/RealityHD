import simd
import Foundation

/// Rooftop deck pergola: architectural facade customizer, Contemporary, rooftop timber pergola with steel base plates, mortised beams, rafters and through bolts. Parts: square steel base plates, timber posts, double beams with mortise joints, rafters with notched ends, through bolts and washers, knee braces, timber deck boards, grain and weathering.
public struct RooftopDeckPergola: RealAsset {
    public static let id = "rooftop-deck-pergola"
    public static let summary = "Rooftop deck pergola, 3.0 x 2.6 x 3.0 m: four posts, double beams, rafters, bolts and deck boards."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(3.0, 2.6, 3.0)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let wd: MaterialKey = "wood.cedar-weathered", wd2: MaterialKey = "wood.lumber-cedar", wd3: MaterialKey = "wood.weathered"
        let gal: MaterialKey = "metal.galvanized-aged", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime"
        let steel: MaterialKey = "metal.painted:2E3135", conc: MaterialKey = "concrete.rough"
        let hw: Float = 1.3, pw: Float = 0.1, deck: Float = 0.06, ph: Float = 2.4
        let by = deck + 0.012 // post base plate top
        // Concrete paver deck slab under the pergola with a timber deck inset.
        FA.box(&m, V3(3.0, deck, 3.0), V3(0, deck / 2, 0), conc, r: 0.004)
        for k in 0..<12 {
            let z = -1.4 + Float(k) * 0.2545
            FA.box(&m, V3(2.6, 0.016, 0.24), V3(0, deck + 0.008, z), k % 3 == 0 ? wd3 : wd2, r: 0.003)
            if k % 2 == 0 { for sx: Float in [-1, 1] { FA.cylY(&m, 0.0045, 0.002, V3(sx * 1.1, deck + 0.016, z + 0.05), zinc) } }
        }
        // Posts: steel base plate, 4 anchor bolts, standoff, timber post with chamfers and end-grain cap.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let px = sx * hw, pz = sz * hw
            FA.box(&m, V3(0.2, 0.012, 0.2), V3(px, deck + 0.012 / 2 + 0.016, pz), steel, r: 0.002)
            for a: Float in [-1, 1] { for b: Float in [-1, 1] {
                FA.cylY(&m, 0.0075, 0.012, V3(px + a * 0.08, deck + 0.034, pz + b * 0.08), gal, hex: true)
            } }
            FA.box(&m, V3(0.04, 0.05, 0.04), V3(px, deck + 0.07, pz), steel, r: 0.002)
            let y0 = deck + 0.095, ph2 = ph - y0 - 0.0
            FA.box(&m, V3(pw, ph2, pw), V3(px, y0 + ph2 / 2, pz), wd, r: 0.006)
            // Vertical checks and a knot.
            for k in 0..<3 { FA.box(&m, V3(0.0015, rng.float(0.3...0.7), 0.0015), V3(px + (rng.chance(0.5) ? 1 : -1) * pw / 2, y0 + rng.float(0.4...1.8), pz + rng.float(-0.03...0.03)), wd3, r: 0.0004); _ = k }
            FA.box(&m, V3(0.03, 0.04, 0.0015), V3(px + pw / 2 * (-sx) * 0.0, y0 + 0.9, pz - sz * pw / 2 - sz * 0.0007), wd3, r: 0.001)
        } }
        // Beams: doubled 2x8 on each side of the posts, with through-bolts, washers and nuts; tenons projecting past the post.
        let by0 = ph - 0.03, bt: Float = 0.045, bh: Float = 0.2
        for sz: Float in [-1, 1] { for f: Float in [-1, 1] {
            let z = sz * hw + f * (pw / 2 + bt / 2 + 0.001)
            FA.box(&m, V3(3.0, bh, bt), V3(0, by0 - bh / 2 + 0.03, z), wd2, r: 0.004)
            FA.box(&m, V3(0.006, 0.12, bt + 0.0006), V3(-1.496, by0 - 0.05, z), wd3, r: 0.001)
            for sx: Float in [-1, 1] {
                for yy in [by0 - 0.05, by0 - 0.13] as [Float] {
                    let x = sx * hw + (yy < by0 - 0.1 ? 0.03 : -0.03) * sx
                    FA.cylZ(&m, r: 0.0085, h: 0.006, at: V3(x, yy, z + f * (bt / 2)), gal, bevel: 0.001, segments: 6)
                }
            }
        } }
        // Rafters: 2x6 across the beams with birdsmouth notches and angled tails, plus end grain caps.
        let nR = 9, ry = by0 + 0.03 + 0.07
        for k in 0..<nR {
            let x = -1.4 + Float(k) * 2.8 / Float(nR - 1)
            let mt: MaterialKey = k % 2 == 0 ? wd2 : wd
            FA.box(&m, V3(0.045, 0.14, 2.9), V3(x, ry, 0), mt, r: 0.004)
            for sz: Float in [-1, 1] {
                // Angled tail cut and bearing notch over the beam, with end-grain cap.
                FA.box(&m, V3(0.045, 0.14, 0.12), V3(x, ry + 0.0, sz * 1.43), mt, r: 0.004, rot: FA.q(sz * 12, FA.X))
                FA.cylY(&m, 0.0055, 0.003, V3(x, ry + 0.07, sz * hw), zinc, hex: true)
            }
        }
        // Purlin slats on top spaced for shade, notched flat 1x2.
        for k in 0..<8 {
            let z = -1.45 + Float(k) * 0.414
            FA.box(&m, V3(3.0, 0.02, 0.05), V3(0, ry + 0.07 + 0.0125, z), wd, r: 0.002)
        }
        // Knee braces at each post, mortised with a through bolt at both ends.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { for dir in 0..<2 {
            let px = sx * hw, pz = sz * hw
            let a: V3, b: V3
            if dir == 0 { a = V3(px, ph - 0.55, pz + sz * (-0.0)); b = V3(px - sx * 0.35, by0 - 0.16, pz) } else { continue }
            let zz = pz + sz * 0.0
            _ = (a, b, zz)
            let mid = V3((a.x + b.x) / 2, (a.y + b.y) / 2, pz + sz * (pw / 2 + 0.0))
            let ang = atan2f(b.y - a.y, b.x - a.x) * 57.2958
            let len = simd_length(V3(b.x - a.x, b.y - a.y, 0))
            FA.box(&m, V3(len, 0.07, 0.04), V3(mid.x, mid.y, pz + sz * (pw / 2 + bt + 0.021)), wd, r: 0.004, rot: FA.q(ang, FA.Z))
            FA.cylZ(&m, r: 0.007, h: 0.004, at: V3(a.x, a.y, pz + sz * (pw / 2 + bt + 0.04)), gal, bevel: 0.0008, segments: 6)
            FA.cylZ(&m, r: 0.007, h: 0.004, at: V3(b.x, b.y, pz + sz * (pw / 2 + bt + 0.04)), gal, bevel: 0.0008, segments: 6)
        } } }
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}

extension FA {
    /// Short vertical cylinder from a base point (hex bolt head when `hex`).
    static func cylY(_ m: inout Model, _ r: Float, _ h: Float, _ c: V3, _ mat: MaterialKey, hex: Bool = false) {
        m.add(Prim.cylinder(radius: r, height: h, bevel: 0.0007, segments: hex ? 6 : 8, bevelSegments: 1, material: mat), Xform(translation: c))
    }
}
