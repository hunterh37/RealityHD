import simd
import Foundation

/// Single broadleaf cattail stalk, ~1.5 m: slender green culm, 14 to 19 cm brown velvet head 2.5 cm thick,
/// a thin tan spike above it and 3 to 4 long strap leaves wrapping the base. Seeded lean and curl.
public struct CattailStalk: RealAsset {
    public static let id = "cattail-stalk"
    public static let summary = "Single cattail stalk, ~1.5 m: green culm, 16 cm brown velvet head, thin tan spike and 3-4 strap leaves at the base; 2 LODs."
    public static let tags = ["nature", "plant", "grass", "water"]
    public static let budget = 700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 10, distance: 1.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        var levels = [Model(name: Self.id), Model(name: Self.id)]
        let yaw = rng.float(0...6.28), h = rng.float(1.3...1.7)
        let pts = PlantKit.arc(from: .zero, height: h, yaw: yaw, lean: rng.float(0.02...0.12), bend: rng.float(0.05...0.35), count: 7)
        for l in 0..<2 {
            levels[l].add(PlantKit.stem(pts, radius: 0.0055, tipRadius: 0.0035, sides: l == 0 ? 6 : 4, weight: V2(0, 0.8), phase: phase, material: "plant.stem:5E7A3A"))
        }
        let top = pts[6], axis = simd_normalize(top - pts[5])
        let headLen = rng.float(0.14...0.19), headR = rng.float(0.011...0.015)
        let hb = top - axis * (headLen + 0.1)
        let hp = (0...6).map { hb + axis * headLen * Float($0) / 6 }
        let hr: [Float] = [0.003, headR * 0.82, headR * 0.97, headR, headR * 0.95, headR * 0.7, 0.003]
        let hw: [Float] = [0.74, 0.75, 0.77, 0.78, 0.8, 0.82, 0.84]
        for l in 0..<2 {
            var head = Prim.tube(hp, radii: hr, sides: l == 0 ? 10 : 5, seamTile: 0.04, material: "plant.cattail", weights: hw, phase: phase, capEnd: true)
            head.occlusion = Array(repeating: 0.92, count: head.positions.count)
            levels[l].add(head)
        }
        let spike = PlantKit.stem([hp[6], hp[6] + axis * 0.05, top + axis * 0.06, top + axis * 0.085 + V3(0.004, 0, 0)], radius: 0.002, tipRadius: 0.0007,
                                  weight: V2(0.84, 0.9), phase: phase, material: "plant.stem:9A8660")
        levels[0].add(spike)
        levels[1].add(spike)
        for k in 0..<rng.int(3...4) {
            var rr = rng.fork(10 + k)
            let ly = yaw + rr.float(-1.2...1.2) + (k % 2 == 0 ? 0 : .pi)
            let len = h * rr.float(0.6...0.95)
            for l in 0..<2 {
                var r2 = rr
                levels[l].add(DetailKit12.leaf(root: V3(rr.float(-0.01...0.01), 0, rr.float(-0.01...0.01)), yaw: ly, length: len, width: 0.015 * rr.float(0.8...1.25),
                                               lean: rr.float(0.04...0.22), curl: rr.float(0.2...0.9), twist: rr.float(-0.6...0.6),
                                               segments: l == 0 ? 6 : 3, material: "grass.reed", rng: &r2, phase: phase + Float(k) * 0.3))
            }
        }
        for l in levels.indices { PlantKit.finish(&levels[l]) }
        return LODModel(levels: levels, switchDistances: [10])
    }
}
