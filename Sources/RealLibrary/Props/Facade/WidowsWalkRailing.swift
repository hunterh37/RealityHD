import simd
import Foundation

/// Federal / Coastal Colonial widow's walk railing, 3.0 m: square newel posts with raised panel faces,
/// plinth blocks, moulded caps and urn-and-ball finials; a bottom rail with sloped top and drip edge; a top
/// rail with a bullnose-and-cove cap; vase-turned balusters in the end bays and an X lattice in the centre bay.
/// White lead paint worn through to grey wood at the bottom rail where salt spray and standing water sit.
public struct WidowsWalkRailing: RealAsset {
    public static let id = "widows-walk-railing"
    public static let summary = "Federal widow's walk railing, 3.0 m: top and bottom rails, turned balusters, newel posts with caps and ball finials, cross-braces."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 2.4)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(3.0, 0.9, 0.1)
    /// Fresh white paint.
    public var paint: MaterialKey = "wood.barn-white"
    /// Salt-weathered paint on the lower members.
    public var worn: MaterialKey = "wood.painted-shaker-worn"
    /// Bare weathered wood showing through at chips.
    public var bare: MaterialKey = "wood.cedar-weathered"
    /// Galvanized through-bolts and nail heads.
    public var iron: MaterialKey = "metal.galvanized-aged"
    /// Rust running from fasteners.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    /// Vase baluster profile (radius, y) from the bottom tenon up to the top tenon, y 0...len.
    private static func vase(len: Float) -> [(Float, Float)] {
        let s = len / 0.54
        let p: [(Float, Float)] = [(0, 0), (0.012, 0), (0.012, 0.012), (0.017, 0.022), (0.0125, 0.046), (0.011, 0.07),
                                   (0.018, 0.11), (0.0255, 0.17), (0.021, 0.24), (0.0125, 0.31), (0.0105, 0.36),
                                   (0.0135, 0.4), (0.0115, 0.425), (0.018, 0.47), (0.012, 0.52), (0.012, 0.54), (0, 0.54)]
        return p.map { ($0.0, $0.1 * s) }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = size.x, D = size.z
        let postW: Float = 0.1, postH: Float = 0.72
        let railD: Float = 0.07
        let yB0: Float = 0.06, yB1: Float = 0.125          // bottom rail
        let yT0: Float = 0.665, yT1: Float = 0.72          // top rail body (cap rides above)
        let xs: [Float] = [-L / 2 + postW / 2, -0.5, 0.5, L / 2 - postW / 2]

        // Newel posts: plinth block, shaft with raised panel faces, neck, moulded cap, then finial.
        for (i, x) in xs.enumerated() {
            let end = i == 0 || i == xs.count - 1
            let mat = paint
            FA.box(&m, V3(postW + 0.008, 0.06, D - 0.004), V3(x, 0.03, 0), worn, r: 0.003)
            FA.box(&m, V3(postW - 0.012, postH - 0.06 - 0.03, D - 0.016), V3(x, 0.06 + (postH - 0.09) / 2, 0), mat, r: 0.003)
            // Raised panel on the four faces: frame stile pair and an inner field.
            for f in 0..<4 {
                let ang = Float(f) * .pi / 2
                let d = V3(cos(ang), 0, sin(ang))
                let faceHalf = (f % 2 == 0 ? (postW - 0.012) : (D - 0.016)) / 2
                let w: Float = 0.062
                let pc = V3(x, 0.06 + (postH - 0.09) / 2 + 0.01, 0) + d * (faceHalf + 0.002)
                let rot = FA.q(90 - ang * 180 / .pi, FA.Y)
                FA.box(&m, V3(w, 0.4, 0.005), pc, mat, r: 0.0015, rot: rot)
                if f % 2 == 1 { FA.box(&m, V3(w - 0.022, 0.38 - 0.02, 0.004), pc + d * 0.003, mat, r: 0.001, rot: rot) }
            }
            // Neck fillet and cap: cove, abacus, bullnose.
            FA.box(&m, V3(postW - 0.002, 0.014, D - 0.012), V3(x, postH - 0.005, 0), mat, r: 0.003)
            FA.box(&m, V3(postW + 0.012, 0.014, D), V3(x, postH + 0.009, 0), mat, r: 0.004)
            FA.box(&m, V3(postW + 0.002, 0.012, D - 0.01), V3(x, postH + 0.022, 0), mat, r: 0.003)
            // Finial: urn on the end posts, ball only on the intermediate newels.
            let fy = postH + 0.028
            if end {
                let u: Float = 1.3
                let urn: [(Float, Float)] = [(0, 0), (0.03, 0), (0.03, 0.004), (0.022, 0.008), (0.014, 0.016), (0.019, 0.028), (0.026, 0.04),
                                             (0.028, 0.05), (0.022, 0.058), (0.012, 0.064), (0.017, 0.07), (0.015, 0.074), (0, 0.074)]
                m.add(turned(urn.map { ($0.0 * u, fy + $0.1 * u) }, segments: 16, material: mat), Xform(translation: V3(x, 0, 0)))
                FC.bead(&m, r: 0.03, at: V3(x, fy + 0.074 * u + 0.026, 0), mat, sub: 4)
            } else {
                m.add(turned([(0, fy), (0.026, fy), (0.026, fy + 0.006), (0.016, fy + 0.012), (0.014, fy + 0.016), (0, fy + 0.016)], segments: 16, material: mat),
                      Xform(translation: V3(x, 0, 0)))
                FC.bead(&m, r: 0.032, at: V3(x, fy + 0.04, 0), mat, sub: 4)
            }
        }

        // Bays: centre bay balusters are replaced by lattice, side bays are turned balusters.
        let bays: [(Float, Float, Bool)] = [(xs[0], xs[1], false), (xs[1], xs[2], true), (xs[2], xs[3], false)]
        for (a, b, lattice) in bays {
            let x0 = a + postW / 2 - 0.004, x1 = b - postW / 2 + 0.004, cx = (x0 + x1) / 2, len = x1 - x0
            m.add(Prim.extrude(Shape2D.rect(len, yB1 - yB0), depth: railD, bevel: 0.002, bevelSegments: 1, material: worn),
                  Xform(translation: V3(cx, (yB0 + yB1) / 2, 0)))
            // Sloped weather cap with drip groove on the bottom rail.
            m.add(Prim.extrude([V2(-railD / 2, 0), V2(railD / 2 + 0.006, 0), V2(railD / 2 + 0.006, 0.008), V2(railD / 2 - 0.004, 0.011),
                                V2(-railD / 2 + 0.006, 0.02), V2(-railD / 2, 0.02)],
                               depth: len + 0.004, bevel: 0.0015, bevelSegments: 1, material: worn),
                  Xform(translation: V3(cx, yB1 - 0.003, 0), rotation: FA.q(-90, FA.Y)))
            // Top rail: body, moulded cap (bullnose over a cove) and an under-bead.
            FA.box(&m, V3(len, yT1 - yT0, railD - 0.01), V3(cx, (yT0 + yT1) / 2, 0), paint, r: 0.002)
            m.add(Prim.extrude([V2(-0.047, 0), V2(0.047, 0), V2(0.047, 0.006), V2(0.043, 0.012), V2(0.032, 0.0155), V2(0.02, 0.0175), V2(-0.02, 0.0175),
                                V2(-0.032, 0.0155), V2(-0.043, 0.012), V2(-0.047, 0.006)],
                               depth: len + 0.006, bevel: 0.001, bevelSegments: 1, material: paint),
                  Xform(translation: V3(cx, yT1, 0), rotation: FA.q(-90, FA.Y)))
            FA.box(&m, V3(len, 0.008, railD - 0.004), V3(cx, yT0 - 0.004, 0), paint, r: 0.002)
            let yb = yB1 + 0.017, yt = yT0 - 0.008
            if lattice {
                // Diamond X lattice: two crossings per bay, slats 22 x 11 mm, halved at the crossings.
                let cells = 2
                let cw = len / Float(cells)
                for c in 0..<cells {
                    let xa = x0 + Float(c) * cw, xb = xa + cw
                    for (k, flip) in [false, true].enumerated() {
                        let p0 = V3(flip ? xb : xa, yb, 0), p1 = V3(flip ? xa : xb, yt, 0)
                        let dv = p1 - p0, ln = simd_length(dv) + 0.01
                        let ang = atan2(dv.y, dv.x) * 180 / .pi
                        FA.box(&m, V3(ln, 0.022, 0.011), (p0 + p1) / 2 + V3(0, 0, k == 0 ? 0.006 : -0.006), paint, r: 0.0015, rot: FA.q(ang, FA.Z))
                    }
                }
                // Centre stile where the X's meet.
                for c in 1..<cells { FA.box(&m, V3(0.024, yt - yb, 0.016), V3(x0 + Float(c) * cw, (yb + yt) / 2, 0), paint, r: 0.002) }
            } else {
                // Turned balusters on a regular pitch, tenons hidden in the rails.
                let n = 7
                let pitch = len / Float(n)
                for k in 0..<n {
                    let x = x0 + pitch * (Float(k) + 0.5)
                    m.add(turned(Self.vase(len: yt - yb + 0.002), segments: 9, material: paint, grainVertical: true),
                          Xform(translation: V3(x + rng.float(-0.0008...0.0008), yb - 0.001, 0)))
                }
            }
        }

        // Through-bolts holding the rails to the newels, each with a rust tear and a bright washer face.
        for (i, x) in xs.enumerated() {
            for y in [0.093 as Float, 0.69] {
                for sgn: Float in [-1, 1] where i < 3 || sgn < 0 {
                    let px = x + sgn * (postW / 2 + 0.0015)
                    guard (i == 0 && sgn > 0) || (i == 3 && sgn < 0) || (i > 0 && i < 3) else { continue }
                    m.add(Prim.cylinder(radius: 0.0075, height: 0.005, bevel: 0.0008, segments: 6, bevelSegments: 1, material: iron),
                          Xform(translation: V3(px - sgn * 0.0005, y, D / 2 - 0.02), rotation: FA.q(-90 * sgn, FA.Z)))
                    m.add(Prim.superellipsoid(V3(0.0014, rng.float(0.03...0.06), 0.005), exponent: 2.4, subdivisions: 2, material: rust),
                          Xform(translation: V3(px + sgn * 0.0004, y - 0.03, D / 2 - 0.02)))
                }
            }
        }
        // Salt weathering: grey wood patches where the bottom rail's paint has gone, and lichen-dark foot grime.
        for _ in 0..<18 {
            let x = rng.float(-L / 2 + 0.2...L / 2 - 0.2)
            m.add(Prim.superellipsoid(V3(rng.float(0.06...0.2), rng.float(0.012...0.026), 0.002), exponent: 2.4, subdivisions: 2, material: bare),
                  Xform(translation: V3(x, rng.float(yB0 + 0.012...yB1 - 0.006), railD / 2 + 0.0008)))
        }
        for _ in 0..<3 {
            let x = rng.float(-L / 2 + 0.2...L / 2 - 0.2)
            m.add(Prim.superellipsoid(V3(rng.float(0.04...0.1), rng.float(0.006...0.014), 0.002), exponent: 2.4, subdivisions: 2, material: bare),
                  Xform(translation: V3(x, rng.float(yB0 + 0.01...yB1 - 0.005), -railD / 2 - 0.0008)))
        }
        // Chipped paint on every plinth block and the top-rail cap where hands and rain reach.
        for x in xs {
            m.add(Prim.superellipsoid(V3(0.05, 0.026, 0.003), exponent: 2.4, subdivisions: 2, material: bare),
                  Xform(translation: V3(x + rng.float(-0.01...0.01), 0.032, D / 2 - 0.0035)))
            m.add(Prim.superellipsoid(V3(0.034, 0.02, 0.003), exponent: 2.4, subdivisions: 2, material: bare),
                  Xform(translation: V3(x + rng.float(-0.01...0.01), 0.028, -D / 2 + 0.0035)))
        }
        groundAO(&m, height: 0.18, floor: 0.6)
        return LODModel(FC.place(m))
    }
}
