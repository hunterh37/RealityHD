import simd
import Foundation

/// School Desk: everyday school, laminate and steel. Parts: laminate top with edge band, steel tube frame, book rack, inkwell hole, pencil groove, rubber glides.
public struct SchoolDesk: RealAsset {
    public static let id = "school-desk"
    public static let summary = "Classroom desk with a laminate top, tube frame and under-top book rack."
    public static let tags = ["prop", "interior", "school", "wood", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 0.75, 0.45)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let frame = "metal.powdercoat:3A3F45", topT: Float = 0.022
        func rod(_ a: V3, _ b: V3, _ r: Float = 0.0125) {
            m.add(Prim.tube([a, b], radii: [r, r], sides: 12, seamTile: 0.05, material: frame), Xform())
        }
        // Laminate top with PVC edge band and a slightly cambered work surface.
        m.add(Prim.roundedBox(V3(W, topT, D), radius: 0.004, bevelSegments: 2, material: "wood.veneer-oak"), Xform(translation: V3(0, H - topT / 2, 0)))
        m.add(Prim.roundedBox(V3(W + 0.001, 0.004, D + 0.001), radius: 0.002, bevelSegments: 1, material: "plastic.matte:2A2A2A"), Xform(translation: V3(0, H - topT + 0.002, 0)))
        // Pencil groove at the back edge and an inkwell hole at the top right.
        m.add(Prim.roundedBox(V3(W * 0.7, 0.0008, 0.016), radius: 0.0003, bevelSegments: 1, material: "plastic.matte:6B5B45"), Xform(translation: V3(0, H + 0.0003, -D / 2 + 0.035)))
        m.add(Prim.cylinder(radius: 0.017, height: 0.0008, bevel: 0, segments: 20, material: "plastic.matte:1A1A1A"), Xform(translation: V3(W / 2 - 0.055, H + 0.0002, -D / 2 + 0.06)))
        // Tube frame: four legs, side rails, a back stretcher and ball-end corner joints.
        let lx = W / 2 - 0.045, lz = D / 2 - 0.04, yb: Float = 0.012, yt = H - topT - 0.01
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                rod(V3(sx * lx, yb, sz * lz), V3(sx * lx, yt, sz * lz))
                m.add(Prim.cylinder(radius: 0.016, height: 0.014, bevel: 0.003, segments: 14, material: "plastic.matte:1E1E1E"), Xform(translation: V3(sx * lx, 0, sz * lz)))
                m.add(Prim.superellipsoid(V3(0.028, 0.028, 0.028), exponent: 2, subdivisions: 8, material: frame), Xform(translation: V3(sx * lx, yt, sz * lz)))
            }
            rod(V3(sx * lx, 0.06, -lz), V3(sx * lx, 0.06, lz))
            rod(V3(sx * lx, yt, -lz), V3(sx * lx, yt, lz))
        }
        rod(V3(-lx, 0.06, -lz), V3(lx, 0.06, -lz))
        rod(V3(-lx, yt, -lz), V3(lx, yt, -lz))
        // Under-top book rack: steel sheet with a front lip and two end walls.
        let rackY = H - topT - 0.16
        m.add(Prim.roundedBox(V3(2 * lx - 0.03, 0.002, 2 * lz - 0.03), radius: 0.0008, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(0, rackY, 0)))
        m.add(Prim.roundedBox(V3(2 * lx - 0.03, 0.05, 0.002), radius: 0.0008, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(0, rackY + 0.025, lz - 0.015)))
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.002, 0.05, 2 * lz - 0.03), radius: 0.0008, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(s * (lx - 0.015), rackY + 0.025, 0)))
        }
        // Story detail: a worn patch where forearms rest and a scratched initial line.
        m.add(Prim.roundedBox(V3(0.2, 0.0004, 0.12), radius: 0.0002, bevelSegments: 1, material: "wood.veneer-oak:D2BC96"), Xform(translation: V3(-0.05, H + 0.0002, 0.09)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
