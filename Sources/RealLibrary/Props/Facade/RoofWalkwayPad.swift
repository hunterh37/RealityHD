import simd
import Foundation

/// Roof walkway pad: architectural facade customizer, Commercial, rubber roof walkway pad bonded over membrane with tread ribs, seam strip and scuffing. Parts: membrane underlay, rubber pad, tread ribs, edge chamfer, seam strip, adhesive bleed, debris, wear scuffs.
public struct RoofWalkwayPad: RealAsset {
    public static let id = "roof-walkway-pad"
    public static let summary = "Roof walkway pad, 1.0 x 0.05 x 3.0 m: ribbed rubber pad bonded over roof membrane."
    public static let tags = ["prop", "architecture", "facade"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.0, 0.05, 3.0)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pad: MaterialKey = "rubber.tire-worn", padNew: MaterialKey = "rubber.tire", mem: MaterialKey = "asphalt.worn", seam: MaterialKey = "metal.solder"
        // Membrane underlay extends past the pad with a welded lap and a patched blister.
        FA.box(&m, V3(1.0, 0.008, 3.0), V3(0, 0.004, 0), mem, r: 0.002)
        FA.box(&m, V3(1.0, 0.0012, 0.05), V3(0, 0.0086, 0.55), seam, r: 0.0004)
        // Two pad panels with a 4 mm butt joint; each has a chamfered perimeter and 12 transverse tread ribs.
        let L: Float = 1.44, W: Float = 0.94
        for (pi, zc) in [Float(-0.74), 0.74].enumerated() {
            let mat = pad; let rib: MaterialKey = pi == 0 ? padNew : pad
            let outline = Shape2D.rounded([V2(-W / 2, 0), V2(W / 2, 0), V2(W / 2, 0.022), V2(W / 2 - 0.01, 0.026), V2(-W / 2 + 0.01, 0.026), V2(-W / 2, 0.022)], radius: 0.002)
            m.add(Prim.extrude(outline, depth: L, bevel: 0.002, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0.0085, zc), rotation: FA.q(0, FA.Y)))
            for k in 0..<12 {
                let z = zc - L / 2 + 0.08 + Float(k) * (L - 0.16) / 11
                FA.box(&m, V3(W - 0.14, 0.012, 0.028), V3(0, 0.0085 + 0.026 + 0.004, z), rib, r: 0.004)
                FA.box(&m, V3(W - 0.17, 0.0018, 0.012), V3(0, 0.0085 + 0.0356, z), pad, r: 0.0006)
            }
            // Raised border lip all around the pad face.
            for sx: Float in [-1, 1] { FA.box(&m, V3(0.028, 0.01, L - 0.04), V3(sx * (W / 2 - 0.03), 0.0085 + 0.029, zc), mat, r: 0.003) }
            for sz: Float in [-1, 1] { FA.box(&m, V3(W - 0.06, 0.01, 0.028), V3(0, 0.0085 + 0.029, zc + sz * (L / 2 - 0.022)), mat, r: 0.003) }
        }
        // Cap strip over the butt joint, with a row of countersunk fasteners.
        FA.box(&m, V3(W - 0.02, 0.006, 0.07), V3(0, 0.0085 + 0.032, 0), "metal.galvanized-aged", r: 0.0015)
        for k in 0..<9 {
            let x = -W / 2 + 0.07 + Float(k) * (W - 0.14) / 8
            m.add(Prim.cylinder(radius: 0.0065, height: 0.0025, bevel: 0.0009, segments: 8, bevelSegments: 1, material: "metal.screw-zinc"), Xform(translation: V3(x, 0.0085 + 0.037, 0)))
        }
        // Adhesive bleed along the edges, scuff patches, rust stain, debris.
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.008, 0.0016, 2.9), V3(sx * (W / 2 + 0.006), 0.0088, 0), "asphalt.sealant", r: 0.0006)
        }
        for _ in 0..<7 {
            let x = rng.float(-0.3...0.3), z = rng.float(-1.4...1.4)
            m.add(Prim.superellipsoid(V3(rng.float(0.10...0.22), 0.0018, rng.float(0.08...0.16)), exponent: 2, subdivisions: 4, material: "asphalt.patch"), Xform(translation: V3(x, 0.0085 + 0.0365, z), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        for _ in 0..<6 {
            m.add(Prim.superellipsoid(V3(rng.float(0.03...0.06), 0.0025, rng.float(0.018...0.03)), exponent: 2, subdivisions: 4, material: i2(&rng)),
                  Xform(translation: V3(rng.float(-0.45...0.45), 0.0085 + 0.0345, rng.float(-1.4...1.4)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        // Worn crescent at the entry end where boots land, and a gouge corner.
        m.add(Prim.superellipsoid(V3(0.7, 0.0016, 0.18), exponent: 2, subdivisions: 5, material: "asphalt.patch"), Xform(translation: V3(0, 0.0085 + 0.0368, -1.30)))
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m)
        return LODModel(m)
    }
    private func i2(_ rng: inout SeededRNG) -> MaterialKey { rng.chance(0.5) ? "wood.weathered" : "wood.deadwood" }
}
