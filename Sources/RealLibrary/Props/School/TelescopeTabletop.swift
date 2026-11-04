import simd
import Foundation

/// Tabletop Telescope: everyday school, steel. Parts: optical tube, dew shield, focuser and eyepiece, finder scope, tube rings, mount head with pan handle, three tripod legs.
public struct TelescopeTabletop: RealAsset {
    public static let id = "telescope-tabletop"
    public static let summary = "Tabletop refractor telescope with focuser, finder and a three-leg tabletop tripod."
    public static let tags = ["prop", "interior", "school", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.15, 0.4, 0.45)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let white = "metal.powdercoat:F0F0EC", black = "metal.powdercoat:1E1E20", steel = "metal.stainless"
        let pivot = V3(0, 0.205, 0)
        // Optical tube axis frame: local +Y runs along the tube (eyepiece end negative, objective positive); tilted 32 degrees up.
        let tilt = simd_quatf(degrees: 54, axis: V3(1, 0, 0))
        func tube(_ s: Surface, _ off: V3 = V3(0, 0, 0)) { m.add(s, Xform(translation: pivot, rotation: tilt).then(Xform()).then(Xform())) ; _ = off }
        func place(_ s: Surface, _ a: V3) { m.add(s, Xform(translation: a, rotation: simd_quatf(angle: 0, axis: V3(0, 1, 0))).then(Xform(translation: pivot, rotation: tilt))) }
        // Main tube, dew shield, objective ring and lens.
        place(Prim.cylinder(radius: 0.028, height: 0.29, bevel: 0.0012, segments: 28, material: white), V3(0, -0.05, 0))
        place(Prim.cylinder(radius: 0.033, height: 0.085, bevel: 0.0015, segments: 28, material: black), V3(0, 0.235, 0))
        place(Prim.torus(major: 0.0325, minor: 0.0016, segments: 28, sides: 6, material: steel), V3(0, 0.24, 0))
        place(Prim.cylinder(radius: 0.0265, height: 0.0008, bevel: 0, segments: 24, material: "plastic.matte:0B1A2A"), V3(0, 0.250, 0))
        // Focuser: draw tube, body, two knobs, eyepiece barrel with rubber eyecup.
        place(Prim.cylinder(radius: 0.021, height: 0.032, bevel: 0.002, segments: 20, material: black), V3(0, -0.082, 0))
        place(Prim.cylinder(radius: 0.0135, height: 0.07, bevel: 0.001, segments: 18, material: steel), V3(0, -0.15, 0))
        place(Prim.cylinder(radius: 0.011, height: 0.07, bevel: 0.001, segments: 18, material: black), V3(0, -0.215, 0))
        place(Prim.cylinder(radius: 0.0155, height: 0.012, bevel: 0.003, segments: 20, material: "plastic.matte:222426"), V3(0, -0.222, 0))
        for s: Float in [-1, 1] {
            place(Prim.cylinder(radius: 0.009, height: 0.008, bevel: 0.002, segments: 16, material: black), V3(s * 0.0245, -0.07, 0))
        }
        // Tube rings and dovetail bar below the tube.
        for a: Float in [0.0, 0.17] {
            place(Prim.torus(major: 0.0295, minor: 0.0035, segments: 28, sides: 8, material: black), V3(0, a, 0))
        }
        // Finder scope on top, carried by two small brackets.
        place(Prim.cylinder(radius: 0.0085, height: 0.075, bevel: 0.001, segments: 14, material: black), V3(0, 0.02, -0.046))
        place(Prim.cylinder(radius: 0.0105, height: 0.012, bevel: 0.002, segments: 14, material: steel), V3(0, 0.083, -0.046))
        for a: Float in [0.05, 0.11] { place(Prim.roundedBox(V3(0.006, 0.006, 0.018), radius: 0.001, bevelSegments: 1, material: steel), V3(0, a, -0.037)) }
        // Details: blue band decal on the tube, rubber grip bands on the focuser knobs, objective cell ring, and a small thumbscrew on the focuser.
        place(Prim.cylinder(radius: 0.0283, height: 0.012, bevel: 0.0004, segments: 28, material: "plastic.matte:2E5FA8"), V3(0, 0.12, 0))
        place(Prim.cylinder(radius: 0.0283, height: 0.003, bevel: 0.0002, segments: 28, material: "plastic.matte:E2342A"), V3(0, 0.108, 0))
        for k in 0..<3 {
            place(Prim.torus(major: 0.0338, minor: 0.0008, segments: 28, sides: 5, material: "plastic.matte:2A2A2C"), V3(0, 0.26 + Float(k) * 0.02, 0))
        }
        place(Prim.cylinder(radius: 0.0032, height: 0.010, bevel: 0.001, segments: 10, material: "metal.stainless"), V3(0, -0.095, -0.0245))
        place(Prim.torus(major: 0.0155, minor: 0.0009, segments: 20, sides: 5, material: "plastic.matte:2A2A2C"), V3(0, -0.2175, 0))
        // Mount: central post, altaz head block and a pan handle with knob.
        m.add(Prim.cylinder(radius: 0.014, height: 0.09, bevel: 0.002, segments: 18, material: steel), Xform(translation: V3(0, 0.13, 0)))
        m.add(Prim.roundedBox(V3(0.075, 0.035, 0.05), radius: 0.006, bevelSegments: 2, material: black), Xform(translation: V3(0, pivot.y - 0.002, 0)))
        m.add(Prim.tube([V3(0.0375, pivot.y - 0.01, 0), V3(0.058, pivot.y - 0.03, 0.01)], radii: [0.004, 0.004], sides: 8, seamTile: 0.04, material: steel), Xform())
        m.add(Prim.superellipsoid(V3(0.02, 0.02, 0.02), exponent: 2, subdivisions: 8, material: "plastic.matte:222426"), Xform(translation: V3(0.066, pivot.y - 0.031, 0.01)))
        // Tripod: three splayed legs to rubber feet, with a leg bracket collar.
        for k in 0..<3 {
            let a = Float.pi * 2 * Float(k) / 3 + Float.pi / 2
            let foot = V3(0.065 * cos(a), 0.0, 0.065 * sin(a)), top = V3(0.016 * cos(a), 0.14, 0.016 * sin(a))
            m.add(Prim.tube([foot + V3(0, 0.01, 0), top], radii: [0.0085, 0.0085], sides: 12, seamTile: 0.05, material: steel), Xform())
            m.add(Prim.cylinder(radius: 0.0105, height: 0.012, bevel: 0.003, segments: 12, material: "plastic.matte:1A1A1A"), Xform(translation: foot))
        }
        m.add(Prim.cylinder(radius: 0.026, height: 0.014, bevel: 0.003, segments: 20, material: black), Xform(translation: V3(0, 0.12, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
