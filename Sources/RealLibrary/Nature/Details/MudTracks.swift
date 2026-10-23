import simd
import Foundation

/// Mud patch, 50 cm, wet and glossy near the water, pressed with raccoon hand prints, deer hoof pairs and heron toe prints.
public struct MudTracks: RealAsset {
    public static let id = "mud-tracks"
    public static let summary = "Fifty-centimeter river mud patch pressed with raccoon, deer and heron tracks and raised displacement rims."
    public static let tags = ["nature", "ground", "river"]
    public static let budget = 6_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 55, distance: 0.9, ground: false)
    public init() {}

    private struct Print { var c: V2; var dir: V2; var kind: Int }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [3])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        func dir(_ a: Float) -> V2 { V2(cos(a), sin(a)) }
        var prints: [Print] = []
        let raccoonA = rng.float(0...6.28), deerA = rng.float(0...6.28), heronA = rng.float(0...6.28)
        for i in 0..<3 { prints.append(Print(c: dir(raccoonA) * (Float(i) * 0.09 - 0.1) + V2(-0.09, 0.08) + dir(raccoonA + 1.57) * (i % 2 == 0 ? 0.02 : -0.02), dir: dir(raccoonA + rng.float(-0.15...0.15)), kind: 0)) }
        for i in 0..<2 { prints.append(Print(c: dir(deerA) * (Float(i) * 0.2 - 0.1) + V2(0.07, -0.12), dir: dir(deerA + rng.float(-0.1...0.1)), kind: 1)) }
        for i in 0..<2 { prints.append(Print(c: dir(heronA) * (Float(i) * 0.17 - 0.08) + V2(0.1, 0.1), dir: dir(heronA + rng.float(-0.12...0.12)), kind: 2)) }
        func perp(_ d: V2) -> V2 { V2(-d.y, d.x) }
        // Depth in meters (positive = pressed) and rim berm.
        func press(_ q: V2) -> (Float, Float) {
            var dep: Float = 0, berm: Float = 0
            for p in prints {
                var w: Float = 0, wb: Float = 0
                switch p.kind {
                case 0: // raccoon: palm + 5 spread toes
                    w = max(w, DetailKit06.oval(q, c: p.c, dir: p.dir, len: 0.016, wid: 0.014))
                    wb = max(wb, DetailKit06.oval(q, c: p.c, dir: p.dir, len: 0.027, wid: 0.025))
                    for k in 0..<5 {
                        let a = (Float(k) - 2) * 0.33
                        let d = V2(p.dir.x * cos(a) - p.dir.y * sin(a), p.dir.x * sin(a) + p.dir.y * cos(a))
                        let tc = p.c + d * 0.034
                        w = max(w, DetailKit06.oval(q, c: tc, dir: d, len: 0.011, wid: 0.0055))
                    }
                case 1: // deer: two pointed halves
                    for s: Float in [-1, 1] {
                        let hc = p.c + perp(p.dir) * s * 0.012
                        w = max(w, DetailKit06.oval(q, c: hc, dir: p.dir, len: 0.036, wid: 0.0125))
                        wb = max(wb, DetailKit06.oval(q, c: hc, dir: p.dir, len: 0.046, wid: 0.02))
                    }
                default: // heron: three long forward toes and a short hind toe
                    for a: Float in [-0.55, 0, 0.55] {
                        let d = V2(p.dir.x * cos(a) - p.dir.y * sin(a), p.dir.x * sin(a) + p.dir.y * cos(a))
                        w = max(w, DetailKit06.oval(q, c: p.c + d * 0.045, dir: d, len: 0.048, wid: 0.0055))
                    }
                    w = max(w, DetailKit06.oval(q, c: p.c - p.dir * 0.02, dir: p.dir, len: 0.022, wid: 0.005))
                }
                dep = max(dep, w); berm = max(berm, wb * (1 - w))
            }
            return (dep, berm)
        }
        let ph = rng.float(0...50)
        m.add(GroundMesh.disc(material: "ground.mud", rings: lod == 0 ? 40 : 18, sectors: lod == 0 ? 72 : 32,
            outline: { a in GroundMesh.outline(a, radius: 0.25, wobble: 0.12, seed: UInt32(seed & 0xFFFF)) },
            height: { q, t in
                let noise = 0.003 * Noise.fbm(V3(q.x * 12 + ph, 0, q.y * 12), octaves: 3, seed: 11)
                let (dep, berm) = press(q)
                let h = 0.016 + noise - 0.013 * dep + 0.0025 * berm
                return h * GroundMesh.rim(t, from: 0.7)
            }))
        groundAO(&m)
        return m
    }
}
