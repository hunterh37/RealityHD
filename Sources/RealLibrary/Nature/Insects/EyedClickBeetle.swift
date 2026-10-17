import simd
import Foundation

/// Eastern eyed click beetle (Alaus oculatus), 35 mm: elongate mottled black body with silver-white scale
/// speckle, two white-ringed black eyespots on the pronotum, serrate comb antennae, ridged elytra.
public struct EyedClickBeetle: RealArticulated {
    public static let id = "insect-eyed-click-beetle"
    public static let summary = "Eyed click beetle, 35 mm: mottled black body with silver speckle, white-ringed pronotum eyespots, comb antennae; articulated legs, elytra, wings."
    public static let tags = ["nature", "insect", "crawling", "flying", "articulated"]
    public static let budget = 16_000
    public static let preview = PreviewHint(azimuth: 35, elevation: 30, distance: 0.45, ground: false, studio: true)
    public var shell: MaterialKey = "insect.chitin-matte:26262A"
    public var black: MaterialKey = "insect.chitin-matte:1A1A1C"
    public var silver: MaterialKey = "insect.chitin-matte:B4B4AE"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var p = InsectPlan(name: Self.id)
        p.height = 0.010
        p.bodyPivot = V3(0, 0.0055, 0.003)
        p.thorax = [.init(V3(0, 0.0056, 0.0086), V3(0.0049, 0.0019, 0.0046), black),
                    .init(V3(0, 0.0050, 0.0020), V3(0.0042, 0.0022, 0.0030), black)]
        p.neck = V3(0, 0.0054, 0.0128)
        p.head = [.init(V3(0, 0.0050, 0.0154), V3(0.0039, 0.0027, 0.0034), black),
                  .init(V3(0.0032, 0.0056, 0.0158), V3(0.0010, 0.0013, 0.0014), "insect.eye", mirror: true)]
        p.abdomenPivot = V3(0, 0.0048, -0.001)
        p.abdomen = [.init(V3(0, 0.0046, -0.0100), V3(0.0042, 0.0022, 0.0105), "insect.chitin-matte:1E1E20")]
        p.legs = [
            .init(attach: V3(0.0030, 0.0042, 0.0085), side: 1, yaw: 55, coxa: 0.0010, femur: 0.0055, tibia: 0.0060, tarsus: 0.0050, lift: 25, radius: 0.00055, bulge: 1.2),
            .init(attach: V3(0.0034, 0.0040, 0.0010), side: 1, yaw: 0, coxa: 0.0010, femur: 0.0060, tibia: 0.0065, tarsus: 0.0055, lift: 25, radius: 0.00055, bulge: 1.2),
            .init(attach: V3(0.0034, 0.0040, -0.0035), side: 1, yaw: -50, coxa: 0.0010, femur: 0.0065, tibia: 0.0070, tarsus: 0.0060, lift: 25, radius: 0.00055, bulge: 1.2),
        ]
        p.legMat = "insect.chitin-matte:2A241E"; p.antennaMat = black; p.spines = [2, 2, 2]
        p.antenna = .init(base: V3(0.0028, 0.0058, 0.0172), dir: V3(0.45, 0.15, 0.85), length: 0.0085, radius: 0.00028, curve: 0, beads: 9)
        p.elytra = .init(front: 0.0030, length: 0.0235, halfWidth: 0.0049, height: 0.0040, baseY: 0.0050, mat: shell, inner: "insect.chitin-matte:1A1A1C", atlas: false, tipRound: 0.7)
        p.hind = .init(.membraneHind, root: V3(0.0022, 0.0060, 0.0030), span: V3(1, 0.05, -0.35), chord: V3(0.35, 0, 1), length: 0.022, width: 0.0085,
                       mat: "insect.membrane-amber", veins: "insect.veins-beetle", droop: 0.0012,
                       folded: (V3(0.0018, 0.0051, 0.0030), V3(0.1, 0, -1), V3(1, 0, 0.1), 0.0105, 0.003))
        p.openWing = 10
        let black = black, silver = silver
        p.extra = { rig, d, L in
            var rng = SeededRNG(seed: seed &+ 7)
            func prof(_ u: Float) -> Float {
                let t = (0.7 - (1 - u)) / 0.7
                return t > 0 ? sqrt(max(0, 1 - t * t)) : 1
            }
            for side: Float in [1, -1] {
                // Pronotum eyespot: white ring with black pupil.
                rig.add(InsectKit.blob(V3(side * 0.0019, 0.0072, 0.0090), V3(0.0011, 0.0004, 0.0013), material: "insect.chitin-matte:E6E6E0", sub: max(2, d.sub - 2)), to: "body", lods: L)
                rig.add(InsectKit.blob(V3(side * 0.0019, 0.0073, 0.0090), V3(0.0007, 0.0004, 0.0009), material: "insect.chitin-matte:070708", sub: max(2, d.sub - 2)), to: "body", lods: L)
                // Comb teeth on each antennal segment.
                let base = V3(0.0028, 0.0058, 0.0172), dir = simd_normalize(V3(0.45, 0.15, 0.85))
                for k in 1...9 {
                    let t = Float(k) / 10, c = base + dir * (0.0085 * t)
                    let c2 = c + V3(0.0004, -0.0010, 0.0006) * (1 - 0.3 * t) + V3(0.0006, 0, -0.0002)
                    let a = V3(side * c.x, c.y, c.z), b = V3(side * c2.x, c2.y, c2.z)
                    rig.add(InsectKit.limb([a, b], radii: [0.00022, 0.00008], material: black, sides: 4, per: 1), to: side > 0 ? "antenna-l" : "antenna-r", lods: L)
                }
                // Pronotum hind-angle spine.
                rig.add(InsectKit.limb([V3(side * 0.0042, 0.0058, 0.0046), V3(side * 0.0052, 0.0054, 0.0030)], radii: [0.0008, 0.00008], material: black, sides: 4, per: 1), to: "body", lods: L)
                // Mandible and palps.
                rig.add(InsectKit.limb([V3(side * 0.0016, 0.0042, 0.0178), V3(side * 0.0012, 0.0036, 0.0196)], radii: [0.0007, 0.0002], material: black, sides: 5, per: 1), to: "head", lods: L)
                // Silver scale speckle on elytron.
                // Longitudinal ridges (striae) on the elytron.
                for xf: Float in [0.2, 0.4, 0.6, 0.8] {
                    let pts = (0...6).map { i -> V3 in
                        let u = Float(i) / 6 * 0.9 + 0.02
                        let hw = 0.0049 * max(0.02, prof(u)) * xf
                        return V3(side * hw, 0.0050 + 0.0040 * sqrt(max(0, 1 - xf * xf)) * prof(u) * (1 - 0.25 * u) + 0.00005, 0.0030 - 0.0235 * u)
                    }
                    rig.add(InsectKit.limb(pts, radii: [0.00014, 0.00014, 0.00014, 0.00014, 0.00012, 0.00009, 0.00004], material: "insect.chitin-matte:343438", sides: 4, per: 1), to: side > 0 ? "elytra-l" : "elytra-r", lods: L)
                }
                let n = d.lod == 0 ? 42 : 0
                for _ in 0..<n {
                    let u = Float.random(in: 0.04...0.88, using: &rng), x = Float.random(in: 0.08...0.92, using: &rng)
                    let z = 0.0030 - 0.0235 * u
                    let hw = 0.0049 * max(0.02, prof(u)) * x
                    let y = 0.0050 + 0.0040 * sqrt(max(0, 1 - x * x)) * prof(u) * (1 - 0.25 * u) + 0.0003
                    let r = Float.random(in: 0.00012...0.00024, using: &rng)
                    rig.add(InsectKit.blob(V3(side * hw, y, z), V3(r, r * 0.35, r * 1.2), material: silver, sub: 1), to: side > 0 ? "elytra-l" : "elytra-r", lods: L)
                }
                for _ in 0..<(d.lod == 0 ? 8 : 0) {
                    let x = Float.random(in: 0.1...0.9, using: &rng), z = Float.random(in: 0.0045...0.0120, using: &rng)
                    let r = Float.random(in: 0.00012...0.00022, using: &rng)
                    rig.add(InsectKit.blob(V3(side * 0.0042 * x, 0.0076 - 0.0005 * x * x, z), V3(r, r * 0.5, r), material: silver, sub: 1), to: "body", lods: L)
                }
            }
        }
        return InsectKit.assemble(p)
    }
}
