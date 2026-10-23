import simd
import Foundation

/// Barrel vault roof: architectural facade customizer, modernism, weathered galvanized barrel vault. Parts: standing-seam barrel sheets, seam caps, steel arch ribs, end arch frames, concrete edge beams, eave gutter, fastener rows.
public struct BarrelVaultRoof: RealAsset {
    public static let id = "barrel-vault-roof"
    public static let summary = "Barrel vault roof, 6.0 x 2.0 x 4.0 m: six standing-seam galvanized sheets on steel arch ribs and concrete edge beams."
    public static let tags = ["prop", "architecture", "facade", "roof", "metal"]
    public static let budget = 24000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(6.0, 2.0, 4.0)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = size.x, y0: Float = 0.75, Rs: Float = 1.96, sheets = 6
        let sw = L / Float(sheets)
        let pan: MaterialKey = "metal.galvanized", aged: MaterialKey = "metal.galvanized-aged", steel: MaterialKey = "metal.anodized-worn"
        let ry = FA.q(90, FA.Y)
        // Arc strip between radii r0 and r1 from angle a0 to a1 (degrees from vertical), extruded `depth` along the vault length at world x.
        func arc(_ r0: Float, _ r1: Float, _ a0: Float, _ a1: Float, depth: Float, x: Float, _ mat: MaterialKey, segs: Int = 28, bevel: Float = 0.002) {
            var o: [V2] = [], i: [V2] = []
            for k in 0...segs {
                let t = (a0 + (a1 - a0) * Float(k) / Float(segs)) * .pi / 180
                o.append(V2(r1 * sin(t), r1 * cos(t))); i.append(V2(r0 * sin(t), r0 * cos(t)))
            }
            m.add(Prim.extrude(o + i.reversed(), depth: depth, bevel: bevel, bevelSegments: 1, material: mat),
                  Xform(translation: V3(x, 0, 0), rotation: ry))
        }
        let tEnd = asin(sqrt(Rs * Rs - y0 * y0) / Rs) * 180 / .pi
        func scr(_ t: Float, _ x: Float, _ r: Float) {
            let tr = t * .pi / 180
            m.add(Prim.cylinder(radius: 0.011, height: 0.006, bevel: 0, segments: 6, material: "metal.screw-zinc"),
                  Xform(translation: V3(x, r * cos(tr), -r * sin(tr)), rotation: ry * FA.q(-t, FA.Z)))
        }
        // Standing-seam sheets (alternating weathering) with raised seam caps.
        for i in 0..<sheets {
            let x = -L / 2 + sw * (Float(i) + 0.5)
            arc(Rs - 0.02, Rs, -tEnd, tEnd, depth: sw - 0.04, x: x, i % 2 == 0 ? pan : aged, segs: 36)
            // Rust runoff streaks at the eaves, both sides.
            for sd: Float in [-1, 1] {
                let off = rng.float(-0.25...0.25), w = rng.float(0.06...0.16)
                arc(Rs - 0.002, Rs + 0.003, sd * (tEnd - rng.float(10...22)), sd * (tEnd + 0.4), depth: w, x: x + off, "metal.rust-grime", segs: 6, bevel: 0.0004)
            }
            // Eave fastener rows with washers on both sides.
            for sd: Float in [-1, 1] {
                for k in 0..<5 { scr(sd * (tEnd - 3 - Float(k) * 0.4 ), x + (k % 2 == 0 ? -0.2 : 0.2), Rs + 0.002) }
            }
            // Mid-field row of screws along the crown purlin lines.
            for k in 0..<3 { scr(-28 + Float(k) * 28, x, Rs + 0.002) }
        }
        for i in 0...sheets {
            arc(Rs - 0.012, Rs + 0.03, -tEnd + 1.2, tEnd - 1.2, depth: 0.04, x: -L / 2 + sw * Float(i), aged, segs: 36, bevel: 0.004)
        }
        // Repair patch on sheet 2 with extra fasteners.
        arc(Rs, Rs + 0.004, 10, 28, depth: 0.5, x: -L / 2 + sw * 2.5, pan, segs: 6, bevel: 0.0008)
        for (t, dx) in [(11 as Float, -0.2 as Float), (11, 0.2), (27, -0.2), (27, 0.2)] { scr(t, -L / 2 + sw * 2.5 + dx, Rs + 0.004) }
        // Steel arch ribs under the sheets and heavy end frames.
        for i in 0..<5 { arc(Rs - 0.16, Rs - 0.02, -tEnd, tEnd, depth: 0.05, x: -L / 2 + sw * (Float(i) + 1), steel, segs: 24) }
        for e: Float in [-1, 1] { arc(Rs - 0.24, Rs, -tEnd, tEnd, depth: 0.1, x: e * (L / 2 - 0.05), steel, segs: 30, bevel: 0.004) }
        // Concrete edge beams with expansion joints and form-tie holes.
        for sd: Float in [-1, 1] {
            FA.box(&m, V3(L, y0, 0.3), V3(0, y0 / 2, sd * 1.85), "concrete.smooth", r: 0.01)
            for k in 0...4 {
                let x = -L / 2 + 0.45 + (L - 0.9) * Float(k) / 4
                FA.box(&m, V3(0.012, y0 - 0.1, 0.302), V3(x, y0 / 2, sd * 1.85), "concrete.rough", r: 0.002)
                for h in 0..<(k < 4 ? 2 : 0) {
                    m.add(Prim.cylinder(radius: 0.014, height: 0.006, bevel: 0, segments: 8, material: "metal.rust-grime"),
                          Xform(translation: V3(x + 0.6, 0.2 + Float(h) * 0.35, sd * 1.85 + sd * 0.15), rotation: FA.q(90 * sd, FA.X)))
                }
            }
            FA.box(&m, V3(L, 0.03, 0.34), V3(0, y0 + 0.012, sd * 1.85), steel, r: 0.004)
        }
        // Eave gutters inside the beams.
        let g: [V2] = [V2(-0.05, 0), V2(0.05, 0), V2(0.05, 0.07), V2(0.04, 0.07), V2(0.04, 0.012), V2(-0.04, 0.012), V2(-0.04, 0.07), V2(-0.05, 0.07)]
        for sd: Float in [-1, 1] { FA.run(&m, g, length: L - 0.2, at: V3(0, y0 + 0.027, sd * 1.72), aged, bevel: 0.002) }
        // Downpipe at one end.
        FA.rod(&m, V3(L / 2 - 0.2, y0, 1.72), V3(L / 2 - 0.2, 0.05, 1.72), r: 0.03, aged, sides: 12)
        FA.box(&m, V3(0.12, 0.04, 0.12), V3(L / 2 - 0.2, 0.02, 1.72), aged, r: 0.008)
        groundAO(&m)
        return LODModel(m)
    }
}
