import simd
import Foundation

/// English Cottage espaliered fruit tree on a wire trellis, 1.5 m wide and 2.0 m tall: five tensioned
/// galvanised wires on eye bolts set into the wall, one with a rusting straining screw, a trained
/// horizontal-tier tree with a central leader, spurs, leaves, apples and twine ties, planted in a soil
/// mound with mulch. Wall plane at z = 0.
public struct EspalieredFruitTreeWireTrellis: RealAsset {
    public static let id = "espaliered-fruit-tree-wire-trellis"
    public static let summary = "English Cottage espalier, 1.5 m x 2.0 m: tiered fruit tree tied to galvanised wires on eye bolts with a straining screw."
    public static let tags = ["prop", "architecture", "facade", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 6, distance: 1.55)

    /// Training wire.
    public var wire: MaterialKey = "metal.galvanized-aged"
    /// Branch bark.
    public var bark: MaterialKey = "bark.beech"
    /// Leaf material.
    public var leaf: MaterialKey = "leaf.plain:5E8F34"
    /// Ripe fruit tint.
    public var fruit: MaterialKey = "flower.petal:B8322A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ys: [Float] = [0.3, 0.7, 1.1, 1.5, 1.9], reach: [Float] = [0.66, 0.62, 0.52, 0.4, 0.24]
        let hw: Float = 0.72, wz: Float = 0.07, tz: Float = 0.05
        // Wires with a little sag, eye bolts at both ends, straining screw on the right of the second wire.
        for (i, y) in ys.enumerated() {
            let sag: Float = 0.004 + 0.002 * Float(i % 2)
            let pts = (0...10).map { k -> V3 in
                let t = Float(k) / 10
                return V3(-hw + 2 * hw * t, y - sag * 4 * t * (1 - t), wz)
            }
            FA.path(&m, pts, r: 0.0019, wire, sides: 5)
            for s: Float in [-1, 1] {
                FA.rod(&m, V3(s * hw, y, 0.0), V3(s * hw, y, 0.052), r: 0.0042, wire, sides: 6)
                m.add(Prim.torus(major: 0.0115, minor: 0.0028, segments: 14, sides: 5, material: wire),
                      Xform(translation: V3(s * hw, y, wz - 0.003), rotation: FA.q(90, FA.Z)))
                FA.box(&m, V3(0.024, 0.02, 0.004), V3(s * hw, y, 0.002), wire, r: 0.0008)
            }
            if i == 1 {
                // Straining screw: barrel with two nuts and a threaded tail, rusting.
                FA.cylX(&m, r: 0.0065, h: 0.07, at: V3(hw - 0.15, y - 0.001, wz), "metal.rust", bevel: 0.001, segments: 10)
                FA.cylX(&m, r: 0.0095, h: 0.011, at: V3(hw - 0.12, y - 0.001, wz), wire, bevel: 0.0012, segments: 6)
                FA.cylX(&m, r: 0.0095, h: 0.011, at: V3(hw - 0.13 + 0.07, y - 0.001, wz), wire, bevel: 0.0012, segments: 6)
            }
        }
        // Soil mound with mulch at the foot, and the leader.
        m.add(Prim.superellipsoid(V3(0.4, 0.09, 0.1), exponent: 3, subdivisions: 4, material: "soil.potting"), Xform(translation: V3(0, 0.03, tz)))
        m.add(Prim.superellipsoid(V3(0.3, 0.02, 0.08), exponent: 3, subdivisions: 3, material: "mulch.bark"), Xform(translation: V3(0, 0.075, tz)))
        let trunk = (0...12).map { k -> V3 in let t = Float(k) / 12; return V3(0.006 * sin(t * 7), 0.06 + t * 1.84, tz + 0.003 * sin(t * 5)) }
        m.add(Prim.tube(trunk, radii: (0...12).map { 0.028 - 0.016 * Float($0) / 12 }, sides: 8, seamTile: 0.3, material: bark, capEnd: true))
        func leafSurface(_ mat: MaterialKey) -> Surface {
            var s = Prim.superellipsoid(V3(0.052, 0.034, 0.0045), exponent: 2.4, subdivisions: 1, material: mat)
            s.uvs = s.positions.map { V2($0.x, $0.y) }
            s.computeTangents()
            return s
        }
        let leafSet = [leafSurface(leaf), leafSurface("leaf.plain:A5B040"), leafSurface("leaf.plain:9A7A3A")]
        func leafPick() -> Surface {
            let r = rng.float()
            return r < 0.1 ? leafSet[2] : (r < 0.25 ? leafSet[1] : leafSet[0])
        }
        // Tiers: a pair of branches along each wire turning up at the tips, with spurs, leaves, fruit and twine ties.
        for (i, y) in ys.enumerated() {
            for s: Float in [-1, 1] {
                let R = reach[i], r0: Float = 0.017 - 0.002 * Float(i)
                let pts = (0...8).map { k -> V3 in
                    let t = Float(k) / 8
                    let up = t > 0.75 ? (t - 0.75) * 0.25 : 0
                    return V3(s * R * t, y + 0.004 + up + 0.008 * sin(t * 6 + Float(i)), tz + 0.006 * sin(t * 4 + s))
                }
                m.add(Prim.tube(pts, radii: (0...8).map { r0 * (1 - 0.75 * Float($0) / 8) }, sides: 7, seamTile: 0.2, material: bark, capEnd: true))
                let n = Int(R / 0.075)
                for k in 1...n {
                    let t = Float(k) / Float(n + 1)
                    let x = s * R * t
                    let by = y + 0.004 + 0.008 * sin(t * 6 + Float(i))
                    // Twine tie at each second spur.
                    if k % 2 == 0 {
                        FA.box(&m, V3(0.008, 0.012, 0.03), V3(x, by - 0.001, (tz + wz) / 2 + 0.002), "straw.hay", r: 0.002)
                    }
                    let dir: Float = k % 2 == 0 ? 1 : -1
                    let len = rng.float(0.035...0.06)
                    let tip = V3(x + rng.float(-0.01...0.01), by + dir * len, tz + rng.float(-0.012...0.02))
                    FA.rod(&m, V3(x, by, tz), tip, r: 0.0038, bark, sides: 5)
                    for l in 0..<3 {
                        let a = rng.float(0...360)
                        m.add(leafPick(),
                              Xform(translation: tip + V3(Float(l) * 0.022 - 0.022, dir * 0.014 * Float(l % 2), 0.004 * Float(l)), rotation: FA.q(a, FA.Z) * FA.q(rng.float(-18...18), FA.X)))
                    }
                    // Apples hang from some spurs.
                    if rng.chance(0.28) {
                        let green = rng.chance(0.3)
                        m.add(Prim.superellipsoid(V3(0.058, 0.052, 0.058), exponent: 2, subdivisions: 3, material: green ? "flower.petal:A7B947" : fruit),
                              Xform(translation: V3(tip.x, by - 0.045, min(tip.z + 0.01, 0.085))))
                        FA.rod(&m, V3(tip.x, by - 0.015, tip.z), V3(tip.x, by - 0.02, min(tip.z + 0.01, 0.085)), r: 0.002, bark, sides: 4)
                    }
                }
            }
        }
        // Crown leaves and a bud shoot at the leader tip.
        for _ in 0..<4 {
            m.add(leafSet[0],
                  Xform(translation: V3(rng.float(-0.03...0.03), 1.93 + rng.float(0...0.05), tz + rng.float(0...0.02)), rotation: FA.q(rng.float(0...360), FA.Z)))
        }
        // One fallen windfall apple at the foot with a bruise, and damp staining on the wall base.
        m.add(Prim.superellipsoid(V3(0.058, 0.05, 0.058), exponent: 2, subdivisions: 3, material: "flower.petal:8C4A22"), Xform(translation: V3(0.2, 0.03, 0.08)))
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
