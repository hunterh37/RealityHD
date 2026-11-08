import simd
import Foundation

/// 355 ml aluminum soda can, 66 x 122 mm: domed base inside a stand ring, straight printed wall, stepped
/// necked shoulder, double-seamed lid with countersink, score line, stay-on tab with finger hole and rivet,
/// a printed coating with rubbed rims and a small wall dent. Invented brand FIZZO.
public struct SodaCan: RealAsset {
    public static let id = "soda-can"
    public static let summary = "355 ml aluminum soda can, 12 cm: necked shoulder, seamed lid with stay-on tab, printed coated wall, rubbed rims."
    public static let tags = ["prop", "grocery", "food", "metal", "aluminium", "container", "handheld"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 18, distance: 1.3, studio: true)

    /// Brand field color of the printed wall.
    public var color: UInt32 = 0xB01E23
    public var brand = "FIZZO"
    /// Wordmark key.
    public var ink: MaterialKey = "plastic.gloss:F6F4EE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true, seed: seed), level(hi: false, seed: seed)], switchDistances: [2])
    }

    func level(hi: Bool, seed: UInt64) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.033, seg = hi ? 64 : 20
        // Can body: stand ring, inner dome, wall, necked shoulder (three steps), up to the seam.
        let body: [V2] = [V2(0.0001, 0.0105), V2(0.012, 0.0098), V2(0.02, 0.0072), V2(0.0236, 0.0035), V2(0.0248, 0.0004),
                          V2(0.0258, 0.0), V2(0.0272, 0.0004), V2(0.0296, 0.0026), V2(0.0318, 0.0064), V2(0.0329, 0.0098), V2(r, 0.0125)]
        m.add(Prim.lathe(body, segments: seg, seamTile: 0.05, material: "metal.aluminum"))
        let wall: [V2] = [V2(r, 0.0125), V2(r, 0.104), V2(0.0326, 0.1072), V2(0.0314, 0.1098), V2(0.0298, 0.1122),
                          V2(0.0288, 0.1146), V2(0.0284, 0.1162)]
        let coat = GroceryKit.tint("pkg.can-print", color)
        var w = GroceryKit.printLathe(wall, seg: seg, coat, y0: 0.0125, y1: 0.1162)
        if hi {
            // Small dent low on the back wall.
            var rng = SeededRNG(seed: seed &+ 77)
            let a = rng.float(2.4...3.6), dy = rng.float(0.03...0.05)
            let c = V3(r * sin(a), dy, r * cos(a))
            for i in w.positions.indices {
                let p = w.positions[i], d = simd_distance(p, c)
                if d < 0.009 { let k = 1 - d / 0.009; w.positions[i] -= simd_normalize(V3(p.x, 0, p.z)) * 0.0011 * k * k }
            }
            w.recomputeNormals(); w.computeTangents()
        }
        m.add(w)
        // Lid: double seam rim, countersink, recessed panel with score ring.
        let lid: [V2] = [V2(0.0284, 0.1162), V2(0.0287, 0.1178), V2(0.0285, 0.1203), V2(0.0277, 0.1213), V2(0.0266, 0.1208),
                         V2(0.0262, 0.1185), V2(0.0255, 0.1162), V2(0.0248, 0.1158), V2(0.0242, 0.1166), V2(0.0236, 0.1170), V2(0.0001, 0.1172)]
        m.add(Prim.lathe(lid, segments: seg, seamTile: 0.05, material: "metal.aluminum"))
        if hi {
            // Score line: a teardrop groove in front of the rivet.
            var score: [V3] = []
            for i in 0...28 {
                let t = Float(i) / 28 * 2 * .pi
                score.append(V3(0.0085 * sin(t), 0.11715, 0.0115 + 0.0075 * cos(t) * (1 + 0.25 * cos(t))))
            }
            m.add(Prim.tube(score, radii: score.map { _ in 0.00025 }, sides: 4, seamTile: 0.05, material: "metal.aluminum"))
            // Debossed lid ring and drink-hole panel edge.
            m.add(Prim.torus(major: 0.0218, minor: 0.0003, segments: 48, sides: 4, material: "metal.aluminum"), Xform(translation: V3(0, 0.1170, 0)))
        }
        // Rivet.
        m.add(Prim.lathe([V2(0.0001, 0.1181), V2(0.0018, 0.1180), V2(0.0026, 0.1174), V2(0.0028, 0.1170)], segments: hi ? 16 : 8,
                         seamTile: 0.05, material: "metal.aluminum"))
        // Stay-on tab: rounded plate with a finger hole, slight bend, nose over the score.
        let outline = Shape2D.rounded([V2(-0.0095, -0.0175), V2(0.0095, -0.0175), V2(0.0085, 0.0085), V2(0.0045, 0.0125),
                                       V2(-0.0045, 0.0125), V2(-0.0085, 0.0085)], radius: 0.0035, segments: hi ? 4 : 2)
        var tab = Prim.extrude(outline, depth: 0.0007, bevel: 0.00025, bevelSegments: 1, material: "metal.aluminum-brushed")
        let holeC = V2(0, -0.0095)
        tab.deform { p in
            var q = p
            let d = simd_length((V2(p.x, p.y) - holeC) / V2(0.0072, 0.0052))
            if d < 1 { q.z -= 0.0004 * (1 - d) }
            return q
        }
        m.add(tab, Xform(translation: V3(0, 0.1186, 0), rotation: simd_quatf(angle: .pi / 2 + 0.04, axis: V3(1, 0, 0))))
        // Finger hole: dark recess under the tab ring.
        m.add(Prim.extrude(Shape2D.circle(0.0062, ry: 0.0042, segments: hi ? 16 : 8), depth: 0.0002, bevel: 0, bevelSegments: 1,
                           material: "plastic.matte:6E7176"), Xform(translation: V3(0, 0.1176, -0.0095),
                                                                    rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
        // Wordmark on the logo pill, wrapped on the wall.
        GroceryKit.wrapPrintSmooth(&m, brand, height: 0.0095, radius: r + 0.0001, y: 0.0125 + 0.85 * 0.1037 - 0.0047, ink,
                                   maxWidth: 0.05, weight: 1.25)
        return m
    }
}
