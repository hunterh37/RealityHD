import simd
import Foundation

/// Eastern carpenter bee (Xylocopa virginica), 2.2 cm: stout body, dense yellow thorax fur with a bare
/// glossy black disc, bare glossy black abdomen, smoky blue-violet wings, short stout antennae.
public struct CarpenterBee: RealArticulated {
    public static let id = "insect-carpenter-bee"
    public static let summary = "Eastern carpenter bee, 2.2 cm: yellow furred thorax, bare glossy black abdomen, smoky violet wings; articulated."
    public static let tags = ["nature", "insect", "flying", "articulated"]
    public static let budget = 14_000
    public static let preview = PreviewHint(azimuth: 40, elevation: 28, distance: 1.0, ground: false, studio: true)
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var s = InsectKit.Bee()
        s.k = 1.15; s.plump = 1.3
        let black = "insect.chitin:0B0A10"
        s.head = black
        s.collar = "insect.fur:E3B72A"
        s.thorax = "insect.fur:E3B72A"
        s.bands = Array(repeating: black, count: 6)
        s.membrane = "insect.membrane-smoky:3A2C78"
        s.legs = black
        var p = InsectKit.bee(Self.id, s)
        let k = s.k
        let y: Float = 0.0042 * k
        // Bare glossy black disc on the dorsal thorax.
        p.thorax.append(.init(V3(0, y + 0.0013 * k, 0.0030 * k), V3(0.0014, 0.0011, 0.0012) * k, black))
        // Broad abdomen with squarer shoulders.
        for i in p.abdomen.indices {
            p.abdomen[i].r.z *= 2.6; p.abdomen[i].r.x *= 1.04
            if i < 4 { p.abdomen[i].r.x *= 1.06; p.abdomen[i].r.y *= 1.04 }
        }
        for i in p.legs.indices { p.legs[i].radius *= 1.35 }
        p.fore?.length *= 1.4; p.fore?.width *= 1.1
        p.hind?.length *= 1.4
        // Short stout antennae.
        p.antenna?.length = 0.0040 * k
        p.antenna?.radius = 0.00017 * k
        p.antenna?.beads = 6
        return InsectKit.assemble(p)
    }
}
