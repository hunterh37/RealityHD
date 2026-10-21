import simd
import Foundation

/// Boston Common perimeter fence, one tileable 2.4 m bay: black wrought iron spear-top pickets
/// between two flat rails, a square post with ball finial at the bay start, all leaded into a
/// dressed granite curb. Tile along +X every `bay` meters (the next bay supplies the far post).
public struct BostonIronFence: RealAsset {
    public static let id = "boston-iron-fence"
    public static let summary = "Tileable 2.4 m bay of Boston Common wrought iron fence: spear-top pickets, two rails and a ball-finial post on a granite curb."
    public static let tags = ["prop", "fence", "metal", "park", "street", "stone"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 1.1)

    /// Bay length along X in meters (post spacing).
    public var bay: Float = 2.4
    /// Granite curb height above grade in meters.
    public var curbHeight: Float = 0.3
    /// Granite curb depth (Z) in meters.
    public var curbDepth: Float = 0.36
    /// Picket height above the curb top, including the spear, in meters.
    public var picketHeight: Float = 1.02
    /// Picket centre spacing in meters.
    public var picketSpacing: Float = 0.125
    /// Iron material key.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Rusted iron at the leaded feet.
    public var rust: MaterialKey = "metal.rust"
    /// Curb stone material key.
    public var stone: MaterialKey = "stone.granite-curb:9E8C86"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let half = bay / 2
        // Curb: dressed granite with a pitched top edge.
        m.add(Prim.roundedBox(V3(bay - 0.004, curbHeight, curbDepth), radius: 0.012, bevelSegments: 1, material: stone),
              Xform(translation: V3(0, curbHeight / 2, 0)))
        let y0 = curbHeight
        // Post at the bay start.
        let postW: Float = 0.075, postH = picketHeight + 0.14
        let px = -half + 0.05
        m.add(Prim.roundedBox(V3(postW, postH, postW), radius: 0.006, bevelSegments: 2, material: iron),
              Xform(translation: V3(px, y0 + postH / 2, 0)))
        // Post base collar and cap moulding.
        m.add(turned([(0.0, 0), (0.062, 0), (0.062, 0.03), (0.05, 0.05), (0.0, 0.05)], segments: 4, material: rust),
              Xform(translation: V3(px, y0, 0), rotation: simd_quatf(degrees: 45, axis: .up)))
        m.add(turned([(0.0, 0), (0.056, 0), (0.056, 0.018), (0.046, 0.03), (0.03, 0.04), (0.012, 0.05), (0.0, 0.05)], segments: 4, material: iron),
              Xform(translation: V3(px, y0 + postH, 0), rotation: simd_quatf(degrees: 45, axis: .up)))
        // Ball finial on a short neck.
        var ball: [(Float, Float)] = [(0, 0), (0.014, 0), (0.014, 0.02)]
        for i in 0...7 { let a = Float.pi * Float(i) / 7; ball.append((0.042 * sin(a) + (i == 0 ? 0.001 : 0), 0.062 - 0.042 * cos(a))) }
        ball.append((0, 0.105))
        m.add(turned(ball.map { ($0.0, $0.1) }, segments: 12, material: iron), Xform(translation: V3(px, y0 + postH + 0.048, 0)))
        // Rails: flat bars, bottom and top.
        let railX0 = px + postW / 2, railX1 = half
        for ry in [Float(0.11), picketHeight - 0.2] {
            m.add(Prim.roundedBox(V3(railX1 - railX0, 0.04, 0.014), radius: 0.003, bevelSegments: 1, material: iron),
                  Xform(translation: V3((railX0 + railX1) / 2, y0 + ry, 0)))
        }
        // Pickets with spear heads.
        let pw: Float = 0.019
        let shaftH = picketHeight - 0.11
        var spear = Shape2D.deduped([V2(0, 0.11), V2(-0.012, 0.035), V2(-0.024, 0.0), V2(-0.009, 0.006), V2(-0.009, -0.01),
                                    V2(0.009, -0.01), V2(0.009, 0.006), V2(0.024, 0.0), V2(0.012, 0.035)])
        spear = spear.reversed()
        let spearS = Prim.extrude(spear, depth: 0.012, bevel: 0.0015, bevelSegments: 0, material: iron)
        func sq(_ w: Float, _ h: Float, _ mat: MaterialKey, bevels: Bool = true) -> Surface {
            var c = Prim.cylinder(radius: w * 0.7071, height: h, bevel: 0.0015, segments: 4, bevelSegments: 1, topBevel: bevels, bottomBevel: bevels, material: mat)
            c.deform { simd_quatf(degrees: 45, axis: .up).act($0) }
            return c
        }
        let collar = sq(0.028, 0.012, iron)
        let count = Int(((railX1 - railX0) / picketSpacing).rounded(.down))
        let start = railX0 + ((railX1 - railX0) - Float(count - 1) * picketSpacing) / 2
        for i in 0..<count {
            var r = rng.fork(i)
            let x = start + Float(i) * picketSpacing
            let lean = r.float(-0.35...0.35)
            let rot = simd_quatf(degrees: lean, axis: V3(0, 0, 1)) * simd_quatf(degrees: 45 * 0, axis: .up)
            m.add(sq(pw, shaftH + 0.004, iron, bevels: false), Xform(translation: V3(x, y0 - 0.004, 0), rotation: rot))
            m.add(spearS, Xform(translation: V3(x, y0 + shaftH, 0), rotation: rot))
            m.add(collar, Xform(translation: V3(x, y0 + shaftH - 0.012, 0), rotation: rot))
            // Leaded foot with rust bloom.
            if r.chance(0.45) {
                // Rust bleed on the curb top around the leaded foot.
                let stain = Prim.extrude(Shape2D.circle(r.float(0.025...0.045), ry: r.float(0.02...0.035), segments: 6), depth: 0.0016, bevel: 0, bevelSegments: 0, material: rust)
                m.add(stain, Xform(translation: V3(x + r.float(-0.01...0.01), y0 + 0.0007, r.float(-0.01...0.02)), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            m.add(sq(0.032, 0.014, r.chance(0.6) ? rust : iron, bevels: false), Xform(translation: V3(x, y0 - 0.002, 0)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
