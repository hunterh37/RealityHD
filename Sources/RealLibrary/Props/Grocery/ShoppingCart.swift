import simd
import Foundation

/// Nesting wire shopping cart, 0.98 m long (nose toward +Z), 0.56 m wide, handle at 1.0 m. Parts: a
/// tapered chrome wire basket (rims, side and front wires, a swing-gate back, bottom grid), a tubular
/// chassis with a wire bottom tray, four swivel casters with gray polyurethane wheels, a handle bar with a
/// red plastic grip, and a blue plastic child seat flap on the back gate. States: folded, seat-open.
public struct ShoppingCart: RealArticulated {
    public static let id = "shopping-cart"
    public static let summary = "Chrome wire shopping cart, 0.98 x 1.0 x 0.56 m: tapered basket, bottom tray, swivel casters, red handle grip, folding child seat."
    public static let tags = ["prop", "grocery", "retail", "metal", "vehicle", "articulated", "interior"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 18, distance: 1.3, studio: true)

    public var chrome: MaterialKey = "metal.chrome"
    public var grip: MaterialKey = "plastic.gloss:C8202A"
    public var seatColor: MaterialKey = "plastic.matte:2E4D8A"
    public init() {}

    /// Basket point: side s in -1...1 (x), t 0 rear to 1 front, h 0 bottom to 1 top.
    static func basket(_ s: Float, _ t: Float, _ h: Float) -> V3 {
        let yb: Float = 0.47, yt: Float = 0.93
        let zr = -0.33 + (-0.42 + 0.33) * h, zf = 0.40 + (0.48 - 0.40) * h
        let hwR = 0.21 + 0.06 * h, hwF = 0.19 + 0.06 * h
        return V3(s * (hwR + (hwF - hwR) * t), yb + (yt - yb) * h, zr + (zf - zr) * t)
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        for l in 0..<2 {
            let hi = l == 0
            var m = Model(name: Self.id)
            let sides = hi ? 5 : 3
            func wire(_ a: V3, _ b: V3, _ r: Float = 0.0025) {
                m.add(Prim.tube([a, b], radii: [r, r], sides: sides, seamTile: 0.05, material: chrome, capEnd: false))
            }
            func loop(_ pts: [V3], _ r: Float) { for i in pts.indices { wire(pts[i], pts[(i + 1) % pts.count], r) } }
            let B = Self.basket
            // Rims.
            for h: Float in [0, 1] { loop([B(-1, 0, h), B(1, 0, h), B(1, 1, h), B(-1, 1, h)], h == 1 ? 0.006 : 0.004) }
            loop([B(-1, 0, 0.5), B(1, 0, 0.5), B(1, 1, 0.5), B(-1, 1, 0.5)], 0.003)
            // Side walls and front: near-vertical wires.
            let nSide = hi ? 20 : 10
            for i in 1..<nSide {
                let t = Float(i) / Float(nSide)
                for s: Float in [-1, 1] { wire(B(s, t, 0), B(s, t, 1)) }
            }
            let nEnd = hi ? 11 : 6
            for i in 1..<nEnd {
                let s = -1 + 2 * Float(i) / Float(nEnd)
                wire(B(s, 1, 0), B(s, 1, 1))
                wire(B(s, 0, 0), B(s, 0, 1))
            }
            // Bottom grid.
            for i in 1..<(hi ? 10 : 5) {
                let s = -1 + 2 * Float(i) / Float(hi ? 10 : 5)
                wire(B(s, 0, 0), B(s, 1, 0))
            }
            for t: Float in [0.33, 0.66] { wire(B(-1, t, 0), B(1, t, 0)) }
            // Chassis: rails, uprights, bottom tray.
            let ry: Float = 0.15
            for s: Float in [-1, 1] {
                wire(V3(s * 0.2, ry, -0.4), V3(s * 0.17, ry, 0.42), 0.011)
                wire(V3(s * 0.2, ry, -0.4), B(s, 0, 0) + V3(0, 0, -0.02), 0.011)
                wire(V3(s * 0.17, ry, 0.36), B(s, 1, 0), 0.009)
            }
            wire(V3(-0.2, ry, -0.4), V3(0.2, ry, -0.4), 0.011)
            wire(V3(-0.17, ry, 0.42), V3(0.17, ry, 0.42), 0.011)
            for i in 0..<(hi ? 8 : 4) {
                let x = -0.15 + 0.3 * Float(i) / Float(hi ? 7 : 3)
                wire(V3(x, ry + 0.05, -0.3), V3(x * 0.92, ry + 0.05, 0.36))
            }
            for z: Float in [-0.3, 0.03, 0.36] { wire(V3(-0.19, ry + 0.05, z), V3(0.19, ry + 0.05, z), 0.004) }
            // Casters.
            for (x, z) in [(Float(-0.2), Float(-0.38)), (0.2, -0.38), (-0.17, 0.4), (0.17, 0.4)] {
                let wheel = Prim.lathe([V2(0, -0.015), V2(0.055, -0.015), V2(0.0625, -0.008), V2(0.0625, 0.008), V2(0.055, 0.015), V2(0, 0.015)],
                                       segments: hi ? 16 : 8, seamTile: 0.05, material: "rubber.tire:7A7D80")
                m.add(wheel, Xform(translation: V3(x, 0.0625, z), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                for sx: Float in [-1, 1] { GroceryKit.box(&m, V3(0.004, 0.08, 0.03), V3(x + sx * 0.02, 0.09, z), chrome, r: 0.0015) }
                GroceryKit.box(&m, V3(0.05, 0.01, 0.05), V3(x, 0.135, z), chrome, r: 0.003)
            }
            // Handle: side tubes and grip bar.
            let hz: Float = -0.5, hy: Float = 1.0, hw: Float = 0.25
            for s: Float in [-1, 1] { wire(B(s, 0, 1), V3(s * hw, hy, hz), 0.009) }
            wire(V3(-hw, hy, hz), V3(hw, hy, hz), 0.011)
            m.add(GroceryKit.cyl(0.018, 0.42, seg: hi ? 14 : 8, grip, bevel: 0.006),
                  Xform(translation: V3(-0.21, hy, hz), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            rig.base[l] = m
        }
        // Child seat flap: hangs on the back gate, folds forward to horizontal.
        let pivot = V3(0, 0.905, -0.39)
        rig.part("seat", pivot: pivot, joint: .hinge(axis: V3(1, 0, 0), -90...0, duration: 0.7))
        for l in 0..<2 {
            var s = Model(name: "seat")
            GroceryKit.box(&s, V3(0.36, 0.24, 0.012), pivot + V3(0, -0.125, 0.012), seatColor, r: 0.005)
            GroceryKit.box(&s, V3(0.36, 0.02, 0.03), pivot + V3(0, -0.01, 0.01), seatColor, r: 0.006)
            if l == 0 {
                for x: Float in [-0.09, 0.09] { GroceryKit.decal(&s, 0.08, 0.1, pivot + V3(x, -0.15, 0.0185), "plastic.matte:1F3B6E") }
            }
            rig.set(s, part: "seat", lod: l)
        }
        groundAO(&rig, height: 0.08, floor: 0.75)
        rig.states = [RigState("folded"), RigState("seat-open", ["seat": -88])]
        return rig
    }
}
