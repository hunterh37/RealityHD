import simd
import Foundation

/// Young fern frond tip, 28 cm, unrolling in a loose curl; pinnae shrink to the tip and carry dew beads.
public struct DewFernTip: RealAsset {
    public static let id = "dew-fern-tip"
    public static let summary = "Fern frond tip 28 cm with tapering pinnae, a loose curled end and dew beads hanging from the leaflets; 2 LODs."
    public static let tags = ["nature", "plant", "foliage", "water"]
    public static let budget = 3_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 0.6)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [2.5])
    }
    private func gen(_ seed: UInt64, _ coarse: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = 12
        // Rachis: rises, arcs forward, curls down at the tip.
        var pts: [V3] = []
        var p = V3(-0.09, 0, 0)
        for i in 0...n {
            pts.append(p)
            let f = Float(i) / Float(n)
            let ang = 1.35 - f * 1.1 - pow(f, 3) * 2.2 + rng.float(-0.05...0.05)
            p += V3(cos(ang), sin(ang), 0.03 * sin(f * 9 + 1)) * 0.028 * (1 - 0.3 * f)
        }
        let radii = (0...n).map { 0.0028 * (1 - Float($0) / Float(n + 1) * 0.85) }
        var stem = Prim.tube(pts, radii: radii, sides: 5, seamTile: 0.03, material: "plant.stem")
        stem.computeTangents()
        m.add(stem)
        var leaves = Surface(material: "fern.bracken")
        var beads = Surface(material: "water.pond")
        for i in 2...n {
            let f = Float(i) / Float(n)
            let a = pts[i], b = pts[min(i + 1, n)]
            let t = simd_normalize(b - a + V3(0, 0, 0.0001))
            let len = 0.095 * sin(min(f * 1.05, 1) * 2.7).magnitude * (1 - f * 0.45) * rng.float(0.85...1.1) + 0.012
            for side: Float in [-1, 1] {
                if rng.float(0...1) < 0.04 { continue }
                let yaw = (side > 0 ? 0.0 : Float.pi) + (side * -0.9 + rng.float(-0.12...0.12)) * 0 + rng.float(-0.2...0.2) + side * -0.5
                let root = a + V3(0, 0, 0) * 1
                let w = len * 0.45
                leaves.append(DetailKit18.pinna(root: root, yaw: yaw + (side > 0 ? 0 : 0), length: len, width: w, lean: 1.2 + 0.4 * f + rng.float(-0.1...0.1), curl: rng.float(0.2...0.6), rng: &rng))
                if rng.float(0...1) < (coarse == 0 ? 0.55 : 0.3) {
                    let r = rng.float(0.0016...0.0034)
                    let ex = root + V3(cos(yaw) * len * 0.8, len * 0.25 - r, -sin(yaw) * len * 0.8)
                    beads.append(DetailKit18.drop(ex, r))
                }
            }
        }
        // Terminal curled bud pinnae.
        let tip = pts[n]
        leaves.append(DetailKit18.pinna(root: tip, yaw: 0.3, length: 0.018, width: 0.006, lean: 0.4, curl: 0.8, rng: &rng))
        beads.append(DetailKit18.drop(tip + V3(0, 0.002, 0.004), 0.0028))
        leaves.computeTangents(); beads.computeTangents()
        m.add(leaves); m.add(beads)
        if coarse == 0 { groundAO(&m) }
        return m
    }
}
