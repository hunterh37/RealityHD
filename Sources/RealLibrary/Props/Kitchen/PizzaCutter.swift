import simd
import Foundation

/// Pizza wheel lying flat: stamped stainless handle with a loop for the fingers, riveted fork and thumb guard holding a 7.6 cm wheel on a domed axle rivet. Story: dried cheese and sauce on the blade.
public struct PizzaCutter: RealAsset {
    public static let id = "pizza-cutter"
    public static let summary = "Pizza wheel, 20 cm, lying flat: stamped stainless handle, riveted fork holding a 7 cm wheel."
    public static let tags = ["prop", "interior", "kitchen", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 55, distance: 1.15, studio: true)

    /// Wheel radius (m).
    public var wheelRadius: Float = 0.038
    /// Handle and fork steel.
    public var handle: MaterialKey = "metal.brushed-nickel"
    /// Wheel blade steel.
    public var blade: MaterialKey = "metal.satin-aluminum"
    /// Rivets and washers.
    public var hardware: MaterialKey = "metal.nickel-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let zc: Float = -0.062                    // axle position along the length
        let flat = simd_quatf(degrees: 90, axis: V3(1, 0, 0))   // XY outline -> XZ plane
        // Wheel: dished disc with a sharpened rim and a stamped ring.
        let r = wheelRadius
        let wp: [V2] = [V2(0, 0.0011), V2(0.009, 0.0011), V2(0.013, 0.0014), V2(0.014, 0.0017), V2(r - 0.008, 0.0017), V2(r - 0.0015, 0.0020), V2(r, 0.0022),
                        V2(r - 0.0015, 0.0024), V2(r - 0.008, 0.0027), V2(0.016, 0.0027), V2(0.0145, 0.0030), V2(0.0135, 0.0032), V2(0.009, 0.0033), V2(0, 0.0033)]
        m.add(Prim.lathe(wp, segments: 96, seamTile: 0.05, material: blade), Xform(translation: V3(0, 0, zc)))
        // Lower washer and axle rivet through the hub.
        m.add(Prim.cylinder(radius: 0.0075, height: 0.0011, bevel: 0.0003, segments: 20, material: hardware), Xform(translation: V3(0, 0, zc)))
        m.add(Prim.cylinder(radius: 0.0030, height: 0.0075, bevel: 0.0003, segments: 12, material: hardware), Xform(translation: V3(0, 0.001, zc)))
        // Fork boss over the wheel hub.
        m.add(Prim.cylinder(radius: 0.0100, height: 0.0034, bevel: 0.0010, segments: 28, material: handle), Xform(translation: V3(0, 0.0042, zc)))
        // Handle bar (tapering) with a spring-formed neck.
        let bar = Shape2D.rounded([V2(-0.0075, zc), V2(0.0075, zc), V2(0.0055, 0.045), V2(-0.0055, 0.045)], radius: 0.0018)
        m.add(Prim.extrude(bar, depth: 0.0050, bevel: 0.0009, bevelSegments: 2, material: handle), Xform(translation: V3(0, 0.0052, 0), rotation: flat))
        // Finger loop: flat stamped band bent into an oval.
        let loop: [V3] = (0..<40).map { i in
            let a = Float(i) / 40 * 2 * .pi
            return V3(0.0200 * cos(a), 0.0052, 0.070 + 0.0300 * sin(a))
        }
        m.add(Prim.sweep(Shape2D.roundedRect(0.0050, 0.0062, radius: 0.0012), along: loop, up: .up, closedPath: true, caps: false, material: handle))
        // Thumb guard: stamped arc rising around the handle side of the hub.
        m.add(Prim.torus(major: 0.0225, minor: 0.0018, segments: 24, sides: 8, arc: .pi * 0.55, minorY: 0.0034, material: handle),
              Xform(translation: V3(0, 0.0062, zc), rotation: DD1EKitchen.rotY(-143)))
        // Domed rivet heads: axle and two on the handle bar.
        rivet(&m, at: V3(0, 0.0072, zc), normal: .up, radius: 0.0042, height: 0.0030, segments: 14, material: hardware)
        for z: Float in [zc + 0.032, zc + 0.062] { rivet(&m, at: V3(0, 0.0077, z), normal: .up, radius: 0.0026, height: 0.0020, segments: 10, material: hardware) }
        // Dried cheese and sauce on the blade.
        m.add(Prim.superellipsoid(V3(0.0090, 0.0010, 0.0045), exponent: 2.4, subdivisions: 6, material: "food.cheese-melted"),
              Xform(translation: V3(0.0285, 0.0030, zc + 0.012), rotation: simd_quatf(degrees: -30, axis: .up)))
        m.add(Prim.superellipsoid(V3(0.0060, 0.0008, 0.0040), exponent: 2.4, subdivisions: 6, material: "food.tomato-sauce"),
              Xform(translation: V3(-0.0220, 0.0030, zc - 0.026), rotation: simd_quatf(degrees: 40, axis: .up)))
        m.add(Prim.superellipsoid(V3(0.0050, 0.0008, 0.0030), exponent: 2.4, subdivisions: 6, material: "food.cheese-melted"),
              Xform(translation: V3(0.0110, 0.0030, zc - 0.0300), rotation: simd_quatf(degrees: 70, axis: .up)))
        _ = rng.float()
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.006, floor: 0.75)
        return LODModel(m)
    }
}
