import simd
import Foundation

/// Fallen branch, 70 cm long with one fork, 2.5 cm thick at the butt, rough bark, small dark leaf scars
/// along the stem and a snapped butt end showing wood. 2 LODs.
public struct ForkedBranch: RealAsset {
    public static let id = "forked-branch"
    public static let summary = "Fallen 70 cm branch with a fork, rough bark, leaf scars and a snapped end; 2 LODs."
    public static let tags = ["nature", "ground", "wood"]
    public static let budget = 2_400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.9, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var bark = Surface(material: "bark.oak:7A6248"), scars = Surface(material: "wood.endgrain")
        var lo = Surface(material: "bark.oak:7A6248")
        let yaw = rng.float(0...6.28)
        let d = V3(cos(yaw), 0.05, sin(yaw))
        let a = V3(0, 0.014, 0) - d * 0.35
        // Main stem 0.45 m with forks at ~60%.
        var pts: [V3] = [a]; var p = a; var dd = d
        for _ in 0..<5 {
            dd = simd_normalize(dd + V3(rng.float(-0.12...0.12), rng.float(-0.04...0.02), rng.float(-0.12...0.12)))
            p += dd * 0.09; p.y = max(p.y, 0.012); pts.append(p)
        }
        let radii: [Float] = [0.0125, 0.0115, 0.0105, 0.0095, 0.0085, 0.0075].map { $0 * rng.float(0.95...1.05) }
        bark.append(Prim.tube(pts, radii: radii, sides: 9, seamTile: 0.08, material: "bark.oak:7A6248", capEnd: true))
        lo.append(Prim.tube([pts[0], pts[3], pts[5]], radii: [radii[0], radii[3], radii[5]], sides: 5, seamTile: 0.08, material: "bark.oak:7A6248", capEnd: true))
        for sgn: Float in [1, -1] {
            let dir = simd_normalize(simd_cross(dd, V3(0, 1, 0)) * sgn * 0.5 + dd + V3(0, 0.05, 0))
            let st = rng.state
            DetailKit01.limb(&bark, rng: &rng, from: pts[4], dir: dir, len: rng.float(0.28...0.36), r: 0.0065, fork: 0, sides: 7, material: "bark.oak:7A6248", floorY: 0.0)
            var r2 = SeededRNG(seed: 1); r2.state = st
            DetailKit01.limb(&lo, rng: &r2, from: pts[4], dir: dir, len: 0.3, r: 0.0065, fork: 0, sides: 4, material: "bark.oak:7A6248", floorY: 0.0)
        }
        // Leaf scars: small dark flattened bumps along the stem.
        for i in 1..<5 where rng.chance(0.85) {
            let c = pts[i] + V3(rng.float(-0.002...0.002), radii[i] * 0.8, rng.float(-0.002...0.002))
            let up = simd_normalize(V3(rng.float(-0.4...0.4), 1, rng.float(-0.4...0.4)))
            let ctr = pts[i] + up * radii[i] * 0.97
            _ = c
            scars.append(Prim.cubeSphere(subdivisions: 2, material: "wood.endgrain") { n in V3(n.x * 0.0035, n.y * 0.0012, n.z * 0.0026) },
                         Xform(translation: ctr, rotation: simd_quatf(from: V3(0, 1, 0), to: up)))
        }
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        bark.computeTangents(); scars.computeTangents(); lo.computeTangents()
        m0.add(bark); m0.add(scars); m1.add(lo)
        groundAO(&m0); groundAO(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [5])
    }
}
