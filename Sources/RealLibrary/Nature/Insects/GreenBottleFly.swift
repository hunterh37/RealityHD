import simd
import Foundation

/// Green bottle fly (Lucilia sericata), 1.0 cm: metallic green-bronze thorax and abdomen with black bristles,
/// large red-brown eyes, two clear veined wings, small halteres, stout dark legs.
public struct GreenBottleFly: RealArticulated {
    public static let id = "insect-green-bottle-fly"
    public static let summary = "Green bottle fly, 1 cm: metallic green-bronze body, red-brown eyes, bristles, two clear wings; articulated."
    public static let tags = ["nature", "insect", "flying", "articulated"]
    public static let budget = 14_000
    public static let preview = PreviewHint(azimuth: 40, elevation: 28, distance: 0.5, ground: false, studio: true)
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var s = InsectKit.Bee()
        s.k = 0.68; s.plump = 0.9
        let green = "insect.chitin-metallic:2FA05A"
        s.head = "insect.chitin:2A3A28"
        s.collar = green
        s.thorax = green
        s.bands = ["insect.chitin-metallic:5AA040", "insect.chitin-metallic:2C9468", "insect.chitin-metallic:3A9C58", "insect.chitin-metallic:4A9A48", "insect.chitin-metallic:2C8E5C", "insect.chitin-metallic:2A8A58"]
        s.membrane = "insect.membrane"
        s.legs = "insect.chitin:16120E"
        var p = InsectKit.bee(Self.id, s)
        let k = s.k
        let y: Float = 0.0042 * k
        // Stout oval abdomen, shorter than a bee's.
        for i in p.abdomen.indices {
            let t = Float(i) / 5
            p.abdomen[i].c.z = (-0.0003 - Float(i) * 0.00070) * k
            p.abdomen[i].r.x *= 1.2 - 0.18 * t * t; p.abdomen[i].r.y *= 0.95 - 0.15 * t; p.abdomen[i].r.z *= 1.25
        }
        for i in p.thorax.indices { p.thorax[i].r *= 1.12 }
        // Large red-brown eyes covering most of the head.
        p.head[1] = .init(V3(0.0011, y + 0.0003 * k, 0.0058 * k), V3(0.0012, 0.0017, 0.0013) * k, "insect.eye:8A2E1A", mirror: true)
        // Two wings only, long, clear, veined.
        p.hind = nil
        p.fore?.length *= 1.6; p.fore?.width *= 1.25
        p.fore?.mat = "insect.membrane"
        p.fore?.veins = "insect.veins-bee-fore"
        p.antenna = .init(base: V3(0.0004, y + 0.0005 * k, 0.0069 * k), dir: V3(0.2, 0.3, 0.9), length: 0.0024 * k, radius: 0.00014 * k, curve: 0.1, elbow: 0.4, beads: 3)
        for i in p.legs.indices { p.legs[i].radius *= 1.0 }
        p.extra = { rig, d, L in
            // Halteres behind the wing base.
            for side: Float in [1, -1] {
                rig.add(InsectKit.limb([V3(side * 0.0009 * k, y + 0.0003 * k, 0.0016 * k), V3(side * 0.0016 * k, y + 0.0001 * k, 0.0012 * k)],
                             radii: [0.00010 * k, 0.00007 * k], material: "insect.chitin:D8C890", sides: 4, per: 1), to: "body", lods: L)
                rig.add(InsectKit.blob(V3(side * 0.0017 * k, y + 0.0001 * k, 0.0012 * k), V3(0.00015, 0.00015, 0.00015) * k, material: "insect.chitin:E8DCA8", sub: 3), to: "body", lods: L)
            }
            // Black bristles: thorax rows and abdomen rows.
            for side: Float in [1, -1] {
                for i in 0..<6 {
                    let z = (0.0044 - Float(i) * 0.00055) * k
                    let x = side * (0.0012 - 0.00004 * Float(i)) * k
                    rig.add(InsectKit.limb([V3(x, y + 0.0011 * k, z), V3(x * 1.25, y + 0.0024 * k, z - 0.0003 * k)],
                                 radii: [0.00005 * k, 0.00002 * k], material: "insect.chitin:0A0A0A", sides: 3, per: 1), to: "body", lods: L)
                }
                for i in 0..<9 {
                    let z = (-0.0006 - Float(i) * 0.00058) * k
                    let x = side * (0.0014 - 0.0001 * Float(i)) * k
                    rig.add(InsectKit.limb([V3(x, y + 0.0006 * k, z), V3(x * 1.2, y + 0.0017 * k, z - 0.0005 * k)],
                                 radii: [0.00005 * k, 0.00002 * k], material: "insect.chitin:0A0A0A", sides: 3, per: 1), to: "abdomen", lods: L)
                }
            }
            // Short proboscis (labellum).
            rig.add(InsectKit.limb([V3(0, y - 0.0014 * k, 0.0064 * k), V3(0, y - 0.0019 * k, 0.0068 * k)], radii: [0.00014 * k, 0.00007 * k],
                         material: "insect.chitin:3A2A1A", sides: 4, per: 1), to: "head", lods: L)
        }
        return InsectKit.assemble(p)
    }
}
