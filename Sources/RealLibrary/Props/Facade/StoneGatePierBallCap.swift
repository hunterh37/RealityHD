import simd
import Foundation

/// Stone gate pier with ball cap: architectural facade customizer, Georgian. Parts: plinth, rusticated shaft, string course, cornice, capstone, stone ball finial, iron hinge pins.
public struct StoneGatePierBallCap: RealAsset {
    public static let id = "stone-gate-pier-ball-cap"
    public static let summary = "Georgian ashlar gate pier, 2.2 m, moulded plinth, shaft with ashlar joints, cornice, stepped cap and ball finial."
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 2.2, 0.6)
    public init() {}

    /// Ashlar face stone (limestone courses).
    public var stone: MaterialKey = "stone.limestone"
    /// Alternate cast-stone courses and the ball.
    public var cast: MaterialKey = "stone.cast-stone"
    /// Sooted limestone for the footing, soffits and weathered faces.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    /// Iron pintles.
    public var iron: MaterialKey = "metal.wrought-iron"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let sh: Float = 0.46                       // shaft width
        // Footing, chamfered plinth and fillet.
        FA.box(&m, V3(W, 0.12, W), V3(0, 0.06, 0), sooted, r: 0.005)
        FGate.frustum(&m, w0: W - 0.04, w1: sh + 0.04, y0: 0.12, y1: 0.24, sooted)
        FA.box(&m, V3(sh + 0.04, 0.025, sh + 0.04), V3(0, 0.2375 + 0.0125, 0), sooted, r: 0.004)
        // Ashlar courses: alternating tone, vertical joint on every face, bed joints as recessed gaps.
        let y0: Float = 0.2625, courses = 5, ch: Float = 0.2275
        for c in 0..<courses {
            var r = rng.fork(c)
            let mat = c % 2 == 0 ? stone : cast
            let yc = y0 + (Float(c) + 0.5) * ch
            FA.box(&m, V3(sh, ch - 0.006, sh), V3(0, yc, 0), mat, r: 0.005)
            // Vertical joints: a thin sooted slot per face at a staggered position.
            for face in 0..<4 {
                let rot = FA.q(Float(face) * 90, FA.Y)
                let jx = Float(c % 2 == 0 ? -1 : 1) * r.float(0.04...0.12)
                FA.box(&m, V3(0.005, ch - 0.012, 0.004), V3(jx, yc, sh / 2 + 0.0005).rotated(by: rot), sooted, r: 0.0008, rot: rot)
                // Weathered patch and tooling pits on the face.
                if r.chance(0.7) {
                    FA.box(&m, V3(r.float(0.05...0.12), r.float(0.03...0.07), 0.003), V3(r.float(-0.15...0.15), yc + r.float(-0.05...0.05), sh / 2 + 0.0015).rotated(by: rot), sooted, r: 0.001, rot: rot)
                }
            }
        }
        let top = y0 + Float(courses) * ch              // 1.4
        // String course: fillet and ovolo.
        FA.box(&m, V3(sh + 0.04, 0.025, sh + 0.04), V3(0, top + 0.0125, 0), stone, r: 0.004)
        FGate.frustum(&m, w0: sh + 0.04, w1: sh + 0.07, y0: top + 0.025, y1: top + 0.06, stone)
        // Frieze and cornice (cyma, corona with drip, sloping weathering).
        FA.box(&m, V3(sh + 0.04, 0.09, sh + 0.04), V3(0, top + 0.105, 0), cast, r: 0.004)
        FGate.frustum(&m, w0: sh + 0.04, w1: W - 0.01, y0: top + 0.15, y1: top + 0.21, stone)
        FA.box(&m, V3(W, 0.06, W), V3(0, top + 0.24, 0), stone, r: 0.004)
        FA.box(&m, V3(W - 0.03, 0.01, W - 0.03), V3(0, top + 0.205, 0), sooted, r: 0.002)   // drip shadow
        FGate.frustum(&m, w0: W - 0.02, w1: 0.42, y0: top + 0.27, y1: top + 0.33, cast)
        // Blocking course and ball socket.
        FA.box(&m, V3(0.42, 0.08, 0.42), V3(0, top + 0.37, 0), stone, r: 0.004)
        FGate.frustum(&m, w0: 0.36, w1: 0.26, y0: top + 0.41, y1: top + 0.45, cast)
        // Ball finial with a polished bead and a lichen-darkened crown.
        let br = (H - (top + 0.45)) / 2
        m.add(Prim.superellipsoid(V3(repeating: br * 2), exponent: 2, subdivisions: 14, material: cast), Xform(translation: V3(0, top + 0.45 + br - 0.01, 0)))
        // Iron pintles leaded into the +X face.
        for y in [0.52, 1.08] as [Float] {
            FA.box(&m, V3(0.05, 0.05, 0.016), V3(sh / 2 + 0.005, y, 0), sooted, r: 0.003, rot: FA.q(90, FA.Y))
            FA.rod(&m, V3(sh / 2, y, 0), V3(sh / 2 + 0.06, y, 0), r: 0.011, iron)
            m.add(Prim.cylinder(radius: 0.014, height: 0.012, bevel: 0.002, segments: 12, bevelSegments: 1, material: iron),
                  Xform(translation: V3(sh / 2 + 0.06, y + 0.0, 0), rotation: FA.q(-90, FA.Z)))
            FA.rod(&m, V3(sh / 2 + 0.045, y, 0), V3(sh / 2 + 0.045, y + 0.07, 0), r: 0.009, iron)
        }
        // Moss and splash at the footing, rain streaks below the corona, chipped cap corner.
        for k in 0..<6 {
            var r = rng.fork(20 + k)
            let rot = FA.q(Float(r.int(0...3)) * 90, FA.Y)
            FA.box(&m, V3(r.float(0.04...0.1), r.float(0.03...0.06), 0.004), V3(r.float(-0.2...0.2), 0.04, W / 2 + 0.001).rotated(by: rot), "stone.granite-moss", r: 0.001, rot: rot)
            FA.box(&m, V3(r.float(0.012...0.03), r.float(0.1...0.22), 0.003), V3(r.float(-0.2...0.2), top + 0.105, (sh + 0.04) / 2 + 0.0015).rotated(by: rot), sooted, r: 0.0008, rot: rot)
        }
        FA.box(&m, V3(0.07, 0.02, 0.05), V3(W / 2 - 0.05, top + 0.265, W / 2 - 0.04), sooted, r: 0.004, rot: FA.q(25, FA.Y))
        groundAO(&m, height: 0.22, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
