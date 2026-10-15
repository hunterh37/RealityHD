import simd
import RealCore

/// Smallmouth bass (Micropterus dolomieu), built at a typical 0.30 m (max 0.55 m): bronze-brown flanks with broken vertical bars, red eye, jaw ending below the eye, shallow-notched spiny and soft dorsal.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishSmallmouthBass: RealArticulated {
    public static let id = "fish-smallmouth-bass"
    public static let summary = "Smallmouth bass (Micropterus dolomieu), 0.30 m: bronze flanks with broken vertical bars, red eye, notched spiny and soft dorsal."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 0.55 m.
    public var length: Float = 0.3
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.smallmouth-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.bass-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-red"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.27
        f.maxAt = 0.34
        f.width = 0.5
        f.snout = 0.7
        f.arch = 0.12
        f.mouthEnd = 0.115
        f.mouthY = -0.08
        f.mouthDrop = 0.3
        f.underbite = 0.01
        f.eyeAt = 0.085
        f.eyeY = 0.4
        f.eyeR = 0.024
        f.dorsal = FishShape.Fin(0.29, 0.79, height: 0.085, rake: 20, notch: 0.4, rays: 24, split: 0.45, splitDepth: 0.55)
        f.anal = FishShape.Fin(0.66, 0.8, height: 0.075, rake: 32, rays: 12)
        f.caudal = .emarginate
        f.caudalSpread = 0.25
        f.skin = skin; f.fin = fin; f.eye = eye
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
