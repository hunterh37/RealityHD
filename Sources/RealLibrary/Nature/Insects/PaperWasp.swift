import simd
import Foundation

/// European paper wasp (Polistes dominula), 15 mm: slender black body with yellow abdominal bands,
/// long petiole, yellow thorax dots, orange face and antenna tips, trailing hind legs, smoky amber wings folded lengthwise.
public struct PaperWasp: RealArticulated {
    public static let id = "insect-paper-wasp"
    public static let summary = "European paper wasp, 15 mm: slender black body, yellow abdominal bands, long petiole, orange antenna tips, trailing hind legs, folded smoky amber wings; articulated wings, legs, antennae."
    public static let tags = ["nature", "insect", "flying", "articulated"]
    public static let budget = 15_000
    public static let preview = PreviewHint(azimuth: 40, elevation: 28, distance: 1.0, ground: false, studio: true)
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var s = InsectKit.Bee()
        s.k = 1.1
        s.plump = 0.62
        s.head = "insect.chitin:1C1610"
        s.collar = "insect.fur:2A2018"
        s.thorax = "insect.fur:2A2018"
        s.bands = ["insect.chitin:1C1610", "insect.chitin:1C1610", "insect.chitin:E2B41C", "insect.chitin:1C1610", "insect.chitin:E2B41C", "insect.chitin:1C1610", "insect.chitin:E2B41C"]
        s.membrane = "insect.membrane:B98A48"
        s.legs = "insect.chitin:C9871A"
        var p = InsectKit.bee(Self.id, s)
        let k = s.k
        // Long petiole: tergite 0 is a thin stalk, tergite 1 a small knob, the gaster teardrops behind.
        for i in p.abdomen.indices {
            switch i {
            case 0:
                p.abdomen[i].r = V3(0.0004, 0.0004, 0.0016) * k
                p.abdomen[i].c.z = -0.0006 * k
            case 1:
                p.abdomen[i].r = V3(0.0007, 0.0007, 0.0008) * k
                p.abdomen[i].c.z -= 0.0018 * k
            default:
                p.abdomen[i].c.z -= 0.0026 * k
                p.abdomen[i].r.z *= 2.1; p.abdomen[i].r.x *= 0.92; p.abdomen[i].r.y *= 0.88
                if i == 2 || i == 3 { p.abdomen[i].r.x *= 1.15; p.abdomen[i].r.y *= 1.1 }
            }
        }
        let y: Float = 0.0042 * k
        // Two yellow dots on the thorax, yellow scutellum bar.
        p.thorax.append(.init(V3(0.0010 * k, y + 0.0016 * k, 0.0034 * k), V3(0.00040, 0.00022, 0.00035) * k, "insect.chitin:E2B41C", mirror: true))
        p.thorax.append(.init(V3(0, y + 0.0017 * k, 0.0014 * k), V3(0.0008, 0.00018, 0.0003) * k, "insect.chitin:E2B41C"))
        // Orange face plate and yellow cheek stripe.
        p.head.append(.init(V3(0, y - 0.0004 * k, 0.0064 * k), V3(0.0014, 0.0011, 0.0006) * k, "insect.chitin:D9781A"))
        // Orange antennae, thin and long.
        p.antennaMat = "insect.chitin:D9781A"
        p.antenna?.length = 0.0066 * k
        p.antenna?.radius = 0.00009 * k
        // Hind legs trail back and hang low; middle legs angle slightly back.
        if p.legs.count == 3 {
            p.legs[2].yaw = -75
            p.legs[2].lift = 20
            p.legs[2].femur *= 1.2
            p.legs[2].tibia *= 1.25
            p.legs[2].bulge = 1.1
            p.legs[1].yaw = -10
        }
        // Fore wings folded lengthwise: narrow, laid close along the back and gaster.
        p.fore?.folded = (V3(0.0006 * k, y + 0.0022 * k, 0.0034 * k), V3(0.03, 0.02, -1), V3(1, 0.1, 0.05), 0.0108 * k, 0.0016 * k)
        p.hind?.folded = (V3(0.0006 * k, y + 0.0020 * k, 0.0022 * k), V3(0.04, 0.02, -1), V3(1, 0.1, 0.05), 0.0080 * k, 0.0012 * k)
        return InsectKit.assemble(p)
    }
}
