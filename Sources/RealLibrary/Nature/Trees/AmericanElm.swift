import simd
import Foundation

public extension TreeSpecies {
    /// American elm, ~22 m tall, ~20 m wide: trunk forking low (3 to 4 m) into several ascending limbs that
    /// arch out into a vase with a wide umbrella crown, drooping outer twigs, furrowed gray bark,
    /// toothed oval leaves (8 to 15 cm).
    static let americanElm = TreeSpecies(
        name: "american-elm", bark: "bark.oak", leaf: "leaf.beech", height: 22, trunkRadius: 0.5, trunkTipRatio: 0.6,
        trunkFraction: 0.17, trunkCurve: 4, trunkWobble: 0.015, flare: 0.6, flareLobes: 6,
        levels: [
            // Ascending limbs fanning out of the low fork.
            BranchLevel(density: 4.5, span: 0.7...1, lengthRatio: 1.25, downAngle: 30, downAngleSpread: 6, curve: 22, gravity: 0.02, radiusRatio: 0.85, wobble: 0.04),
            // Arching side branches, spreading outward and starting to droop.
            BranchLevel(density: 0.7, span: 0.55...1, lengthRatio: 0.45, profile: .dome, downAngle: 50, downAngleSpread: 14, curve: 25, gravity: -0.04, radiusRatio: 0.5, wobble: 0.05, stubChance: 0.05),
            // Pendulous outer twigs.
            BranchLevel(density: 1.0, span: 0.3...1, lengthRatio: 0.45, downAngle: 55, downAngleSpread: 18, curve: 10, gravity: -0.3, radiusRatio: 0.45, wobble: 0.03),
        ],
        leaves: LeafParams(cardSize: V2(0.9, 0.9), density: 2.6, span: 0.15...1, crownNormalBlend: 0.65, tipCluster: 0.3, sunBias: 0.15),
        barkTile: 0.6).with { $0.woodLevels = 0 }
}

/// American elm, ~22 m: low fork into ascending limbs, vase-shaped umbrella crown, drooping twigs.
public struct AmericanElm: RealAsset {
    public static let id = "american-elm"
    public static let summary = "American elm, ~22 m, low fork into ascending limbs arching into a wide vase crown with drooping twigs."
    public static let tags = ["nature", "tree", "deciduous"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public var height: Float = 22
    public init() {}
    public func build(seed: UInt64) -> LODModel { Tree(TreeSpecies.americanElm.with { $0.height = height }).build(seed: seed) }
}
