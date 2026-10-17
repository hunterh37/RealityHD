import simd
import Foundation

/// Green shield bug (Palomena prasina), 13 mm: broad shield-shaped body in bright green with slight
/// bronzing on the pronotum and scutellum, pale connexivum edging the abdomen, large triangular
/// scutellum, hemelytra whose brown-black membranous tips cross over the rear, five-segment
/// antennae and six slender legs. Hind wings fold under the hemelytra and spread in `wings-open`.
public struct GreenShieldBug: RealArticulated {
    public static let id = "insect-green-shield-bug"
    public static let summary = "Green shield bug, 13 mm: shield-shaped green body, pale connexivum, scutellum, crossed membranous wing tips; articulated legs, hemelytra and wings."
    public static let tags = ["nature", "insect", "crawling", "flying", "articulated"]
    public static let budget = 14_000
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 1.0, ground: false, studio: true)

    /// Body length in meters (11-14 mm in the wild).
    public var length: Float = 0.013
    public var green: MaterialKey = "insect.chitin-shield:4C9E30"
    public var bronze: MaterialKey = "insect.chitin-shield:8A9038"
    public var corium: MaterialKey = "insect.chitin-shield:5E9C34"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        let k = length / 0.013
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [0.8])
        let leg = "insect.chitin-soft:5E9C38", pale = "insect.chitin-soft:C2CC6A", tip = "insect.chitin-matte:241810"
        let legs: [InsectKit.Leg] = [Float(1), -1].flatMap { side in
            [(0.0038, 45), (0.0004, -5), (-0.0030, -50)].map { a in
                InsectKit.Leg(attach: V3(side * 0.0026, 0.0014, Float(a.0)) * k, side: side, yaw: Float(a.1), coxa: 0.0007 * k,
                              femur: 0.0030 * k, tibia: 0.0033 * k, tarsus: 0.0018 * k, lift: 16, radius: 0.00038 * k, bulge: 1.3)
            }
        }.sorted { ($0.attach.z, $0.side) > ($1.attach.z, $1.side) }
        rig.part("body", pivot: V3(0, 0.0020, 0.0005) * k, joint: .fixed)
        rig.part("head", parent: "body", pivot: V3(0, 0.0024, 0.0062) * k, joint: .hinge(axis: V3(1, 0, 0), -15...15, duration: 0.3))
        rig.part("abdomen", parent: "body", pivot: V3(0, 0.0020, -0.0010) * k, joint: .hinge(axis: V3(1, 0, 0), -8...8, duration: 0.3))
        InsectKit.declareLegs(&rig, legs)
        rig.part("elytra-l", parent: "body", pivot: V3(0.0003, 0.0038, 0.0030) * k, joint: .hinge(axis: V3(0, 0, 1), 0...70, duration: 0.25))
        rig.part("elytra-r", parent: "body", pivot: V3(-0.0003, 0.0038, 0.0030) * k, joint: .hinge(axis: V3(0, 0, 1), -70...0, duration: 0.25))
        rig.part("wing-l", parent: "body", pivot: V3(0.0012, 0.0036, -0.0005) * k, joint: .hinge(axis: V3(0, 0, 1), -70...70, duration: 0.05), options: 2)
        rig.part("wing-r", parent: "body", pivot: V3(-0.0012, 0.0036, -0.0005) * k, joint: .hinge(axis: V3(0, 0, 1), -70...70, duration: 0.05), options: 2)
        rig.part("antenna-l", parent: "head", pivot: V3(0.0009, 0.0025, 0.0078) * k, joint: .hinge(axis: .up, -30...30, duration: 0.3))
        rig.part("antenna-r", parent: "head", pivot: V3(-0.0009, 0.0025, 0.0078) * k, joint: .hinge(axis: .up, -30...30, duration: 0.3))

        for lod in 0..<2 {
            let d = InsectKit.Detail(lod: lod)
            let L = lod...lod
            // Pronotum: broad trapezoid, widest at the shoulders, bronzed.
            rig.add(InsectKit.blob(V3(0, 0.0030, 0.0036) * k, V3(0.0044, 0.0008, 0.0021) * k, material: bronze, sub: d.sub) { p in
                let t = (p.z / (0.0021 * k) + 1) / 2   // 0 rear, 1 front
                let sx = p.x * (0.55 + 0.45 * (1 - t * t)) * 1.2
                return V3(max(-0.0044 * k, min(0.0044 * k, sx)), p.y - abs(p.x) * 0.12, p.z)
            }, to: "body", lods: L)
            // Thorax underside and abdomen: broad flat shield with connexivum rim.
            rig.add(InsectKit.blob(V3(0, 0.0019, 0.0020) * k, V3(0.0036, 0.0013, 0.0030) * k, material: green, sub: d.sub - 1), to: "body", lods: L)
            rig.add(InsectKit.blob(V3(0, 0.0021, -0.0028) * k, V3(0.0040, 0.0013, 0.0046) * k, material: green, sub: d.sub - 1) { p in
                V3(p.x, p.y * (p.y < 0 ? 0.6 : 1), p.z + (p.z < 0 ? p.x * p.x * 40 / k : 0))
            }, to: "abdomen", lods: L)
            for side: Float in [1, -1] {
                rig.add(InsectKit.blob(V3(side * 0.0037, 0.0020, -0.0028) * k, V3(0.0006, 0.0004, 0.0044) * k, material: pale, sub: d.sub - 2) { p in
                    V3(p.x, p.y, p.z + (p.z < 0 ? p.z * p.z * 0 : 0) + (p.z < 0 ? 0 : 0))
                }, to: "abdomen", lods: L)
                // Segment notches: darker spots where connexivum plates meet the body.
                for i in 0..<5 {
                    rig.add(InsectKit.blob(V3(side * 0.0041, 0.0022, (-0.0003 - 0.0016 * Float(i)) ) * k, V3(0.0005, 0.0005, 0.0004) * k, material: "insect.chitin-matte:3A6A1E", sub: 3), to: "abdomen", lods: L)
                }
            }
            // Sutures painted dark green: pronotum rear edge and clavus midline.
            let dark = "insect.chitin-matte:2A5016"
            rig.add(InsectKit.blob(V3(0, 0.0033, 0.0016) * k, V3(0.0027, 0.0003, 0.00016) * k, material: dark, sub: max(2, d.sub - 3)), to: "body", lods: L)
            // Scutellum: large triangle tapering to a rounded point at the rear.
            rig.add(InsectKit.blob(V3(0, 0.0035, 0.0000) * k, V3(0.0024, 0.0011, 0.0027) * k, material: "insect.chitin-soft:5C9C34", sub: d.sub) { p in
                let t = (p.z / (0.0027 * k) + 1) / 2   // 0 rear, 1 front
                return V3(p.x * (0.15 + 0.85 * t), p.y, p.z)
            }, to: "body", lods: L)
            // Head: small triangular head with bulging eyes.
            rig.add(InsectKit.blob(V3(0, 0.0024, 0.0072) * k, V3(0.0016, 0.0006, 0.0014) * k, material: green, sub: d.sub - 1) { p in
                V3(p.x * (p.z > 0 ? 1 - 0.5 * p.z / (0.0016 * k) : 1), p.y, p.z)
            }, to: "head", lods: L)
            for side: Float in [1, -1] {
                rig.add(InsectKit.blob(V3(side * 0.0017, 0.0027, 0.0069) * k, V3(0.0005, 0.0006, 0.0006) * k, material: "insect.eye", sub: max(2, d.sub - 3)), to: "head", lods: L)
                rig.add(InsectKit.antenna(base: V3(side * 0.0009, 0.0025, 0.0078) * k, dir: V3(side * 0.6, 0.15, 0.8), length: 0.0058 * k,
                                          radius: 0.00022 * k, curve: -0.15, side: side, beads: 5, material: leg, d: d),
                        to: side > 0 ? "antenna-l" : "antenna-r", lods: L)
            }
            for l in legs { rig.add(InsectKit.leg(l, material: leg, d: d), to: InsectKit.legName(l.side, legIndex(l, legs)), lods: L) }
            for side: Float in [1, -1] {
                // Hemelytra: green corium, flattened; dark membranous tip crossing at the rear.
                let el = InsectKit.elytron(side: side, front: 0.0030 * k, length: 0.0078 * k, halfWidth: 0.0036 * k, height: 0.0008 * k, baseY: 0.0030 * k,
                                           wrap: 1.2, material: corium, inner: green, atlas: false, d: d, shoulder: 0.1, tipRound: 0.2)
                for s in el { rig.add(s, to: side > 0 ? "elytra-l" : "elytra-r", lods: L) }
                for s in InsectKit.elytron(side: side, front: -0.0034 * k, length: 0.0036 * k, halfWidth: 0.0033 * k, height: 0.0006 * k, baseY: 0.0033 * k,
                                           wrap: 1.1, material: tip, inner: tip, atlas: false, d: d, shoulder: 0.1, tipRound: 0.5) {
                    rig.add(s, to: side > 0 ? "elytra-l" : "elytra-r", lods: L)
                }
                let wingName = side > 0 ? "wing-l" : "wing-r"
                for s in InsectKit.wing(.membraneHind, root: V3(side * 0.0010, 0.0032, 0.0000) * k, span: V3(side * 0.15, 0, -1), chord: V3(side, 0, 0.1),
                                        length: 0.0070 * k, width: 0.0026 * k, material: "insect.membrane-smoky", veins: lod == 0 ? "insect.veins-beetle" : nil) {
                    rig.add(s, to: wingName, option: 0, lods: L)
                }
                for s in InsectKit.wing(.membraneHind, root: V3(side * 0.0012, 0.0036, -0.0005) * k, span: V3(side, 0.05, -0.35), chord: V3(side * 0.35, 0, 1),
                                        length: 0.0115 * k, width: 0.0055 * k, material: "insect.membrane-smoky", veins: "insect.veins-beetle", droop: 0.0005 * k) {
                    rig.add(s, to: wingName, option: 1, lods: L)
                }
            }
        }
        rig.states = [
            RigState("rest"),
            RigState("wings-open", ["elytra-l": 55, "elytra-r": -55, "wing-l": 12, "wing-r": -12], options: ["wing-l": 1, "wing-r": 1]),
            RigState("walk-a", InsectKit.gait(20, swapped: false)),
            RigState("walk-b", InsectKit.gait(20, swapped: true)),
        ]
        InsectKit.finish(&rig, height: 0.0055 * k)
        return rig
    }

    private func legIndex(_ l: InsectKit.Leg, _ all: [InsectKit.Leg]) -> Int {
        let same = all.filter { $0.side == l.side }.sorted { $0.attach.z > $1.attach.z }
        return same.firstIndex { $0.attach == l.attach } ?? 0
    }
}
