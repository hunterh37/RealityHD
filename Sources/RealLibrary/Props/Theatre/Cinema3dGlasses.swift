import simd
import Foundation

/// Cinema 3D glasses: retro 1950s-style cardboard anaglyph glasses, 15 cm wide.
/// Two layers of white folded card (0.7 mm each) sandwich red and cyan film lenses; rounded outer corners, nose notch,
/// a navy printed stripe along the top edge and two card temple arms folded out behind the frame with tip tabs.
/// Seeds vary the lean of the arms and small card wear.
public struct Cinema3dGlasses: RealAsset {
    public static let id = "cinema-3d-glasses"
    public static let summary = "Cardboard anaglyph 3D glasses, 15 cm wide: white folded card frame with printed edge stripe, red and cyan film lenses, fold-out card temple arms."
    public static let tags = ["prop", "paper", "cardboard", "antique", "handheld"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, studio: true)

    /// Frame width (m).
    public var width: Float = 0.15
    /// Frame height (m).
    public var frameHeight: Float = 0.05
    /// Temple arm length behind the frame (m).
    public var armLength: Float = 0.155
    /// White card.
    public var card: MaterialKey = "paper.sheet:F0ECE0"
    /// Film over the wearer's left eye (viewer's right).
    public var redFilm: MaterialKey = "glass.tinted:E0201C"
    /// Film over the wearer's right eye (viewer's left).
    public var cyanFilm: MaterialKey = "glass.tinted:10C8E0"
    /// Printed stripe ink.
    public var ink: MaterialKey = "plastic.matte:1E3A8A"
    public init() {}

    static func arc(_ c: V2, _ r: Float, _ a0: Float, _ a1: Float, _ n: Int = 8) -> [V2] {
        (0...n).map { let a = a0 + (a1 - a0) * Float($0) / Float(n); return V2(c.x + r * cos(a), c.y + r * sin(a)) }
    }

    /// Card pieces in the XY plane: top band, left-lower piece, centre bridge, right-lower piece (mirror).
    func pieces() -> [[V2]] {
        let hw = width / 2, H = frameHeight
        let yb: Float = 0.010, yt: Float = H - 0.010          // opening bottom and top
        let xo: Float = 0.0505, xi: Float = 0.0065            // opening outer and inner x (left opening spans -xo ... -xi)
        let rr: Float = 0.004, R: Float = 0.007, nd: Float = 0.0075
        let pi = Float.pi
        var top: [V2] = [V2(-hw, yt), V2(-xo, yt), V2(-xo, yt - rr)]
        top += Self.arc(V2(-xo + rr, yt - rr), rr, pi, pi / 2)
        top += [V2(-xi - rr, yt)] + Self.arc(V2(-xi - rr, yt - rr), rr, pi / 2, 0) + [V2(-xi, yt), V2(xi, yt), V2(xi, yt - rr)]
        top += Self.arc(V2(xi + rr, yt - rr), rr, pi, pi / 2) + [V2(xo - rr, yt)]
        top += Self.arc(V2(xo - rr, yt - rr), rr, pi / 2, 0) + [V2(xo, yt)]
        top += [V2(hw, yt)] + Self.arc(V2(hw - R, H - R), R, 0, pi / 2, 10) + Self.arc(V2(-hw + R, H - R), R, pi / 2, pi, 10)
        var left: [V2] = [V2(-hw, yt)]
        left += Self.arc(V2(-hw + R, R), R, pi, 3 * pi / 2, 10)
        left += (0...8).map { let t = Float($0) / 8 * pi / 2; return V2(-0.0135 + 0.007 * sin(t), nd * (1 - cos(t))) }
        left += [V2(-xi, 0.014)] + Self.arc(V2(-xi - rr, yb + rr), rr, 0, -pi / 2)
        left += Self.arc(V2(-xo + rr, yb + rr), rr, -pi / 2, -pi) + [V2(-xo, yt)]
        let bridge: [V2] = [V2(-xi, nd), V2(xi, nd), V2(xi, yt), V2(-xi, yt)]
        let right = left.map { V2(-$0.x, $0.y) }.reversed() as [V2]
        return [top, left, bridge, right]
    }

    func make(_ detail: Bool, _ rng: inout SeededRNG) -> Model {
        var m = Model(name: Self.id)
        let t: Float = 0.0007, zf: Float = 0.0002 + t / 2
        let hw = width / 2, H = frameHeight
        // Two card layers around the film plane.
        for p in pieces() {
            let s = Prim.extrude(p, depth: t, bevel: 0, material: card)
            m.add(s, Xform(translation: V3(0, 0, zf)))
            m.add(s, Xform(translation: V3(0, 0, -zf)))
        }
        // Film lenses sandwiched, a few mm larger than the openings. Red on the wearer's left (viewer's right).
        let film = Shape2D.roundedRect(0.0505 - 0.0065 + 0.006, 0.030 + 0.006, radius: 0.006)
        m.add(Prim.extrude(film, depth: 0.00016, bevel: 0, material: redFilm), Xform(translation: V3(0.0285, H / 2, 0)))
        m.add(Prim.extrude(film, depth: 0.00016, bevel: 0, material: cyanFilm), Xform(translation: V3(-0.0285, H / 2, 0.00002)))
        // Printed stripe along the top band, on the front card.
        let stripe = Shape2D.roundedRect(0.136, 0.0022, radius: 0.0008)
        m.add(Prim.extrude(stripe, depth: 0.00008, bevel: 0, material: ink), Xform(translation: V3(0, H - 0.0050, zf + t / 2 + 0.00004)))
        let lowStripe = Shape2D.roundedRect(0.060, 0.0014, radius: 0.0006)
        for sx in [Float(-1), 1] {
            m.add(Prim.extrude(lowStripe, depth: 0.00008, bevel: 0, material: ink), Xform(translation: V3(sx * 0.0425, 0.0040, zf + t / 2 + 0.00004)))
        }
        // Temple arms: card strips folded out behind the frame at a crease, tapering to a tip tab.
        let L = armLength
        let outline = Shape2D.rounded([V2(0, 0), V2(L, 0), V2(L, 0.013), V2(L * 0.78, 0.016), V2(L * 0.45, 0.024), V2(0.012, 0.034), V2(0, 0.036)], radius: 0.003)
        let armT: Float = 0.0009
        for sx in [Float(-1), 1] {
            let lean = (detail ? rng.float(-1.5...1.5) : 0)
            let rot = simd_quatf(degrees: 90 + lean, axis: V3(0, 1, 0))
            m.add(Prim.extrude(outline, depth: armT, bevel: 0.0001, bevelSegments: 1, material: card),
                  Xform(translation: V3(sx * (hw + armT / 2 + 0.0002), 0, -2 * zf - t - 0.0004), rotation: rot))
            // Second fold line across the arm, a faint pale crease with a printed stripe along the arm top edge.
            m.add(Prim.extrude(Shape2D.roundedRect(0.0002, 0.030, radius: 0.0001), depth: 0.00004, bevel: 0, material: "paper.sheet:CFC8B8"),
                  Xform(translation: V3(sx * (hw + armT + 0.00028), 0.016, -0.045), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            // Printed stripe along the arm's outer face and a thumb smudge near the hinge.
            let armStripe = Shape2D.roundedRect(0.10, 0.0016, radius: 0.0006)
            m.add(Prim.extrude(armStripe, depth: 0.00008, bevel: 0, material: ink),
                  Xform(translation: V3(sx * (hw + armT + 0.00032), 0.0062, -0.0185 - 0.05), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            m.add(Prim.extrude(Shape2D.superellipse(0.016, 0.011, exponent: 2), depth: 0.00006, bevel: 0, material: "paper.sheet:D9CFBA"),
                  Xform(translation: V3(sx * (hw + armT + 0.00026), 0.022, -0.016), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            // Fold crease: rounded card edge at the hinge, and a glue flap on the back of the frame.
            m.add(Prim.cylinder(radius: 0.0008, height: 0.036, bevel: 0, segments: 12, material: card),
                  Xform(translation: V3(sx * (hw + 0.0002), 0, -2 * zf - t - 0.0003)))
            m.add(Prim.extrude(Shape2D.roundedRect(0.012, 0.030, radius: 0.0015), depth: 0.0004, bevel: 0, material: card),
                  Xform(translation: V3(sx * (hw - 0.006), 0.019, -2 * zf - t - 0.0002)))
        }
        m.add(Prim.extrude(Shape2D.superellipse(0.012, 0.007, exponent: 2), depth: 0.00006, bevel: 0, material: "paper.sheet:D9CFBA"),
              Xform(translation: V3(0.010, 0.0455, zf + t / 2 + 0.00003)))
        // Card wear: tiny crease marks across the lower band (hairline folds).
        if detail {
            for i in 0..<3 {
                let x = rng.float(-0.06...0.06)
                m.add(Prim.extrude(Shape2D.roundedRect(0.0001, 0.006, radius: 0.00004), depth: 0.00004, bevel: 0, material: "paper.sheet:CFC8B8"),
                      Xform(translation: V3(x, 0.0035 + 0.001 * Float(i), zf + t / 2 + 0.00003)))
            }
        }
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, 0, -(bb.min.z + bb.max.z) / 2)))
        // Thin card: contact AO only, no cavity AO (it would grey the paper between the layers).
        for i in m.surfaces.indices { m.surfaces[i].occlusion = m.surfaces[i].positions.map { 0.8 + 0.2 * smoothstep(0, 0.012, $0.y) } }
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        var r1 = SeededRNG(seed: seed), r2 = SeededRNG(seed: seed)
        return LODModel(levels: [make(true, &r1), make(false, &r2)], switchDistances: [3])
    }
}
