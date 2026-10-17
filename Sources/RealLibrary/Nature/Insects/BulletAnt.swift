import simd
import Foundation

/// Bullet ant worker (Paraponera clavata), 25 mm: glossy red-black chitin, large sculpted mandibles, one-node petiole, long stout legs, elbowed antennae, stinger at the gaster tip.
public struct BulletAnt: RealArticulated {
    public static let id = "insect-bullet-ant"
    public static let summary = "Bullet ant worker, 25 mm: glossy red-black chitin, sculpted mandibles, single petiole node, stout legs, elbowed antennae, stinger."
    public static let tags = ["nature", "insect", "crawling", "articulated"]
    public static let budget = 16_000
    public static let preview = PreviewHint(azimuth: 40, elevation: 30, distance: 1.0, ground: false, studio: true)
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var p = InsectPlan(name: Self.id)
        let y: Float = 0.0082
        let c: MaterialKey = "insect.chitin-chestnut:4A1A0A"      // red-brown black mesosoma
        let h: MaterialKey = "insect.chitin-chestnut:5A2210"
        let g: MaterialKey = "insect.chitin:1E0C08"      // darker gaster
        p.height = y + 0.005
        p.bodyPivot = V3(0, y, 0.0035)
        // mesosoma: long humped alate-less thorax with pronotum shoulder and propodeum slope
        p.thorax = [.init(V3(0, y + 0.0006, 0.0046), V3(0.0025, 0.0026, 0.0030), h) { q in V3(q.x, q.y + (q.z < -0.001 ? -0.0008 * (-q.z / 0.0033) : 0), q.z) },
                    .init(V3(0, y + 0.0000, 0.0008), V3(0.0016, 0.0017, 0.0034), c) { q in V3(q.x, q.y - max(0, -q.z) * 0.15, q.z) },
                    .init(V3(0, y + 0.0007, -0.0022), V3(0.0019, 0.0021, 0.0025), c),
                    .init(V3(0, y - 0.0003, -0.0042), V3(0.0011, 0.0019, 0.0011), h)]   // petiole node
        p.neck = V3(0, y + 0.0008, 0.0078)
        p.head = [.init(V3(0, y + 0.0010, 0.0100), V3(0.0025, 0.0025, 0.0032), h) { q in V3(q.x * (1 + (q.z > 0 ? 0.1 : 0)), q.y, q.z) },
                  .init(V3(0.0021, y + 0.0014, 0.0097), V3(0.0005, 0.0007, 0.0008), "insect.eye:2A1410", mirror: true)]
        p.abdomenPivot = V3(0, y - 0.0006, -0.0050)
        p.abdomen = [.init(V3(0, y - 0.0003, -0.0095), V3(0.0027, 0.0025, 0.0043), g) { q in V3(q.x, q.y + max(0, -q.z - 0.004) * -0.2, q.z) },
                     .init(V3(0, y - 0.0007, -0.0060), V3(0.0016, 0.0017, 0.0016), "insect.chitin:2A1008")]
        func leg(_ z: Float, _ yaw: Float, _ f: Float, _ t: Float, _ ta: Float) -> InsectKit.Leg {
            .init(attach: V3(0.0012, y - 0.0010, z), side: 1, yaw: yaw, coxa: 0.0016, femur: f, tibia: t, tarsus: ta, lift: 40, radius: 0.00078, bulge: 1.45)
        }
        p.legs = [leg(0.0060, 50, 0.0072, 0.0074, 0.0050), leg(0.0015, 0, 0.0076, 0.0078, 0.0054), leg(-0.0025, -50, 0.0088, 0.0092, 0.0060)]
        p.legMat = "insect.chitin-matte:3A1A0E"; p.antennaMat = "insect.chitin-matte:4A200E"
        p.antenna = .init(base: V3(0.0007, y + 0.0020, 0.0118), dir: V3(0.35, 0.6, 0.7), length: 0.0095, radius: 0.00042, curve: 0.3, elbow: 1.35, club: 0.3)
        p.extra = { rig, d, L in
            for side: Float in [1, -1] {
                // sculpted mandible: stout base curving inward to a toothed tip
                rig.add(InsectKit.limb([V3(side * 0.0010, y + 0.0002, 0.0122), V3(side * 0.0016, y + 0.0000, 0.0140), V3(side * 0.0008, y - 0.0003, 0.0156), V3(side * 0.0001, y - 0.0003, 0.0160)],
                                       radii: [0.00085, 0.00070, 0.00045, 0.00012], material: "insect.chitin:3A1208", sides: 6, per: 3), to: "head", lods: L)
                rig.add(InsectKit.blob(V3(side * 0.0006, y - 0.0003, 0.0151), V3(0.00018, 0.00030, 0.00050), material: "insect.chitin:2A0E06", sub: 2), to: "head", lods: L)
            }
            // gaster tergite bands (slightly proud rings) and fine sutures
            for dz: Float in [-0.0026, -0.0010, 0.0006, 0.0021] {
                let k = (1 - (dz / 0.0043) * (dz / 0.0043)).squareRoot()
                rig.add(InsectKit.blob(V3(0, y - 0.0003 + dz * 0.0, -0.0095 + dz), V3(0.0027 * k * 1.03, 0.0025 * k * 1.03, 0.00045), material: "insect.chitin:3E160A", sub: 4), to: "abdomen", lods: L)
            }
            // propodeal spines, pronotal shoulders and claws
            for side: Float in [1, -1] {
                rig.add(InsectKit.limb([V3(side * 0.0008, y + 0.0010, -0.0036), V3(side * 0.0009, y + 0.0016, -0.0044), V3(side * 0.0009, y + 0.0020, -0.0050)],
                                       radii: [0.00045, 0.00025, 0.00004], material: "insect.chitin:3A1608", sides: 5, per: 2), to: "body", lods: L)
                rig.add(InsectKit.blob(V3(side * 0.0020, y + 0.0014, 0.0060), V3(0.0006, 0.0005, 0.0010), material: "insect.chitin:4E1E0C", sub: 4), to: "body", lods: L)
            }
            // stinger at gaster tip
            rig.add(InsectKit.limb([V3(0, y - 0.0009, -0.0140), V3(0, y - 0.0012, -0.0156), V3(0, y - 0.0016, -0.0170)],
                                   radii: [0.00055, 0.00030, 0.00005], material: "insect.chitin:5A2A12", sides: 5, per: 2), to: "abdomen", lods: L)
        }
        return InsectKit.assemble(p)
    }
}
