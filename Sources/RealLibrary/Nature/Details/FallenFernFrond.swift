import simd
import Foundation

/// Fallen bracken frond, 55 cm, browning from the tip, lying on the ground with a curled end and a broken stipe.
public struct FallenFernFrond: RealAsset {
    public static let id = "fallen-fern-frond"
    public static let summary = "Fallen bracken frond, 55 cm, lying on the ground, browning toward the tip with a curled end and a snapped stipe."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 55, distance: 0.8)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        var m = Model(name: Self.id)
        let yaw = rng.float(0...6.28)
        let stipeLen: Float = rng.float(0.15...0.2), frondLen: Float = rng.float(0.32...0.4)
        let d = V3(cos(yaw), 0, sin(yaw)), side = V3(-d.z, 0, d.x)
        var pts: [V3] = [], p = V3(0, 0.004, 0) - d * 0.27
        for i in 0...5 {
            pts.append(p)
            p += d * (stipeLen / 5) * rng.float(0.9...1.1) + side * rng.float(-0.006...0.006) + V3(0, i < 1 ? 0.004 : rng.float(-0.0002...0.0006), 0)
            p.y = max(p.y, 0.003)
        }
        let c0 = pts[0] - d * stipeLen * 0.5
        pts = pts.map { $0 + (V3(0, 0, 0)) }
        m.add(PlantKit.stem(pts, radius: 0.0032, tipRadius: 0.0024, weight: V2(0, 0.1), phase: phase, material: "plant.stem:7A6A3A"))
        _ = c0
        for (k, tint) in [("fern.bracken:9A8A45", 0), ("fern.bracken:7A5A2C", 1)].enumerated() {
            var b = PlantKit.Blade()
            b.yaw = yaw + Float(k) * 0.0 + rng.float(-0.08...0.08)
            b.root = pts[5] + V3(0, 0.001, 0) - side * (k == 0 ? 0.002 : -0.002)
            b.length = frondLen * (k == 0 ? 1 : rng.float(0.6...0.75)); b.width = frondLen * (k == 0 ? 0.5 : 0.3)
            b.constantWidth = true; b.tipWidth = 1
            b.lean = rng.float(1.47...1.54); b.curl = rng.float(-0.3...(-0.05)) + Float(tint.1) * 0.05
            b.twist = rng.float(-0.35...0.35)
            let c = PlantKit.cell(rng.int(0...3), cols: 4, rows: 1)
            b.u = V2(c.origin.x, c.origin.x + c.size.x); b.v = V2(0.005, 0.995)
            b.phase = phase; b.ao = V2(0.5, 0.95); b.upNormal = 0.5; b.weight = V2(0.1, 0.5)
            b.segments = 8; b.fold = rng.float(0.04...0.1)
            m.add(PlantKit.blade(b, material: MaterialKey(tint.0)))
        }
        PlantKit.finish(&m)
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
