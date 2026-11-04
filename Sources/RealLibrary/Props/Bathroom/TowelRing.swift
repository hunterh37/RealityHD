import simd
import Foundation

/// Towel ring: everyday bathroom, chrome. Parts: round wall plate, post arm, open ring hoop, mounting screw caps.
public struct TowelRing: RealAsset {
    public static let id = "towel-ring"
    public static let summary = "Wall-mounted chrome towel ring: round escutcheon plate, short post, open torus hoop."
    public static let tags = ["prop", "interior", "bathroom", "metal"]
    public static let budget = 4000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.18, 0.18, 0.07)
    public init() {}

    public var chrome: MaterialKey = "metal.chrome"
    public var tubeRadius: Float = 0.0075

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let wall = -size.z / 2
        let outer = size.x / 2
        let major = outer - tubeRadius
        let cy = size.y - outer
        let postY = cy + major - tubeRadius - 0.0065
        let ringZ: Float = 0.02
        // Round escutcheon plate, 3 mm thick with a rolled edge.
        m.add(Prim.lathe([V2(0.001, 0.0), V2(0.0205, 0.0), V2(0.0212, 0.0012), V2(0.021, 0.0035), V2(0.0185, 0.0058), V2(0.012, 0.0062), V2(0.001, 0.0062)],
                         segments: 36, seamTile: 0.1, material: chrome),
              Xform(translation: V3(0, postY, wall), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Post from the plate to a domed end cap.
        m.add(Prim.lathe([V2(0.001, 0.0), V2(0.0085, 0.0), V2(0.0065, 0.004), V2(0.0065, 0.0555), V2(0.0058, 0.0625), V2(0.0035, 0.0655), V2(0.001, 0.0662)],
                         segments: 20, seamTile: 0.05, material: chrome),
              Xform(translation: V3(0, postY, wall + 0.004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Open hoop hanging on the post, plane parallel to the wall.
        m.add(Prim.torus(major: major, minor: tubeRadius, segments: 72, sides: 16, material: chrome),
              Xform(translation: V3(0, cy, ringZ), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Dark chrome seam where the hoop ends meet, hidden at the bottom.
        m.add(Prim.cylinder(radius: tubeRadius + 0.0008, height: 0.006, bevel: 0.0006, segments: 14, material: "metal.stainless"),
              Xform(translation: V3(0, cy - major, ringZ), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        groundAO(&m)
        return LODModel(m)
    }
}
