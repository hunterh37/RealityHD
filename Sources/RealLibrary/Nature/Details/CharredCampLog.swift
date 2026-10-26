import simd
import Foundation

/// Half-burnt camp log, 55 cm long and 17 cm thick: one end burnt to cracked charcoal blocks, the other still bark-covered, ash on the ground.
public struct CharredCampLog: RealAsset {
    public static let id = "charred-camp-log"
    public static let summary = "Half-burnt camp log, 55 cm long, one end cracked charcoal blocks, the other end still barked, with ash scattered around."
    public static let tags = ["nature", "wood", "ground"]
    public static let budget = 4_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 0.9)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        DetailKit20.lods(SeededRNG(seed: seed), dist: 4) { lod, rng in
            let hi = lod == 0
            var parts: [Surface] = []
            let L: Float = 0.55, R = rng.float(0.078...0.092), yaw = rng.float(-0.2...0.2)
            let ax = V3(cos(yaw), 0, sin(yaw)), side = V3(-sin(yaw), 0, cos(yaw))
            let sides = hi ? 16 : 8, segs = hi ? 10 : 4
            let split = Int(Float(segs) * 0.58)
            var pts: [V3] = [], radii: [Float] = [], bend = rng.float(-0.012...0.012)
            for k in 0...segs {
                let t = Float(k) / Float(segs)
                var r = R * (1 - 0.06 * t)
                if k >= split { r *= 1 - 0.38 * pow(max(0, (t - 0.58) / 0.42), 1.6) * rng.float(0.8...1.1) }
                pts.append(ax * (t - 0.5) * L + side * bend * sin(.pi * t) + V3(0, r - 0.006, 0))
                radii.append(r * rng.float(0.97...1.03))
            }
            let sp = split
            parts.append(Prim.tube(Array(pts[0...sp]), radii: Array(radii[0...sp]), sides: sides, seamTile: 0.3, material: "bark.pine:2A2018", capEnd: true))
            parts.append(Prim.tube(Array(pts[sp...segs]), radii: Array(radii[sp...segs]).map { $0 * 0.99 }, sides: sides, seamTile: 0.3, material: "wood.charred:1B1716", capEnd: true))
            // charcoal scale blocks on the burnt section
            let nb = hi ? 110 : 30
            for _ in 0..<nb {
                let t = Float(sp) / Float(segs) + rng.float(0...1) * (1 - Float(sp) / Float(segs))
                let k = min(segs - 1, Int(t * Float(segs)))
                let f = t * Float(segs) - Float(k)
                let c = pts[k] + (pts[k + 1] - pts[k]) * f, r = radii[k] * (1 - f) + radii[k + 1] * f
                let a = rng.float(0...(2 * .pi))
                let n = simd_normalize(side * cos(a) + V3(0, sin(a), 0))
                let tone = 24 + 12 * rng.int(0...3)
                parts.append(DetailKit22.chunk(c + n * r * 0.97, u: ax, n: n, len: rng.float(0.018...0.04), wid: rng.float(0.016...0.034), th: rng.float(0.006...0.011),
                                               material: MaterialKey(String(format: "wood.charred:%02X%02X%02X", tone, tone - 3, tone - 4))))
            }
            // ember-grey ash flakes on the ground
            for _ in 0..<(hi ? 26 : 8) {
                let p = rng.inDisc(radius: 0.16), o = V2(0.0, 0.0)
                let g = 64 + 12 * rng.int(0...3)
                parts.append(DetailKit22.chunk(V3(p.x + o.x + ax.x * 0.04, 0.0025, p.y * 0.8), u: V3(rng.float(-1...1), 0, rng.float(-1...1)), n: .up,
                                               len: rng.float(0.03...0.09), wid: rng.float(0.025...0.07), th: 0.005, material: MaterialKey(String(format: "ground.sand:%02X%02X%02X", g, g - 2, g - 6))))
            }
            return DetailKit22.model(Self.id, parts)
        }
    }
}
