import simd
import Foundation

/// Climbing rose arch: two wrought iron hoops (posts and round-headed arch) joined by cross purlins and
/// diamond side lattice, on bolted foot plates with ball finials, with rose canes tied in over the left
/// post and across the crown, leaf clusters and blooms in three colours. Free-standing, bounds centered.
public struct ClimbingRoseArch: RealAsset {
    public static let id = "climbing-rose-arch"
    public static let summary = "Cottage garden climbing rose arch 1.4 x 2.4 m: wrought iron hoops with side lattice, foot plates, finials and trained roses in bloom."
    public static let tags = ["prop", "architecture", "facade", "metal", "plant", "garden"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 8, distance: 4.6)

    /// Clear width between posts, spring height of the arch and overall depth (m).
    public var width: Float = 1.2
    public var spring: Float = 1.78
    public var depth: Float = 0.5
    public var leafCount: Int = 120
    public var bloomCount: Int = 28
    public var iron: MaterialKey = "metal.wrought-iron"
    public var rust: MaterialKey = "metal.rust"
    public var leaf: MaterialKey = "leaf.plain:3F6A2B"
    public init() {}

    /// Hoop centreline: up the left post, over the semicircular head, down the right post.
    private func hoop(_ z: Float) -> [V3] {
        let hw = width / 2, ry: Float = 0.58
        var pts = [V3(-hw, 0.03, z), V3(-hw, spring * 0.5, z), V3(-hw, spring, z)]
        for i in 1..<18 {
            let a = Float(i) / 18 * .pi
            pts.append(V3(-hw * cos(a), spring + ry * sin(a), z))
        }
        pts += [V3(hw, spring, z), V3(hw, spring * 0.5, z), V3(hw, 0.03, z)]
        return pts
    }

    private func onArch(_ t: Float, _ z: Float) -> V3 {
        // t 0...1 along the left post, head and right post by arc length (approximate).
        let hw = width / 2, ry: Float = 0.58
        let post = spring, head = .pi * (hw + ry) / 2
        let total = post * 2 + head
        let s = t * total
        if s < post { return V3(-hw, s, z) }
        if s > post + head { return V3(hw, total - s, z) }
        let a = (s - post) / head * .pi
        return V3(-hw * cos(a), spring + ry * sin(a), z)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, zf = depth / 2
        for z in [-zf, zf] {
            FA.path(&m, hoop(z), r: 0.0125, iron, sides: 6)
            // Ball finial at the crown, collars where the posts meet the head, and rust at the joints.
            FC.bead(&m, r: 0.026, at: V3(0, spring + 0.58 + 0.02, z), iron, sub: 3)
            FA.cylZ(&m, r: 0.0085, h: 0.03, at: V3(0, spring + 0.58 - 0.01, z - 0.015), iron, segments: 10)
            for s in [-1, 1] as [Float] {
                FC.bead(&m, r: 0.0195, at: V3(s * hw, spring, z), iron, sub: 2)
                FA.box(&m, V3(0.04, 0.03, 0.04), V3(s * hw, 0.015, z), iron, r: 0.004)
                // Foot plate with four bolts.
                FA.box(&m, V3(0.1, 0.008, 0.1), V3(s * hw, 0.004, z), iron, r: 0.002)
                for (bx, bz) in [(-0.035, -0.035), (0.035, -0.035), (-0.035, 0.035), (0.035, 0.035)] as [(Float, Float)] {
                    FC.bead(&m, r: 0.0065, at: V3(s * hw + bx, 0.01, z + bz), "metal.steel", sub: 1)
                }
                FA.box(&m, V3(0.05, 0.05, 0.05), V3(s * hw, 0.5, z), rust, r: 0.01)
            }
        }
        // Cross purlins joining the hoops along the head, plus collar bands where they meet.
        for i in 1...9 {
            let p0 = onArch(0.3 + Float(i) / 10 * 0.4, -zf), p1 = onArch(0.3 + Float(i) / 10 * 0.4, zf)
            FA.rod(&m, p0, p1, r: 0.0075, iron, sides: 6)
        }
        // Side lattice: rails and diamond diagonals between the posts, both sides.
        for s in [-1, 1] as [Float] {
            let x = s * hw
            for y in [0.35, 0.80, 1.25, 1.70] as [Float] {
                FA.rod(&m, V3(x, y, -zf), V3(x, y, zf), r: 0.0085, iron, sides: 6)
            }
            for k in 0..<6 {
                let y0 = 0.35 + Float(k) * 0.23
                FA.rod(&m, V3(x, y0, -zf), V3(x, y0 + 0.22, zf), r: 0.0055, iron, sides: 5)
                FA.rod(&m, V3(x, y0, zf), V3(x, y0 + 0.22, -zf), r: 0.0055, iron, sides: 5)
            }
        }
        // Rose canes: one heavy cane up the left post and over the crown, a second thin one on the right.
        var cane: [V3] = []
        for i in 0...60 {
            let t = 0.02 + Float(i) / 60 * 0.62
            let p = onArch(t, -zf)
            cane.append(p + V3(0.02 * sin(Float(i) * 0.7), 0.02 * sin(Float(i) * 0.5), 0.02 + 0.018 * sin(Float(i) * 0.9)))
        }
        FA.path(&m, cane, r: 0.0065, "plant.stem", sides: 5)
        var cane2: [V3] = []
        for i in 0...40 {
            let t = 0.98 - Float(i) / 40 * 0.42
            let p = onArch(t, zf)
            cane2.append(p + V3(0.015 * sin(Float(i) * 0.8), 0.01 * sin(Float(i) * 0.6), -0.02 - 0.015 * sin(Float(i) * 1.1)))
        }
        FA.path(&m, cane2, r: 0.0055, "plant.stem", sides: 5)
        let all = cane + cane2
        for _ in 0..<leafCount {
            let p = rng.pick(all)
            m.add(Prim.superellipsoid(V3(0.07, 0.095, 0.007) * rng.float(0.8...1.25), exponent: 2.4, subdivisions: 2, material: leaf),
                  Xform(translation: p + V3(rng.float(-0.06...0.06), rng.float(-0.07...0.07), rng.float(-0.04...0.04)),
                        rotation: FA.q(rng.float(0...360), FA.Z) * FA.q(rng.float(-40...40), FA.X)))
        }
        let blooms: [MaterialKey] = ["flower.petal:E5A9B8", "flower.petal:F1E8DA", "flower.petal:B02F4C", "flower.petal:E5A9B8"]
        for _ in 0..<bloomCount {
            let p = rng.pick(all)
            let c = p + V3(rng.float(-0.06...0.06), rng.float(-0.06...0.06), 0.02 * (p.z > 0 ? -1 : 1) * 0 + (p.z > 0 ? -0.02 : 0.02))
            m.add(Prim.superellipsoid(V3(0.088, 0.088, 0.055) * rng.float(0.8...1.15), exponent: 2.3, subdivisions: 3, material: rng.pick(blooms)),
                  Xform(translation: c, rotation: FA.q(rng.float(0...360), FA.Z)))
            FA.cylZ(&m, r: 0.011, h: 0.008, at: c + V3(0, 0, p.z > 0 ? -0.03 : 0.022), "plastic.yellow", bevel: 0.0, segments: 5)
        }
        _ = rng.float()
        groundAO(&m, height: 0.12, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
