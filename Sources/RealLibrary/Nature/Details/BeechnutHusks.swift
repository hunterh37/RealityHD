import simd
import Foundation

/// 8-12 beech husks on leaf litter: 2 cm four-valved prickly cupules, most split open with 2 glossy
/// three-sided nuts, 1.7 cm. LOD1: fewer spines.
public struct BeechnutHusks: RealAsset {
    public static let id = "beechnut-husks"
    public static let summary = "8-12 spiky split beech husks with three-sided nuts lying on beech leaf litter, 25 cm patch; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 5_400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.55)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        DetailKit10.litter(&m0, radius: 0.15, count: 12, rng: &rng)
        var lr = SeededRNG(seed: seed)
        DetailKit10.litter(&m1, radius: 0.15, count: 12, rng: &lr)
        let n = rng.int(8...12)
        let husk: MaterialKey = "bark.dead:8A6034"
        for i in 0..<n {
            let p = rng.inDisc(radius: 0.11)
            let yaw = rng.float(0...6.28)
            let size = rng.float(0.85...1.15)
            let open = rng.chance(0.75)
            let c = V3(p.x, 0.009, p.y)
            let tilt = simd_quatf(angle: rng.float(0...0.6), axis: V3(-sin(yaw), 0, cos(yaw)))
            let x = Xform(translation: c, rotation: tilt * simd_quatf(angle: yaw, axis: .up), scale: V3(repeating: size))
            for (lod, spines) in [(0, 7), (1, 1)] {
                var h = Model(name: Self.id)
                // Four valves, each a curved shell piece flaring outward, with spines.
                let valves = rng.chance(0.25) ? 3 : 4
                for v in 0..<valves {
                    let a = Float(v) / Float(valves) * 2 * .pi + rng.float(-0.12...0.12)
                    let flare = open ? rng.float(0.5...1.0) : rng.float(0.05...0.2)
                    let dir = V3(cos(a), 0, sin(a))
                    var b = PlantKit.Blade()
                    b.root = dir * 0.002 + V3(0, 0.001, 0)
                    b.yaw = a; b.length = rng.float(0.019...0.025); b.width = 0.015
                    b.lean = 0.25 + flare * 0.9; b.curl = -0.5 - flare * 0.4; b.segments = 3; b.tipWidth = 0.35; b.belly = 0.4
                    b.weight = V2(0, 0); b.ao = V2(0.5, 0.9)
                    h.add(PlantKit.blade(b, material: husk))
                    // Spines.
                    for _ in 0..<spines {
                        let t = rng.float(0.15...0.95), side = rng.float(-0.4...0.4)
                        let th = b.lean + b.curl * t * 0.5
                        let tang = V3(-sin(a), 0, cos(a))
                        let pos = b.root + dir * (sin(th) * b.length * t) + V3(0, cos(th) * b.length * t, 0) + tang * side * b.width * (1 - 0.6 * t)
                        let nrm = (dir * cos(th) + V3(0, -sin(th) * 0, 0) + V3(0, 0.8, 0) * 0 + tang * side * 0.6 + V3(0, 0.5, 0) + dir * 0.7).normalized
                        let len = rng.float(0.004...0.007)
                        h.add(Prim.tube([pos, pos + nrm * len * 0.55 + V3(0, 0.0008, 0), pos + nrm * len], radii: [0.0005, 0.0003, 0.00008], sides: 3, seamTile: 0.004, material: husk, capEnd: false))
                    }
                }
                // Inner lining base.
                h.add(Prim.lathe([V2(0, 0.0), V2(0.007, 0.0015), V2(0.009, 0.006)], segments: 8, seamTile: 0.02, material: husk))
                // Stalk.
                h.add(Prim.tube([V3(0, 0, 0), V3(0.004, -0.003, 0.002), V3(0.01, 0.0, 0.004)].map { $0 * 0 + $0 }, radii: [0.0012, 0.0011, 0.001], sides: 4, seamTile: 0.01, material: husk, capEnd: true))
                if lod == 0 { m0.add(h, x) } else { m1.add(h, x) }
            }
            // Nuts in/near open husks.
            if open {
                for k in 0..<2 {
                    let off = V3(rng.float(-0.006...0.006), 0.003, rng.float(-0.006...0.006))
                    let q = simd_quatf(angle: rng.float(0...6.28), axis: .up) * simd_quatf(angle: rng.float(1.2...1.9), axis: V3(1, 0, 0))
                    let nut = Prim.lathe([V2(0, 0), V2(0.0045, 0.0025), V2(0.0058, 0.008), V2(0.004, 0.0145), V2(0, 0.0175)], segments: 3, seamTile: 0.02, material: "bark.dead:6B4A2C")
                    let nx = Xform(translation: c + x.rotation.act(off) * 1, rotation: q)
                    m0.add(nut, nx); m1.add(nut, nx)
                    _ = k
                }
            }
            _ = i
        }
        // A couple of loose nuts.
        for _ in 0..<rng.int(2...4) {
            let p = rng.inDisc(radius: 0.13)
            let q = simd_quatf(angle: rng.float(0...6.28), axis: .up) * simd_quatf(angle: 1.5, axis: V3(1, 0, 0))
            let nut = Prim.lathe([V2(0, 0), V2(0.0045, 0.0025), V2(0.0058, 0.008), V2(0.004, 0.0145), V2(0, 0.0175)], segments: 3, seamTile: 0.02, material: "bark.dead:6B4A2C")
            let nx = Xform(translation: V3(p.x, 0.005, p.y), rotation: q)
            m0.add(nut, nx); m1.add(nut, nx)
        }
        groundAO(&m0, height: 0.03, floor: 0.6); groundAO(&m1, height: 0.03, floor: 0.6)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }
}
