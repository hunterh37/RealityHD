import simd
import Foundation

/// Axe-split chip pile, 50 cm wide: 70 to 110 fresh pale chips and long splinters, plus a few bark scraps.
public struct WoodChips: RealAsset {
    public static let id = "wood-chips"
    public static let summary = "Wood chip pile, 50 cm: axe-split pale chips and splinters with a few bark scraps at a chopping spot."
    public static let tags = ["nature", "wood", "ground"]
    public static let budget = 4_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.8)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var wood = Surface(material: "wood.pine"), bark = Surface(material: "bark.pine")
        for i in 0..<rng.int(70...110) {
            let r = 0.25 * rng.float().squareRoot()
            let a = rng.float(0...6.28)
            let h = 0.004 + (0.025 * (1 - r / 0.25)) * rng.float(0.2...1) 
            let long = rng.chance(0.2)
            let len = long ? rng.float(0.08...0.16) : rng.float(0.03...0.08)
            let wid = long ? rng.float(0.006...0.012) : rng.float(0.012...0.03)
            let tilt = V2(rng.float(-0.5...0.5), rng.float(-0.4...0.4))
            wood.append(DetailKit02.chip(len: len, wid: wid, t: rng.float(0.003...0.007), at: V3(cos(a) * r, h + Float(i % 3) * 0.001, sin(a) * r), yaw: rng.float(0...6.28), tilt: tilt, material: "wood.pine"))
        }
        for _ in 0..<rng.int(5...9) {
            let r = 0.22 * rng.float().squareRoot(), a = rng.float(0...6.28)
            bark.append(DetailKit02.chip(len: rng.float(0.03...0.06), wid: rng.float(0.01...0.02), t: 0.005, at: V3(cos(a) * r, rng.float(0.006...0.02), sin(a) * r), yaw: rng.float(0...6.28), tilt: V2(rng.float(-0.3...0.3), rng.float(-0.3...0.3)), material: "bark.pine"))
        }
        wood.computeTangents(); bark.computeTangents()
        m.add(wood); m.add(bark)
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
