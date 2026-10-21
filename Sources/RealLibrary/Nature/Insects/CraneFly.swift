import simd
import Foundation

/// Crane fly (Tipula paludosa), 2.5 cm body: slender grey-brown thorax and tapered abdomen, small head with a
/// short snout, long thin antennae, narrow smoky wings, club-tipped halteres, very long fragile legs (about 3x body).
public struct CraneFly: RealArticulated {
    public static let id = "insect-crane-fly"
    public static let summary = "Crane fly, 2.5 cm body: grey-brown, legs 3x body length, narrow smoky wings, halteres, thin antennae; articulated."
    public static let tags = ["nature", "insect", "flying", "crawling", "articulated"]
    public static let budget = 14_000
    public static let preview = PreviewHint(azimuth: 50, elevation: 28, distance: 1.0, ground: false, studio: true)
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var p = InsectPlan(name: Self.id)
        let y: Float = 0.0102
        let body: MaterialKey = "insect.chitin-soft:8A7A62"
        let dark: MaterialKey = "insect.chitin-soft:5E5242"
        p.height = y + 0.006
        p.bodyPivot = V3(0, y, 0.004)
        p.thorax = [.init(V3(0, y + 0.0008, 0.0070), V3(0.0024, 0.0028, 0.0046), body),
                    .init(V3(0, y + 0.0030, 0.0062), V3(0.0020, 0.0014, 0.0034), dark),
                    .init(V3(0, y + 0.0012, 0.0020), V3(0.0016, 0.0016, 0.0016), dark)]
        p.neck = V3(0, y + 0.0004, 0.0118)
        p.head = [.init(V3(0, y + 0.0004, 0.0128), V3(0.0018, 0.0016, 0.0014), dark),
                  .init(V3(0.0015, y + 0.0010, 0.0130), V3(0.0010, 0.0012, 0.0011), "insect.eye:2A2018", mirror: true),
                  .init(V3(0, y - 0.0006, 0.0146), V3(0.0007, 0.0007, 0.0014), body)]
        p.abdomenPivot = V3(0, y, 0.0022)
        p.abdomen = [.init(V3(0, y - 0.0002, -0.0110), V3(0.0015, 0.0014, 0.0140), body) { q in
                        let t = (q.z + 0.025) / 0.028
                        return V3(q.x * (1 - 0.55 * max(0, 1 - t)), q.y * (1 - 0.55 * max(0, 1 - t)), q.z) },
                     .init(V3(0, y + 0.0012, -0.0100), V3(0.0006, 0.0004, 0.0110), dark)]
        let c: Float = 0.0035
        p.legs = [
            .init(attach: V3(0.0014, y - 0.0020, 0.0092), side: 1, yaw: 62, coxa: c, femur: 0.021, tibia: 0.022, tarsus: 0.022, lift: 52, radius: 0.00036, bulge: 1.3),
            .init(attach: V3(0.0016, y - 0.0022, 0.0068), side: 1, yaw: 5, coxa: c, femur: 0.021, tibia: 0.022, tarsus: 0.022, lift: 52, radius: 0.00034, bulge: 1.3),
            .init(attach: V3(0.0014, y - 0.0020, 0.0044), side: 1, yaw: -52, coxa: c, femur: 0.023, tibia: 0.024, tarsus: 0.023, lift: 52, radius: 0.00034, bulge: 1.3),
        ]
        p.legMat = "insect.chitin-soft:6E5E48"; p.antennaMat = "insect.chitin-soft:5E5242"; p.spines = [0, 0, 0]
        p.antenna = .init(base: V3(0.0006, y + 0.0014, 0.0138), dir: V3(0.35, 0.45, 0.85), length: 0.010, radius: 0.00012, curve: 0.3, beads: 8)
        p.fore = .init(.damselfly, root: V3(0.0018, y + 0.0036, 0.0070), span: V3(1, 0, -0.18), chord: V3(0.15, 0, 1), length: 0.027, width: 0.0072,
                       rootV: 0.5, mat: "insect.membrane", veins: "insect.veins-fan", droop: 0.0006,
                       folded: (V3(0.0012, y + 0.0038, 0.0070), V3(0.10, -0.06, -1), V3(0.4, -0.9, 0), 0.026, 0.0050))
        p.openWing = 18
        p.extra = { rig, d, L in
            // Halteres: thin stalk with a knob, behind each wing root.
            for side: Float in [1, -1] {
                rig.add(InsectKit.limb([V3(side * 0.0012, y + 0.0020, 0.0030), V3(side * 0.0030, y + 0.0030, 0.0020), V3(side * 0.0042, y + 0.0030, 0.0008)],
                                       radii: [0.00018, 0.00014, 0.00014], material: "insect.chitin-soft:8A7A62", sides: max(3, d.sides - 2), per: d.per), to: "body", lods: L)
                rig.add(InsectKit.blob(V3(side * 0.0044, y + 0.0030, 0.0006), V3(0.00035, 0.00035, 0.00040), material: "insect.chitin-soft:D8D0B8", sub: 1), to: "body", lods: L)
            }
            // Dorsal thorax stripes.
            for x: Float in [-0.0008, 0.0008] {
                rig.add(InsectKit.blob(V3(x, y + 0.0027, 0.0068), V3(0.00025, 0.00025, 0.0030), material: "insect.chitin-soft:4A4034", sub: 1), to: "body", lods: L)
            }
            // Abdominal segment bands.
            for i in 0..<6 {
                let z = Float(-0.0035 - 0.0035 * Float(i))
                let k = 1 - 0.55 * max(0, 1 - (z + 0.025) / 0.028)
                rig.add(InsectKit.blob(V3(0, y - 0.0002, z), V3(0.0016 * k * 1.1, 0.0015 * k * 1.1, 0.00028), material: "insect.chitin-soft:4A4034", sub: 1), to: "abdomen", lods: L)
            }
        }
        return InsectKit.assemble(p)
    }
}
