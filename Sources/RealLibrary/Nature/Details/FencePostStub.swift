import simd
import Foundation

/// Rotted fence post stub, 10 cm square and ~50 cm tall: gray weathered grain, splintered broken top,
/// one rusty nail, soil heaped at the foot.
public struct FencePostStub: RealAsset {
    public static let id = "fence-post-stub"
    public static let summary = "Rotted fence post stub, 10 cm square, ~50 cm tall: weathered grain, splintered top, rusty nail, soil at the foot."
    public static let tags = ["nature", "wood", "fence", "ground"]
    public static let budget = 1500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 20, distance: 1.3)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let segs = 14, H: Float = rng.float(0.46...0.54)
        let ph = (0..<4).map { _ in rng.float(0...6.28) }
        let lean = V2(rng.float(-0.03...0.03), rng.float(-0.03...0.03))
        let pts = (0...segs).map { i -> V3 in
            let f = Float(i) / Float(segs)
            return V3(lean.x * f * f + 0.003 * sin(f * 5 + ph[0]), -0.008 + (H + 0.008) * f, lean.y * f * f)
        }
        let radii = (0...segs).map { i -> Float in
            let f = Float(i) / Float(segs)
            let rot = 1 - 0.28 * smoothstep(0.75, 1, f) - 0.06 * (1 - smoothstep(0, 0.2, f)) * 0 // top frays inward
            return 0.05 * rot * (1 + 0.06 * sin(f * 9 + ph[1]) - 0.05 * f)
        }
        var post = Prim.tube(pts, radii: radii, sides: 16, seamTile: 0.1, material: "wood.weathered", capEnd: true, rippling: { t, v in
            let a = t * 2 * .pi
            let e = pow(pow(abs(cos(a)), 4) + pow(abs(sin(a)), 4), -0.25)
            // vertical checks and wind-eroded soft grain
            return e * (1 + 0.035 * sin(a * 6 + v * 2 + ph[2]) * sin(v * 5 + ph[3]) + 0.012 * sin(a * 13 + v * 1.3) - 0.07 * max(0, sin(a * 3 + ph[0])) * smoothstep(0.1, 0.45, v))
        })
        post.uvs = post.uvs.map { V2($0.y, $0.x) }; post.computeTangents()
        m.add(post)
        // splinters at the broken top
        var spl = Surface(material: "wood.deadwood")
        let topP = pts[segs]
        for _ in 0..<3 {
            let a = rng.float(0...6.28), r = rng.float(0.018...0.032)
            let base = V3(topP.x + cos(a) * r, topP.y - 0.06, topP.z + sin(a) * r)
            let hh = rng.float(0.07...0.14)
            let sp = (0...4).map { i -> V3 in let f = Float(i) / 4; return base + V3(cos(a) * 0.01 * f * f, hh * f, sin(a) * 0.01 * f * f) }
            let w0 = rng.float(0.012...0.02)
            spl.append(Prim.tube(sp, radii: [w0, w0 * 0.9, w0 * 0.65, w0 * 0.35, w0 * 0.08], sides: 5, seamTile: 0.05, material: "wood.deadwood", capEnd: true))
        }
        spl.uvs = spl.uvs.map { V2($0.y, $0.x) }; spl.computeTangents(); m.add(spl)
        // rusty nail bent out of the side
        let na = rng.float(0...6.28), ny = rng.float(0.22...0.34)
        let o = V3(cos(na), 0, sin(na)), at = V3(pts[6].x, ny, pts[6].z) + o * 0.045
        let np = [at, at + o * 0.02 + V3(0, 0.002, 0), at + o * 0.04 + V3(0, 0.008, 0), at + o * 0.052 + V3(0, 0.02, 0)]
        var nail = Prim.tube(np, radii: [0.0024, 0.0022, 0.002, 0.0016], sides: 6, seamTile: 0.02, material: "metal.wrought-iron:7A4326", capEnd: true)
        nail.computeTangents(); m.add(nail)
        var mo = DetailKit19.mound(radius: 0.13, height: 0.03, at: V3(0, -0.004, 0), material: "ground.forest", rng: &rng)
        mo.computeTangents(); m.add(mo)
        groundAO(&m, height: 0.18)
        return LODModel(levels: [m], switchDistances: [])
    }
}
