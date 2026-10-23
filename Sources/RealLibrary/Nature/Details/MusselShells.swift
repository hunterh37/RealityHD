import simd
import Foundation

/// Freshwater mussel shell halves on a river shore: 5 to 9 valves, 6 to 12 cm long, dark rough outer
/// with growth rings, pearly nacre inside, some lying open side up. 2 LODs.
public struct MusselShells: RealAsset {
    public static let id = "mussel-shells"
    public static let summary = "Five to nine freshwater mussel shell halves, 6-12 cm, ringed dark outside and pearly nacre inside; 2 LODs."
    public static let tags = ["nature", "river", "water"]
    public static let budget = 4_900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.9, ground: false)

    public var count: ClosedRange<Int> = 5...9
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [4])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var placed: [(V2, Float)] = []
        var n = rng.int(count), tries = 0
        while n > 0 && tries < 400 {
            tries += 1
            let L = rng.float(0.06...0.12)
            let p = rng.inDisc(radius: 0.17)
            let yaw = rng.float(0...(2 * .pi))
            let open = rng.chance(0.55)
            let tint = ["3A2B1E", "2E2A20", "463524"][rng.int(0...2)]
            let nac = rng.chance(0.5) ? "B8B4C6" : "C4B8B4"
            let lean = rng.float(-0.12...0.12)
            if placed.contains(where: { simd_distance($0.0, p) < ($0.1 + L) * 0.42 }) { continue }
            placed.append((p, L)); n -= 1
            let (o, i) = DetailKit05.shell(length: L, rng: &rng, nu: lod == 0 ? 16 : 8, nv: lod == 0 ? 8 : 4,
                                            outer: "bark.dead:" + tint, inner: "food.egg-shell:" + nac)
            // Open valves lie dome down (rolled over), others dome up.
            let roll = Xform(rotation: simd_quatf(angle: (open ? .pi : 0) + lean, axis: V3(1, 0, 0)))
            let ro = o.transformed(roll), ri = i.transformed(roll)
            let lift = -min(ro.bounds.min.y, ri.bounds.min.y) + 0.0005
            let xf = Xform(translation: V3(p.x, lift, p.y), rotation: DetailKit01.yawQuat(yaw))
            m.add(ro.transformed(xf)); m.add(ri.transformed(xf))
        }
        groundAO(&m)
        return m
    }
}
