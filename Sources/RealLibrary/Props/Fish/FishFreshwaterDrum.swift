import simd
import RealCore

/// Freshwater drum (Aplodinotus grunniens), built at a typical 0.35 m (max 0.70 m): silvery humpbacked body, blunt rounded snout over a subterminal mouth, long two-part dorsal, rounded tail.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishFreshwaterDrum: RealArticulated {
    public static let id = "fish-freshwater-drum"
    public static let summary = "Freshwater drum (Aplodinotus grunniens), 0.35 m: silvery humpbacked body, blunt rounded snout over a subterminal mouth, long two-part dorsal, rounded tail."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 0.70 m.
    public var length: Float = 0.35
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.drum-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.drum-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-silver"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.32
        f.maxAt = 0.3
        f.width = 0.48
        f.snout = 0.65
        f.arch = 0.5
        f.keel = 0.3
        f.mouthEnd = 0.085
        f.mouthY = -0.35
        f.mouthDrop = 0.15
        f.underbite = -0.006
        f.eyeAt = 0.085
        f.eyeY = 0.35
        f.eyeR = 0.026
        f.operculum = 0.26
        f.dorsal = FishShape.Fin(0.3, 0.8, height: 0.09, rake: 18, notch: 0.3, rays: 34, split: 0.22, splitDepth: 0.5, round: 0.3)
        f.anal = FishShape.Fin(0.64, 0.78, height: 0.08, rake: 26, rays: 9)
        f.caudal = .rounded
        f.caudalSpread = 0.24
        f.pelvic = 0.12
        f.skin = skin; f.fin = fin; f.eye = eye
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
