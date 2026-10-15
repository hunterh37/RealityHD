import simd
import Foundation

public extension TreeSpecies {
    /// American sycamore (Platanus occidentalis) on an Ozark river bank, ~24 m: thick trunk forking low into
    /// a few massive ascending limbs, wide open crown, large shallow-lobed leaves (12 to 20 cm).
    static let sycamore = TreeSpecies(
        name: "sycamore", bark: "bark.sycamore", leaf: "leaf.sycamore", height: 24, trunkRadius: 0.62, trunkTipRatio: 0.1,
        trunkFraction: 0.3, trunkCurve: 12, trunkWobble: 0.02, flare: 0.6, flareLobes: 5,
        levels: [
            BranchLevel(density: 3.2, lengthRatio: 0.72, downAngle: 44, downAngleSpread: 12, curve: 26, gravity: 0.03, radiusRatio: 0.72, wobble: 0.08),
            BranchLevel(density: 1.6, span: 0.15...1, lengthRatio: 0.48, profile: .dome, downAngle: 52, downAngleSpread: 16, curve: 34, gravity: 0.04, radiusRatio: 0.5, wobble: 0.07, stubChance: 0.1),
            BranchLevel(density: 2.6, span: 0.2...1, lengthRatio: 0.34, profile: .tapered, downAngle: 48, downAngleSpread: 18, curve: 24, gravity: 0.08, radiusRatio: 0.55, wobble: 0.05),
        ],
        leaves: LeafParams(cardSize: V2(0.82, 0.82), density: 5, span: 0.25...1, crownNormalBlend: 0.7, tipCluster: 0.6, sunBias: 0.25),
        barkTile: 0.7).with { $0.woodLevels = 1; $0.roots = 1.2 }

    /// River birch (Betula nigra), ~15 m: leaning trunk with salmon papery bark, irregular open crown of
    /// arching branches, small toothed leaves (4 to 8 cm).
    static let riverBirch = TreeSpecies(
        name: "river-birch", bark: "bark.river-birch", leaf: "leaf.river-birch", height: 15, trunkRadius: 0.26, trunkTipRatio: 0.06,
        trunkFraction: 0.55, trunkCurve: 9, trunkWobble: 0.025, flare: 0.4, flareLobes: 4,
        levels: [
            BranchLevel(density: 5, span: 0.1...1, lengthRatio: 0.5, downAngle: 40, downAngleSpread: 14, curve: 30, gravity: 0.04, radiusRatio: 0.55, wobble: 0.07),
            BranchLevel(density: 3.6, span: 0.2...1, lengthRatio: 0.45, downAngle: 45, downAngleSpread: 16, curve: 28, gravity: -0.04, radiusRatio: 0.5, wobble: 0.05, stubChance: 0.06),
        ],
        leaves: LeafParams(cardSize: V2(0.28, 0.3), density: 24, span: 0.12...1, crownNormalBlend: 0.6, tipCluster: 0.25, sunBias: 0.2),
        barkTile: 0.5).with { $0.woodLevels = 0; $0.roots = 0.8 }

    /// Shortleaf pine (Pinus echinata), ~22 m: straight clear bole with reddish plated bark, small open
    /// oval crown of upturned limbs, needle tufts (7 to 11 cm needles) at the shoot tips.
    static let shortleafPine = TreeSpecies(
        name: "shortleaf-pine", bark: "bark.shortleaf-pine", leaf: "leaf.shortleaf-pine", height: 22, trunkRadius: 0.3, trunkTipRatio: 0.06,
        trunkFraction: 0.82, trunkCurve: 4, trunkWobble: 0.008, flare: 0.25, flareLobes: 5,
        levels: [
            BranchLevel(density: 9, span: 0.5...1, lengthRatio: 0.3, profile: .conical, downAngle: 70, downAngleSpread: 14, curve: 26, gravity: 0.06, radiusRatio: 0.42, wobble: 0.06, stubChance: 0.12),
            BranchLevel(density: 2, span: 0.25...1, lengthRatio: 0.5, profile: .tapered, downAngle: 55, downAngleSpread: 16, curve: 22, gravity: 0.1, radiusRatio: 0.48, wobble: 0.05),
            BranchLevel(density: 5.5, span: 0.55...1, lengthRatio: 0.32, downAngle: 48, downAngleSpread: 18, curve: 14, gravity: 0.16, radiusRatio: 0.5, wobble: 0.04),
        ],
        leaves: LeafParams(cardSize: V2(0.6, 0.7), density: 7, span: 0.15...1, crownNormalBlend: 0.5),
        barkTile: 0.5).with { $0.woodLevels = 1 }
}
