import simd
import Foundation

/// Plasma etch cluster tool, generic Lam/AMAT-class, 4 x 2.5 x 4 m. Hex vacuum transfer chamber, four bead-blasted
/// aluminum etch chambers with RF match boxes and gas sticks, two load locks, EFEM with three FOUP load ports,
/// cable bundles, status tower. Named parts: lid-1...lid-4 (hinged chamber lids with match boxes).
public struct PlasmaEtchCluster: RealArticulated {
    public static let id = "plasma-etch-cluster"
    public static let summary = "Etch cluster: hex transfer chamber, 4 bead-blasted aluminum chambers with RF match boxes, 2 load locks, EFEM, gas sticks, status tower."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 1.0, studio: true)

    /// EFEM and load lock skin powdercoat (sRGB hex).
    public var color: UInt32 = 0xEDEDE9
    /// Number of stainless gas sticks per chamber.
    public var gasSticks = 6
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [10])
        var spec = ClusterSpec()
        spec.skinMat = MaterialKey(stringLiteral: "metal.powdercoat:" + String(format: "%06X", color))
        spec.gasSticks = gasSticks
        ClusterTool.declareParts(&rig, spec)
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            ClusterTool.assemble(k, spec, status: V3(1.3, 0, 1.3))
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"),
                      RigState("lids-open", (1...4).reduce(into: [String: Float]()) { $0["lid-\($1)"] = -100 })]
        return rig
    }
}
