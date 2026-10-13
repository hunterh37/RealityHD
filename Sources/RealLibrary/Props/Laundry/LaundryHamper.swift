import simd
import Foundation

/// Lidded wicker hamper: Natural willow laundry hamper with a linen-topped lid, slightly darkened at the base.. Parts: tapered woven willow body with course bands and corner stakes, rim ring and base ring, padded linen lid on a willow frame with piping, leather tab handle on the lid, two brass hinges at the back, leather end handles with brass rivet plates, four wooden feet, a sleeve caught under the lid.
public struct LaundryHamper: RealAsset {
    public static let id = "laundry-hamper"
    public static let summary = "Lidded willow laundry hamper: tapered woven body with bands and stakes, padded linen lid with leather tab, brass hinges, leather end handles."
    public static let tags = ["prop", "floorplan", "laundry", "fabric", "container", "interior"]
    public static let budget = 8500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth), lid overhang included.
    public var size = V3(0.42, 0.62, 0.36)
    /// Lid pad color.
    public var lidColor: UInt32 = 0xD8CCB8
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    private func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let willow: MaterialKey = "wicker.willow"
        let linen = String(format: "fabric.linen:%06X", lidColor)
        let yB: Float = 0.03, yT: Float = 0.52
        let Lb: Float = 0.38, Wb: Float = 0.32, Lt: Float = size.x - 0.02, Wt: Float = size.z - 0.02
        func plan(_ y: Float) -> (Float, Float) {
            let t = (y - yB) / (yT - yB)
            return (Lb + (Lt - Lb) * t, Wb + (Wt - Wb) * t)
        }
        let seg = lite ? 2 : 4
        func rrPath(_ L: Float, _ W: Float, _ y: Float, r: Float) -> [V3] {
            var pts: [V3] = []
            let cs: [(Float, Float, Float)] = [(L / 2 - r, W / 2 - r, 0), (-(L / 2 - r), W / 2 - r, .pi / 2), (-(L / 2 - r), -(W / 2 - r), .pi), (L / 2 - r, -(W / 2 - r), 3 * .pi / 2)]
            for (cx, cz, a0) in cs { for k in 0...seg { let t = a0 + Float(k) / Float(seg) * (.pi / 2); pts.append(V3(cx + r * cos(t), y, cz + r * sin(t))) } }
            pts.append(pts[0])
            return pts
        }
        func band(_ y: Float, rad: Float, inset: Float = 0, mat: MaterialKey = "wicker.willow") {
            let (L, W) = plan(y)
            m.add(Prim.sweep(Shape2D.circle(rad, segments: lite ? 5 : 8), along: rrPath(L - inset, W - inset, y, r: 0.045), closedPath: true, caps: false, material: mat))
        }
        // Woven body.
        func outline(_ L: Float, _ W: Float) -> [V2] { Shape2D.roundedRect(L, W, radius: 0.045, segments: lite ? 3 : 5) }
        let rings = [yB, 0.28, yT].map { y -> [V3] in let (L, W) = plan(y); return Prim.ring(outline(L, W), y: y) }
        m.add(Prim.loft(rings, capStart: true, capEnd: true, material: willow))
        // Courses, rim and base rings.
        band(0.045, rad: 0.009)
        band(yT - 0.006, rad: 0.0105)
        if !lite { for y in [Float(0.15), 0.26, 0.37] { band(y, rad: 0.0045, inset: -0.004) } }
        // Corner stakes and feet.
        for sx in [Float(-1), 1] { for sz in [Float(-1), 1] {
            let (L0, W0) = plan(yB), (L1, W1) = plan(yT)
            let a = V3(sx * (L0 / 2 - 0.013), yB, sz * (W0 / 2 - 0.013)), b = V3(sx * (L1 / 2 - 0.013), yT, sz * (W1 / 2 - 0.013))
            m.add(Prim.tube([a, b], radii: [0.0075, 0.0075], sides: lite ? 6 : 8, seamTile: 0.05, material: willow, capEnd: true))
            m.add(Prim.roundedBox(V3(0.04, 0.03, 0.04), radius: 0.006, bevelSegments: 1, material: "wood.beech-stained"), Xform(translation: V3(sx * (L0 / 2 - 0.03), 0.015, sz * (W0 / 2 - 0.03))))
        } }
        // Lid: willow frame, linen pad with piping and buttons.
        let lidFrame = Shape2D.roundedRect(size.x, size.z, radius: 0.05, segments: lite ? 3 : 5)
        m.add(Prim.extrude(lidFrame, depth: 0.03, bevel: 0.006, bevelSegments: lite ? 1 : 2, material: willow), Xform(translation: V3(0, yT + 0.015, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.superellipsoid(V3(size.x - 0.03, 0.074, size.z - 0.03), exponent: 4, subdivisions: lite ? 5 : 8, material: linen),
              Xform(translation: V3(0, yT + 0.03 + 0.0335, 0)))
        if !lite {
            let pipe = rrPath(size.x - 0.03, size.z - 0.03, yT + 0.03 + 0.0335, r: 0.05)
            m.add(Prim.sweep(Shape2D.circle(0.0035, segments: 6), along: pipe, closedPath: true, caps: false, material: "leather.tan"))
            for (bx, bz) in [(Float(-0.07), Float(-0.05)), (0.07, -0.05), (-0.07, 0.05), (0.07, 0.05)] {
                m.add(Prim.cylinder(radius: 0.008, height: 0.006, bevel: 0.002, segments: 10, bevelSegments: 1, material: "leather.tan"), Xform(translation: V3(bx, 0.617, bz)))
            }
        }
        // Leather tab handle on the lid front.
        m.add(Prim.torus(major: 0.018, minor: 0.0042, segments: lite ? 8 : 14, sides: 6, arc: .pi, material: "leather.tan"),
              Xform(translation: V3(0, 0.6, size.z / 2 - 0.045), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.roundedBox(V3(0.07, 0.003, 0.02), radius: 0.001, bevelSegments: 1, material: "leather.tan"), Xform(translation: V3(0, 0.6, size.z / 2 - 0.045)))
        // Brass hinges at the back.
        for sx in [Float(-1), 1] {
            m.add(Prim.roundedBox(V3(0.034, 0.008, 0.022), radius: 0.002, bevelSegments: 1, material: "metal.brass-aged"), Xform(translation: V3(sx * 0.12, yT + 0.034, -size.z / 2 + 0.011)))
            m.add(Prim.cylinder(radius: 0.005, height: 0.036, bevel: 0.001, segments: 8, bevelSegments: 1, material: "metal.brass-aged"),
                  Xform(translation: V3(sx * 0.12 - 0.018, yT + 0.037, -size.z / 2 + 0.011), rotation: simd_quatf(from: V3(0, 1, 0), to: V3(1, 0, 0))))
        }
        // Leather end handles lying on the short walls, with brass rivet plates.
        for sx in [Float(-1), 1] {
            let (Le, _) = plan(0.42)
            let x = sx * (Le / 2 + 0.0035)
            let hp: [V3] = [V3(x, 0.372, -0.034), V3(x, 0.4, -0.036), V3(x, 0.418, 0), V3(x, 0.4, 0.036), V3(x, 0.372, 0.034)]
            let path = catmull(hp, per: lite ? 2 : 4)
            m.add(Prim.tube(path, radii: path.map { _ in Float(0.0045) }, sides: lite ? 5 : 8, seamTile: 0.03, material: "leather.tan", capEnd: true))
            for sz in [Float(-1), 1] {
                m.add(Prim.cylinder(radius: 0.009, height: 0.003, bevel: 0.0008, segments: lite ? 6 : 10, bevelSegments: 1, material: "metal.brass-aged"),
                      Xform(translation: V3(x - sx * 0.0005, 0.372, sz * 0.034), rotation: simd_quatf(from: V3(0, 1, 0), to: V3(sx, 0, 0))))
            }
        }
        // A sleeve caught under the front of the lid, hanging over the wall.
        if !lite {
            let (Lw, Ww) = plan(0.5)
            _ = Lw
            m.add(Prim.superellipsoid(V3(0.075, 0.11, 0.011), exponent: 3, subdivisions: 7, material: "fabric.canvas:8CA9BF"),
                  Xform(translation: V3(-0.08, 0.49, Ww / 2 + 0.0035), rotation: simd_quatf(degrees: 6, axis: V3(0, 0, 1)) * simd_quatf(degrees: 8, axis: V3(1, 0, 0))))
            m.add(Prim.superellipsoid(V3(0.05, 0.05, 0.012), exponent: 3, subdivisions: 6, material: "fabric.canvas:8CA9BF"),
                  Xform(translation: V3(-0.075, 0.43, Ww / 2 + 0.0035), rotation: simd_quatf(degrees: -10, axis: V3(0, 0, 1))))
        }
        _ = rng.float()
        groundAO(&m, height: 0.12, floor: 0.6)
        return m
    }
}
