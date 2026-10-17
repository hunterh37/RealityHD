import simd
import Foundation

/// Male goliath beetle (Goliathus goliatus), 8.5 cm: white pronotum with bold black longitudinal stripes,
/// milky-white elytra with brown veining, black-brown head with a Y-shaped horn, thick spined legs.
public struct GoliathBeetle: RealArticulated {
    public static let id = "insect-goliath-beetle"
    public static let summary = "Male goliath beetle, 8.5 cm: striped white-and-black pronotum, milky elytra, Y-horn, thick spined legs; articulated legs, elytra, wings."
    public static let tags = ["nature", "insect", "crawling", "flying", "articulated"]
    public static let budget = 16_000
    public static let preview = PreviewHint(azimuth: 38, elevation: 28, distance: 1.0, ground: false, studio: true)
    public var shell: MaterialKey = "insect.chitin-matte:E8E3D2"
    public var black: MaterialKey = "insect.chitin:171310"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var p = InsectPlan(name: Self.id)
        let white: MaterialKey = "insect.chitin-matte:EDE8DA"
        p.height = 0.032
        p.bodyPivot = V3(0, 0.0125, 0.006)
        p.thorax = [.init(V3(0, 0.0150, 0.0125), V3(0.0150, 0.0058, 0.0115), white) { q in V3(q.x, q.y, q.z) },
                    .init(V3(0, 0.0105, 0.0040), V3(0.0110, 0.0050, 0.0080), black)]
        p.neck = V3(0, 0.0125, 0.0235)
        p.head = [.init(V3(0, 0.0125, 0.0285), V3(0.0115, 0.0060, 0.0085), "insect.chitin:2A1A12"),
                  .init(V3(0.0092, 0.0135, 0.0290), V3(0.0020, 0.0020, 0.0022), "insect.eye", mirror: true)]
        p.abdomenPivot = V3(0, 0.0115, 0.003)
        p.abdomen = [.init(V3(0, 0.0105, -0.0140), V3(0.0125, 0.0050, 0.0185), "insect.chitin-matte:241812")]
        p.legs = [
            .init(attach: V3(0.0070, 0.0095, 0.0180), side: 1, yaw: 55, coxa: 0.0025, femur: 0.0130, tibia: 0.0150, tarsus: 0.0110, lift: 26, radius: 0.0018, bulge: 1.35),
            .init(attach: V3(0.0080, 0.0090, 0.0050), side: 1, yaw: -5, coxa: 0.0025, femur: 0.0150, tibia: 0.0160, tarsus: 0.0120, lift: 26, radius: 0.0017, bulge: 1.3),
            .init(attach: V3(0.0080, 0.0090, -0.0050), side: 1, yaw: -50, coxa: 0.0025, femur: 0.0160, tibia: 0.0170, tarsus: 0.0130, lift: 26, radius: 0.0017, bulge: 1.3),
        ]
        p.legMat = "insect.chitin:2A1A12"; p.antennaMat = black; p.spines = [5, 4, 4]
        p.antenna = .init(base: V3(0.0060, 0.0140, 0.0340), dir: V3(0.6, 0.2, 0.75), length: 0.0095, radius: 0.0005, curve: 0.25, elbow: 0.9, club: 3.0, beads: 3)
        p.elytra = .init(front: 0.0090, length: 0.0400, halfWidth: 0.0140, height: 0.0075, baseY: 0.0110, mat: shell, inner: "insect.chitin-matte:5A3A22", atlas: false)
        p.hind = .init(.membraneHind, root: V3(0.0050, 0.0185, 0.0050), span: V3(1, 0.05, -0.35), chord: V3(0.35, 0, 1), length: 0.058, width: 0.026,
                       mat: "insect.membrane-amber", veins: "insect.veins-beetle", droop: 0.003,
                       folded: (V3(0.0040, 0.0170, 0.0050), V3(0.12, 0, -1), V3(1, 0, 0.1), 0.026, 0.009))
        p.openWing = 10
        let black = black
        p.extra = { rig, d, L in
            // Black pronotum stripes: median pair and lateral bands on the white shield.
            for x: Float in [0.0030, 0.0085, -0.0030, -0.0085] {
                rig.add(InsectKit.blob(V3(x, 0.0192, 0.0125), V3(0.0017, 0.0014, 0.0105), material: black, sub: d.sub - 2), to: "body", lods: L)
            }
            for side: Float in [1, -1] {
                rig.add(InsectKit.blob(V3(side * 0.0140, 0.0150, 0.0125), V3(0.0016, 0.0042, 0.0100), material: black, sub: d.sub - 2), to: "body", lods: L)
            }
            // Brown elytral veins: parallel longitudinal ribs.
            for (i, x) in [Float(0.0025), 0.0050, 0.0075, 0.0100, 0.0125].enumerated() {
                for side: Float in [1, -1] {
                    let pts = (0..<5).map { k -> V3 in let t = Float(k) / 4; return V3(side * x * (1 - 0.15 * t * t), 0.0192 - 0.0050 * t * t - Float(i) * 0.0009, 0.0030 - 0.028 * t) }
                    rig.add(InsectKit.limb(pts, radii: [0.0006, 0.0007, 0.0007, 0.0006, 0.0003], material: "insect.chitin-matte:6B4326", sides: 4, per: 2), to: side > 0 ? "elytra-l" : "elytra-r", lods: L)
                }
            }
            // Wear: brown mottling and scuffs across the milky elytra.
            var g = SeededRNG(seed: 77)
            for k in 0..<26 {
                let side: Float = k % 2 == 0 ? 1 : -1
                let x = side * (0.002 + g.float() * 0.011), z = 0.003 - g.float() * 0.027
                let y = 0.0192 - 0.0050 * pow((0.003 - z) / 0.028, 2) - x * x * 0
                let r = 0.0005 + g.float() * 0.0007
                rig.add(InsectKit.blob(V3(x, y - 0.0006, z), V3(r, r * 0.5, r * 1.3), material: "insect.chitin-matte:8A6A48", sub: max(2, d.sub - 4)), to: side > 0 ? "elytra-l" : "elytra-r", lods: L)
            }
            // Y-horn: stem rising from the clypeus, forking into two tines curving forward.
            let stem = [V3(0, 0.0140, 0.0320), V3(0, 0.0175, 0.0350), V3(0, 0.0215, 0.0370)]
            rig.add(InsectKit.limb(stem, radii: [0.0032, 0.0023, 0.0016], material: "insect.chitin:2A1A12", sides: d.sides, per: d.per), to: "head", lods: L)
            for side: Float in [1, -1] {
                let tine = [V3(0, 0.0215, 0.0370), V3(side * 0.0035, 0.0235, 0.0410), V3(side * 0.0050, 0.0245, 0.0470)]
                rig.add(InsectKit.limb(tine, radii: [0.0016, 0.0012, 0.0004], material: "insect.chitin:2A1A12", sides: d.sides, per: d.per), to: "head", lods: L)
                // Small clypeal horn tines and palps.
                rig.add(InsectKit.limb([V3(side * 0.0030, 0.0090, 0.0345), V3(side * 0.0040, 0.0085, 0.0385)], radii: [0.0010, 0.0003], material: black, sides: 4, per: 1), to: "head", lods: L)
            }
        }
        return InsectKit.assemble(p)
    }
}
