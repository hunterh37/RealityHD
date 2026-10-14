import simd
import RealCore

/// Green sunfish (Lepomis cyanellus), built at a typical 0.13 m (max 0.25 m): blue-green body with turquoise cheek lines, large mouth, short dark ear flap, dark blotch at the rear dorsal base.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishGreenSunfish: RealArticulated {
    public static let id = "fish-green-sunfish"
    public static let summary = "Green sunfish (Lepomis cyanellus), 0.13 m: blue-green body with turquoise cheek lines, large mouth, short dark ear flap, dark blotch at the rear dorsal base."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 0.25 m.
    public var length: Float = 0.13
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.green-sunfish-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.green-sunfish-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-red"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.33
        f.maxAt = 0.4
        f.width = 0.42
        f.snout = 0.95
        f.arch = 0.1
        f.keel = 0.4
        f.mouthEnd = 0.1
        f.mouthY = -0.03
        f.mouthDrop = 0.28
        f.underbite = 0.006
        f.eyeAt = 0.09
        f.eyeY = 0.42
        f.eyeR = 0.024
        f.operculum = 0.28
        f.earFlap = 0.045
        f.dorsal = FishShape.Fin(0.35, 0.8, height: 0.12, rake: 18, notch: 0.35, rays: 21, split: 0.45, splitDepth: 0.75)
        f.anal = FishShape.Fin(0.63, 0.8, height: 0.1, rake: 26, rays: 12)
        f.caudal = .emarginate
        f.caudalSpread = 0.28
        f.pectoral = 0.15
        f.skin = skin; f.fin = fin; f.eye = eye
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
