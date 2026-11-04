import simd
import Foundation

/// Drawing Compass: everyday school, steel. Parts: two tubular legs, hinge head, knurled top knob, needle point, pencil holder with lead, hinge pin.
public struct CompassDrawing: RealAsset {
    public static let id = "compass-drawing"
    public static let summary = "Drawing compass with a needle leg, pencil leg, hinge head and knurled top knob."
    public static let tags = ["prop", "interior", "school", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.03, 0.13, 0.02)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let steel = "metal.nickel", hy: Float = 0.1135
        func leg(_ pts: [V3], _ radii: [Float]) { m.add(Prim.tube(pts, radii: radii, sides: 10, seamTile: 0.03, material: steel), Xform()) }
        // Needle leg (left): tapered tube ending in a removable steel needle.
        leg([V3(-0.0015, hy, 0), V3(-0.0075, 0.06, 0), V3(-0.011, 0.012, 0)], [0.0026, 0.0023, 0.0020])
        m.add(Prim.lathe([V2(0.0020, 0), V2(0.0006, 0.010), V2(0.0001, 0.0125)], segments: 10, seamTile: 0.02, material: "metal.steel"),
              Xform(translation: V3(-0.0112, 0.0, 0), rotation: simd_quatf(degrees: 3, axis: V3(0, 0, 1))).then(Xform(translation: V3(0, 0.0, 0))))
        // Pencil leg (right): tube to a clamp collar holding a short pencil lead.
        leg([V3(0.0015, hy, 0), V3(0.0075, 0.062, 0), V3(0.0112, 0.030, 0)], [0.0026, 0.0023, 0.0020])
        m.add(Prim.cylinder(radius: 0.0036, height: 0.016, bevel: 0.0006, segments: 12, material: steel), Xform(translation: V3(0.0116, 0.016, 0), rotation: simd_quatf(degrees: -2, axis: V3(0, 0, 1))))
        m.add(Prim.lathe([V2(0.0012, 0), V2(0.0010, 0.006), V2(0.0001, 0.0085)], segments: 8, seamTile: 0.02, material: "plastic.matte:2A2A2A"),
              Xform(translation: V3(0.0118, 0.0, 0)))
        m.add(Prim.cylinder(radius: 0.0015, height: 0.010, bevel: 0.0003, segments: 8, material: "plastic.matte:2A2A2A"), Xform(translation: V3(0.0118, 0.008, 0)))
        m.add(Prim.cylinder(radius: 0.0018, height: 0.003, bevel: 0.0005, segments: 8, material: "metal.steel"), Xform(translation: V3(0.0116, 0.0165, 0.0036)))
        // Hinge head: cylinder across Z with two cheek plates and a pin head each side.
        m.add(Prim.cylinder(radius: 0.0045, height: 0.0165, bevel: 0.0008, segments: 20, material: "metal.chrome"),
              Xform(translation: V3(0, hy, -0.00825), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        for s: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.0030, height: 0.0016, bevel: 0.0005, segments: 12, material: "metal.steel"),
                  Xform(translation: V3(0, hy, s * 0.0083 - (s > 0 ? 0 : 0.0016)), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Stem and knurled top knob.
        m.add(Prim.cylinder(radius: 0.0018, height: 0.008, bevel: 0.0003, segments: 10, material: steel), Xform(translation: V3(0, hy + 0.003, 0)))
        m.add(Prim.cylinder(radius: 0.0058, height: 0.0095, bevel: 0.0008, segments: 24, material: "metal.chrome"), Xform(translation: V3(0, 0.1205, 0)))
        for k in 0..<24 {
            let a = Float.pi * 2 * Float(k) / 24
            m.add(Prim.roundedBox(V3(0.0006, 0.0075, 0.0006), radius: 0.0002, bevelSegments: 1, material: "metal.steel"),
                  Xform(translation: V3(0.0059 * cos(a), 0.1252, 0.0059 * sin(a))))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
