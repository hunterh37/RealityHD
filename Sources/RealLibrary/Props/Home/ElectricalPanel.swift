import simd
import Foundation

/// Electrical panel: Residential 200 A load center, grey enamel, slightly dusty.. Parts: grey sheet-steel enclosure with trim cover, breaker window with two columns of toggle breakers and a main breaker, lower hinged door with circuit directory card and hinges, latch and cover screws, EMT conduit stubs with locknuts on top, cable connectors on the bottom, warning label.
public struct ElectricalPanel: RealAsset {
    public static let id = "electrical-panel"
    public static let summary = "Wall-mounted residential breaker panel: grey enclosure and trim, two columns of toggle breakers, main breaker, hinged directory door, conduit stubs."
    public static let tags = ["prop", "floorplan", "home", "electrical", "metal", "wall", "interior"]
    public static let budget = 6500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Back face at z = -depth / 2, lowest point at y = 0.
    public var size = V3(0.4, 0.65, 0.1)
    /// Enclosure enamel color.
    public var enclosureColor: UInt32 = 0xBFC1C2
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    private func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let enc = String(format: "metal.powdercoat:%06X", enclosureColor)
        let zb = -size.z / 2   // back face
        func along(_ dir: V3) -> simd_quatf { simd_quatf(from: V3(0, 1, 0), to: dir.normalized) }
        func cyl(_ r: Float, _ h: Float, _ mat: MaterialKey, at: V3, dir: V3 = V3(0, 1, 0), seg: Int = 12, bevel: Float = 0.0008) {
            m.add(Prim.cylinder(radius: r, height: h, bevel: bevel, segments: lite ? max(6, seg / 2) : seg, bevelSegments: 1, material: mat), Xform(translation: at, rotation: along(dir)))
        }
        func box(_ s: V3, _ r: Float, _ mat: MaterialKey, at: V3) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: at))
        }
        func sbox(_ s: V3, _ mat: MaterialKey, at: V3) { m.add(cuboid(s, material: mat), Xform(translation: at)) }
        func hexNut(_ at: V3, r: Float, h: Float, mat: MaterialKey) {
            let hex = Shape2D.rounded(Shape2D.polygon(sides: 6, radius: r), radius: r * 0.08, segments: 1)
            m.add(Prim.extrude(hex, depth: h, bevel: 0.0005, bevelSegments: 1, material: mat), Xform(translation: at, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        let yb: Float = 0.03, yt: Float = 0.62    // enclosure bottom and top
        let zFront: Float = 0.025                  // front plane of the can
        // Can (back box).
        box(V3(0.4, yt - yb, zFront - zb), 0.004, enc, at: V3(0, (yt + yb) / 2, (zFront + zb) / 2))
        // Trim cover: top bar, side bars, rail above the door.
        let tz = zFront + 0.006 - 0.0005
        box(V3(0.4, 0.027, 0.012), 0.002, enc, at: V3(0, yt - 0.0135, tz))
        for sx in [Float(-1), 1] { box(V3(0.07, yt - yb, 0.012), 0.002, enc, at: V3(sx * 0.165, (yt + yb) / 2, tz)) }
        box(V3(0.4, 0.02, 0.012), 0.002, enc, at: V3(0, 0.295, tz))
        // Dead-front pan, bus strip.
        box(V3(0.27, 0.3, 0.004), 0.001, "metal.painted:6E7074", at: V3(0, 0.447, 0.012))
        sbox(V3(0.014, 0.29, 0.006), "metal.brass-aged", at: V3(0, 0.447, 0.016))
        // Breakers: main on top, 9 rows by 2 columns.
        let bodyMats: [MaterialKey] = ["plastic.matte:2B2B2D", "plastic.matte:2B2B2D", "plastic.matte:2B2B2D", "plastic.white", "plastic.orange"]
        box(V3(0.11, 0.034, 0.024), 0.002, "plastic.matte:2B2B2D", at: V3(0, 0.575, 0.024))
        sbox(V3(0.09, 0.012, 0.012), "plastic.matte:1A1A1B", at: V3(0, 0.575, 0.04))
        sbox(V3(0.09, 0.004, 0.002), "plastic.white", at: V3(0, 0.592, 0.037))
        for col in 0..<2 {
            let x: Float = (col == 0 ? -1 : 1) * 0.0625
            for k in 0..<(lite ? 5 : 9) {
                let pitch: Float = lite ? 0.0495 : 0.0275
                let y = 0.322 + Float(k) * pitch
                let body = lite ? bodyMats[0] : bodyMats[rng.int(0...4) < 3 ? 0 : (rng.chance(0.5) ? 3 : 4)]
                let on = rng.chance(0.85)
                box(V3(0.05, pitch - 0.003, 0.022), 0.0015, body, at: V3(x, y, 0.023))
                if !lite {
                    sbox(V3(0.016, 0.009, 0.012), body, at: V3(x + (col == 0 ? 0.01 : -0.01), y + (on ? 0.003 : -0.003), 0.037))
                    sbox(V3(0.04, 0.0015, 0.001), "plastic.white", at: V3(x, y - 0.0105, 0.0345))
                }
            }
        }
        // Lower flip door with hinges, latch, directory card.
        do {
            let outline = Shape2D.rounded([V2(-0.19, 0), V2(0.19, 0), V2(0.19, 0.25), V2(-0.19, 0.25)], radius: 0.006)
            m.add(Prim.extrude(outline, depth: 0.007, bevel: 0.0015, bevelSegments: 1, material: enc), Xform(translation: V3(0, 0.04, zFront + 0.012 + 0.0035)))
            let zd = zFront + 0.012 + 0.007
            sbox(V3(0.12, 0.17, 0.002), "label.inspection", at: V3(0, 0.15, zd + 0.0005))
            sbox(V3(0.13, 0.18, 0.001), "glass.clear", at: V3(0, 0.15, zd + 0.0016))
            sbox(V3(0.14, 0.012, 0.002), "metal.galvanized-aged", at: V3(0, 0.248, zd + 0.0002))
            for sy in [Float(0.07), 0.25] { // hinges on the left
                cyl(0.004, 0.032, "metal.galvanized-aged", at: V3(-0.19, 0.04 + sy - 0.016, zFront + 0.012 + 0.0045), seg: 10)
            }
            // Latch tab and cylinder lock on the right.
            cyl(0.008, 0.005, "metal.galvanized-aged", at: V3(0.165, 0.16, zd), dir: V3(0, 0, 1), seg: 14, bevel: 0.0012)
            sbox(V3(0.002, 0.012, 0.0015), "plastic.black", at: V3(0.165, 0.16, zd + 0.0055))
            sbox(V3(0.09, 0.03, 0.0015), "label.hazard-small", at: V3(0, 0.068, zd + 0.0005))
        }
        // Cover screws.
        if !lite {
            for (sx, sy) in [(Float(-0.185), Float(0.607)), (0.185, 0.607), (-0.185, 0.31), (0.185, 0.31), (-0.185, 0.45), (0.185, 0.45)] {
                cyl(0.0042, 0.0025, "metal.screw-zinc", at: V3(sx, sy, zFront + 0.012 - 0.0005), dir: V3(0, 0, 1), seg: 8, bevel: 0.0006)
            }
        }
        // Conduit stubs on top and cable connectors on the bottom.
        for sx in [Float(-0.1), 0.1] {
            cyl(0.0135, 0.03, "metal.galvanized-aged", at: V3(sx, yt, -0.012), seg: 14)
            hexNut(V3(sx, yt + 0.002, -0.012), r: 0.0185, h: 0.005, mat: "metal.galvanized-aged")
            cyl(0.0105, 0.03, "plastic.black", at: V3(sx, 0.0, -0.012), seg: 12)
            hexNut(V3(sx, yb - 0.003, -0.012), r: 0.017, h: 0.006, mat: "metal.galvanized-aged")
        }
        // Mounting ears: top and bottom tabs on the back.
        for (sx, sy) in [(Float(-0.17), yt - 0.012), (0.17, yt - 0.012), (-0.17, yb + 0.012), (0.17, yb + 0.012)] {
            cyl(0.0045, 0.003, "metal.screw-zinc", at: V3(sx, sy, zFront + 0.0115), dir: V3(0, 0, 1), seg: 8, bevel: 0.0006)
        }
        groundAO(&m, height: 0.1, floor: 0.8)
        return m
    }
}
