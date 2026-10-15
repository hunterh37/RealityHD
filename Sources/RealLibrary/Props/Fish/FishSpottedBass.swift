import simd
import RealCore

/// Spotted bass (Micropterus punctulatus), built at a typical 0.28 m (max 0.50 m): olive back, dark blotch row along the lateral line, rows of dark spots on the lower flank, connected dorsal.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishSpottedBass: RealArticulated {
    public static let id = "fish-spotted-bass"
    public static let summary = "Spotted bass (Micropterus punctulatus), 0.28 m: olive back, dark blotch row along the lateral line, rows of dark spots on the lower flank, connected dorsal."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 0.50 m.
    public var length: Float = 0.28
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.spotted-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.bass-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-red"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.24
        f.maxAt = 0.37
        f.width = 0.5
        f.snout = 0.85
        f.arch = 0.1
        f.mouthEnd = 0.125
        f.mouthY = -0.07
        f.mouthDrop = 0.32
        f.underbite = 0.01
        f.eyeAt = 0.085
        f.eyeY = 0.4
        f.eyeR = 0.022
        f.dorsal = FishShape.Fin(0.33, 0.79, height: 0.10, rake: 20, notch: 0.4, rays: 24, split: 0.42, splitDepth: 0.62)
        f.anal = FishShape.Fin(0.66, 0.8, height: 0.075, rake: 32, rays: 12)
        f.caudal = .emarginate
        f.caudalSpread = 0.25
        f.skin = skin; f.fin = fin; f.eye = eye
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
