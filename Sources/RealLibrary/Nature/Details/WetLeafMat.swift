import simd
import Foundation

/// Wet leaf mat, 80 cm: sodden, dark, compressed oak, beech and maple leaves plastered flat on mud, glossy and veined.
public struct WetLeafMat: RealAsset {
    public static let id = "wet-leaf-mat"
    public static let summary = "Wet leaf mat, 80 cm: sodden dark compressed leaves plastered flat on mud, glossy and veined; 2 LODs."
    public static let tags = ["nature", "ground", "plant"]
    public static let budget = 2_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 1.1, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let mats = ["litter.dry:3A2818", "litter.dry:4A3320", "litter.dry:42281A", "litter.dry:2B2014", "litter.dry:50381E", "litter.dry:352214"]
        let n = 220
        // Mud underlay peeking between leaves.
        let mud = PlantKit.disc(center: V3(0, 0.001, 0), normal: V3(0, 1, 0), radius: 0.33, cup: 0, rim: 16, cell: PlantKit.cell(0, cols: 1, rows: 1), spin: 0, weight: 0, phase: 0, material: "ground.mud:2A2016")
        m0.add(mud); m1.add(mud)
        for i in 0..<n {
            var p = rng.inDisc(radius: 0.44)
            p = V2(p.x * 0.9, p.y * 0.9)
            let c = PlantKit.cell(rng.int(0...15), cols: 4, rows: 4)
            var b = PlantKit.Blade()
            b.length = rng.float(0.07...0.14); b.width = b.length * rng.float(0.8...1.0)
            b.yaw = rng.float(0...6.28)
            let d = V3(cos(b.yaw), 0, sin(b.yaw))
            b.root = V3(p.x, 0.0015 + Float(i) * 0.00018, p.y) - d * b.length / 2
            b.constantWidth = true; b.tipWidth = 1
            b.lean = rng.float(1.5...1.57); b.curl = rng.float(-0.03...0.03); b.segments = 1
            b.u = V2(c.origin.x, c.origin.x + c.size.x); b.v = V2(c.origin.y, c.origin.y + c.size.y)
            b.weight = V2(0, 0); b.ao = V2(0.6, 0.85); b.upNormal = 0.5
            let key = MaterialKey(mats[rng.int(0...mats.count - 1)])
            var hi = b; hi.fold = rng.float(-0.05...0.05); hi.segments = 2
            m0.add(PlantKit.blade(hi, material: key))
            if i % 3 != 0 { m1.add(PlantKit.blade(b, material: key)) }
        }
        groundAO(&m0, height: 0.02, floor: 0.6); groundAO(&m1, height: 0.02, floor: 0.6)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [5])
    }
}
