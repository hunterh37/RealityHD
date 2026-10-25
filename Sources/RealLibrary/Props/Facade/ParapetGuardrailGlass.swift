import simd
import Foundation

/// Parapet glass guardrail: architectural facade customizer, Contemporary, frameless glass guardrail with patch fittings and stainless handrail on a parapet. Parts: laminated glass panel, stainless patch fittings, stainless handrail, rail end caps, base shoe, fasteners, coping stone, glass edge.
public struct ParapetGuardrailGlass: RealAsset {
    public static let id = "parapet-guardrail-glass"
    public static let summary = "Parapet glass guardrail, 2.0 x 1.1 x 0.1 m: laminated glass, patch fittings, stainless handrail on a parapet."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 1.1, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ss: MaterialKey = "metal.stainless", sat: MaterialKey = "metal.satin-aluminum", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime"
        let stone: MaterialKey = "stone.limestone-sooted", mem: MaterialKey = "asphalt.worn", glass: MaterialKey = "glass.clear"
        let L: Float = 2.0, wallH: Float = 0.24, copH: Float = 0.04, wallD: Float = 0.085, copD: Float = 0.1
        let gy0: Float = 0.3, gy1: Float = 1.045, gw: Float = 0.0215
        // Parapet: two courses of limestone blocks with mortar joints, coping with drip overhang, membrane up the roof side.
        for c in 0..<2 {
            let off: Float = c == 0 ? 0 : 0.2
            let y = Float(c) * (wallH / 2) + wallH / 4
            for k in 0..<6 {
                let x0 = -L / 2 + Float(k) * 0.4 - off + (c == 0 ? 0 : 0), x1 = x0 + 0.4
                let a = max(x0, -L / 2), b = min(x1, L / 2)
                if b - a < 0.02 { continue }
                FA.box(&m, V3(b - a - 0.006, wallH / 2 - 0.004, wallD), V3((a + b) / 2, y, 0), (k + c) % 3 == 0 ? "stone.limestone" : stone, r: 0.003)
            }
        }
        FA.box(&m, V3(L, 0.002, wallD - 0.006), V3(0, wallH / 2, 0), "metal.solder", r: 0.0005)
        for k in 0..<4 { FA.box(&m, V3(0.5, copH, copD), V3(-0.75 + Float(k) * 0.5, wallH + copH / 2, 0), stone, r: 0.004) }
        for k in 1..<4 { FA.box(&m, V3(0.004, copH - 0.004, copD - 0.004), V3(-1.0 + Float(k) * 0.5, wallH + copH / 2, 0), mem, r: 0.0005) }
        FA.box(&m, V3(L, 0.006, 0.004), V3(0, wallH + 0.003, copD / 2 + 0.0005), "metal.galvanized-aged", r: 0.001) // drip
        FA.box(&m, V3(L - 0.02, 0.14, 0.004), V3(0, 0.07, -wallD / 2 - 0.002), mem, r: 0.001)
        for _ in 0..<9 { let l = rng.float(0.05...0.16); FA.box(&m, V3(rng.float(0.01...0.035), l, 0.0007), V3(rng.float(-0.95...0.95), wallH - l / 2, wallD / 2 + 0.0004), mem, r: 0.0002) }
        for _ in 0..<4 { FA.box(&m, V3(rng.float(0.05...0.1), 0.0008, 0.0006), V3(rng.float(-0.8...0.8), gy0 + 0.004, gw / 2 + 0.0004), "plastic.frosted", r: 0.0002) }
        // Base shoe: stainless U channel with set screws and rust weep stains.
        let sh: Float = 0.075, sw: Float = 0.052, wt: Float = 0.005
        FA.box(&m, V3(L - 0.1, wt, sw), V3(0, wallH + copH + wt / 2, 0), ss, r: 0.0012)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(L - 0.1, sh, wt), V3(0, wallH + copH + sh / 2, s * (sw / 2 - wt / 2)), ss, r: 0.0012)
            FA.box(&m, V3(0.002, sh - 0.004, sw), V3(s * (L - 0.1) / 2, wallH + copH + sh / 2, 0), ss, r: 0.0005)
            for k in 0..<7 { FA.cylZ(&m, r: 0.005, h: 0.003, at: V3(-0.9 + Float(k) * 0.3, wallH + copH + 0.04, s * (sw / 2) + (s > 0 ? 0 : -0.003)), zinc, bevel: 0.001, segments: 8) }
        }
        FA.box(&m, V3(L - 0.1, 0.002, 0.004), V3(0, wallH + copH + 0.0005, 0.0), "metal.solder", r: 0.0004)
        for _ in 0..<4 { let l = rng.float(0.02...0.05); FA.box(&m, V3(rng.float(0.004...0.01), l, 0.0006), V3(rng.float(-0.9...0.9), wallH + copH - l / 2, copD / 2 + 0.0008), rust, r: 0.0002) }
        // Laminated glass: two panes and a visible interlayer edge, bottom seated in the shoe.
        let gl = L - 0.12
        FA.box(&m, V3(gl, gy1 - gy0, gw), V3(0, (gy0 + gy1) / 2, 0), glass, r: 0.0012)
        FA.box(&m, V3(gl - 0.002, 0.006, gw + 0.002), V3(0, gy0 + 0.02, 0), "plastic.black", r: 0.001) // setting block / gasket in the shoe
        // Patch fittings: stainless plates through-bolted on both faces, at the two lower corners and under the rail.
        for x in [-0.86, 0.86] as [Float] {
            for (y, h) in [(gy0 + 0.09, 0.09), (gy1 - 0.065, 0.09)] as [(Float, Float)] {
                for s: Float in [-1, 1] {
                    FA.box(&m, V3(0.1, h, 0.008), V3(x, y, s * (gw / 2 + 0.004)), ss, r: 0.003)
                    for a: Float in [-1, 1] { for b: Float in [-1, 1] {
                        FA.cylZ(&m, r: 0.0065, h: 0.003, at: V3(x + a * 0.034, y + b * (h / 2 - 0.016), s * (gw / 2 + 0.008) + (s > 0 ? 0 : -0.003)), sat, bevel: 0.001, segments: 8)
                    } }
                }
            }
        }
        // Handrail: 48 mm stainless tube on a slotted clamp saddle, end caps, joint sleeve.
        let ry = gy1 + 0.0235
        FA.box(&m, V3(L - 0.12, 0.022, 0.034), V3(0, gy1 + 0.011, 0), sat, r: 0.004)
        FA.rod(&m, V3(-L / 2 + 0.07, ry + 0.012, 0), V3(L / 2 - 0.07, ry + 0.012, 0), r: 0.0235, ss, sides: 16)
        for s: Float in [-1, 1] { FA.ball(&m, r: 0.0235, at: V3(s * (L / 2 - 0.07), ry + 0.012, 0), ss) }
        FA.cylX(&m, r: 0.0255, h: 0.06, at: V3(-0.03, ry + 0.012, 0), sat, bevel: 0.002, segments: 16)
        for s: Float in [-1, 1] { FA.cylX(&m, r: 0.0255, h: 0.012, at: V3(s * 0.65 - 0.006, ry + 0.012, 0), sat, bevel: 0.002, segments: 16) }
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
