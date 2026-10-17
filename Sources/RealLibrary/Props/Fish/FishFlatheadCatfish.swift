import simd
import RealCore

/// Flathead catfish (Pylodictis olivaris), built at a typical 0.60 m (max 1.20 m): mottled olive-brown scaleless body, broad flat head with projecting lower jaw, tiny eyes, square tail, large adipose fin.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishFlatheadCatfish: RealArticulated {
    public static let id = "fish-flathead-catfish"
    public static let summary = "Flathead catfish (Pylodictis olivaris), 0.60 m: mottled scaleless body, broad flat head, projecting lower jaw, square tail."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 1.20 m.
    public var length: Float = 0.6
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.flathead-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.flathead-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-amber"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.15
        f.maxAt = 0.32
        f.width = 0.95
        f.headWidth = 1.55
        f.snout = 0.5
        f.arch = 0.12
        f.section = 2.5
        f.keel = 0.05
        f.flatBelly = 0.7
        f.peduncle = 0.5
        f.mouthEnd = 0.08
        f.mouthY = -0.05
        f.mouthDrop = 0.1
        f.underbite = 0.016
        f.eyeAt = 0.075
        f.eyeY = 0.6
        f.eyeR = 0.009
        f.operculum = 0.2
        f.dorsal = FishShape.Fin(0.3, 0.38, height: 0.09, rake: 18, peak: 0.25, rays: 7)
        f.adipose = true
        f.anal = FishShape.Fin(0.62, 0.8, height: 0.06, rake: 22, peak: 0.35, rays: 15, round: 0.3)
        f.caudal = .truncate
        f.caudalSpread = 0.2
        f.pectoral = 0.1
        f.pelvic = 0.08
        f.pelvicAt = 0.5
        f.barbels = 8
        f.skin = skin; f.fin = fin; f.eye = eye
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
