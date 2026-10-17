import simd
import Foundation

/// Green lacewing (Chrysoperla carnea), 1.3 cm body: pale green slender body, metallic golden eyes, long thread
/// antennae, two pairs of large transparent net-veined wings held tent-wise with green costal veins.
public struct GreenLacewing: RealArticulated {
    public static let id = "insect-green-lacewing"
    public static let summary = "Green lacewing, 1.3 cm body: pale green, golden eyes, long thread antennae, large net-veined wings held tent-wise; articulated."
    public static let tags = ["nature", "insect", "flying", "crawling", "articulated"]
    public static let budget = 14_000
    public static let preview = PreviewHint(azimuth: 50, elevation: 28, distance: 0.5, ground: false, studio: true)
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var p = InsectPlan(name: Self.id)
        let y: Float = 0.0070
        let body: MaterialKey = "insect.chitin-soft:A9D08A"
        let pale: MaterialKey = "insect.chitin-soft:C6E0A6"
        let leg: MaterialKey = "insect.chitin-soft:9CC47A"
        p.height = y + 0.005
        p.bodyPivot = V3(0, y, 0.002)
        p.thorax = [.init(V3(0, y + 0.0008, 0.0038), V3(0.0015, 0.0016, 0.0026), body),
                    .init(V3(0, y + 0.0022, 0.0034), V3(0.0010, 0.0008, 0.0022), pale),
                    .init(V3(0, y + 0.0004, 0.0008), V3(0.0013, 0.0014, 0.0014), body)]
        p.neck = V3(0, y + 0.0002, 0.0066)
        p.head = [.init(V3(0, y - 0.0002, 0.0074), V3(0.0015, 0.0013, 0.0012), body),
                  .init(V3(0.0013, y + 0.0003, 0.0078), V3(0.0008, 0.0010, 0.0009), "insect.eye:C8962A", mirror: true),
                  .init(V3(0, y - 0.0010, 0.0086), V3(0.0006, 0.0005, 0.0005), pale)]
        p.abdomenPivot = V3(0, y, 0.0004)
        p.abdomen = [.init(V3(0, y - 0.0002, -0.0054), V3(0.0012, 0.0011, 0.0068), body) { q in
                        let t = (q.z + 0.012) / 0.014
                        return V3(q.x * (1 - 0.45 * max(0, 1 - t)), q.y * (1 - 0.45 * max(0, 1 - t)), q.z) },
                     .init(V3(0, y + 0.0007, -0.0050), V3(0.0004, 0.0003, 0.0056), pale)]
        let c: Float = 0.0012
        p.legs = [
            .init(attach: V3(0.0010, y - 0.0012, 0.0048), side: 1, yaw: 58, coxa: c, femur: 0.0042, tibia: 0.0048, tarsus: 0.0026, lift: 30, radius: 0.00030, bulge: 1.2),
            .init(attach: V3(0.0012, y - 0.0014, 0.0034), side: 1, yaw: 8, coxa: c, femur: 0.0044, tibia: 0.0050, tarsus: 0.0026, lift: 30, radius: 0.00030, bulge: 1.2),
            .init(attach: V3(0.0010, y - 0.0012, 0.0020), side: 1, yaw: -45, coxa: c, femur: 0.0048, tibia: 0.0056, tarsus: 0.0028, lift: 30, radius: 0.00030, bulge: 1.2),
        ]
        p.legMat = leg; p.antennaMat = "insect.chitin-soft:8AB06A"; p.spines = [0, 0, 0]
        p.antenna = .init(base: V3(0.0005, y + 0.0008, 0.0082), dir: V3(0.30, 0.50, 0.85), length: 0.014, radius: 0.00009, curve: 0.35, beads: 10)
        p.fore = .init(.membraneHind, root: V3(0.0012, y + 0.0028, 0.0042), span: V3(1, 0, -0.10), chord: V3(0.10, 0, 1), length: 0.022, width: 0.0088,
                       rootV: 0.5, mat: "insect.membrane", veins: "insect.veins-fan:8CC464", droop: 0.0004,
                       folded: (V3(0.0008, y + 0.0030, 0.0040), V3(0.28, -0.30, -1), V3(0.70, -0.70, 0.05), 0.022, 0.0086))
        p.hind = .init(.membraneHind, root: V3(0.0012, y + 0.0026, 0.0030), span: V3(1, 0, -0.32), chord: V3(0.30, 0, 1), length: 0.020, width: 0.0078,
                       rootV: 0.5, mat: "insect.membrane", veins: "insect.veins-fan:8CC464",
                       folded: (V3(0.0008, y + 0.0028, 0.0030), V3(0.26, -0.30, -1), V3(0.70, -0.70, 0.05), 0.020, 0.0076))
        p.openWing = 22
        p.extra = { rig, d, L in
            // Abdominal segment bands.
            for i in 0..<6 {
                let z = Float(-0.0016 - 0.0017 * Float(i))
                let k = 1 - 0.45 * max(0, 1 - (z + 0.012) / 0.014)
                rig.add(InsectKit.blob(V3(0, y - 0.0002, z), V3(0.0012 * k * 1.05, 0.0011 * k * 1.05, 0.00018), material: "insect.chitin-soft:8DB86E", sub: 1), to: "abdomen", lods: L)
            }
        }
        return InsectKit.assemble(p)
    }
}
