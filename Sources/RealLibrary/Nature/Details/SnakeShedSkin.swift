import simd
import Foundation

/// Shed garter snake skin, 70 cm long, crumpled translucent tube about 1 cm wide lying in an S curve on litter.
public struct SnakeShedSkin: RealAsset {
    public static let id = "snake-shed-skin"
    public static let summary = "Shed snake skin 70 cm long: a crumpled paper-thin pale tube in a loose S curve with a flared head end."
    public static let tags = ["nature", "ground"]
    public static let budget = 2_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 60, distance: 0.9, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 120), gen(seed, 48)], switchDistances: [3])
    }

    private func gen(_ seed: UInt64, _ n: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = rng.float(0.62...0.78)
        let amp = rng.float(0.05...0.09), waves = rng.float(1.3...1.9), ph = rng.float(0...6.28), tilt = rng.float(-0.25...0.25)
        let ph2 = rng.float(0...40)
        var path: [V3] = [], half: [Float] = [], roll: [Float] = []
        for i in 0..<n {
            let f = Float(i) / Float(n - 1)
            let x = (f - 0.5) * L * 0.96
            let z = amp * sin(f * waves * 2 * .pi + ph) * (0.6 + 0.4 * sin(f * 3 + ph)) + tilt * x
            let y = 0.002 + 0.0035 * max(0, Noise.fbm(V3(f * 14 + ph2, 0, 0), octaves: 2, seed: 9))
            path.append(V3(x, y, z))
            // head end (f = 0) flares, body holds ~9 mm half width flattened, tail tapers to a point
            let body = 0.0085 * (1 + 0.25 * Noise.fbm(V3(f * 9 + ph2, 1, 0), octaves: 2, seed: 4))
            let head = 1 + 0.35 * (1 - smoothstep(0, 0.08, f))
            let tail = f > 0.7 ? max(0.04, 1 - pow((f - 0.7) / 0.3, 1.6)) : 1
            half.append(body * head * tail)
            roll.append(0.7 * Noise.fbm(V3(f * 6 + ph2, 2, 0), octaves: 2, seed: 13) * 2)
        }
        var s = DetailKit16.ribbon(path: path, half: half, thick: 0.0022, roll: roll, noise: 0.22, rng: &rng, material: "fabric.linen:E4DDC6")
        let lift = -s.bounds.min.y - 0.002
        s = s.transformed(Xform(translation: V3(0, lift, 0)))
        s.computeTangents()
        m.add(s)
        groundAO(&m, height: 0.015, floor: 0.7)
        return m
    }
}
