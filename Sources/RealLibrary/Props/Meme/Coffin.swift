import simd
import Foundation

/// Coffin: polished lacquered mahogany hexagonal casket on a plinth, brass swing handles and corner caps, satin lining showing under a lid raised a few centimeters.
public struct Coffin: RealAsset {
    public static let id = "coffin"
    public static let summary = "Hexagonal lacquered wood casket, 2.1 m: brass handles, lid raised to show pleated satin lining at the edge."
    public static let tags = ["prop", "wood", "metal", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Gap between body rim and lid in meters.
    public var lidGap: Float = 0.035
    public init() {}

    /// Hexagon in plan, (x, z): narrow head, wide shoulders, narrow foot.
    private static let plan: [V2] = [V2(0.21, -1.05), V2(0.31, -0.60), V2(0.19, 1.05), V2(-0.19, 1.05), V2(-0.31, -0.60), V2(-0.21, -1.05)]

    /// Plan outline in extrude space (x, -z), offset and with softened corners.
    private func outline(_ d: Float, round: Float) -> [V2] {
        Shape2D.rounded(Shape2D.offset(Self.plan.map { V2($0.x, -$0.y) }, d), radius: round, segments: 8)
    }

    /// A prism of the plan outline standing from y0 to y1.
    private func slab(_ d: Float, round: Float, y0: Float, y1: Float, bevel: Float, material: MaterialKey) -> (Surface, Xform) {
        let s = Prim.extrude(outline(d, round: round), depth: y1 - y0, bevel: bevel, bevelSegments: 4, material: material)
        return (s, Xform(translation: V3(0, (y0 + y1) / 2, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let wood: MaterialKey = "wood.mahogany", dark: MaterialKey = "wood.walnut:2A160C", brass: MaterialKey = "metal.brass"
        let satin: MaterialKey = "fabric.velvet:EEE5CE"
        let rim: Float = 0.50
        // Plinth, body, then the lining pad that crowns the body and shows through the lid gap.
        for (d, y0, y1, r, b, mat) in [(-0.035, 0.0, 0.07, 0.03, 0.006, dark), (0.0, 0.07, rim, 0.045, 0.012, wood), (-0.035, rim - 0.03, rim + lidGap * 0.7, 0.06, 0.012, satin)] as [(Float, Float, Float, Float, Float, MaterialKey)] {
            let (s, x) = slab(d, round: r, y0: y0, y1: y1, bevel: b, material: mat); m.add(s, x)
        }
        // Pleats in the satin: soft ridges along the lining edge.
        for k in 0..<28 {
            let t = Float(k) / 28, side: Float = k % 2 == 0 ? 1 : -1
            let z = -0.85 + 1.75 * t
            let hw = 0.31 - 0.12 * (z + 0.6) / 1.65
            m.add(Prim.roundedBox(V3(0.010, lidGap * 0.9, 0.040), radius: 0.004, bevelSegments: 2, material: satin),
                  Xform(translation: V3(side * (min(0.31, hw) - 0.045), rim + lidGap * 0.35, z)))
        }
        // Lid: raised panel stack with a rolled edge moulding.
        let lid0 = rim + lidGap
        for (d, y0, y1, r, b) in [(0.014, lid0, lid0 + 0.09, 0.05, 0.02), (-0.06, lid0 + 0.09, lid0 + 0.125, 0.06, 0.014), (-0.12, lid0 + 0.125, lid0 + 0.150, 0.07, 0.01)] as [(Float, Float, Float, Float, Float)] {
            let (s, x) = slab(d, round: r, y0: y0, y1: y1, bevel: b, material: wood); m.add(s, x)
        }
        let ring = Shape2D.rounded(Shape2D.offset(Self.plan.map { V2($0.x, -$0.y) }, 0.016), radius: 0.05, segments: 6)
        let path = ring.map { V3($0.x, lid0 + 0.012, -$0.y) }
        m.add(Prim.sweep(Shape2D.circle(0.011, segments: 16), along: path, up: .up, closedPath: true, caps: false, grainAlongPath: true, material: wood))
        // Brass: three swing handles per flank (bar on two lugs), trim bands, name plate and cross.
        let a = Self.plan[1], b = Self.plan[2]
        let d = simd_normalize(V2(b.x - a.x, b.y - a.y)), n = V2(d.y, -d.x)
        var bar: [V3] = [V3(0.004, 0, -0.085), V3(0.020, 0, -0.078), V3(0.031, 0, -0.050), V3(0.031, 0, 0.050), V3(0.020, 0, 0.078), V3(0.004, 0, 0.085)]
        bar = catmull(bar, per: 8)
        for s: Float in [-1, 1] {
            let theta = atan2(-n.y, s * n.x)
            let rot = simd_quatf(angle: theta, axis: .up)
            for t: Float in [0.22, 0.52, 0.82] {
                let p = a + (b - a) * t
                let at = V3(s * p.x, 0.30, p.y)
                m.add(Prim.tube(bar, radii: bar.map { _ in 0.0085 }, sides: 24, seamTile: 0.03, material: brass), Xform(translation: at, rotation: rot))
                for e: Float in [-1, 1] {
                    m.add(Prim.roundedBox(V3(0.010, 0.046, 0.032), radius: 0.004, bevelSegments: 3, material: brass),
                          Xform(translation: at + rot.act(V3(0.001, 0, e * 0.085)), rotation: rot))
                }
            }
        }
        for (d0, y) in [(0.004, 0.074), (0.003, rim - 0.004)] as [(Float, Float)] {
            let ring = Shape2D.rounded(Shape2D.offset(Self.plan.map { V2($0.x, -$0.y) }, d0), radius: 0.045, segments: 6)
            m.add(Prim.sweep(Shape2D.circle(0.0055, segments: 12), along: ring.map { V3($0.x, y, -$0.y) }, up: .up, closedPath: true, caps: false, grainAlongPath: true, material: brass))
        }
        let top = lid0 + 0.150
        m.add(Prim.roundedBox(V3(0.110, 0.005, 0.050), radius: 0.002, bevelSegments: 2, material: brass), Xform(translation: V3(0, top + 0.001, -0.35)))
        m.add(Prim.roundedBox(V3(0.026, 0.005, 0.210), radius: 0.002, bevelSegments: 2, material: brass), Xform(translation: V3(0, top + 0.001, 0.30)))
        m.add(Prim.roundedBox(V3(0.120, 0.005, 0.026), radius: 0.002, bevelSegments: 2, material: brass), Xform(translation: V3(0, top + 0.001, 0.24)))
        return LODModel(m)
    }
}
