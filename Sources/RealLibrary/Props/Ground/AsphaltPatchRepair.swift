import simd
import Foundation

/// Cut-and-patch asphalt repair, 1.4 x 1.0 m: a fresh dark rectangle set 4 mm proud of weathered road,
/// outlined with hot-poured sealant and cracked at the corners where the old surface lifts.
public struct AsphaltPatchRepair: RealAsset {
    public static let id = "asphalt-patch-repair"
    public static let summary = "Asphalt patch repair, 1.4 x 1.0 m: fresh rectangular patch on worn road with sealant border and corner cracks."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 2500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 1.7, studio: true)

    /// Road slab size X, Z (m).
    public var slab = V2(1.4, 1.0)
    /// Patch size X, Z (m).
    public var patch = V2(0.9, 0.6)
    /// Road thickness (m).
    public var thickness: Float = 0.04
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = thickness, yaw = rng.float(-4...4)
        GK.slab(&m, w: slab.x, d: slab.y, h: top, "asphalt.worn")
        GK.box(&m, V3(0, top + 0.002, 0), V3(patch.x, 0.004, patch.y), "asphalt.patch", r: 0.0015, yaw: yaw)
        // Sealant border.
        let bw: Float = 0.014
        for s: Float in [-1, 1] {
            GK.box(&m, V3(0, top + 0.0045, s * (patch.y / 2 + bw / 2)), V3(patch.x + 2 * bw, 0.002, bw), "asphalt.sealant", r: 0.0005, yaw: yaw)
            GK.box(&m, V3(s * (patch.x / 2 + bw / 2), top + 0.0045, 0), V3(bw, 0.002, patch.y), "asphalt.sealant", r: 0.0005, yaw: yaw)
        }
        // Cracks radiating from the corners.
        for (i, (sx, sz)) in [(Float(-1), Float(-1)), (1, -1), (-1, 1), (1, 1)].enumerated() {
            let start = V2(sx * (patch.x / 2 + 0.02), sz * (patch.y / 2 + 0.02))
            citySealedCrack(&m, start: start, angle: atan2(sz, sx) + rng.float(-0.4...0.4), length: rng.float(0.2...0.3), y: top, bounds: 0.45, rng: &rng)
            _ = i
        }
        return GK.finish(&m)
    }
}
