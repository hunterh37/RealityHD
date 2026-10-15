import simd
import RealCore

/// Longear sunfish (Lepomis megalotis), built at a typical 0.12 m (max 0.22 m): orange belly, turquoise cheek lines and speckles, long black ear flap edged white, deep rounded body.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishLongearSunfish: RealArticulated {
    public static let id = "fish-longear-sunfish"
    public static let summary = "Longear sunfish (Lepomis megalotis), 0.12 m: orange belly, turquoise cheek lines and speckles, long black ear flap edged white, deep rounded body."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 0.22 m.
    public var length: Float = 0.12
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.longear-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.longear-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-red"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.45
        f.maxAt = 0.42
        f.width = 0.38
        f.snout = 0.6
        f.arch = 0.12
        f.keel = 0.5
        f.mouthEnd = 0.075
        f.mouthY = 0.0
        f.mouthDrop = 0.15
        f.underbite = 0.004
        f.eyeAt = 0.09
        f.eyeY = 0.42
        f.eyeR = 0.034
        f.operculum = 0.29
        f.earFlap = 0.13
        f.dorsal = FishShape.Fin(0.36, 0.8, height: 0.13, rake: 18, notch: 0.35, rays: 21, split: 0.45, splitDepth: 0.75)
        f.anal = FishShape.Fin(0.62, 0.8, height: 0.11, rake: 26, rays: 12)
        f.caudal = .emarginate
        f.caudalSpread = 0.3
        f.pectoral = 0.17
        f.pelvicAt = 0.36
        f.skin = skin; f.fin = fin; f.eye = eye
        f.earFlapMaterial = "fish.ear-flap-longear"
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
