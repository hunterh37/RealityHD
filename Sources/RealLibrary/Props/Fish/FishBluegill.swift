import simd
import RealCore

/// Bluegill (Lepomis macrochirus), built at a typical 0.15 m (max 0.28 m): deep compressed olive body with faint vertical bars, yellow-orange breast, all-black ear flap, small mouth, long pointed pectorals.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishBluegill: RealArticulated {
    public static let id = "fish-bluegill"
    public static let summary = "Bluegill (Lepomis macrochirus), 0.15 m: deep olive body with faint bars, yellow-orange breast, black ear flap, long pectorals."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 0.28 m.
    public var length: Float = 0.15
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.bluegill-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.bluegill-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-dark"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.48
        f.maxAt = 0.42
        f.width = 0.34
        f.snout = 0.6
        f.arch = 0.12
        f.keel = 0.5
        f.mouthEnd = 0.065
        f.mouthY = 0.02
        f.mouthDrop = 0.12
        f.underbite = 0.004
        f.eyeAt = 0.09
        f.eyeY = 0.42
        f.eyeR = 0.03
        f.operculum = 0.29
        f.earFlap = 0.07
        f.dorsal = FishShape.Fin(0.36, 0.8, height: 0.13, rake: 18, notch: 0.35, rays: 21, split: 0.45, splitDepth: 0.8)
        f.anal = FishShape.Fin(0.62, 0.8, height: 0.11, rake: 26, rays: 12)
        f.caudal = .emarginate
        f.caudalSpread = 0.3
        f.pectoral = 0.22
        f.pelvicAt = 0.36
        f.skin = skin; f.fin = fin; f.eye = eye
        f.earFlapMaterial = "fish.ear-flap-black"
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
