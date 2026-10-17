import simd
import Foundation

/// Common earwig (Forficula auricularia), 14 mm body: flat shiny chestnut-brown body, heart-shaped head,
/// short elytra exposing ten abdominal segments, curved forceps (cerci), pale yellow-brown legs, beaded antennae.
public struct Earwig: RealArticulated {
    public static let id = "insect-earwig"
    public static let summary = "Common earwig, 14 mm: flat chestnut body, short elytra over 10 abdominal segments, curved forceps, pale legs, beaded antennae; articulated legs, antennae, abdomen."
    public static let tags = ["nature", "insect", "crawling", "articulated"]
    public static let budget = 16_000
    public static let preview = PreviewHint(azimuth: 35, elevation: 45, distance: 0.55, ground: false, studio: true)
    public var shell: MaterialKey = "insect.chitin-earwig:6A3216"
    public var dark: MaterialKey = "insect.chitin-earwig:3A1A0C"
    public var legTone: MaterialKey = "insect.chitin-earwig:B08E50"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var p = InsectPlan(name: Self.id)
        let y: Float = 0.0014
        p.height = 0.0030
        p.bodyPivot = V3(0, y, 0.003)
        p.thorax = [.init(V3(0, y + 0.0001, 0.0043), V3(0.0016, 0.0006, 0.0013), "insect.chitin-earwig:5E2C14"),
                    .init(V3(0, y, 0.0028), V3(0.0015, 0.0006, 0.0010), shell)]
        p.neck = V3(0, y, 0.0056)
        p.head = [.init(V3(0, y, 0.0069), V3(0.0014, 0.0007, 0.0012), "insect.chitin-earwig:8A4420"),
                  .init(V3(0.0011, y + 0.0002, 0.0066), V3(0.0004, 0.0004, 0.0005), "insect.eye:140C08", mirror: true)]
        p.abdomenPivot = V3(0, y, 0.0018)
        p.abdomen = [.init(V3(0, y - 0.0001, 0.0014), V3(0.0012, 0.0005, 0.0008), dark)]
        p.legs = [
            .init(attach: V3(0.0009, y - 0.0003, 0.0046), side: 1, yaw: 55, coxa: 0.0004, femur: 0.0019, tibia: 0.0020, tarsus: 0.0013, lift: 30, radius: 0.00030),
            .init(attach: V3(0.0011, y - 0.0003, 0.0030), side: 1, yaw: 5, coxa: 0.0004, femur: 0.0021, tibia: 0.0022, tarsus: 0.0014, lift: 30, radius: 0.00030),
            .init(attach: V3(0.0012, y - 0.0003, 0.0018), side: 1, yaw: -50, coxa: 0.0004, femur: 0.0024, tibia: 0.0025, tarsus: 0.0015, lift: 30, radius: 0.00030),
        ]
        p.legMat = legTone
        p.antennaMat = "insect.chitin-earwig:4A2410"
        p.antenna = .init(base: V3(0.0006, y + 0.0003, 0.0076), dir: V3(0.45, 0.25, 0.85), length: 0.0058, radius: 0.00017, curve: 0.35, beads: 14)
        p.elytra = .init(front: 0.0046, length: 0.0032, halfWidth: 0.0016, height: 0.0007, baseY: 0.0015, mat: "insect.chitin-earwig:4C2210", inner: dark, atlas: false, wrap: 1.4, tipRound: 0.25)
        p.extraParts = { rig in
            for i in 0..<10 {
                rig.part("segment-\(i)", parent: "abdomen", pivot: V3(0, y, 0.0010 - Float(i) * 0.00072), joint: .hinge(axis: .up, -8...8, duration: 0.3))
            }
        }
        let dark = dark
        p.extra = { rig, d, L in
            for i in 0..<10 {
                let f = Float(i)
                let z = 0.0006 - f * 0.00072
                let w: Float = 0.00140 - 0.000030 * pow(f - 4.0, 2)
                let tone: MaterialKey = i % 2 == 0 ? "insect.chitin-earwig:5A2A10" : "insect.chitin-earwig:6A3216"
                // Flat tergite plate with a darker rim band at the segment edge.
                rig.add(InsectKit.blob(V3(0, y - 0.0001, z), V3(w, 0.00034, 0.00066), material: tone, sub: max(2, d.sub - 1)), to: "segment-\(i)", lods: L)
                rig.add(InsectKit.blob(V3(0, y - 0.0002, z - 0.00050), V3(w * 0.98, 0.00026, 0.00014), material: dark, sub: 2), to: "segment-\(i)", lods: L)
            }
            // Pleural margin under each tergite.
            for i in 0..<10 {
                let f = Float(i), z = 0.0006 - f * 0.00072
                let w: Float = 0.00140 - 0.000030 * pow(f - 4.0, 2)
                for side: Float in [1, -1] {
                    rig.add(InsectKit.blob(V3(side * w * 0.9, y - 0.0003, z), V3(0.00022, 0.00018, 0.00060), material: "insect.chitin-earwig:8A5A30", sub: 2), to: "segment-\(i)", lods: L)
                }
            }
            // Forceps: broad base plate, thick curved arms with inward tips and inner teeth.
            rig.add(InsectKit.blob(V3(0, y - 0.0001, -0.0068), V3(0.0006, 0.00032, 0.00030), material: dark, sub: 2), to: "segment-9", lods: L)
            for side: Float in [1, -1] {
                let pts = [V3(side * 0.00040, y - 0.0001, -0.0066), V3(side * 0.00075, y - 0.0001, -0.0076), V3(side * 0.00095, y - 0.0001, -0.0088),
                           V3(side * 0.00080, y - 0.0001, -0.0099), V3(side * 0.00062, y - 0.0001, -0.0108), V3(side * 0.00044, y - 0.0001, -0.0112)]
                rig.add(InsectKit.limb(pts, radii: [0.00034, 0.00032, 0.00026, 0.00020, 0.00012, 0.00004], material: "insect.chitin-earwig:5A2410", sides: 6, per: 3), to: "segment-9", lods: L)
                if d.lod == 0 {
                    rig.add(InsectKit.limb([V3(side * 0.00078, y - 0.0001, -0.0092), V3(side * 0.00050, y - 0.0001, -0.0095)], radii: [0.00016, 0.00003], material: "insect.chitin-earwig:5A2410", sides: 4, per: 1), to: "segment-9", lods: L)
                    rig.add(InsectKit.limb([V3(side * 0.00060, y - 0.0003, 0.0078), V3(side * 0.00030, y - 0.0003, 0.0086)], radii: [0.00018, 0.00004], material: dark, sides: 4, per: 1), to: "head", lods: L)
                }
            }
        }
        return InsectKit.assemble(p)
    }
}
