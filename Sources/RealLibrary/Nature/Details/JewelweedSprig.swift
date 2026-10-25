import simd
import Foundation

/// Spotted jewelweed sprig, 45 cm: a translucent branching stem with alternate oval toothed leaves and orange spurred flowers.
public struct JewelweedSprig: RealAsset {
    public static let id = "jewelweed-sprig"
    public static let summary = "Spotted jewelweed sprig, 45 cm: a translucent green stem with alternate oval leaves and orange spurred flowers."
    public static let tags = ["nature", "plant", "flower"]
    public static let budget = 900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 1.3)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        var m = Model(name: Self.id)
        let H = rng.float(0.38...0.48), a0 = rng.float(0...6.28)
        let main = PlantKit.arc(from: .zero, height: H, yaw: a0, lean: rng.float(0.05...0.15), bend: rng.float(0.2...0.45), count: 8)
        m.add(PlantKit.stem(main, radius: 0.0032, tipRadius: 0.0016, sides: 5, weight: V2(0, 0.9), phase: phase, material: "plant.stem:9AB868"))
        let leaf: MaterialKey = "leaf.plain:5E9A3A"
        var yaw = a0 + rng.float(0...3)
        for i in 1..<7 {
            let at = main[i], f = Float(i) / 7
            yaw += 2.4 + rng.float(-0.5...0.5)
            let len = rng.float(0.06...0.095) * (1.1 - 0.5 * f)
            var b = PlantKit.Blade()
            b.yaw = yaw; b.root = at; b.length = len; b.width = len * 0.5
            b.belly = 1.4; b.constantWidth = false
            b.lean = rng.float(0.9...1.35); b.curl = rng.float(0.4...0.9); b.twist = rng.float(-0.4...0.4)
            b.segments = 4; b.fold = rng.float(0.05...0.15)
            b.weight = V2(0.5, 1); b.phase = phase + Float(i) * 0.4; b.ao = V2(0.7, 1); b.upNormal = 0.3
            m.add(PlantKit.blade(b, material: leaf))
            if i >= 3 && rng.chance(0.75) {
                // flower on a thin pedicel hanging from the axil
                let fy = yaw + rng.float(1.5...3)
                let dd = V3(cos(fy), 0, sin(fy))
                let pp = [at, at + dd * 0.012 + V3(0, 0.008, 0), at + dd * 0.025 + V3(0, -0.004, 0)]
                m.add(PlantKit.stem(pp, radius: 0.0006, tipRadius: 0.0005, weight: V2(0.6, 1), phase: phase, material: "plant.stem:9AB868"))
                let c = pp[2], n = simd_normalize(dd + V3(0, 0.3, 0))
                let cell = PlantKit.cell(4, cols: 4, rows: 4)
                m.add(PlantKit.disc(center: c + n * 0.004, normal: n, radius: rng.float(0.007...0.01), cup: 0.5, rim: 7, cell: cell,
                                    spin: rng.float(0...6), weight: 1, phase: phase, material: "flower.meadow:F29A2E"))
                // curled spur
                var sp = PlantKit.Blade()
                sp.yaw = fy + 3.14; sp.root = c; sp.length = 0.011; sp.width = 0.004; sp.lean = 1.9; sp.curl = 1.5
                sp.constantWidth = true; sp.tipWidth = 0.2; sp.segments = 3; sp.u = V2(cell.origin.x, cell.origin.x + cell.size.x); sp.v = V2(cell.origin.y, cell.origin.y + cell.size.y)
                sp.weight = V2(1, 1); sp.phase = phase
                m.add(PlantKit.blade(sp, material: "flower.meadow:F29A2E"))
            }
        }
        PlantKit.finish(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
