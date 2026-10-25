import simd
import Foundation

/// Lightning rod air terminal: architectural facade customizer, Traditional, copper air terminal on a bronze tripod roof base with conductor cable, clamps and verdigris. Parts: copper rod, pointed tip, bronze tripod base, roof feet, cable clamp, copper conductor, mid brace ring, set screws.
public struct LightningRodAirTerminal: RealAsset {
    public static let id = "lightning-rod-air-terminal"
    public static let summary = "Lightning rod air terminal, 0.2 x 1.0 x 0.2 m: copper rod on a bronze tripod base with conductor cable."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.2, 1.0, 0.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cu: MaterialKey = "metal.copper", cp: MaterialKey = "metal.copper-patina", vd: MaterialKey = "metal.verdigris-roof", br: MaterialKey = "metal.brass-aged", strand: MaterialKey = "metal.copper-strand", zinc: MaterialKey = "metal.screw-zinc"
        // Lead flashing pad bedded in sealant, with a rolled edge and fastener heads at the corners.
        FA.box(&m, V3(0.2, 0.004, 0.2), V3(0, 0.002, 0), "metal.galvanized", r: 0.0012)
        m.add(Prim.torus(major: 0.099, minor: 0.0018, segments: 4, sides: 4, material: "asphalt.sealant"), Xform(translation: V3(0, 0.004, 0)))
        // Three bronze feet with screws, legs sloping to a central hub.
        let hubY: Float = 0.17
        for k in 0..<3 {
            let a = Float(k) * 120 + 15
            let q = FA.q(a, FA.Y)
            let foot = q.act(V3(0.078, 0, 0))
            FA.box(&m, V3(0.046, 0.007, 0.036), V3(foot.x, 0.0075, foot.z), "metal.bronze-weathered", r: 0.002, rot: q)
            for s: Float in [-1, 1] {
                let sp = foot + q.act(V3(0, 0, s * 0.012))
                m.add(Prim.cylinder(radius: 0.0052, height: 0.0028, bevel: 0.0009, segments: 8, bevelSegments: 1, material: zinc), Xform(translation: V3(sp.x, 0.011, sp.z)))
            }
            let a0 = V3(foot.x, 0.011, foot.z), top = q.act(V3(0.022, 0, 0)) + V3(0, hubY - 0.022, 0)
            m.add(Prim.tube([a0, a0 + (top - a0) * 0.5, top], radii: [0.0125, 0.0105, 0.0095], sides: 10, seamTile: 0.15, material: "metal.bronze-weathered", capEnd: true))
            FA.ball(&m, r: 0.0125, at: a0, "metal.bronze-weathered")
        }
        // Hub casting with three set screws and a cable clamp lug.
        m.add(Prim.lathe([V2(0.0, hubY - 0.04), V2(0.028, hubY - 0.04), V2(0.031, hubY - 0.03), V2(0.031, hubY + 0.022), V2(0.026, hubY + 0.03), V2(0.0, hubY + 0.03)], segments: 24, seamTile: 0.1, material: br))
        for k in 0..<3 {
            let q = FA.q(Float(k) * 120 + 75, FA.Y)
            let p = q.act(V3(0.031, hubY + 0.004, 0))
            m.add(Prim.cylinder(radius: 0.0055, height: 0.012, bevel: 0.001, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: p, rotation: q * FA.q(-90, FA.Z)))
        }
        // Rod: 3/8 in copper, verdigris on the lower length, bright patina above, tapered point; ferrule collars.
        m.add(Prim.lathe([V2(0.0, hubY - 0.03), V2(0.0095, hubY - 0.03), V2(0.0095, 0.52), V2(0.0, 0.52)], segments: 18, seamTile: 0.12, material: vd))
        m.add(Prim.lathe([V2(0.0, 0.52), V2(0.0098, 0.52), V2(0.0098, 0.80), V2(0.0085, 0.88), V2(0.0058, 0.945), V2(0.0028, 0.985), V2(0.0, 1.0)], segments: 18, seamTile: 0.12, material: cu))
        m.add(Prim.lathe([V2(0.0095, 0.495), V2(0.0165, 0.50), V2(0.0175, 0.52), V2(0.0175, 0.56), V2(0.0165, 0.575), V2(0.0098, 0.58)], segments: 20, seamTile: 0.08, material: br))
        for k in 0..<2 { m.add(Prim.cylinder(radius: 0.0042, height: 0.011, bevel: 0.0008, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: V3(0.0165, 0.535 + Float(k) * 0.02, 0), rotation: FA.q(-90, FA.Z))) }
        m.add(Prim.torus(major: 0.0108, minor: 0.0022, segments: 18, sides: 6, material: cp), Xform(translation: V3(0, 0.80, 0)))
        // Patina drips and a bird dropping at the hub.
        for k in 0..<5 {
            let a = Float(k) * 72 + 10
            let q = FA.q(a, FA.Y)
            m.add(Prim.superellipsoid(V3(0.004, 0.05 + 0.02 * rng.float(), 0.0016), exponent: 2, subdivisions: 4, material: vd), Xform(translation: q.act(V3(0.0316, hubY - 0.02, 0)), rotation: q))
        }
        m.add(Prim.superellipsoid(V3(0.02, 0.003, 0.014), exponent: 2, subdivisions: 4, material: "plastic.white"), Xform(translation: V3(0.0, hubY + 0.031, 0.0)))
        // Down conductor: stranded copper cable from the hub lug, a saddle clip, then to a lug bolted to the pad.
        let lug = FA.q(195, FA.Y).act(V3(0.034, hubY - 0.01, 0))
        FA.box(&m, V3(0.016, 0.014, 0.010), lug, br, r: 0.0015, rot: FA.q(195, FA.Y))
        let end = V3(-0.060, 0.008, -0.075)
        let pts = catmull([lug + V3(0, 0, 0), V3(-0.05, hubY - 0.03, -0.01), V3(-0.065, 0.10, -0.03), V3(-0.062, 0.04, -0.06), end], per: 6)
        m.add(Prim.tube(pts, radii: Array(repeating: 0.0042, count: pts.count), sides: 8, seamTile: 0.05, material: strand, capEnd: true))
        FA.box(&m, V3(0.022, 0.003, 0.022), V3(end.x, 0.0055, end.z), br, r: 0.0008)
        m.add(Prim.cylinder(radius: 0.0055, height: 0.003, bevel: 0.0008, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: V3(end.x, 0.0075, end.z)))
        FA.box(&m, V3(0.010, 0.003, 0.014), V3(-0.063, 0.085, -0.036), br, r: 0.0008)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m)
        return LODModel(m)
    }
}
