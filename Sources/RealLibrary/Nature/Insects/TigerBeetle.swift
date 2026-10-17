import simd
import Foundation

/// Six-spotted tiger beetle (Cicindela sexguttata), 12 mm: slender metallic emerald body with bronze
/// sheen, huge bulging eyes, long curved toothed mandibles, long thin legs, three white spots on each elytron.
public struct TigerBeetle: RealArticulated {
    public static let id = "insect-tiger-beetle"
    public static let summary = "Six-spotted tiger beetle, 12 mm: metallic emerald elytra with white spots, bulging eyes, toothed mandibles, long legs; articulated legs, elytra, wings."
    public static let tags = ["nature", "insect", "crawling", "flying", "articulated"]
    public static let budget = 15_000
    public static let preview = PreviewHint(azimuth: 35, elevation: 30, distance: 0.3, ground: false, studio: true)
    public var metal: MaterialKey = "insect.chitin-metallic:1C9A58"
    public var bronze: MaterialKey = "insect.chitin-metallic:7A6A28"
    public var dark: MaterialKey = "insect.chitin-matte:2A2418"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var p = InsectPlan(name: Self.id)
        p.height = 0.0075
        p.bodyPivot = V3(0, 0.0048, 0.002)
        p.thorax = [.init(V3(0, 0.0058, 0.0047), V3(0.0023, 0.0016, 0.0020), "insect.chitin-metallic:2A8A40"),
                    .init(V3(0, 0.0050, 0.0020), V3(0.0026, 0.0017, 0.0022), metal)]
        p.neck = V3(0, 0.0054, 0.0065)
        p.head = [.init(V3(0, 0.0056, 0.0078), V3(0.0023, 0.0017, 0.0017), "insect.chitin-metallic:1C9A58"),
                  .init(V3(0.0026, 0.0063, 0.0077), V3(0.0015, 0.0018, 0.0017), "insect.eye:2A1E14", mirror: true)]
        p.abdomenPivot = V3(0, 0.0046, 0.0004)
        p.abdomen = [.init(V3(0, 0.0045, -0.0022), V3(0.0027, 0.0016, 0.0036), "insect.chitin-metallic:4A5A28")]
        p.legs = [
            .init(attach: V3(0.0018, 0.0040, 0.0054), side: 1, yaw: 50, coxa: 0.0007, femur: 0.0050, tibia: 0.0056, tarsus: 0.0048, lift: 38, radius: 0.00028),
            .init(attach: V3(0.0021, 0.0038, 0.0020), side: 1, yaw: 0, coxa: 0.0007, femur: 0.0056, tibia: 0.0062, tarsus: 0.0050, lift: 38, radius: 0.00028),
            .init(attach: V3(0.0021, 0.0038, -0.0006), side: 1, yaw: -50, coxa: 0.0007, femur: 0.0060, tibia: 0.0066, tarsus: 0.0052, lift: 38, radius: 0.00028),
        ]
        p.legMat = "insect.chitin-metallic:6A4A28"; p.antennaMat = dark
        p.antenna = .init(base: V3(0.0012, 0.0066, 0.0090), dir: V3(0.55, 0.3, 0.8), length: 0.0075, radius: 0.00013, curve: 0.4, beads: 11)
        p.elytra = .init(front: 0.0036, length: 0.0094, halfWidth: 0.0027, height: 0.0020, baseY: 0.0049, mat: "insect.elytra-tiger", inner: "insect.elytra-tiger", atlas: true, wrap: 1.75, tipRound: 0.5)
        p.hind = .init(.membraneHind, root: V3(0.0016, 0.0062, 0.0030), span: V3(1, 0.05, -0.3), chord: V3(0.3, 0, 1), length: 0.0120, width: 0.0050,
                       mat: "insect.membrane-smoky", veins: "insect.veins-beetle", droop: 0.0008,
                       folded: (V3(0.0012, 0.0054, 0.0030), V3(0.1, 0, -1), V3(1, 0, 0.1), 0.0068, 0.002))
        p.openWing = 10
        let dark = dark
        p.extra = { rig, d, L in
            for side: Float in [1, -1] {
                let sub = max(2, d.sub - 2)
                // Labrum plate and long curved mandibles with inner teeth.
                rig.add(InsectKit.blob(V3(side * 0.0006, 0.0050, 0.0094), V3(0.0006, 0.0003, 0.0003), material: "insect.chitin-matte:E6E0CC", sub: sub), to: "head", lods: L)
                let m = [V3(side * 0.0016, 0.0047, 0.0088), V3(side * 0.0019, 0.0045, 0.0100), V3(side * 0.0013, 0.0045, 0.0110), V3(side * 0.0004, 0.0046, 0.0114), V3(side * -0.0002, 0.0047, 0.0118)]
                rig.add(InsectKit.limb(m, radii: [0.00040, 0.00032, 0.00020, 0.00012, 0.00003], material: "insect.chitin-matte:B8A878", sides: 5, per: 2), to: "head", lods: L)
                if d.lod == 0 {
                    for (a, b) in [(1, 0.00036 as Float), (2, 0.0003), (3, 0.00022)] {
                        let c = m[a], tip = c + V3(-side * 0.0004, 0, 0.0002)
                        rig.add(InsectKit.limb([c, tip], radii: [b, 0.00003], material: "insect.chitin-matte:B8A878", sides: 4, per: 1), to: "head", lods: L)
                    }
                }
                // Maxillary palps.
                rig.add(InsectKit.limb([V3(side * 0.0010, 0.0042, 0.0088), V3(side * 0.0010, 0.0036, 0.0098)], radii: [0.00020, 0.00008], material: dark, sides: 4, per: 1), to: "head", lods: L)
                // White hair tufts on the sides of the thorax.
                if d.lod == 0 {
                    rig.add(InsectKit.blob(V3(side * 0.0024, 0.0044, 0.0040), V3(0.0002, 0.0004, 0.0009), material: "insect.chitin-matte:B8B4A4", sub: 1), to: "body", lods: L)
                }
            }
        }
        let seedV = seed
        let prev = p.extra
        p.extra = { rig, d, L in
            prev?(&rig, d, L)
            guard d.lod == 0 else { return }
            var rng = SeededRNG(seed: seedV &+ 11)
            let hair: MaterialKey = "insect.chitin-matte:E4E0D0"
            var strands = Surface(material: hair)
            for _ in 0..<70 {
                let side: Float = Bool.random(using: &rng) ? 1 : -1
                let z = Float.random(in: 0.0010...0.0085, using: &rng)
                let y = Float.random(in: 0.0036...0.0052, using: &rng)
                let base = V3(side * 0.0025, y, z)
                let len = Float.random(in: 0.0006...0.0011, using: &rng)
                let dir = simd_normalize(V3(side * 0.8, -0.5, Float.random(in: -0.3...0.3, using: &rng)))
                strands.append(InsectKit.limb([base, base + dir * len], radii: [0.00005, 0.00001], material: hair, sides: 3, per: 1))
            }
            rig.add(strands, to: "body", lods: L)
        }
        return InsectKit.assemble(p)
    }
}
