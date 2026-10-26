import simd
import Foundation

/// Fallen sweetgum fruit balls, 3 cm: spiky brown spheres with short stalks, 6 to 10 on bare ground.
public struct SweetgumBalls: RealAsset {
    public static let id = "sweetgum-balls"
    public static let summary = "Six to ten spiky sweetgum gum balls, 3 cm, brown and weathered, some with stalk stubs; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 9_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.55)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit07.lods(seed: seed, switchAt: 3) { lod, rng in
            let n = rng.int(6...10)
            let tints = ["4A3524", "5A4230", "3A2A1C", "6B5238", "443020"]
            var all: [Surface] = []
            var spots: [V2] = []
            for i in 0..<n {
                var p = rng.inDisc(radius: 0.15)
                var tries = 0
                while tries < 30, spots.contains(where: { simd_distance($0, p) < 0.034 }) { p = rng.inDisc(radius: 0.15); tries += 1 }
                spots.append(p)
                let r = rng.float(0.0095...0.0125)
                let tint = tints[i % tints.count]
                let ballMat = MaterialKey("bark.dead:" + tint)
                let spikeMat = MaterialKey("bark.dead:" + tints[(i + 2) % tints.count])
                var parts: [Surface] = [DetailKit07.blob(V3(r, r * 0.95, r * 1.02), sub: lod == 0 ? 5 : 3, material: ballMat, rng: &rng, jitter: 0.07)]
                var sp = Surface(material: spikeMat)
                let count = lod == 0 ? 52 : 22
                for k in 0..<count {
                    // Fibonacci directions with jitter, some spikes broken short.
                    let y = 1 - 2 * (Float(k) + 0.5) / Float(count)
                    let rr = sqrt(max(0, 1 - y * y)), a = Float(k) * 2.39996 + rng.float(-0.15...0.15)
                    let d = simd_normalize(V3(rr * cos(a), y, rr * sin(a)) + rng.unitVector() * 0.12)
                    let len = rng.float(0.0035...0.0075) * (rng.chance(0.18) ? 0.4 : 1)
                    let base = d * r * 0.9
                    let tip = base + d * len + rng.unitVector() * 0.0008
                    sp.append(DetailKit21.tube([base, tip], r0: rng.float(0.0009...0.0014), r1: 0.00012, material: spikeMat))
                }
                parts.append(sp)
                if rng.chance(0.6) {
                    let s0 = V3(0, r * 0.85, 0)
                    let pts = [s0, s0 + V3(0.003, 0.012, 0.002), s0 + V3(0.009, 0.022, 0.003), s0 + V3(0.017, 0.027, 0.002)]
                    parts.append(DetailKit21.tube(pts, r0: 0.0011, r1: 0.0007, material: "bark.dead:5A4630"))
                }
                let q = simd_quatf(angle: rng.float(0...6.28), axis: rng.unitVector())
                parts = parts.map { DetailKit07.xf($0, Xform(translation: .zero, rotation: q)) }
                var placed = parts
                DetailKit21.dropTo(&placed, y: 0.0005)
                DetailKit07.shift(&placed, V3(p.x, 0, p.y))
                all += placed
            }
            DetailKit07.settle(&all, sink: 0.003, center: true)
            return DetailKit21.finish(Self.id, all, aoHeight: 0.02, floor: 0.55)
        }
    }
}
