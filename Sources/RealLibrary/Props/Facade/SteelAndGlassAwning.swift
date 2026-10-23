import simd
import Foundation

/// Contemporary steel and glass awning, 2.0 m wide, 1.0 m projection, 0.2 m high: an anthracite powder-coated box-tube
/// frame pitched 6 degrees with two T-bar purlins dividing three laminated green glass panes, carried by three triangular
/// gusset plates with lightening holes and a wall plate with a double row of hex bolts. A stainless drip edge closes the
/// front bar. The coating is chipped to rust at corners and bolts, the glass hazes with limescale at the lower edge and
/// carries bird droppings, and the concrete wall strip is water stained. Wall plane at z = 0.
public struct SteelAndGlassAwning: RealAsset {
    public static let id = "steel-and-glass-awning"
    public static let summary = "Contemporary steel and glass awning, 2.0 m: anthracite frame, three laminated panes, drilled gusset plates, wall plate, drip edge."
    public static let tags = ["prop", "architecture", "facade", "glass", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 3.0)

    /// Overall width in meters.
    public var width: Float = 2.0
    /// Frame coating.
    public var coat: MaterialKey = "metal.painted:3A3D41"
    /// Glass leaves.
    public var glass: MaterialKey = "glass.pane"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2
        let zWall: Float = 0.03, yBack: Float = 0.2
        let tanA = (0.1 as Float) / 0.95
        let alpha = atan(tanA)
        let tilt = FA.q(alpha * 180 / .pi, FA.X)
        let len: Float = 0.95 / cos(alpha)
        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, rot: simd_quatf = .identity) { FA.box(&m, s, c, mat, r: r, rot: rot) }
        func flat(_ s: V3, _ c: V3, _ mat: MaterialKey, rot: simd_quatf = .identity) {
            let x = s.x / 2, y = s.y / 2
            m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: s.z, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: rot))
        }
        func onSlope(_ z: Float, _ up: Float) -> V3 {   // point on the frame top plane plus `up` along the normal
            V3(0, yBack - z * sin(alpha), zWall + z * cos(alpha)) + V3(0, cos(alpha), sin(alpha)) * up
        }

        // Concrete wall strip with water stains, wall plate with bolts.
        bx(V3(width, 0.2, 0.02), V3(0, 0.1, 0.01), "concrete.smooth", r: 0.002)
        for k in 0..<5 where !lite {
            let x = -0.8 + Float(k) * 0.4 + rng.float(-0.05...0.05), h = rng.float(0.05...0.12)
            flat(V3(0.03, h, 0.0012), V3(x, 0.01 + h / 2, 0.0206), "concrete.sealed-dark")
        }
        bx(V3(width - 0.1, 0.18, 0.008), V3(0, 0.1, 0.024), coat, r: 0.002)
        for k in 0..<8 {
            let x = -hw + 0.12 + Float(k) * (width - 0.24) / 7
            for y in [0.05 as Float, 0.15] where !lite || y > 0.1 {
                hexBolt(&m, at: V3(x, y, 0.028), normal: FA.Z, size: 0.016, material: k % 3 == 1 ? "metal.rust" : "metal.screw-zinc")
            }
        }

        // Frame, purlins and glass in a local slope frame (local +z down the slope, local y normal to the glass).
        var fm = Model(name: "frame")
        func fb(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) { FA.box(&fm, s, c, mat, r: r) }
        fb(V3(width, 0.03, 0.045), V3(0, -0.015, 0.0225), coat)                       // back bar
        fb(V3(width, 0.03, 0.045), V3(0, -0.015, len - 0.0225), coat)                  // front bar
        for sx: Float in [-1, 1] { fb(V3(0.045, 0.03, len), V3(sx * (hw - 0.0225), -0.015, len / 2), coat) }
        for px in [-0.33 as Float, 0.33] {
            fb(V3(0.012, 0.022, len - 0.09), V3(px, -0.011, len / 2), coat, r: 0.0015)   // T stem
            fb(V3(0.034, 0.005, len - 0.09), V3(px, 0.0005, len / 2), coat, r: 0.0015)    // T cap
        }
        let xr: [(Float, Float)] = [(-hw + 0.045, -0.33 - 0.006), (-0.33 + 0.006, 0.33 - 0.006), (0.33 + 0.006, hw - 0.045)]
        for (a, b) in xr {
            let w = b - a - 0.006, cx = (a + b) / 2
            for (off, th, mat) in [(-0.0048 as Float, 0.005 as Float, glass), (-0.0098, 0.0016, "glass.emerald"), (-0.0148, 0.005, glass)] {
                fm.add(Prim.roundedBox(V3(w, th, len - 0.09 - 0.006), radius: 0.0008, bevelSegments: 1, material: mat), Xform(translation: V3(cx, off, len / 2)))
            }
            flat2(&fm, V3(w + 0.004, 0.0012, 0.004), V3(cx, -0.0006 + 0.0, 0.045 + 0.001), "plastic.black")
        }
        // Stainless drip edge.
        fb(V3(width - 0.02, 0.012, 0.012), V3(0, -0.036, len + 0.004), "metal.stainless", r: 0.002)
        if !lite {
            // Coating chips with rust at the corners and along the front bar, limescale haze, droppings.
            for (x, z) in [(-hw + 0.06, 0.02), (hw - 0.06, 0.02), (-hw + 0.06, len - 0.02), (hw - 0.06, len - 0.02), (-0.5, len - 0.02), (0.6, len - 0.02), (0.1, 0.02)] as [(Float, Float)] {
                flat2(&fm, V3(0.09, 0.0014, 0.035), V3(x, 0.0008, z), "metal.rust")
            }
            for (a, b) in xr { flat2(&fm, V3(b - a - 0.02, 0.0012, 0.25), V3((a + b) / 2, -0.0042, len - 0.25), "glass.frosted") }
            for _ in 0..<5 {
                let (a, b) = xr[rng.int(0...2)]
                flat2(&fm, V3(0.026, 0.0012, 0.016), V3(rng.float((a + 0.05)...(b - 0.05)), -0.0046, rng.float(0.2...(len - 0.15))), "paint.stucco:F2F0E8")
            }
            for (a, b) in xr {
                flat2(&fm, V3(b - a - 0.02, 0.0013, 0.05), V3((a + b) / 2, -0.0041, len - 0.1), "wood.weathered:4F4536")   // grime line at the lower edge
                for k in 0..<3 {
                    let x = rng.float((a + 0.04)...(b - 0.04)), l = rng.float(0.2...0.5)
                    flat2(&fm, V3(0.012, 0.0013, l), V3(x, -0.0041, 0.15 + l / 2), "wood.weathered:6A5C4A")   // water run
                }
            }
            for sx: Float in [-1, 1] { flat2(&fm, V3(0.02, 0.0012, 0.4), V3(sx * 0.33 + sx * 0.02, -0.0046, len - 0.4), "wood.weathered:55483A") }
        }
        m.add(fm, Xform(translation: V3(0, yBack, zWall), rotation: tilt))

        // Gusset plates with lightening holes (one extrusion with a bridged hole).
        func yu(_ z: Float) -> Float { yBack - 0.03 - (z - zWall) * tanA }
        for gx in [-0.9 as Float, 0, 0.9] {
            let outline: [V2] = [V2(zWall + 0.006, 0.0), V2(0.86, yu(0.86) - 0.0), V2(zWall + 0.006, yu(zWall + 0.006)), V2(zWall + 0.006, 0.13), V2(zWall + 0.006, 0.085)]
            var holeC = V2(0.26, 0.09)
            holeC.y = (yu(0.26) + 0.0 + (0.86 - 0.26) * 0.0) / 2 + 0.01
            let hole: [V2] = (0..<(lite ? 8 : 16)).map { i in let a = Float(i) / Float(lite ? 8 : 16) * 2 * .pi; return V2(holeC.x + 0.034 * cos(a), holeC.y + 0.034 * sin(a)) }
            // The hole must stay inside the plate: pull its centre between the bottom edge and the frame line.
            let poly = ChaletCutworkBalconyBoard.withHoles(outline, holes: [hole], leftX: zWall + 0.006)
            m.add(Prim.extrude(poly, depth: 0.012, bevel: lite ? 0 : 0.0012, bevelSegments: 1, material: coat), Xform(translation: V3(gx, 0, 0), rotation: FA.q(-90, FA.Y)))
            if !lite {
                bx(V3(0.012, 0.03, 0.03), V3(gx, 0.04, 0.06), "metal.rust", r: 0.001)
                hexBolt(&m, at: V3(gx + 0.0065, 0.1, 0.06), normal: FA.X, size: 0.012, material: "metal.rust")
            }
        }

        groundAO(&m, height: 0.05, floor: 0.8)
        return FC.place(m)
    }

    func flat2(_ m: inout Model, _ s: V3, _ c: V3, _ mat: MaterialKey) {
        let x = s.x / 2, z = s.z / 2
        m.add(Prim.extrude([V2(-x, -z), V2(x, -z), V2(x, z), V2(-x, z)], depth: s.y, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: FA.q(90, FA.X)))
    }
}
