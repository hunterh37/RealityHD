import simd
import Foundation

/// Glue Stick: everyday school, plastic. Parts: plastic tube body, printed label band, twist knob base, ribbed cap, dome top.
public struct GlueStick: RealAsset {
    public static let id = "glue-stick"
    public static let summary = "Glue stick with a printed label band, ribbed cap and twist base."
    public static let tags = ["prop", "interior", "school", "plastic"]
    public static let budget = 13000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.03, 0.09, 0.03)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let R: Float = 0.0142
        // Twist knob base (darker), tube body, printed label band, translucent ribbed cap with a domed top.
        m.add(Prim.cylinder(radius: 0.0128, height: 0.008, bevel: 0.0008, segments: 32, material: "plastic.matte:2A4FA0"), Xform())
        m.add(Prim.cylinder(radius: R, height: 0.064, bevel: 0.0008, segments: 24, material: "plastic.matte:F3F1EA"), Xform(translation: V3(0, 0.008, 0)))
        m.add(Prim.cylinder(radius: R + 0.0002, height: 0.040, bevel: 0.0003, segments: 24, material: "plastic.matte:2A4FA0"), Xform(translation: V3(0, 0.016, 0)))
        // Label art: two thin red edge stripes, a white oval badge on the front with a blue bar and red mark, back barcode-free text bars.
        for y: Float in [0.0165, 0.0535] {
            m.add(Prim.cylinder(radius: R + 0.0004, height: 0.0014, bevel: 0.0001, segments: 24, material: "plastic.matte:E2342A"), Xform(translation: V3(0, y, 0)))
        }
        m.add(Prim.superellipsoid(V3(0.016, 0.019, 0.0010), exponent: 2, subdivisions: 12, material: "plastic.matte:F3F1EA"), Xform(translation: V3(0, 0.036, R + 0.0003)))
        m.add(Prim.roundedBox(V3(0.012, 0.0036, 0.0006), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:2A4FA0"), Xform(translation: V3(0, 0.0395, R + 0.0013)))
        m.add(Prim.roundedBox(V3(0.008, 0.0024, 0.0006), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:E2342A"), Xform(translation: V3(0, 0.0335, R + 0.0013)))
        for k in 0..<3 {
            m.add(Prim.roundedBox(V3(0.016 - Float(k) * 0.003, 0.0014, 0.0006), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:F3F1EA"),
                  Xform(translation: V3(0, 0.0235 - Float(k) * 0.0028, R + 0.0004)))
        }
        // Grip ribs around the twist knob and a scuff on the cap.
        for k in 0..<18 {
            let a = Float.pi * 2 * Float(k) / 18
            m.add(Prim.roundedBox(V3(0.0012, 0.0062, 0.0010), radius: 0.0003, bevelSegments: 1, material: "plastic.matte:213E80"),
                  Xform(translation: V3(0.0131 * cos(a), 0.004, 0.0131 * sin(a)), rotation: simd_quatf(degrees: -a * 180 / .pi, axis: V3(0, 1, 0))))
        }
        m.add(Prim.roundedBox(V3(0.0007, 0.006, 0.0004), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:9AA3AB"),
              Xform(translation: V3(0.0105, 0.082, 0.0105), rotation: simd_quatf(degrees: -45, axis: V3(0, 1, 0))))
        // Cap seated over the top of the tube.
        m.add(Prim.cylinder(radius: 0.0150, height: 0.025, bevel: 0.0012, segments: 24, material: "plastic.gloss:CDBFEA"), Xform(translation: V3(0, 0.0655, 0)))
        for k in 0..<3 {
            m.add(Prim.torus(major: 0.0150, minor: 0.0004, segments: 24, sides: 6, material: "plastic.gloss:CDBFEA"),
                  Xform(translation: V3(0, 0.072 + Float(k) * 0.0042, 0)))
        }
        // Visible glue through the translucent cap top: a pale dome.
        m.add(Prim.superellipsoid(V3(0.0240, 0.012, 0.0240), exponent: 2, subdivisions: 16, material: "plastic.matte:8B5FBF"),
              Xform(translation: V3(0, 0.0705, 0)))
        // Seam where the cap meets the tube.
        m.add(Prim.torus(major: 0.0146, minor: 0.0003, segments: 24, sides: 6, material: "plastic.matte:3A3A3A"), Xform(translation: V3(0, 0.0645, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
