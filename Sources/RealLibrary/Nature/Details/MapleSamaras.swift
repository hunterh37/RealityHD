import simd
import Foundation

/// Maple samaras, 12-20 winged seed keys (3-4 cm) scattered on the ground as joined pairs of papery wings.
public struct MapleSamaras: RealAsset {
    public static let id = "maple-samaras"
    public static let summary = "Maple samaras: 12-20 paired-wing seed keys, 3-4 cm, scattered on the ground with ridged seed nuts; 2 LODs."
    public static let tags = ["nature", "ground", "plant"]
    public static let budget = 900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.45, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let n = rng.int(12...20)
        let centers = (0..<2).map { _ in rng.inDisc(radius: 0.06) }
        for i in 0..<n {
            var p = rng.inDisc(radius: 0.14)
            if rng.chance(0.5) { p = centers[i % 2] + rng.inDisc(radius: 0.05) }
            let y0 = 0.003 + Float(i) * 0.0004
            let yaw = rng.float(0...6.28)
            let size = rng.float(0.03...0.04)
            let spread = rng.float(1.0...1.7)
            let tint = rng.chance(0.5) ? "wood.weathered:CFAE72" : "wood.weathered:B8935A"
            for w in 0..<2 {
                var b = PlantKit.Blade()
                let wy = yaw + (w == 0 ? 0 : spread)
                b.root = V3(p.x, y0, p.y); b.yaw = wy
                b.length = size * rng.float(0.9...1.05); b.width = size * rng.float(0.3...0.38)
                b.lean = rng.float(1.45...1.56); b.curl = rng.float(-0.05...0.15); b.twist = .pi + rng.float(-0.4...0.4)
                b.segments = 3; b.belly = 0.35; b.tipWidth = 0.2; b.fold = rng.float(-0.1...0.1)
                b.weight = V2(0, 0); b.ao = V2(0.7, 0.95); b.upNormal = 0.3
                let wing = PlantKit.blade(b, material: tint)
                m0.add(wing); m1.add(wing)
            }
            let nut = DetailKit03.blob(V3(p.x, y0 + 0.002, p.y), V3(0.0035, 0.0025, 0.0035), sub: 1, material: "wood.weathered:7A5A30")
            m0.add(nut); m1.add(nut)
        }
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [5])
    }
}
