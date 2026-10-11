import simd
import Foundation

/// Double-leaf utility vault lid, 0.75 x 1.0 m: two cast-iron leaves with raised anti-skid ribs in a
/// frame, a center pick slot per leaf, set in a 1.1 x 1.4 m concrete collar flush with the road.
public struct UtilityVaultLid: RealAsset {
    public static let id = "utility-vault-lid"
    public static let summary = "Utility vault lid, 0.75 x 1 m: two ribbed cast-iron leaves in a frame inside a concrete collar."
    public static let tags = ["prop", "street", "city", "urban", "outdoor", "ground", "metal", "utility"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 50, distance: 1.7, studio: true)

    /// Lid opening X, Z (m).
    public var lid = V2(0.75, 1.0)
    /// Collar size X, Z (m).
    public var collar = V2(1.1, 1.4)
    /// Materials.
    public var iron: MaterialKey = "metal.cast-iron-street"
    public var worn: MaterialKey = "metal.cast-iron-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.03
        GK.slab(&m, w: collar.x, d: collar.y, h: top - 0.002, "concrete.sidewalk", r: 0.006)
        // Frame angle.
        let f: Float = 0.035
        GK.box(&m, V3(0, top - 0.004, -(lid.y / 2 + f / 2)), V3(lid.x + 2 * f, 0.012, f), iron, r: 0.003)
        GK.box(&m, V3(0, top - 0.004, lid.y / 2 + f / 2), V3(lid.x + 2 * f, 0.012, f), iron, r: 0.003)
        for s: Float in [-1, 1] { GK.box(&m, V3(s * (lid.x / 2 + f / 2), top - 0.004, 0), V3(f, 0.012, lid.y), iron, r: 0.003) }
        // Two leaves split across Z with a center joint, ribs along X.
        let leaf = (lid.y - 0.008) / 2
        for s: Float in [-1, 1] {
            let cz = s * (leaf + 0.008) / 2
            GK.box(&m, V3(0, top - 0.006, cz), V3(lid.x - 0.006, 0.014, leaf), iron, r: 0.003)
            let n = 12
            for i in 0..<n {
                let z = cz - leaf / 2 + 0.03 + Float(i) * (leaf - 0.06) / Float(n - 1)
                GK.box(&m, V3(0, top + 0.001, z), V3(lid.x - 0.1, 0.004, 0.014), i % 3 == 0 ? worn : iron, r: 0.0015)
            }
            // Pick slot.
            GK.box(&m, V3(0, top + 0.0012, cz + s * (leaf / 2 - 0.03)), V3(0.09, 0.0012, 0.018), "asphalt.sealant", r: 0.0005)
        }
        // Raised legend band across the center joint.
        GK.box(&m, V3(0, top + 0.0015, 0), V3(lid.x - 0.1, 0.004, 0.07), iron, r: 0.002)
        GK.layer(&m, x: rng.float(-0.2...0.2), z: rng.float(-0.4...0.4), w: 0.3, d: 0.4, top: top, "ground.mud", yaw: rng.float(0...40))
        return GK.finish(&m, ao: 0.07)
    }
}
