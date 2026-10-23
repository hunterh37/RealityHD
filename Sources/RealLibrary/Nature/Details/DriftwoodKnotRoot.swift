import simd
import Foundation

/// Bleached driftwood root knot, ~55 cm long and 30 cm tall: a stubby trunk section flaring into a fat knot
/// with 5 to 7 broken root arms that taper, curve and end in splintered stumps; one side lies on the ground.
public struct DriftwoodKnotRoot: RealAsset {
    public static let id = "driftwood-knot-root"
    public static let summary = "Bleached driftwood root knot, ~55 cm long: trunk stub flaring into a knot with 5-7 tapered, curved, broken root arms; 2 LODs."
    public static let tags = ["nature", "wood", "river"]
    public static let budget = 3_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 30, distance: 0.9)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var levels: [Model] = []
        for lod in 0..<2 {
            var r = SeededRNG(seed: seed ^ 0x9E37)
            var m = Model(name: Self.id)
            var wood = Surface(material: "wood.deadwood"), ends = Surface(material: "wood.driftwood-end")
            let sides = lod == 0 ? 9 : 5, full = 8, segs = lod == 0 ? 8 : 4, st = full / segs
            func sub(_ p: [V3]) -> [V3] { stride(from: 0, through: full, by: st).map { p[$0] } }
            let ph = Float(seed % 97)
            func jit(_ i: Float, _ a: Float, _ k: Float) -> Float { 1 + a * sin(i * 12.9898 + k * 78.233 + ph) }
            let tr = r.float(0.06...0.08)
            // trunk stub along +X, ending in a flat sawn-off break
            let tl = r.float(0.2...0.28)
            let trunk = sub(DetailKit02.limbPath(from: V3(-0.08, tr + 0.02, 0), dir: V3(-1, 0.05, r.float(-0.2...0.2)), len: tl, segs: full, wobble: 0.1, rng: &r))
            let trr = (0...segs).map { i -> Float in
                let f = Float(i) / Float(segs)
                return tr * (1 + 0.15 * (1 - f)) * (1 - 0.1 * f) * jit(Float(i), 0.07, 1)
            }
            wood.append(Prim.tube(trunk, radii: trr, sides: sides, seamTile: 0.3, material: "wood.deadwood", capEnd: false))
            ends.append(Prim.tube([trunk[segs] - V3(0.002, 0, 0) * 0, trunk[segs] + simd_normalize(trunk[segs] - trunk[segs - 1]) * 0.004],
                                  radii: [trr[segs] * 0.97, trr[segs] * 0.9], sides: sides, seamTile: 0.3, material: "wood.driftwood-end", capEnd: true))
            // knot: fat bulb at the root end
            let kc = V3(-0.08, tr + 0.02, 0)
            let kr = tr * r.float(1.35...1.6)
            let bulb = [kc + V3(0.07, 0, 0.01), kc + V3(0.02, 0.01, 0), kc + V3(-0.04, 0, 0.01), kc + V3(-0.08, -0.005, 0.0)]
            wood.append(Prim.tube(bulb, radii: [tr * 0.9, kr, kr * 0.95, kr * 0.3], sides: sides, seamTile: 0.3, material: "wood.deadwood", capEnd: true))
            // root arms
            let arms = r.int(5...7)
            for a in 0..<arms {
                let ang = (Float(a) + r.float(-0.3...0.3)) / Float(arms) * 2 * .pi
                let down = r.float(-0.55...0.25)
                let dir = V3(-0.5 + r.float(-0.2...0.2), down, 0) + V3(0, 0, 0)
                let rot = simd_quatf(angle: ang, axis: V3(1, 0, 0))
                let d0 = simd_normalize(rot.act(V3(-1, 0.1, 0)) * 0.9 + dir * 0.4)
                let len = r.float(0.14...0.3)
                let start = kc + rot.act(V3(-0.03, kr * 0.55, 0))
                var pts = DetailKit02.limbPath(from: start, dir: d0, len: len, segs: full, wobble: 0.22, rng: &r)
                for i in pts.indices { pts[i].y -= 0.05 * pow(Float(i) / Float(full), 2) * len / 0.2 }
                pts = sub(pts)
                // roots droop under gravity
                let r0 = kr * r.float(0.42...0.6)
                let radii = (0...segs).map { i -> Float in
                    let f = Float(i) / Float(segs)
                    return max(0.004, r0 * (1 - 0.82 * pow(f, 0.8)) * jit(Float(i), 0.1, Float(a) + 3))
                }
                wood.append(Prim.tube(pts, radii: radii, sides: max(4, sides - 2), seamTile: 0.3, material: "wood.deadwood", capEnd: false))
                if r.chance(0.5) {
                    let e = pts[segs], ax = simd_normalize(pts[segs] - pts[segs - 1])
                    ends.append(Prim.tube([e, e + ax * 0.004], radii: [radii[segs] * 0.98, radii[segs] * 0.5], sides: max(4, sides - 2), seamTile: 0.3, material: "wood.driftwood-end", capEnd: true))
                }
            }
            // plank texture runs grain along U: swap so the grain follows the tube axis
            for i in wood.uvs.indices { wood.uvs[i] = V2(wood.uvs[i].y, wood.uvs[i].x) }
            wood.computeTangents(); ends.computeTangents()
            m.add(wood); m.add(ends)
            levels.append(DetailKit12.settle(m, sink: 0.005))
        }
        _ = rng.float()
        for k in levels.indices { groundAO(&levels[k]) }
        return LODModel(levels: levels, switchDistances: [6])
    }
}
