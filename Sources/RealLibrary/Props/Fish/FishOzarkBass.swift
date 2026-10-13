import simd
import RealCore

/// Ozark bass (Ambloplites constellatus), built at a typical 0.18 m (max 0.30 m): deep olive-grey body freckled with dark scale spots, large red eye, long spiny anal fin.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishOzarkBass: RealArticulated {
    public static let id = "fish-ozark-bass"
    public static let summary = "Ozark bass (Ambloplites constellatus), 0.18 m: deep olive-grey body freckled with dark scale spots, large red eye, long spiny anal fin."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 0.30 m.
    public var length: Float = 0.18
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.ozark-bass-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.bass-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-red"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.36
        f.maxAt = 0.4
        f.width = 0.46
        f.snout = 0.7
        f.arch = 0.14
        f.keel = 0.35
        f.mouthEnd = 0.11
        f.mouthY = -0.04
        f.mouthDrop = 0.32
        f.underbite = 0.008
        f.eyeAt = 0.085
        f.eyeY = 0.4
        f.eyeR = 0.034
        f.dorsal = FishShape.Fin(0.34, 0.79, height: 0.11, rake: 18, notch: 0.35, rays: 22, split: 0.5, splitDepth: 0.75)
        f.anal = FishShape.Fin(0.58, 0.8, height: 0.11, rake: 28, rays: 16, split: 0.4, splitDepth: 0.8)
        f.caudal = .emarginate
        f.caudalSpread = 0.28
        f.skin = skin; f.fin = fin; f.eye = eye
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
