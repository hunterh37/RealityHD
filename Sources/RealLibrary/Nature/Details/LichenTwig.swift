import simd
import Foundation

/// Bundle of 5 to 8 lichen-crusted dead twigs, 25 to 40 cm, with pale green frond lichen tufts.
public struct LichenTwig: RealAsset {
    public static let id = "lichen-twig"
    public static let summary = "Lichen-crusted dead twig bundle, 35 cm: gray twigs with pale green frond lichen tufts."
    public static let tags = ["nature", "wood", "plant"]
    public static let budget = 2_400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.8)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var twig = Surface(material: "bark.dead"), lich = Surface(material: "moss.cushion:A9BE8C")
        for i in 0..<rng.int(5...8) {
            let len = rng.float(0.25...0.42), r = rng.float(0.003...0.006)
            let yaw = rng.float(-0.5...0.5) + (i % 2 == 0 ? 0 : 3.14)
            let st = V3(rng.float(-0.04...0.04), 0.004 + Float(i) * 0.005, rng.float(-0.05...0.05)) - V3(cos(yaw), 0, sin(yaw)) * len / 2
            let pts = DetailKit02.limbPath(from: st, dir: V3(cos(yaw), rng.float(0...0.12), sin(yaw)), len: len, segs: 6, wobble: 0.2, rng: &rng).map { V3($0.x, max($0.y, 0.003), $0.z) }
            let rd = (0...6).map { r * (1 - 0.7 * Float($0) / 6) }
            twig.append(Prim.tube(pts, radii: rd, sides: 5, seamTile: 0.05, material: "bark.dead", capEnd: true))
            for _ in 0..<rng.int(4...7) {
                let k = rng.int(0...5), f = rng.float(0...1)
                let c = pts[k] + (pts[k + 1] - pts[k]) * f
                let rr = rd[k]
                for _ in 0..<rng.int(2...3) {
                    let n = V3(rng.float(-0.6...0.6), rng.float(0.2...1), rng.float(-0.8...0.8)).normalized
                    lich.append(DetailKit02.lump(at: c + n * rr * 0.9, normal: n, radius: rng.float(0.01...0.022), height: rng.float(0.004...0.01), rng: &rng, material: "moss.cushion:A9BE8C"))
                }
            }
        }
        twig.computeTangents(); lich.computeTangents()
        m.add(twig); m.add(lich)
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
