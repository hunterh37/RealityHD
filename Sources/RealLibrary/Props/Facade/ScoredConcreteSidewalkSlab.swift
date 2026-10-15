import simd
import Foundation

/// Scored concrete sidewalk tile, 2 x 2 m: four 1 x 1 m poured slabs, 100 mm thick on a gravel
/// sub-base, separated by 12 mm sealed expansion joints. Each slab has a tooled control joint at
/// mid-span, edger-rounded margins, a broom finish, and one slab carries a hairline crack.
public struct ScoredConcreteSidewalkSlab: RealAsset {
    public static let id = "scored-concrete-sidewalk-slab"
    public static let summary = "Scored concrete sidewalk tile, 2 x 2 m: poured slabs with tooled control joints, sealed expansion joints, edged margins and broom finish."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.15, 2.0)
    /// Slab thickness (m).
    public var slabThickness: Float = 0.1
    /// Expansion joint width (m).
    public var expansionJoint: Float = 0.012
    /// Tooled control joint width (m).
    public var controlJoint: Float = 0.005
    /// Control joint depth (m).
    public var controlDepth: Float = 0.025
    /// Slab tones (sRGB hex).
    public var tones: [UInt32] = [0xA8A59E, 0x9E9B93, 0xB0ADA5, 0xA19C92]
    /// Slab concrete.
    public var concrete: MaterialKey = "concrete.sidewalk"
    /// Joint sealant.
    public var sealant: MaterialKey = "asphalt.sealant"
    /// Sub-base.
    public var subBase: MaterialKey = "ground.gravel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y, base = top - slabThickness, hx = size.x / 2, hz = size.z / 2, e = expansionJoint
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: base + 0.004, subBase, r: 0.003)
        let crackSlab = rng.int(0...3)
        for sj in 0..<2 { for si in 0..<2 {
            let idx = sj * 2 + si
            let x0 = -hx + Float(si) * hx + e / 2, x1 = x0 + hx - e, z0 = -hz + Float(sj) * hz + e / 2, z1 = z0 + hz - e
            let mat = "\(concrete):\(String(format: "%06X", rng.pick(tones)))"
            let settle: Float = idx == crackSlab ? 0.003 : rng.float(0...0.0015)
            let t = top - settle
            // Lower body carries the full slab under the control joint.
            GK.box(&m, V3((x0 + x1) / 2, base + (slabThickness - controlDepth) / 2, (z0 + z1) / 2), V3(x1 - x0, slabThickness - controlDepth - settle, z1 - z0), mat, r: 0.004)
            // Two halves above, split by the tooled control joint running across X.
            let mid = (x0 + x1) / 2, cj = controlJoint
            for h in 0..<2 {
                let a = h == 0 ? x0 : mid + cj / 2, b = h == 0 ? mid - cj / 2 : x1
                GK.box(&m, V3((a + b) / 2, t - controlDepth / 2 - 0.001, (z0 + z1) / 2), V3(b - a, controlDepth + 0.002, z1 - z0), mat, r: 0.008)
            }
            if idx == crackSlab {
                // Hairline crack wandering across one half.
                var p = V2(x0 + 0.05, rng.float(z0 + 0.2...z1 - 0.2))
                while p.x < mid - 0.05 {
                    let q = V2(min(mid - 0.04, p.x + rng.float(0.04...0.09)), p.y + rng.float(-0.04...0.04))
                    let d = q - p, len = simd_length(d)
                    GK.box(&m, V3((p.x + q.x) / 2, t - 0.0008, (p.y + q.y) / 2), V3(len, 0.003, 0.0028), sealant, r: 0.0004, yaw: -atan2(d.y, d.x) * 180 / .pi)
                    p = q
                }
            }
        }}
        // Sealed expansion joints: dark sealant 6 mm below the slab tops.
        GK.box(&m, V3(0, top - 0.006 - 0.01, 0), V3(e + 0.002, 0.02, size.z - 0.004), sealant, r: 0.001)
        GK.box(&m, V3(0, top - 0.006 - 0.01, 0), V3(size.x - 0.004, 0.02, e + 0.002), sealant, r: 0.001)
        // Story detail: a pressed-in leaf and a gum blot.
        GK.box(&m, V3(rng.float(-0.8...0.8), top + 0.0004, rng.float(-0.8...0.8)), V3(0.035, 0.0012, 0.035), "asphalt.patch", r: 0.0005)
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.004, bevelSegments: 1, material: concrete), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
