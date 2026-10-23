import simd
import Foundation

/// Beaver-gnawed stick, 35 cm long, 3 cm thick: pencil-point tooth cone at both ends, bark stripped in the middle.
public struct GnawedStick: RealAsset {
    public static let id = "gnawed-stick"
    public static let summary = "Beaver-gnawed stick, 35 cm: pencil-point tooth cones at both ends and bark stripped to pale wood."
    public static let tags = ["nature", "wood"]
    public static let budget = 700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 0.7)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var bark = Surface(material: "bark.pine"), wood = Surface(material: "wood.pine:E2CFA3")
        let r = rng.float(0.014...0.019), L: Float = 0.35
        let pts = DetailKit02.limbPath(from: V3(-L / 2, r, 0), dir: V3(1, 0.02, 0.05), len: L, segs: 10, wobble: 0.06, rng: &rng).map { V3($0.x, max($0.y, r * 0.5), $0.z) }
        func rad(_ i: Int) -> Float {
            let f = Float(i) / 10
            return r * (1 - 0.1 * f) * rng.float(0.94...1.06)
        }
        let full = (0...10).map(rad)
        // bark covers segments 3...7 (wood visible near ends and a stripped patch)
        let tooth: (Int, Float) -> Float = { i, base in
            if i == 0 { return 0.12 * r }
            if i == 1 { return base * 0.4 }
            if i == 2 { return base * 0.8 }
            if i == 8 { return base * 0.75 }
            if i == 9 { return base * 0.4 }
            if i == 10 { return 0.12 * r }
            return base
        }
        wood.append(Prim.tube(pts, radii: (0...10).map { tooth($0, full[$0] * 0.97) }, sides: 8, seamTile: 0.1, material: "wood.pine:E2CFA3", capEnd: true))
        let bp = Array(pts[2...8]), br = (2...8).map { full[$0] * rng.float(1.0...1.08) }
        bark.append(Prim.tube(bp, radii: [br[0] * 0.7] + br[1...4] + [br[5] * 0.85, br[6] * 0.6], sides: 8, seamTile: 0.1, material: "bark.pine", capEnd: false))
        bark.computeTangents(); wood.computeTangents()
        m.add(bark); m.add(wood)
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
