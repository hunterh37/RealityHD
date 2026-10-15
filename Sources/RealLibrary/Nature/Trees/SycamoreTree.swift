import simd
import Foundation

/// American sycamore (Platanus occidentalis), ~24 m, the signature tree of Ozark river banks: brown scaly
/// bark on the lower trunk giving way to white, cream and olive mottled limbs above `whiteFrom`, wide open
/// crown of large lobed leaves. 3 LODs.
public struct SycamoreTree: RealAsset {
    public static let id = "sycamore-tree"
    public static let summary = "American sycamore, ~24 m: brown scaly lower trunk, white mottled upper limbs, wide open crown of large lobed leaves, 3 LODs."
    public static let tags = ["nature", "tree", "deciduous", "river"]
    public static let budget = 60_000
    public static let author = "realityhd"

    /// Total height in meters.
    public var height: Float = 24
    /// Height (meters) above which the bark turns white and mottled.
    public var whiteFrom: Float = 4.5
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var sp = TreeSpecies.sycamore
        let k = height / sp.height
        sp.height = height; sp.trunkRadius *= k
        let ns = UInt32(truncatingIfNeeded: seed)
        let cut = whiteFrom * k
        return ConiferBuild.lods(sp, seed: seed) { m, _ in
            // Lower trunk keeps its brown outer bark; the transition breaks up over ~2 m.
            ConiferBuild.splitSurface(&m, "bark.sycamore", into: "bark.sycamore-lower") { c in
                c.y + Noise.fbm(V3(c.x * 3, c.y * 0.6, c.z * 3), octaves: 3, seed: ns) * 1.6 < cut
            }
        }
    }
}
