import simd
import Foundation

/// Fallen pine bough, about 65 cm: scaly bark limb thinning to the tip, side twigs drooping to the ground, bottle-brush tufts of 7 cm needles, mostly browning. 2 LODs.
public struct PineBoughFallen: RealAsset {
    public static let id = "pine-bough-fallen"
    public static let summary = "Fallen pine bough, 65 cm: bark limb with drooping side twigs and tufts of green and browning needles; 2 LODs."
    public static let tags = ["nature", "ground", "plant", "wood"]
    public static let budget = 4_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 1.0)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit20.lods(SeededRNG(seed: seed), dist: 4) { lvl, rng in make(lvl, &rng) }
    }

    private func make(_ lvl: Int, _ rng: inout SeededRNG) -> Model {
        let hi = lvl == 0
        var wood = Surface(material: "bark.pine:6A5A48"), green = Surface(material: "plant.stem:5E7A2C"), brown = Surface(material: "plant.stem:8E6B3A")
        let L = rng.float(0.58...0.72), segs = 12, up = V3(0, 1, 0)
        let yaw0 = rng.float(-0.3...0.3)
        var pts = DetailKit02.limbPath(from: V3(-L / 2, 0.03, rng.float(-0.05...0.05)), dir: V3(cos(yaw0), -0.02, sin(yaw0)), len: L, segs: segs, wobble: 0.1, rng: &rng)
        let radii = (0...segs).map { i -> Float in
            let t = Float(i) / Float(segs)
            return (0.0035 + 0.0095 * pow(t, 1.1)) * rng.float(0.92...1.08)
        }
        for i in pts.indices { pts[i].y = max(pts[i].y, radii[i] * 0.85) }
        wood.append(Prim.tube(pts, radii: radii, sides: hi ? 7 : 5, seamTile: 0.05, material: "bark.pine:6A5A48", capEnd: true))
        for i in 1..<segs where rng.chance(0.92) {
            let ti = Float(i) / Float(segs)
            let p = pts[i], tang = simd_normalize(pts[i + 1] - pts[i - 1])
            let sgn: Float = rng.chance(0.5) ? 1 : -1
            let side = simd_normalize(simd_cross(tang, up)) * sgn
            let d0 = simd_normalize(side * 0.8 - tang * 0.5 + V3(0, rng.float(0.1...0.4), 0))
            let tl = rng.float(0.12...0.2) * (0.5 + 0.5 * ti)
            var tw = DetailKit02.limbPath(from: p, dir: d0, len: tl, segs: 4, wobble: 0.15, rng: &rng)
            for k in tw.indices { tw[k].y = max(tw[k].y - 0.035 * Float(k * k) / 16, 0.004) }
            let tr0 = 0.0028 * (0.5 + 0.5 * ti)
            wood.append(Prim.tube(tw, radii: (0..<tw.count).map { tr0 * (1 - 0.65 * Float($0) / 4) }, sides: 4, seamTile: 0.04, material: "bark.pine:6A5A48", capEnd: true))
            let isBrown = rng.chance(0.45)
            for j in 1...4 {
                let tdir = simd_normalize(tw[j] - tw[j - 1])
                for _ in 0..<(hi ? 6 : 3) {
                    let dir = simd_normalize(tdir * 0.9 + V3(rng.float(-1...1), rng.float(-0.5...0.6), rng.float(-1...1)) * 0.5)
                    let len = rng.float(0.065...0.1) * (j == 4 ? 0.85 : 1)
                    let a = tw[j], e = a + dir * len + V3(0, -0.018, 0)
                    var mid = a + dir * len * 0.5
                    mid.y = max(mid.y, 0.001)
                    let end = V3(e.x, max(e.y, 0.0008), e.z)
                    let np = hi ? [a, mid, end] : [a, end]
                    let nd = DetailKit20.spike(np, r0: 0.0008, r1: 0.0002, material: "plant.stem")
                    if isBrown { brown.append(nd) } else { green.append(nd) }
                }
            }
        }
        var m = Model(name: Self.id)
        m.add(wood); m.add(green); m.add(brown)
        groundAO(&m, height: 0.06, floor: 0.6)
        PlantKit.finish(&m)
        return m
    }
}
