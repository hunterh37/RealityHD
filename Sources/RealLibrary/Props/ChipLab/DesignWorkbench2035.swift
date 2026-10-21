import simd
import Foundation

/// 2035 design workbench, 2.4 x 1.0 x 1.2 m: pale laminate top with rounded corners over a dark anodized frame
/// (end plates, rails, rear cross beam, leveling feet), three curved glass displays on slim stands, a keyboard
/// deck with palm rest and keycaps, a floating emissive holo plane and a cable spine along the rear.
/// Parts: display-left, display-center, display-right, holo-plane (fixed, named), cable-spine.
public struct DesignWorkbench2035: RealArticulated {
    public static let id = "design-workbench-2035"
    public static let summary = "2035 design workbench: laminate top, anodized frame, three curved glass displays, keyboard deck, emissive holo plane, cable spine."
    public static let tags = ["prop", "chiplab", "furniture", "articulated"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 1.0, studio: true)

    /// Overall size (x width, y height, z depth) in meters.
    public var size = V3(2.4, 1.0, 1.2)
    /// Desk surface height in meters.
    public var deskHeight: Float = 0.72
    public var top: MaterialKey = "laminate.white:B9BDC0"
    public var frame: MaterialKey = "metal.anodized-black"
    public var trim: MaterialKey = "metal.aluminum-brushed"
    public var glass: MaterialKey = "glass.display"
    public var screen: MaterialKey = "screen.ui"
    public var holo: MaterialKey = "emissive.holo-plane"
    public var keys: MaterialKey = "plastic.black"
    public var foot: MaterialKey = "rubber"
    public init() {}

    func box(_ m: inout Model, _ s: V3, _ r: Float, _ at: V3, _ mat: MaterialKey) {
        m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: at))
    }

    /// Curved slab: arc band in XY (concave toward +z), extruded up by h, base at y = 0.
    func arc(_ chord: Float, _ radius: Float, _ thick: Float, _ h: Float, bevel: Float, _ mat: MaterialKey) -> Surface {
        let a = asin(chord / 2 / radius), n = 7
        var pts: [V2] = []
        for i in 0...n { let th = -a + 2 * a * Float(i) / Float(n); pts.append(V2((radius + thick / 2) * sin(th), radius - (radius + thick / 2) * cos(th))) }
        for i in (0...n).reversed() { let th = -a + 2 * a * Float(i) / Float(n); pts.append(V2((radius - thick / 2) * sin(th), radius - (radius - thick / 2) * cos(th))) }
        return Prim.extrude(pts, depth: h, bevel: bevel, bevelSegments: 1, material: mat)
    }

    func place(_ x: Float, _ y: Float, _ z: Float, yaw: Float, h: Float) -> Xform {
        Xform(translation: V3(x, y + h / 2, z), rotation: simd_quatf(angle: yaw, axis: V3(0, 1, 0)) * simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, dh = deskHeight, topT: Float = 0.04
        let y0 = dh - topT
        // Laminate top with rounded corners, aluminum edge lip underneath.
        m.add(Prim.extrude(Shape2D.roundedRect(W, D, radius: 0.06), depth: topT, bevel: 0.004, bevelSegments: 1, material: top),
              Xform(translation: V3(0, y0 + topT / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.extrude(Shape2D.roundedRect(W - 0.02, D - 0.02, radius: 0.055), depth: 0.006, bevel: 0.001, bevelSegments: 1, material: trim),
              Xform(translation: V3(0, y0 - 0.003, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Frame: end plates, foot bars, leveling feet, rails and rear cross beam.
        for sx: Float in [-1, 1] {
            let x = sx * (W / 2 - 0.16)
            box(&m, V3(0.05, y0 - 0.05 - 0.01, D - 0.3), 0.012, V3(x, 0.05 + (y0 - 0.06) / 2, 0), frame)
            box(&m, V3(0.09, 0.04, D - 0.1), 0.012, V3(x, 0.03 + 0.01, 0), frame)
            for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.025, height: 0.02, bevel: 0.004, segments: 12, material: foot), Xform(translation: V3(x, 0, sz * (D / 2 - 0.15))))
            }
            // Machined reveal on the end plate.
            box(&m, V3(0.006, y0 - 0.3, 0.03), 0.002, V3(x + sx * 0.026, 0.05 + (y0 - 0.06) / 2, 0), trim)
        }
        box(&m, V3(W - 0.4, 0.06, 0.04), 0.01, V3(0, y0 - 0.05, -D / 2 + 0.16), frame)
        box(&m, V3(W - 0.4, 0.04, 0.04), 0.01, V3(0, y0 - 0.04, D / 2 - 0.16), frame)
        box(&m, V3(0.04, 0.04, D - 0.36), 0.01, V3(0, y0 - 0.04, 0), frame)
        // Keyboard deck: palm rest, base, keycaps in rows, scroll dial, status LED strip on the front edge.
        let kz: Float = 0.34
        box(&m, V3(0.56, 0.012, 0.3), 0.004, V3(0, dh + 0.006, kz + 0.03), frame)
        box(&m, V3(0.46, 0.014, 0.15), 0.004, V3(0, dh + 0.012, kz - 0.04), frame)
        let cols = 12, rows = 4, pitch: Float = 0.0345
        let capGeo = Prim.extrude(Shape2D.rect(0.028, 0.028), depth: 0.008, bevel: 0.0012, bevelSegments: 1, material: keys)
        for r in 0..<rows { for c in 0..<cols {
            let x = (Float(c) - Float(cols - 1) / 2) * pitch, z = kz - 0.095 + Float(r) * pitch + 0.004
            if r == rows - 1 && c > 3 && c < 8 { continue }
            m.add(capGeo, Xform(translation: V3(x, dh + 0.023, z), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        } }
        m.add(Prim.extrude(Shape2D.rect(0.14, 0.028), depth: 0.008, bevel: 0.0012, bevelSegments: 1, material: keys),
              Xform(translation: V3(0, dh + 0.023, kz - 0.095 + 3 * pitch + 0.004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.03, height: 0.022, bevel: 0.003, segments: 20, material: trim), Xform(translation: V3(0.38, dh, kz - 0.02)))
        m.add(Prim.extrude(Shape2D.rect(0.5, 0.004), depth: 0.002, bevel: 0, bevelSegments: 1, material: "emissive.holo-grid"),
              Xform(translation: V3(0, dh - 0.02, D / 2 - 0.014), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Desk mat under the keyboard deck, slightly worn rubber.
        box(&m, V3(1.0, 0.004, 0.42), 0.002, V3(0.05, dh + 0.002, kz + 0.02), "rubber")
        // Story detail: desk-mounted stylus lying on the laminate.
        m.add(Prim.cylinder(radius: 0.004, height: 0.14, bevel: 0.002, segments: 8, material: trim),
              Xform(translation: V3(-0.5, dh + 0.004, 0.38), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1)) * simd_quatf(degrees: 20, axis: V3(1, 0, 0))))
        rig.base[0] = m

        // Displays: glass shell plus emissive screen band, slim stands, fanned on an arc behind the keyboard.
        let specs: [(String, Float, Float, Float)] = [("display-left", -0.66, -0.2, 0.42), ("display-center", 0, -0.3, 0), ("display-right", 0.66, -0.2, -0.42)]
        let dispH: Float = 0.26, dispY: Float = dh + 0.015
        for (name, x, z, yaw) in specs {
            _ = rig.part(name, pivot: V3(x, dispY, z), joint: .fixed)
            rig.add(arc(0.64, 1.3, 0.012, dispH, bevel: 0.002, glass), place(x, dispY, z, yaw: yaw, h: dispH), to: name)
            rig.add(arc(0.62, 1.3, 0.0016, dispH - 0.024, bevel: 0, screen), place(x, dispY + 0.012, z + 0.0065, yaw: yaw, h: dispH - 0.024), to: name)
            let stand = V3(x - 0.0, 0, z - 0.04)
            rig.add(Prim.roundedBox(V3(0.18, 0.008, 0.12), radius: 0.003, bevelSegments: 1, material: frame), Xform(translation: V3(x, dh + 0.004, z - 0.02)), to: name)
            rig.add(Prim.roundedBox(V3(0.04, 0.035, 0.012), radius: 0.003, bevelSegments: 1, material: frame), Xform(translation: V3(stand.x, dh + 0.024, stand.z + 0.015)), to: name)
        }
        // Holo plane: floating translucent emissive sheet with a bright frame line, right of the keyboard.
        _ = rig.part("holo-plane", pivot: V3(0.85, 0.86, 0.2), joint: .fixed)
        let hq = simd_quatf(angle: -0.6, axis: V3(0, 1, 0)) * simd_quatf(degrees: -8, axis: V3(1, 0, 0))
        rig.add(Prim.extrude(Shape2D.roundedRect(0.42, 0.2, radius: 0.01), depth: 0.0015, bevel: 0, bevelSegments: 1, material: holo), Xform(translation: V3(0.85, 0.86, 0.2), rotation: hq), to: "holo-plane")
        rig.add(Prim.extrude(Shape2D.roundedRect(0.3, 0.012, radius: 0.004), depth: 0.002, bevel: 0, bevelSegments: 1, material: "emissive.holo-grid"),
                Xform(translation: V3(0.85, 0.89, 0.2) + hq.act(V3(0, 0, 0.002)), rotation: hq), to: "holo-plane")
        // Cable spine: trunk under the rear rail, riser along the right end plate and three drooping cables to the displays.
        _ = rig.part("cable-spine", pivot: V3(0, y0 - 0.1, -D / 2 + 0.12), joint: .fixed)
        rig.add(Prim.roundedBox(V3(W - 0.5, 0.05, 0.07), radius: 0.015, bevelSegments: 2, material: frame), Xform(translation: V3(0, y0 - 0.1, -D / 2 + 0.12)), to: "cable-spine")
        rig.add(Prim.roundedBox(V3(0.07, y0 - 0.12, 0.07), radius: 0.015, bevelSegments: 2, material: frame), Xform(translation: V3(W / 2 - 0.3, (y0 - 0.1) / 2 + 0.04, -D / 2 + 0.12)), to: "cable-spine")
        for (i, x) in [Float(-0.66), 0, 0.66].enumerated() {
            let sag = rng.float(0.02...0.05)
            let path = catmull([V3(x, dh + 0.04, -0.3 - 0.04), V3(x, dh + 0.01, -0.36), V3(x + 0.03 * Float(i - 1), dh - 0.02 - sag, -0.5), V3(x + 0.03 * Float(i - 1), y0 - 0.1, -D / 2 + 0.14)], per: 5)
            rig.add(Prim.tube(path, radii: path.map { _ in 0.006 }, sides: 6, seamTile: 0.05, material: "rubber", capEnd: true), to: "cable-spine")
        }
        rig.states = [RigState("assembled")]
        return rig
    }
}
