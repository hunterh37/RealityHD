import simd
import RealCore

/// Largemouth bass (Micropterus salmoides), built at a typical 0.35 m (max 0.65 m): green back, jagged dark lateral band, white belly, jaw reaching past the eye, deeply notched dorsal.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishLargemouthBass: RealArticulated {
    public static let id = "fish-largemouth-bass"
    public static let summary = "Largemouth bass (Micropterus salmoides), 0.35 m: green back, jagged dark lateral band, white belly, jaw reaching past the eye, deeply notched dorsal."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 0.65 m.
    public var length: Float = 0.35
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.largemouth-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.largemouth-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-amber"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.27
        f.maxAt = 0.38
        f.width = 0.5
        f.snout = 0.8
        f.arch = 0.12
        f.mouthEnd = 0.15
        f.mouthY = -0.06
        f.mouthDrop = 0.38
        f.underbite = 0.014
        f.eyeAt = 0.085
        f.eyeY = 0.42
        f.eyeR = 0.02
        f.dorsal = FishShape.Fin(0.33, 0.79, height: 0.10, rake: 20, notch: 0.4, rays: 24, split: 0.42, splitDepth: 0.22)
        f.anal = FishShape.Fin(0.66, 0.8, height: 0.075, rake: 32, rays: 12)
        f.caudal = .emarginate
        f.caudalSpread = 0.26
        f.skin = skin; f.fin = fin; f.eye = eye
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
