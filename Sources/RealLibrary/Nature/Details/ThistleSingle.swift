import simd
import Foundation

/// Single thistle, 70 cm: ridged stem, deeply cut spiny leaves and a purple flower head on a green bract bulb.
public struct ThistleSingle: RealAsset {
    public static let id = "thistle-single"
    public static let summary = "Single thistle, 70 cm: spiny cut leaves up a grey-green stem and a purple flower head on a spiky bract bulb; 2 LODs."
    public static let tags = ["nature", "plant", "flower", "foliage"]
    public static let budget = 1_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 1.6)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phase = rng.float(0...6.28)
        let lean = rng.float(0.03...0.12), yaw = rng.float(0...6.28)
        let pts = PlantKit.arc(from: V3(0, -0.003, 0), height: 0.68, yaw: yaw, lean: lean, bend: 0.25, count: 8)
        let stem = PlantKit.stem(pts, radius: 0.0045, tipRadius: 0.0022, sides: 5, weight: V2(0, 0.5), phase: phase, material: "plant.stem:7E8F63")
        m0.add(stem); m1.add(stem)
        let leafMat: MaterialKey = "leaf.plain:5E7F4C"
        // Basal rosette then alternate stem leaves, each a main blade plus spiny side lobes.
        for k in 0..<13 {
            let t = k < 5 ? 0 : Float(k - 4) / 9 * 0.75
            let idx = min(pts.count - 1, Int(t * Float(pts.count - 1)))
            let root = k < 5 ? V3(rng.float(-0.005...0.005), 0.0, rng.float(-0.005...0.005)) : pts[idx]
            let ly = yaw + Float(k) * 2.4 + rng.float(-0.4...0.4)
            let len = (k < 5 ? rng.float(0.17...0.24) : 0.16 * (1 - t * 0.7)) * rng.float(0.85...1.1)
            let lean = k < 5 ? rng.float(0.9...1.3) : rng.float(0.8...1.2)
            var ls = [DetailKit03.leaf(root: root, yaw: ly, length: len, width: len * 0.2, lean: lean, curl: rng.float(0.3...0.8), fold: 0.3,
                                       belly: 0.6, tip: 0.05, segments: 5, weight: 0.5, phase: phase, material: leafMat)]
            for j in 0..<4 {
                let at = V3(0, 0, 0)
                _ = at
                let side: Float = j % 2 == 0 ? 1 : -1
                ls.append(DetailKit03.leaf(root: root + V3(0, 0.0005 * Float(j), 0), yaw: ly + side * rng.float(0.5...0.9), length: len * rng.float(0.35...0.55),
                                           width: len * 0.07, lean: lean + 0.1, curl: 0.4, fold: 0.2, belly: 0.4, tip: 0, segments: 2,
                                           weight: 0.6, phase: phase, material: leafMat))
            }
            for l in ls { m0.add(l); if k % 2 == 0 { m1.add(l) } }
        }
        // Flower head: bract bulb, spiky bract fringe, purple floret brush.
        let top = pts.last!
        let head = top + V3(0, 0.006, 0)
        let bulb = DetailKit03.blob(head + V3(0, 0.008, 0), V3(0.022, 0.026, 0.022), sub: 2, material: "leaf.plain:6B8450")
        m0.add(bulb); m1.add(bulb)
        let spikes = DetailKit08.fan(at: head + V3(0, 0.006, 0), axis: V3(0, 1, 0), count: 34, length: 0.015...0.025, width: 0.003,
                                     spread: 0.7...1.9, curl: 0.0...0.3, phase: phase, rng: &rng, material: "leaf.plain:5E7448")
        for s in spikes { m0.add(s) }
        let florets = DetailKit08.fan(at: head + V3(0, 0.03, 0), axis: V3(0, 1, 0), count: 70, length: 0.028...0.042, width: 0.003,
                                      spread: -0.1...0.75, curl: 0.0...0.3, phase: phase, rng: &rng, material: "flower.petal:9A3FA8")
        for f in florets { m0.add(f) }
        for f in florets.prefix(35) { m1.add(f) }
        groundAO(&m0, height: 0.15, floor: 0.6); groundAO(&m1, height: 0.15, floor: 0.6)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [5])
    }
}
