import simd
import Foundation

/// Three Ring Binder: everyday school, vinyl. Parts: vinyl-wrapped boards, spine with label sleeve, three-ring steel mechanism, page block, inside pocket.
public struct ThreeRingBinder: RealAsset {
    public static let id = "three-ring-binder"
    public static let summary = "Vinyl 3-ring binder with 1 in rings on a steel mounting plate and punched paper."
    public static let tags = ["prop", "interior", "school", "vinyl", "metal"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.28, 0.05, 0.3)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, T = size.y, D = size.z
        let vinyl = "plastic.matte:2A4F86", board: Float = 0.0035
        // Covers and spine: board with vinyl wrap, 1 in (25 mm) ring capacity.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(W - 0.012, board, D), radius: 0.0015, bevelSegments: 2, material: vinyl),
                  Xform(translation: V3(0.006, T / 2 + s * (T / 2 - board / 2), 0)))
        }
        m.add(Prim.roundedBox(V3(0.012, T, D), radius: 0.003, bevelSegments: 3, material: vinyl),
              Xform(translation: V3(-W / 2 + 0.006, T / 2, 0)))
        // Spine label sleeve: clear window with paper insert on the outside of the spine.
        m.add(Prim.roundedBox(V3(0.0006, T * 0.8, D * 0.7), radius: 0.0002, bevelSegments: 1, material: "paper.sheet"),
              Xform(translation: V3(-W / 2 - 0.0002, T / 2, 0)))
        // Page block: punched paper stack resting against the rings.
        m.add(Prim.roundedBox(V3(0.2159, T - 2 * board - 0.002, 0.2794), radius: 0.0006, bevelSegments: 1, material: "paper.pages:E9E1CC"),
              Xform(translation: V3(0.016, T / 2, 0)).jittered(&rng))
        // Steel mounting plate on the back board and three D-shaped ring halves (spacing 108 mm).
        m.add(Prim.roundedBox(V3(0.022, 0.0012, D * 0.86), radius: 0.0004, bevelSegments: 1, material: "metal.steel"),
              Xform(translation: V3(-W / 2 + 0.034, board + 0.0006, 0)))
        for k in -1...1 {
            let z = Float(k) * 0.108
            let r = T * 0.26, cx = -W / 2 + 0.034 + r
            let pts = (0...16).map { j -> V3 in
                let a = Float.pi * Float(j) / 16
                return V3(cx + r * cos(a), board + 0.0012 + r * 0.85 * sin(a), z)
            }
            m.add(Prim.tube(pts, radii: Array(repeating: 0.0022, count: pts.count), sides: 8, seamTile: 0.02, material: "metal.steel"), Xform())
        }
        // Inside front pocket: vinyl flap, slightly shorter than the board.
        m.add(Prim.roundedBox(V3(W * 0.8, 0.0008, D * 0.55), radius: 0.0003, bevelSegments: 1, material: vinyl),
              Xform(translation: V3(0.02, T - board - 0.0006, -D * 0.2)))
        // Page edges on fore edge, head and tail.
        let pb = T - 2 * board - 0.002
        m.add(Prim.roundedBox(V3(0.0004, pb, 0.2794), radius: 0.0001, bevelSegments: 1, material: "paper.pages:E9E1CC"), Xform(translation: V3(0.016 + 0.2159 / 2 + 0.0002, T / 2, 0)))
        for sg: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.2159, pb, 0.0004), radius: 0.0001, bevelSegments: 1, material: "paper.pages:E9E1CC"), Xform(translation: V3(0.016, T / 2, sg * (0.2794 / 2 + 0.0002))))
        }
        // Stitched border on the front cover (dashes as flat quads) and a hinge groove near the spine.
        var ink = Surface(material: "plastic.matte:C9CED6")
        func dash(_ x: Float, _ z: Float, _ w: Float, _ d: Float) {
            for order in 0..<2 {
                let p = [V2(x, z), V2(x + w, z), V2(x + w, z + d), V2(x, z + d)]
                let q = order == 0 ? p : p.reversed()
                let i = q.map { ink.add(V3($0.x, T + 0.00004, $0.y), V3(0, 1, 0), V2($0.x, $0.y)) }
                ink.quad(i[0], i[3], i[2], i[1])
            }
        }
        let x0: Float = -W / 2 + 0.03, x1: Float = W / 2 - 0.016, z0: Float = -D / 2 + 0.012, z1: Float = D / 2 - 0.012
        var xx = x0
        while xx < x1 - 0.008 { dash(xx, z0, 0.008, 0.0009); dash(xx, z1, 0.008, 0.0009); xx += 0.014 }
        var zz = z0
        while zz < z1 - 0.008 { dash(x0, zz, 0.0009, 0.008); dash(x1, zz, 0.0009, 0.008); zz += 0.014 }
        dash(-W / 2 + 0.0185, -D / 2 + 0.004, 0.001, D - 0.008)
        ink.computeTangents()
        m.add(ink, Xform())
        // Spine label sleeve frame.
        for (dy, dz) in [(T * 0.4, 0.0), (-T * 0.4, 0.0)] as [(Float, Float)] {
            m.add(Prim.roundedBox(V3(0.0012, 0.0012, D * 0.72), radius: 0.0003, bevelSegments: 1, material: "plastic.matte:C9CED6"), Xform(translation: V3(-W / 2 - 0.0002, T / 2 + dy, dz)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
