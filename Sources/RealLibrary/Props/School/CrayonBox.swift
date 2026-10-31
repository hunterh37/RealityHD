import simd
import Foundation

/// Crayon Box: everyday school, wax. Parts: cardboard tray, hinged lid standing open, two rows of wax crayons, paper wrappers, tip cones.
public struct CrayonBox: RealAsset {
    public static let id = "crayon-box"
    public static let summary = "Cardboard crayon box with the lid open over two rows of wrapped wax crayons."
    public static let tags = ["prop", "interior", "school", "wax", "paper"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.12, 0.04, 0.09)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z, wall: Float = 0.0012, wallH: Float = 0.020
        let card = "paper.sheet:E9B81E"
        // Tray: floor plus four walls.
        m.add(Prim.roundedBox(V3(W, 0.0012, D), radius: 0.0004, bevelSegments: 1, material: card), Xform(translation: V3(0, 0.0006, 0)))
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(W, wallH, wall), radius: 0.0004, bevelSegments: 1, material: card), Xform(translation: V3(0, wallH / 2, s * (D / 2 - wall / 2))))
            m.add(Prim.roundedBox(V3(wall, wallH, D), radius: 0.0004, bevelSegments: 1, material: card), Xform(translation: V3(s * (W / 2 - wall / 2), wallH / 2, 0)))
        }
        // Lid hinged open: stands at the back, 40 mm tall, with a green printed panel inside and a red band.
        m.add(Prim.roundedBox(V3(W, H, wall), radius: 0.0004, bevelSegments: 1, material: card), Xform(translation: V3(0, H / 2, -D / 2 - wall / 2 - 0.0004)))
        m.add(Prim.roundedBox(V3(W * 0.86, H * 0.5, 0.0004), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:1F7A3E"),
              Xform(translation: V3(0, H * 0.55, -D / 2 + 0.0001 - 0.0004)))
        m.add(Prim.roundedBox(V3(W * 0.86, H * 0.12, 0.0004), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:C8281E"),
              Xform(translation: V3(0, H * 0.17, -D / 2 + 0.0001 - 0.0004)))
        // Two layers of wrapped crayons lying along Z: 12 in the lower row, 11 nested in the upper row, tips toward +Z.
        let colors: [UInt32] = [0xD8281E, 0xF08A1C, 0xF6C21A, 0xE8D83A, 0x9BC53D, 0x3C9B4A, 0x1F8A70, 0x2E8FC9, 0x2B4CA8, 0x5B3E8F, 0xB8317A, 0x7A4A2B]
        let r: Float = 0.0043, pitch: Float = 0.0092
        for layer in 0..<2 {
            let n = layer == 0 ? 12 : 11
            for k in 0..<n {
                let c = colors[(k + layer * 5) % colors.count]
                let hex = String(c, radix: 16, uppercase: true)
                let x = (Float(k) - Float(n - 1) / 2) * pitch
                let y: Float = 0.0012 + r + (layer == 1 ? 0.0079 : 0)
                let body = rng.float(0.068...0.074)
                let z0 = -D / 2 + wall + 0.001
                // Local frame along +Y; rotate +90 about X so +Y points to +Z.
                let pxf = Xform(translation: V3(x, y, z0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
                m.add(Prim.cylinder(radius: r, height: body, bevel: 0.0003, segments: 12, material: "paper.sheet:" + hex), Xform().then(pxf))
                // Dark printed band at the wrapper ends and a brand-free text stripe.
                m.add(Prim.cylinder(radius: r + 0.00005, height: 0.0035, bevel: 0, segments: 12, material: "plastic.matte:" + hex),
                      Xform(translation: V3(0, body * 0.45, 0)).then(pxf))
                m.add(Prim.lathe([V2(r, 0), V2(0.0014, 0.0075), V2(0.0006, 0.0098)], segments: 12, seamTile: 0.02, material: "plastic.matte:" + hex),
                      Xform(translation: V3(0, body, 0)).then(pxf))
            }
        }
        groundAO(&m)
        return LODModel(m)
    }
}
