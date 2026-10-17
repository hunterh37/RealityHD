import simd
import Foundation

/// European hornet worker (Vespa crabro), 25 mm: chestnut-red head and thorax, yellow face, narrow
/// petiole waist, yellow abdomen with dark saddle marks, amber fore wings folded over the abdomen.
public struct EuropeanHornet: RealArticulated {
    public static let id = "insect-european-hornet"
    public static let summary = "European hornet worker, 25 mm: chestnut thorax, petiole waist, yellow-saddled abdomen, amber wings; articulated."
    public static let tags = ["nature", "insect", "flying", "articulated"]
    public static let budget = 15_000
    public static let preview = PreviewHint(azimuth: 40, elevation: 28, distance: 1.0, ground: false, studio: true)
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var s = InsectKit.Bee()
        s.k = 1.6
        s.plump = 0.85
        s.head = "insect.chitin:7A3418"
        s.collar = "insect.fur:7A3418"
        s.thorax = "insect.fur:6E2E16"
        s.bands = ["insect.chitin:4A2410", "insect.chitin:DDA320", "insect.chitin:C98E18", "insect.chitin:DDA320", "insect.chitin:C98E18", "insect.chitin:D49A1C"]
        s.membrane = "insect.membrane:D9A850"
        s.legs = "insect.chitin:4A2410"
        var p = InsectKit.bee(Self.id, s)
        let k = s.k
        // Petiole waist: first tergite shrinks to a narrow stalk, the rest slide back.
        for i in p.abdomen.indices {
            if i == 0 {
                p.abdomen[i].r = V3(0.0006, 0.0006, 0.0010) * k
                p.abdomen[i].c.z = -0.0003 * k
            } else {
                p.abdomen[i].c.z -= 0.0012 * k
                p.abdomen[i].r.x *= 1.15
                p.abdomen[i].r.y *= 1.1
                p.abdomen[i].r.z *= 1.3
            }
        }
        // Dark dorsal saddle marks on tergites 3 to 6 (black teardrops of the real hornet).
        for b in Array(p.abdomen.dropFirst(2)) {
            p.abdomen.append(.init(b.c + V3(0, b.r.y * 0.62, 0), V3(b.r.x * 0.6, b.r.y * 0.5, b.r.z * 0.75), "insect.chitin:2A1608"))
        }
        // Yellow face plate, dark saddle marks on the abdomen are carried by the alternating tergite tints.
        let y: Float = 0.0042 * k
        p.head.append(.init(V3(0, y - 0.0003 * k, 0.0064 * k), V3(0.0013, 0.0012, 0.0006) * k, "insect.chitin:E2B020"))
        return InsectKit.assemble(p)
    }
}
