import simd
import Foundation

/// French Baroque oeil-de-boeuf, 0.8 m across and 0.2 m proud of the wall: a limestone surround revolved from
/// a moulded section (fascia, step, cyma, bead and reveal), four tapered keystones at the cardinal points with
/// carved cabochon bosses and acanthus tufts, a laurel bead of 24 small berries inside the moulding, and a
/// painted round sash with a glazing cross, a centre ring, glass, two iron pivot pins and a latch. Soot gathers
/// on the upper moulding, rain streaks fall from the keystones, the sash paint is flaked at its foot and moss
/// sits in the lower reveal.
public struct OeilDeBoeufWindow: RealAsset {
    public static let id = "oeil-de-boeuf-window"
    public static let summary = "French Baroque oeil-de-boeuf, 0.8 m diameter: moulded limestone ring with four scrolled keystones, a painted round sash with glazing bars and glass."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.1)

    /// Limestone surround.
    public var stone: MaterialKey = "stone.limestone"
    /// Soot and stains.
    public var soot: MaterialKey = "stone.limestone-sooted"
    /// Painted sash.
    public var sash: MaterialKey = "wood.painted-exterior:5B6E5E"
    /// Bare wood under flaked paint.
    public var bare: MaterialKey = "wood.painted-exterior:8A7A62"
    /// Glass.
    public var glass: MaterialKey = "glass.pane"
    /// Iron fittings.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Moss in the reveal.
    public var moss: MaterialKey = "stone.granite-moss:4F6B2E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let seg = lite ? 28 : 64
        let toZ = FA.q(90, FA.X)
        /// Transform of a local keystone-space point and orientation by the keystone rotation `rot` about the window axis.
        func at(_ rot: simd_quatf, _ p: V3, _ r: simd_quatf = simd_quatf(angle: 0, axis: FA.Z), scale: V3 = V3(1, 1, 1)) -> Xform {
            Xform(translation: rot.act(p), rotation: rot * r, scale: scale)
        }
        // Surround: closed moulded section (radius, depth) revolved about the window axis.
        let section: [(Float, Float)] = [(0.2, 0.0), (0.4, 0.0), (0.4, 0.04), (0.39, 0.05), (0.385, 0.07), (0.355, 0.075), (0.345, 0.09), (0.335, 0.1), (0.3, 0.105),
                                         (0.29, 0.115), (0.275, 0.12), (0.258, 0.115), (0.25, 0.105), (0.245, 0.09), (0.22, 0.085), (0.2, 0.08), (0.2, 0.0)]
        m.add(turned(section, segments: seg, material: stone, seamTile: 0.5), Xform(rotation: toZ))
        // Keystones: tapered blocks at 12, 3, 6 and 9 o'clock, proud of the ring, with boss and tuft.
        for k in 0..<4 {
            let rot = FA.q(Float(k) * 90, FA.Z)
            let key: [V2] = [V2(-0.034, 0.215), V2(0.034, 0.215), V2(0.052, 0.4), V2(-0.052, 0.4)]
            m.add(Prim.extrude(key, depth: 0.195, bevel: 0.004, bevelSegments: 1, material: stone), at(rot, V3(0, 0, 0.0975)))
            // Capping fillet band across the keystone head, and a recessed-look panel.
            m.add(Prim.extrude([V2(-0.058, 0.388), V2(0.058, 0.388), V2(0.058, 0.4), V2(-0.058, 0.4)], depth: 0.17, bevel: 0.003, bevelSegments: 1, material: stone), at(rot, V3(0, 0, 0.085)))
            // Cabochon boss and acanthus tuft on the face (local +Y is radial outward).
            let boss = V3(0, 0.3, 0.188)
            m.add(Prim.superellipsoid(V3(0.05, 0.08, 0.026), exponent: 2, subdivisions: lite ? 2 : 4, material: stone), at(rot, boss))
            for j in 0..<(lite ? 3 : 5) {
                let a = (Float(j) - Float(lite ? 1 : 2)) * 0.5
                m.add(turned([(0, 0), (0.005, 0.005), (0.009, 0.026), (0.005, 0.044), (0, 0.05)], segments: 5, material: stone, seamTile: 0.1),
                      at(rot, V3(sin(a) * 0.012, 0.345, 0.172), FA.q(-a * 57.3, FA.Z) * FA.q(25, FA.X), scale: V3(1, 1, 0.5)))
            }
            // Facing volute scrolls at the head of the keystone and a small tuft pair at the foot.
            for s: Float in [-1, 1] {
                var pts: [V3] = [], rad: [Float] = []
                let n = lite ? 8 : 14
                for q in 0...n {
                    let t = Float(q) / Float(n), a = s > 0 ? (.pi + t * 2.1 * .pi) : (-t * 2.1 * .pi), r = 0.024 * (1 - 0.72 * t)
                    pts.append(V3(s * 0.026 + cos(a) * r, 0.366 + sin(a) * r, 0.1925)); rad.append(0.0046 * (1 - 0.35 * t))
                }
                m.add(Prim.tube(pts, radii: rad, sides: lite ? 4 : 6, seamTile: 0.1, material: stone, capEnd: true), at(rot, .zero))
                m.add(turned([(0, 0), (0.005, 0.004), (0.01, 0.022), (0.006, 0.04), (0, 0.046)], segments: 5, material: stone, seamTile: 0.1),
                      at(rot, V3(s * 0.016, 0.232, 0.185), FA.q(s * -25, FA.Z) * FA.q(20, FA.X), scale: V3(1, 1, 0.5)))
            }
        }
        // Laurel bead: a ring of berries on the cyma.
        let nb = lite ? 12 : 24
        for j in 0..<nb {
            let a = Float(j) / Float(nb) * 2 * .pi
            if abs(cos(a)) < 0.12 || abs(sin(a)) < 0.12 { continue }
            FC.bead(&m, r: 0.0075, at: V3(cos(a) * 0.318, sin(a) * 0.318, 0.108), stone, sub: lite ? 1 : 2)
        }
        // Painted round sash: closed frame section revolved at the back of the reveal.
        let frame: [(Float, Float)] = [(0.168, 0.035), (0.2, 0.035), (0.2, 0.068), (0.19, 0.074), (0.172, 0.074), (0.165, 0.066), (0.165, 0.045), (0.168, 0.035)]
        m.add(turned(frame, segments: seg, material: sash, seamTile: 0.3), Xform(rotation: toZ))
        // Glass disc in the rebate.
        m.add(Prim.cylinder(radius: 0.168, height: 0.003, bevel: 0.0005, segments: seg, bevelSegments: 1, material: glass), Xform(translation: V3(0, 0, 0.054), rotation: toZ))
        // Glazing bars: cross and a centre ring with boss.
        FA.box(&m, V3(0.34, 0.016, 0.024), V3(0, 0, 0.056), sash, r: 0.002)
        FA.box(&m, V3(0.016, 0.34, 0.024), V3(0, 0, 0.056), sash, r: 0.002)
        m.add(Prim.torus(major: 0.06, minor: 0.0085, segments: lite ? 16 : 32, sides: 6, material: sash), Xform(translation: V3(0, 0, 0.057), rotation: toZ))
        FC.bead(&m, r: 0.017, at: V3(0, 0, 0.066), sash, sub: lite ? 1 : 3)
        // Iron pivot pins at 3 and 9 o'clock and a latch plate with hook on the lower right.
        for s: Float in [-1, 1] {
            FA.cylX(&m, r: 0.0065, h: 0.04, at: V3(s * 0.192 - (s > 0 ? 0 : 0.0) + (s > 0 ? -0.02 : -0.02), 0, 0.055), iron, bevel: 0.001, segments: lite ? 6 : 8)
        }
        FA.box(&m, V3(0.036, 0.016, 0.004), V3(0.178, -0.07, 0.076), iron, r: 0.001)
        FA.rod(&m, V3(0.178, -0.07, 0.078), V3(0.178, -0.07, 0.092), r: 0.004, iron, sides: 6)
        FA.rod(&m, V3(0.178, -0.07, 0.092), V3(0.17, -0.07, 0.092), r: 0.004, iron, sides: 6)
        // Weathering.
        if !lite {
            // Soot on the upper moulding and in the crevice behind the berries, plus rain streaks under each keystone.
            for _ in 0..<10 {
                let a = rng.float(0.5...2.6)
                FO9.patch(&m, cx: cos(a) * 0.37, cy: sin(a) * 0.37, rx: rng.float(0.012...0.025), ry: rng.float(0.01...0.02), z: 0.0762, soot, rng: &rng, depth: 0.0006)
            }
            for dx: Float in [-0.012, 0.012] { FO9.patch(&m, cx: dx, cy: -0.31, rx: 0.004, ry: rng.float(0.04...0.07), z: 0.0003, soot, rng: &rng, depth: 0.0006, n: 6) }
            // Keystone faces: soot in the carving, rain streaks, chipped corners; moss on the bottom stone.
            for k in 0..<4 {
                let ang = Float(k) * .pi / 2
                func rp(_ u: Float, _ v: Float) -> (Float, Float) { (u * cos(ang) - v * sin(ang), u * sin(ang) + v * cos(ang)) }
                for _ in 0..<3 {
                    let (cx, cy) = rp(rng.float(-0.03...0.03), rng.float(0.24...0.38))
                    FO9.patch(&m, cx: cx, cy: cy, rx: rng.float(0.008...0.02), ry: rng.float(0.01...0.03), z: 0.1956, soot, rng: &rng, depth: 0.0006, n: 8)
                }
                let (sx, sy) = rp(rng.float(-0.04...0.04), 0.383)
                FO9.patch(&m, cx: sx, cy: sy, rx: 0.012, ry: 0.012, z: 0.1957, "stone.sandstone", rng: &rng, depth: 0.0006, n: 6)
                if k == 2 { for _ in 0..<4 { let (mx, my) = rp(rng.float(-0.035...0.035), rng.float(0.25...0.38)); FO9.patch(&m, cx: mx, cy: my, rx: rng.float(0.01...0.02), ry: rng.float(0.01...0.02), z: 0.1958, moss, rng: &rng, depth: 0.0007, n: 8) } }
            }
            // Sash paint flaked at the foot and along the bars.
            for _ in 0..<7 {
                let a = rng.float(3.6...5.8)
                FO9.patch(&m, cx: cos(a) * 0.175, cy: sin(a) * 0.175, rx: rng.float(0.008...0.02), ry: rng.float(0.006...0.014), z: 0.0745, bare, rng: &rng, depth: 0.0005, n: 7)
            }
            for _ in 0..<4 { FO9.patch(&m, cx: rng.float(-0.15...0.15), cy: 0.0, rx: rng.float(0.01...0.025), ry: 0.0045, z: 0.0683, bare, rng: &rng, depth: 0.0005, n: 6) }
            // Moss in the lower reveal.
            for _ in 0..<5 { FO9.patch(&m, cx: rng.float(-0.12...0.12), cy: -0.2 + 0.0, rx: rng.float(0.02...0.05), ry: rng.float(0.01...0.02), z: 0.0004, moss, rng: &rng, depth: 0.0007) }
        }
        groundAO(&m, height: 0.05, floor: 0.9)
        return FC.place(m)
    }
}
