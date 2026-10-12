import simd
import Foundation

/// Top-hinged awning window, 0.9 x 0.6 x 0.15 m: painted wood frame and sloped sill, interior stool and casing,
/// a glazed sash on two nickel butt hinges with insulated glass, weatherstrip, a cam lock and finger pull, and a
/// sill-mounted operator. The sash bottom swings toward +Z (into the room); origin at the sill center.
public struct AwningWindow: RealArticulated {
    public static let id = "awning-window"
    public static let summary = "Top-hinged awning window, 0.9 x 0.6 m: painted wood frame, sill, casing, glazed sash on hinges with cam lock; states closed, open."
    public static let tags = ["structure", "floorplan", "interior", "window", "glass", "wood", "articulated"]
    public static let budget = 9_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.1, studio: true)

    public var width: Float = 0.9
    public var height: Float = 0.6
    /// Painted wood for frame, casing and sash.
    public var paint: MaterialKey = "wood.painted-shaker:E8E3D6"
    /// Sill, stool and exterior trim: more worn paint.
    public var sillMaterial: MaterialKey = "wood.painted-shaker-worn:D9D5C8"
    public var glass: MaterialKey = "glass.clear"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        let W = width, H = height
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let seg = l == 0 ? 2 : 1
            let s = WindowKit.surround(W: W, H: H, sillTop: 0.05, jw: 0.045, jz: 0.045, casing: 0.05, depth: 0.075, out: 0.075,
                                       frame: paint, trim: sillMaterial, sillMat: sillMaterial, seg: seg)
            for p in s.parts { m.add(p.0, p.1) }
            let o = s.opening
            if l == 0 {
                // Weatherstrip on the frame rebate and a sill-mounted operator housing.
                for sx: Float in [-1, 1] {
                    m.add(WindowKit.box(V3(0.004, o.y1 - o.y0, 0.004), V3(sx * (o.ox - 0.002), (o.y0 + o.y1) / 2, -0.028), "rubber", r: 0.001, seg: 1).0,
                          Xform(translation: V3(sx * (o.ox - 0.002), (o.y0 + o.y1) / 2, -0.028)))
                }
                let op = WindowKit.box(V3(0.07, 0.022, 0.03), V3(0.2, 0.05 + 0.025 + 0.011, 0.058), hardware, r: 0.004, seg: 2)
                m.add(op.0, op.1)
                m.add(Prim.cylinder(radius: 0.004, height: 0.03, bevel: 0.001, segments: 10, bevelSegments: 1, material: hardware),
                      Xform(translation: V3(0.2, 0.05 + 0.025 + 0.022, 0.058), rotation: .identity))
                m.add(WindowKit.box(V3(0.035, 0.005, 0.01), V3(0.2 + 0.012, 0.05 + 0.025 + 0.05, 0.058), hardware, r: 0.002, seg: 1).0,
                      Xform(translation: V3(0.2 + 0.012, 0.05 + 0.025 + 0.05, 0.058)))
            }
            rig.base[l] = m
        }

        // Sash: 3 mm margin to the frame, 40 mm stiles, hinged on the top edge.
        let sx0 = s0(width, height).ox - 0.003, sy0: Float = 0.05 + 0.003, sy1: Float = (height - 0.04 - 0.045) - 0.003
        rig.part("sash", pivot: V3(0, sy1, 0.0), joint: .hinge(axis: V3(1, 0, 0), -55...0, duration: 1.0))
        let sw: Float = 0.04, sd: Float = 0.04
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, seg: Int = 2) -> (Surface, Xform) { WindowKit.box(s, c, mat, r: r, seg: seg) }
        for sx: Float in [-1, 1] {
            let b = box(V3(sw, sy1 - sy0, sd), V3(sx * (sx0 - sw / 2), (sy0 + sy1) / 2, 0), paint, r: 0.003)
            rig.add(b.0, b.1, to: "sash")
        }
        for y in [sy0 + sw / 2, sy1 - sw / 2] {
            let b = box(V3(2 * (sx0 - sw) + 0.002, sw, sd), V3(0, y, 0), paint, r: 0.003)
            rig.add(b.0, b.1, to: "sash")
        }
        let gx = sx0 - sw, gy0 = sy0 + sw, gy1 = sy1 - sw, gcy = (gy0 + gy1) / 2
        for z: Float in [-0.009, 0.009] {
            let b = box(V3(2 * gx + 0.026, gy1 - gy0 + 0.026, 0.004), V3(0, gcy, z), glass, r: 0.001, seg: 1)
            rig.add(b.0, b.1, to: "sash")
        }
        for sx: Float in [-1, 1] {
            rig.add(cuboid(V3(0.012, gy1 - gy0, 0.014), material: "rubber"), Xform(translation: V3(sx * (gx - 0.006), gcy, 0)), to: "sash", lods: 0...0)
        }
        for y in [gy0 + 0.006, gy1 - 0.006] {
            rig.add(cuboid(V3(2 * gx, 0.012, 0.014), material: "rubber"), Xform(translation: V3(0, y, 0)), to: "sash", lods: 0...0)
        }
        for z: Float in [-1, 1] {
            // Glazing beads.
            for sx: Float in [-1, 1] {
                let b = box(V3(0.012, gy1 - gy0, 0.01), V3(sx * (gx - 0.006), gcy, z * 0.0215), paint, r: 0.0015, seg: 1)
                rig.add(b.0, b.1, to: "sash", lods: 0...0)
            }
            for y in [gy0 + 0.006, gy1 - 0.006] {
                let b = box(V3(2 * gx, 0.012, 0.01), V3(0, y, z * 0.0215), paint, r: 0.0015, seg: 1)
                rig.add(b.0, b.1, to: "sash", lods: 0...0)
            }
        }
        // Butt hinges on the top rail, interior face, with a pin barrel along X.
        for sx: Float in [-1, 1] {
            let hx = sx * 0.24
            let leaf = box(V3(0.05, 0.034, 0.003), V3(hx, sy1 - 0.02, sd / 2 + 0.0015), hardware, r: 0.001, seg: 1)
            rig.add(leaf.0, leaf.1, to: "sash", lods: 0...0)
            rig.add(Prim.cylinder(radius: 0.0045, height: 0.05, bevel: 0.001, segments: 10, bevelSegments: 1, material: hardware),
                    Xform(translation: V3(hx - 0.025, sy1 - 0.004, sd / 2 + 0.003), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))), to: "sash", lods: 0...0)
        }
        // Cam lock with flip lever and finger pull on the bottom rail.
        let plate = box(V3(0.06, 0.02, 0.006), V3(0, sy0 + sw / 2, sd / 2 + 0.003), hardware, r: 0.003, seg: 1)
        rig.add(plate.0, plate.1, to: "sash", lods: 0...0)
        let lever = box(V3(0.045, 0.007, 0.007), V3(0.008, sy0 + sw / 2, sd / 2 + 0.0095), hardware, r: 0.0025, seg: 1)
        rig.add(lever.0, lever.1, to: "sash", lods: 0...0)
        let pull = box(V3(0.03, 0.01, 0.012), V3(-0.12, sy0 + 0.008, sd / 2 + 0.006), paint, r: 0.003, seg: 1)
        rig.add(pull.0, pull.1, to: "sash", lods: 0...0)

        groundAO(&rig, height: 0.05, floor: 0.75)
        rig.states = [RigState("closed"), RigState("open", ["sash": -40])]
        return rig
    }

    private func s0(_ w: Float, _ h: Float) -> WindowKit.Opening {
        WindowKit.surround(W: w, H: h, sillTop: 0.05, jw: 0.045, jz: 0.045, casing: 0.05, depth: 0.075, out: 0.075,
                           frame: paint, trim: sillMaterial, sillMat: sillMaterial, seg: 1).opening
    }
}
