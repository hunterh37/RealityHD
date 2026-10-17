import simd
import Foundation

/// Drone fly (Eristalis tenax), 1.3 cm: one pair of clear wings plus club-tipped halteres, large red-brown
/// eyes, furry olive-brown thorax, brown-orange banded abdomen with a dark mid-stripe, short aristate antennae.
public struct HoverFly: RealArticulated {
    public static let id = "insect-hover-fly"
    public static let summary = "Drone fly, 1.3 cm: two clear wings and halteres, red-brown eyes, furry thorax, banded abdomen; articulated."
    public static let tags = ["nature", "insect", "flying", "articulated"]
    public static let budget = 14_000
    public static let preview = PreviewHint(azimuth: 40, elevation: 28, distance: 0.6, ground: false, studio: true)
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var s = InsectKit.Bee()
        s.k = 0.85; s.plump = 0.88
        let dark = "insect.chitin:1E140C"
        s.head = "insect.chitin:3A2A1A"
        s.collar = "insect.fur:A8834A"
        s.thorax = "insect.fur:6E5530"
        s.bands = ["insect.fur:8A5624", "insect.chitin:C27A22", "insect.chitin:B86C1E", "insect.chitin:2A1A0E", "insect.chitin:3A2412", "insect.chitin:2A1A0E"]
        s.membrane = "insect.membrane"
        s.legs = "insect.chitin:3A2A1A"
        var p = InsectKit.bee(Self.id, s)
        let k = s.k
        let y: Float = 0.0042 * k
        // Wide flattened abdomen.
        for i in p.abdomen.indices {
            let t = Float(i) / 5
            p.abdomen[i].c.z = (-0.0003 - Float(i) * 0.00085) * k
            p.abdomen[i].r.x *= 1.30 - 0.25 * t * t; p.abdomen[i].r.y *= 0.95 - 0.2 * t; p.abdomen[i].r.z *= 1.55; p.abdomen[i].r.x *= 1.0 + 0.12 * (1 - t)
        }
        // Large red-brown eyes covering most of the head.
        p.head[1] = .init(V3(0.0010, y + 0.0003 * k, 0.0058 * k), V3(0.0011, 0.0016, 0.0012) * k, "insect.eye:7A2A18", mirror: true)
        // Dark thorax stripes.
        p.thorax.append(.init(V3(0.0006 * k, y + 0.0016 * k, 0.0030 * k), V3(0.00035, 0.00018, 0.0016) * k, dark, mirror: true))
        // Two wings only: no hind pair, wings longer and clear.
        p.hind = nil
        p.fore?.length *= 1.55; p.fore?.width *= 1.25
        p.fore?.mat = "insect.membrane"
        p.fore?.veins = "insect.veins-bee-fore"
        // Short antennae with a flat third segment and arista.
        p.antenna = .init(base: V3(0.0004, y + 0.0004 * k, 0.0068 * k), dir: V3(0.2, 0.3, 0.9), length: 0.0026 * k, radius: 0.00014 * k, curve: 0.1, elbow: 0.4, beads: 3)
        for i in p.legs.indices { p.legs[i].radius *= 1.1 }
        p.extra = { rig, d, L in
            // Halteres: thin stalk with a knob, behind the wing base.
            for side: Float in [1, -1] {
                rig.add(InsectKit.limb([V3(side * 0.0009 * k, y + 0.0008 * k, 0.0014 * k), V3(side * 0.0016 * k, y + 0.0006 * k, 0.0010 * k)],
                             radii: [0.00010 * k, 0.00007 * k], material: "insect.chitin:D8C890", sides: 4, per: 1), to: "body", lods: L)
                rig.add(InsectKit.blob(V3(side * 0.0017 * k, y + 0.0006 * k, 0.0010 * k), V3(0.00015, 0.00015, 0.00015) * k, material: "insect.chitin:E8DCA8", sub: 3), to: "body", lods: L)
            }
            // Proboscis tip.
            rig.add(InsectKit.limb([V3(0, y - 0.0014 * k, 0.0064 * k), V3(0, y - 0.0020 * k, 0.0070 * k)], radii: [0.00012 * k, 0.00005 * k],
                         material: "insect.chitin:3A2A1A", sides: 4, per: 1), to: "head", lods: L)
        }
        return InsectKit.assemble(p)
    }
}
