import simd
import Foundation

/// Fallen bark flakes: 6 to 12 curled slabs, 5 to 25 cm, ragged fibrous ends, lying on forest floor.
public struct BarkFlakes: RealAsset {
    public static let id = "bark-flakes"
    public static let summary = "Fallen bark flakes: curled slabs 5-25 cm with ragged fiber ends and pale undersides."
    public static let tags = ["nature", "ground", "wood"]
    public static let budget = 1_700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.7)
    public var count: ClosedRange<Int> = 6...12
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var top = Surface(material: "bark.pine"), under = Surface(material: "wood.weathered")
        let n = rng.int(count)
        for i in 0..<n {
            let len = rng.float(0.05...0.25), wid = len * rng.float(0.35...0.7)
            let parts = DetailKit02.sheet(len: len, wid: wid, t: rng.float(0.004...0.009), curl: rng.float(0.5...1.6), bow: rng.float(0.002...0.015), rag: 0.12, rise: 0.003 + Float(i) * 0.0006, rng: &rng, top: "bark.pine", under: "wood.weathered")
            let p = rng.inDisc(radius: 0.22)
            let x = Xform(translation: V3(p.x, 0, p.y), rotation: simd_quatf(angle: rng.float(0...6.28), axis: V3(0, 1, 0)))
            top.append(parts[0], x); under.append(parts[1], x)
        }
        top.computeTangents(); under.computeTangents()
        m.add(top); m.add(under)
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
