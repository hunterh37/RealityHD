import simd
import Foundation

/// School Chair: everyday school, plastic. Parts: molded seat shell, molded back shell, steel tube legs, cross stretchers, back posts, rubber feet.
public struct SchoolChair: RealAsset {
    public static let id = "school-chair"
    public static let summary = "Stacking classroom chair with molded plastic seat and back on a steel tube frame."
    public static let tags = ["prop", "interior", "school", "plastic", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.4, 0.8, 0.42)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let frame = "metal.powdercoat:3A3F45", shell = "plastic.matte:2E6FB5"
        func rod(_ pts: [V3], _ r: Float = 0.0105) {
            m.add(Prim.tube(pts, radii: Array(repeating: r, count: pts.count), sides: 10, seamTile: 0.05, material: frame), Xform())
        }
        let seatY: Float = 0.44, lx = W / 2 - 0.045, fz = D / 2 - 0.04, rz = -D / 2 + 0.06
        // Molded seat shell: soft-edged slab with a slight dish and a rolled front edge.
        m.add(Prim.superellipsoid(V3(W, 0.03, D), exponent: 5, subdivisions: 14, material: shell), Xform(translation: V3(0, seatY + 0.012, 0.0)))
        m.add(Prim.superellipsoid(V3(W - 0.07, 0.006, D - 0.08), exponent: 5, subdivisions: 12, material: "plastic.matte:2860A0"), Xform(translation: V3(0, seatY + 0.0285, 0.005)))
        // Back shell: tilted 8 degrees, wider at the top, carried by two posts.
        let backY: Float = 0.64
        m.add(Prim.superellipsoid(V3(W - 0.02, 0.22, 0.024), exponent: 6, subdivisions: 12, material: shell),
              Xform(translation: V3(0, backY + 0.03, rz - 0.02), rotation: simd_quatf(degrees: -8, axis: V3(1, 0, 0))))
        for sx: Float in [-1, 1] {
            // Rear leg continues up into a back post; front leg is straight with a slight splay.
            rod([V3(sx * (lx + 0.02), 0.012, rz - 0.035), V3(sx * lx, seatY - 0.01, rz), V3(sx * (lx - 0.01), seatY + 0.12, rz - 0.015), V3(sx * (lx - 0.015), backY + 0.01, rz - 0.04)])
            rod([V3(sx * (lx + 0.02), 0.012, fz + 0.035), V3(sx * lx, seatY - 0.01, fz)])
            rod([V3(sx * lx, 0.11, rz - 0.01), V3(sx * lx, 0.11, fz + 0.01)], 0.009)
            for z in [rz - 0.035, fz + 0.035] {
                m.add(Prim.cylinder(radius: 0.0135, height: 0.012, bevel: 0.003, segments: 14, material: "plastic.matte:1E1E1E"), Xform(translation: V3(sx * (lx + 0.02), 0, z)))
            }
        }
        rod([V3(-lx, seatY - 0.02, fz), V3(lx, seatY - 0.02, fz)], 0.009)
        rod([V3(-lx, seatY - 0.02, rz), V3(lx, seatY - 0.02, rz)], 0.009)
        // Bolts under the seat and on the back posts.
        for sx: Float in [-1, 1] { for z in [fz, rz] {
            m.add(Prim.cylinder(radius: 0.005, height: 0.003, bevel: 0.0008, segments: 8, material: "metal.screw-zinc"), Xform(translation: V3(sx * lx, seatY - 0.0135, z)))
        } }
        groundAO(&m)
        return LODModel(m)
    }
}
