import simd
import Foundation

/// Romanesque Revival limestone arch head: eleven wedge voussoirs over a mortar bed, projecting keystone,
/// roll moulding on the intrados, moulded imposts. Wall plane at z = 0.
public struct LimestoneVoussoirArchHead: RealAsset {
    public static let id = "limestone-voussoir-arch-head"
    public static let summary = "Limestone arch head, 1.4 m: eleven voussoirs, projecting keystone, roll moulding, moulded imposts, open joints."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, distance: 2.6)

    public var width: Float = 1.4
    public var depth: Float = 0.3
    public var count = 11
    public var stone: MaterialKey = "stone.limestone"
    public var stoneSooted: MaterialKey = "stone.limestone-sooted"
    public var mortar: MaterialKey = "stone.sandstone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let D = depth, Ao = width / 2, Bo: Float = 0.47, Ai: Float = 0.50, Bi: Float = 0.28, spring: Float = 0.1
        func pt(_ a: Float, _ ra: Float, _ rb: Float) -> V2 { V2(ra * cos(a), spring + rb * sin(a)) }
        let n = count, gapA: Float = 0.007
        // Mortar bed: full ring set back from the face, a little inside the voussoir outline.
        var ring: [V2] = []
        for k in 0...24 { ring.append(pt(Float(k) / 24 * .pi, Ao - 0.006, Bo - 0.006)) }
        for k in (0...24).reversed() { ring.append(pt(Float(k) / 24 * .pi, Ai + 0.006, Bi + 0.006)) }
        m.add(Prim.extrude(ring, depth: D - 0.04, bevel: 0.001, bevelSegments: 1, material: mortar), Xform(translation: V3(0, 0, (D - 0.04) / 2)))
        for i in 0..<n {
            // Right to left, so voussoir 0 starts at the right impost.
            let a0 = Float(i) / Float(n) * .pi + gapA, a1 = Float(i + 1) / Float(n) * .pi - gapA
            let key = i == n / 2
            let ext: Float = key ? 0.03 : 0
            var poly: [V2] = []
            for s in 0...3 { poly.append(pt(a0 + (a1 - a0) * Float(s) / 3, Ao, Bo + ext)) }
            for s in (0...3).reversed() { poly.append(pt(a0 + (a1 - a0) * Float(s) / 3, Ai, Bi)) }
            let face = D - (key ? 0.0 : 0.012 + rng.float(0...0.003))
            let mat = key ? stone : (i % 2 == 0 ? stoneSooted : (rng.int(0...3) == 0 ? mortar : stone))
            m.add(Prim.extrude(poly, depth: face, bevel: 0.0035, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0, face / 2)))
        }
        // Roll moulding on the front intrados edge, built as a swept bead in four segment runs.
        let roll = Shape2D.polygon(sides: 10, radius: 0.014)
        var path: [V3] = []
        for k in 0...40 { path.append(V3(pt(Float(k) / 40 * .pi, Ai - 0.002, Bi - 0.002), D - 0.016)) }
        m.add(Prim.sweep(roll, along: path, up: FA.Z, material: stone))
        var outer: [V3] = []
        for k in 0...48 { outer.append(V3(pt(Float(k) / 48 * .pi, Ao - 0.012, Bo - 0.012), D - 0.02)) }
        m.add(Prim.sweep(Shape2D.polygon(sides: 8, radius: 0.011), along: outer, up: FA.Z, material: stoneSooted))
        // Billet moulding on the outer face: alternating raised blocks along the extrados.
        let nb = 30
        for k in 0..<nb where k % 2 == 0 {
            let a = (Float(k) + 0.5) / Float(nb) * .pi
            let p = pt(a, Ao - 0.05, Bo - 0.05)
            let tang = atan2(Bo * cos(a), -Ao * sin(a)) * 180 / .pi
            FA.box(&m, V3(0.05, 0.03, 0.016), V3(p.x, p.y, D - 0.012 - 0.002), stone, r: 0.002, rot: FA.q(tang + 90 + 90, FA.Z))
        }
        // Imposts: block plus overhanging cap, one corner chipped.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.24, spring - 0.022, D), V3(s * (Ao - 0.12), (spring - 0.022) / 2, D / 2), stoneSooted, r: 0.004)
            FA.run(&m, [V2(0, 0), V2(D, 0), V2(D, 0.008), V2(D - 0.004, 0.016), V2(0, 0.022)], length: 0.24,
                   at: V3(s * (Ao - 0.12), spring - 0.022, -0.0), stone, bevel: 0.0015)
        }
        FA.box(&m, V3(0.05, 0.03, 0.03), V3(Ao - 0.02, 0.015, D - 0.014), mortar, r: 0.004, rot: FA.q(14, FA.Z))
        groundAO(&m, height: 0.08, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
