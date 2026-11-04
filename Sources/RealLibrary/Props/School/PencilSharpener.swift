import simd
import Foundation

/// Pencil Sharpener: everyday school, metal. Parts: magnesium wedge body, steel blade, blade screw, conical bore, blade slot.
public struct PencilSharpener: RealAsset {
    public static let id = "pencil-sharpener"
    public static let summary = "Single-hole pencil sharpener with a magnesium body, steel blade and screw."
    public static let tags = ["prop", "interior", "school", "metal"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.03, 0.02, 0.03)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, bodyH: Float = 0.0195
        let steelC = "metal.magnesium-worn"
        // Magnesium wedge body: side profile (front 13.5 mm, back 17.2 mm) extruded across the width, corners filleted.
        let fh: Float = 0.0155
        let prof = Shape2D.rounded([V2(-D / 2, 0), V2(D / 2, 0), V2(D / 2, bodyH), V2(-D / 2, fh)], radius: 0.0022, segments: 3)
        m.add(Prim.extrude(prof, depth: W, bevel: 0.0018, bevelSegments: 3, material: steelC),
              Xform(rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
        // Steel blade: thin plate tilted 18 degrees on the top face, held by a slotted screw.
        let tilt = Xform(translation: V3(0.0, 0.0178 + 0.0004, -0.002), rotation: simd_quatf(degrees: 7, axis: V3(1, 0, 0)))
        m.add(Prim.roundedBox(V3(0.012, 0.0007, 0.016), radius: 0.0002, bevelSegments: 1, material: "metal.steel"), tilt)
        m.add(Prim.roundedBox(V3(0.0036, 0.0002, 0.0008), radius: 0, bevelSegments: 1, material: "metal.steel"), tilt)
        m.add(Prim.cylinder(radius: 0.0017, height: 0.0010, bevel: 0.0003, segments: 14, material: "metal.screw-zinc"),
              Xform(translation: V3(0, 0.0003, 0.0035)).then(tilt))
        m.add(Prim.roundedBox(V3(0.0026, 0.0003, 0.0004), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:101010"),
              Xform(translation: V3(0, 0.0013, 0.0035)).then(tilt))
        // Conical bore on the front face: dark disc inside a steel ring.
        let face = Xform(translation: V3(0, 0.0076, D / 2), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        m.add(Prim.cylinder(radius: 0.0048, height: 0.0003, bevel: 0, segments: 20, material: "plastic.matte:0C0C0C"),
              Xform(translation: V3(0, -0.0001, 0)).then(face))
        m.add(Prim.torus(major: 0.0051, minor: 0.0006, segments: 24, sides: 8, material: "metal.steel"), face)
        // Side seam line and a worn corner as a lighter patch.
        m.add(Prim.roundedBox(V3(0.0003, 0.0008, D * 0.8), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:3A3A3A"),
              Xform(translation: V3(W / 2 + 0.00005, bodyH * 0.5, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
