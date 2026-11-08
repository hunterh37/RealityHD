import simd
import Foundation

/// Handheld supermarket basket, 0.43 x 0.29 m, 0.22 m deep. Parts: molded red polypropylene walls as a
/// grid of bands and ribs with real openings, a solid ribbed floor, a rolled top rim, four corner feet,
/// and two upright chrome wire handles with black grips meeting over the center.
public struct ShoppingBasket: RealAsset {
    public static let id = "shopping-basket"
    public static let summary = "Red plastic shopping basket, 0.43 x 0.29 x 0.22 m: open grid walls, ribbed floor, rolled rim, two chrome handles with black grips."
    public static let tags = ["prop", "grocery", "retail", "plastic", "container", "handheld"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 1.2, studio: true)

    /// Top outer size (x, z) and depth (m).
    public var top = V2(0.43, 0.29)
    public var depth: Float = 0.22
    public var plastic: MaterialKey = "plastic.matte:C8202A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [3])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let H = depth, taper: Float = 0.03
        let bx = top.x / 2 - taper, bz = top.y / 2 - taper
        let t: Float = 0.006
        // Floor with ribs and feet.
        GroceryKit.box(&m, V3(bx * 2, 0.008, bz * 2), V3(0, 0.014, 0), plastic, r: 0.003)
        for i in 0..<5 { GroceryKit.flat(&m, V3(bx * 2 - 0.02, 0.006, 0.006), V3(0, 0.007, -bz + 0.03 + Float(i) * (bz * 2 - 0.06) / 4), plastic) }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { GroceryKit.box(&m, V3(0.04, 0.012, 0.03), V3(sx * (bx - 0.02), 0.006, sz * (bz - 0.015)), plastic, r: 0.003) } }
        // Walls: four sides, each a tilted panel of bands and ribs.
        let walls: [(V3, Float, Float, Float)] = [   // inward normal axis, half-length at bottom, offset at bottom, yaw
            (V3(0, 0, 1), bx, bz, 0), (V3(0, 0, -1), bx, bz, 180), (V3(1, 0, 0), bz, bx, 90), (V3(-1, 0, 0), bz, bx, -90),
        ]
        let lean = atan2(taper, H)
        for (_, half, off, yaw) in walls {
            let rot = simd_quatf(degrees: yaw, axis: .up) * simd_quatf(angle: lean, axis: V3(1, 0, 0))
            let base = simd_quatf(degrees: yaw, axis: .up).act(V3(0, 0, off))
            func at(_ x: Float, _ y: Float) -> V3 { base + rot.act(V3(x, y, 0)) }
            let wl = half * 2 + taper
            for y: Float in [0.01, H * 0.36, H * 0.68] { m.add(cuboid(V3(wl, 0.018, t), material: plastic), Xform(translation: at(0, y + 0.009), rotation: rot)) }
            let ribs = hi ? 12 : 6
            for i in 0...ribs {
                let x = -wl / 2 + wl * Float(i) / Float(ribs)
                m.add(cuboid(V3(0.008, H, t), material: plastic), Xform(translation: at(x, H / 2), rotation: rot))
            }
        }
        // Rolled rim.
        let rim = Prim.sweep(Shape2D.circle(0.007, segments: hi ? 8 : 4), along: [V3(-top.x / 2, H, -top.y / 2), V3(top.x / 2, H, -top.y / 2),
                                                                                   V3(top.x / 2, H, top.y / 2), V3(-top.x / 2, H, top.y / 2)],
                             closedPath: true, material: plastic)
        m.add(rim)
        // Handles: chrome wire arcs from the long-side rims, grips at the top.
        for s: Float in [-1, 1] {
            let arc = Prim.torus(major: 0.16, minor: 0.003, segments: hi ? 20 : 10, sides: hi ? 6 : 4, arc: .pi, material: "metal.chrome")
            m.add(arc, Xform(translation: V3(0, H, s * (top.y / 2 - 0.004)),
                             rotation: simd_quatf(degrees: -s * 28, axis: V3(1, 0, 0)) * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            let tip = simd_quatf(degrees: -s * 28, axis: V3(1, 0, 0)).act(V3(0, 0.16, 0))
            m.add(GroceryKit.cyl(0.011, 0.11, seg: hi ? 12 : 6, "plastic.matte:1A1A1C", bevel: 0.004),
                  Xform(translation: V3(-0.055, H, s * (top.y / 2 - 0.004)) + tip, rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        }
        groundAO(&m, height: 0.05, floor: 0.7)
        return m
    }
}
