import simd
import Foundation

/// Colored Pencil Tin: everyday school, wood. Parts: painted steel tin, twelve hex pencils, sharpened tips, lead points, tin rim.
public struct ColoredPencilTin: RealAsset {
    public static let id = "colored-pencil-tin"
    public static let summary = "Open flat tin holding twelve sharpened colored pencils in a row."
    public static let tags = ["prop", "interior", "school", "wood", "metal"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.2, 0.02, 0.1)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, wall: Float = 0.0015, H: Float = 0.0185
        let tin = "metal.painted:2E6B4F"
        m.add(Prim.roundedBox(V3(W, 0.0012, D), radius: 0.0004, bevelSegments: 1, material: tin), Xform(translation: V3(0, 0.0006, 0)))
        m.add(Prim.roundedBox(V3(W - 2 * wall, 0.0004, D - 2 * wall), radius: 0.0001, bevelSegments: 1, material: "metal.painted:C9C4B2"),
              Xform(translation: V3(0, 0.0013, 0)))
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(W, H, wall), radius: 0.0006, bevelSegments: 2, material: tin), Xform(translation: V3(0, H / 2, s * (D / 2 - wall / 2))))
            m.add(Prim.roundedBox(V3(wall, H, D), radius: 0.0006, bevelSegments: 2, material: tin), Xform(translation: V3(s * (W / 2 - wall / 2), H / 2, 0)))
        }
        // Paper label on the front wall.
        m.add(Prim.roundedBox(V3(0.07, 0.009, 0.0004), radius: 0.0001, bevelSegments: 1, material: "paper.sheet"),
              Xform(translation: V3(0, 0.0095, D / 2 + 0.0001)))
        // Twelve hexagonal pencils lying along X, tips toward +X at staggered lengths.
        let colors: [UInt32] = [0xD8321E, 0xF08A1C, 0xF6C21A, 0x9BC53D, 0x3C9B4A, 0x1F8A70, 0x2E8FC9, 0x2B4CA8, 0x5B3E8F, 0xB8317A, 0x6B4A2B, 0x2A2A2A]
        let r: Float = 0.0036
        for (k, c) in colors.enumerated() {
            let z = (Float(k) - 5.5) * 0.0076
            let body = rng.float(0.168...0.178)
            let pxf = Xform(translation: V3(-0.095, 0.0015 + r, z), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1)))
            m.add(Prim.cylinder(radius: r, height: body, bevel: 0.0003, segments: 6,
                                material: "plastic.pencil-lacquer:" + String(c, radix: 16, uppercase: true)), Xform().then(pxf))
            m.add(Prim.lathe([V2(0.0033, 0), V2(0.00095, 0.008)], segments: 12, seamTile: 0.02, material: "wood.pencil-cedar"),
                  Xform(translation: V3(0, body, 0)).then(pxf))
            m.add(Prim.lathe([V2(0.00095, 0), V2(0.0001, 0.0026)], segments: 10, seamTile: 0.02, material: "plastic.matte:" + String(c, radix: 16, uppercase: true)),
                  Xform(translation: V3(0, body + 0.008, 0)).then(pxf))
            // Ferrule-free flat end cap stamp.
            m.add(Prim.cylinder(radius: r * 0.7, height: 0.0002, bevel: 0, segments: 6, material: "metal.aluminum-brushed"),
                  Xform(translation: V3(0, -0.0001, 0)).then(pxf))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
