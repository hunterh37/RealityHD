import simd
import RealCore

/// Channel catfish (Ictalurus punctatus), built at a typical 0.45 m (max 0.90 m): slate-grey scaleless body with scattered dark spots, deeply forked tail, eight barbels, adipose fin.
/// Articulated: tail yaw at the caudal peduncle, lower jaw hinge; states rest, swim-left, swim-right, mouth-open.
public struct FishChannelCatfish: RealArticulated {
    public static let id = "fish-channel-catfish"
    public static let summary = "Channel catfish (Ictalurus punctatus), 0.45 m: slate-grey scaleless body with scattered dark spots, deeply forked tail, eight barbels, adipose fin."
    public static let tags = ["prop", "fish", "handheld", "articulated", "outdoor", "water"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, studio: true)

    /// Total length snout to caudal tip (m); everything scales with it. Max for the species: 0.90 m.
    public var length: Float = 0.45
    /// Skin atlas material (fish.* skin program).
    public var skin: MaterialKey = "fish.channel-cat-skin"
    /// Fin membrane material.
    public var fin: MaterialKey = "fish.catfish-fin"
    /// Eye material.
    public var eye: MaterialKey = "fish.eye-dark"
    public init() {}

    /// Body plan for this species.
    public var shape: FishShape {
        var f = FishShape()
        f.length = length
        f.depth = 0.17
        f.maxAt = 0.3
        f.width = 0.78
        f.headWidth = 1.25
        f.snout = 0.45
        f.arch = 0.22
        f.section = 2.4
        f.keel = 0.1
        f.flatBelly = 0.6
        f.peduncle = 0.42
        f.mouthEnd = 0.065
        f.mouthY = -0.18
        f.mouthDrop = 0.08
        f.underbite = -0.008
        f.eyeAt = 0.08
        f.eyeY = 0.35
        f.eyeR = 0.012
        f.operculum = 0.21
        f.dorsal = FishShape.Fin(0.28, 0.37, height: 0.11, rake: 18, peak: 0.25, rays: 7)
        f.adipose = true
        f.anal = FishShape.Fin(0.55, 0.8, height: 0.065, rake: 22, peak: 0.3, rays: 26, round: 0.2)
        f.caudal = .forked(0.5)
        f.caudalSpread = 0.21
        f.pectoral = 0.12
        f.pelvic = 0.09
        f.pelvicAt = 0.5
        f.barbels = 8
        f.skin = skin; f.fin = fin; f.eye = eye
        return f
    }

    public func rig(seed: UInt64) -> Rig { FishRig.rig(id: Self.id, shape: shape, seed: seed) }
}
