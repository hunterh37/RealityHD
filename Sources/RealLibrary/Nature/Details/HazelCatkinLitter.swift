import simd
import Foundation

/// Spent hazel catkins on the ground, 4-8 cm long, 8 mm thick, scale-ribbed, curved, with a few leaf scraps.
public struct HazelCatkinLitter: RealAsset {
    public static let id = "hazel-catkin-litter"
    public static let summary = "Eighteen spent hazel catkins, 4-8 cm, curved and scale-ribbed, mixed with dry leaf scraps on forest soil."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 6_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 55, distance: 0.7)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let tones = ["plant.stem:B09A5A", "plant.stem:9C8650", "plant.stem:7E6A40", "plant.stem:C2AE72"]
        for i in 0..<18 {
            let p = rng.inDisc(radius: 0.15)
            let yaw = rng.float(0...6.28)
            let len = rng.float(0.04...0.08), r = rng.float(0.0034...0.0046)
            let sides = 6
            var pts: [V3] = [], rad: [Float] = []
            let curve = rng.float(-0.9...0.9), lift = rng.float(0.0...0.25)
            var pos = V3(p.x, r * 0.9, p.y), ang = yaw
            let n = 8
            for k in 0...n {
                pts.append(pos)
                let t = Float(k) / Float(n)
                rad.append(r * (0.55 + 0.45 * sin(.pi * min(1, t * 0.9 + 0.1))) * (k == n ? 0.5 : 1) * rng.float(0.95...1.05))
                ang += curve / Float(n)
                pos += V3(cos(ang), lift * (k < 4 ? 0.2 : -0.1) * 0.5, sin(ang)) * len / Float(n)
                pos.y = max(pos.y, r * 0.5)
            }
            let tube = Prim.tube(pts, radii: rad, sides: sides, seamTile: 0.01, material: MaterialKey(stringLiteral: tones[i % 4]), capEnd: true,
                                 rippling: { t, v in 1 + 0.16 * sin(v / 0.0042 * 2 * .pi + t * 1.3) })
            m.add(tube)
            // stub of attachment
            m.add(Prim.tube([pts[0], pts[0] - V3(cos(yaw), -0.0005, sin(yaw)) * 0.006], radii: [r * 0.3, r * 0.25], sides: 4, seamTile: 0.01, material: "wood.deadwood:5A4630", capEnd: true))
        }
        for _ in 0..<7 {
            let p = rng.inDisc(radius: 0.15)
            var b = PlantKit.Blade()
            b.root = V3(p.x, 0.001, p.y); b.yaw = rng.float(0...6.28); b.length = rng.float(0.05...0.08); b.width = rng.float(0.035...0.05)
            b.lean = 1.5; b.curl = rng.float(-0.2...0.1); b.segments = 3; b.tipWidth = 0.1; b.belly = 0.7; b.weight = V2(0, 0)
            m.add(PlantKit.blade(b, material: "leaf.beech:8E6730"))
        }
        groundAO(&m, height: 0.02, floor: 0.6)
        PlantKit.finish(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
