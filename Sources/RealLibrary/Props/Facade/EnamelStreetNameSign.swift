import simd
import Foundation

/// Enamel street name sign, Parisian Haussmann: 600 x 150 mm blade, 30 mm deep. A pressed steel plate with a rolled
/// edge, a deep blue vitreous enamel field, a white fillet border, white block lettering "RUE DE RIVOLI", four
/// slotted corner screws, and two pressed steel mounting lugs standing the plate off the wall. Wear: enamel chips
/// down to rusting steel at the edges and screws, rust bleed, hairline crazing, grime on the lower edge.
public struct EnamelStreetNameSign: RealAsset {
    public static let id = "enamel-street-name-sign"
    public static let summary = "Enamel street name sign, Parisian Haussmann facade prop, 0.6 x 0.15 x 0.03 m."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 10, distance: 1.0)

    /// Street name.
    public var name = "RUE DE RIVOLI"
    /// Enamel field.
    public var blue: MaterialKey = "metal.enamel:1B3E7A"
    /// Enamel lettering and fillet.
    public var white: MaterialKey = "metal.enamel:EEF0EA"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.6, H: Float = 0.15
        let z0: Float = 0.017                       // plate back, standing off the wall on lugs
        // Pressed steel plate and rolled edge.
        m.add(Prim.extrude(Shape2D.roundedRect(W, H, radius: 0.012, segments: 6), depth: 0.0035, bevel: 0.0008, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(0, 0, z0 + 0.00175)))
        let roll: [V3] = Shape2D.roundedRect(W - 0.004, H - 0.004, radius: 0.011, segments: 6).map { V3($0.x, $0.y, z0 + 0.0018) }
        m.add(Prim.sweep(Shape2D.circle(0.0028, segments: 8), along: roll, up: FA.Z, closedPath: true, caps: false, material: blue))
        // Enamel field and white fillet.
        let zF = z0 + 0.0035
        m.add(Prim.extrude(Shape2D.roundedRect(W - 0.012, H - 0.012, radius: 0.009, segments: 6), depth: 0.0014, bevel: 0.0004, bevelSegments: 1, material: blue), Xform(translation: V3(0, 0, zF + 0.0005)))
        let zT = zF + 0.0012
        let fil: [V3] = Shape2D.roundedRect(W - 0.03, H - 0.03, radius: 0.006, segments: 6).map { V3($0.x, $0.y, zT) }
        m.add(Prim.sweep(Shape2D.circle(0.0012, segments: 6), along: fil, up: FA.Z, closedPath: true, caps: false, material: white))
        let fil2: [V3] = Shape2D.roundedRect(W - 0.042, H - 0.042, radius: 0.004, segments: 6).map { V3($0.x, $0.y, zT) }
        m.add(Prim.sweep(Shape2D.circle(0.0006, segments: 5), along: fil2, up: FA.Z, closedPath: true, caps: false, material: white))
        // Lettering.
        let h: Float = 0.046
        let w = FSO.width(name, h: h)
        FSO.text(&m, name, origin: V2(-w / 2, -h / 2), h: h, w: 0.0072, z: zT + 0.0004, t: 0.0014, white)
        // Corner screws.
        for sx: Float in [-1, 1] {
            for sy: Float in [-1, 1] {
                FSO.screw(&m, at: V3(sx * 0.2825, sy * 0.0535, zT + 0.0003), r: 0.0036, "metal.steel", angle: rng.float(0...180))
            }
        }
        // Pressed mounting lugs: bent flanges behind the plate, bolted to the wall.
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.03, 0.06, 0.0025), V3(sx * 0.2, 0, z0 - 0.0018), "metal.steel", r: 0.0008)
            FA.box(&m, V3(0.03, 0.0025, z0 - 0.002), V3(sx * 0.2, 0.0275, (z0 - 0.002) / 2), "metal.steel", r: 0.0008)
            FA.box(&m, V3(0.03, 0.0025, z0 - 0.002), V3(sx * 0.2, -0.0275, (z0 - 0.002) / 2), "metal.steel", r: 0.0008)
            hexBolt(&m, at: V3(sx * 0.2, 0.0, 0.0), normal: V3(0, 0, -1), size: 0.01, material: "metal.bolt-bright")
        }
        // Weathering: chips to steel and rust along the edges and screws, rust bleed, crazing, grime on the lower edge.
        for _ in 0..<14 {
            let top = rng.chance(0.5)
            let x = rng.float(-0.28...0.28)
            FSO.blob(&m, at: V3(x, (top ? 1 : -1) * (H / 2 - 0.0062), zT + 0.0006), size: V3(rng.float(0.006...0.02), rng.float(0.003...0.007), 0.0008), rng.chance(0.55) ? "metal.steel" : "metal.rust")
        }
        for sx: Float in [-1, 1] {
            for sy: Float in [-1, 1] {
                FSO.blob(&m, at: V3(sx * 0.2825, sy * 0.0535 - sy * 0.002, zT + 0.0001), size: V3(0.011, 0.011, 0.0008), "metal.rust")
                if sy > 0 { FSO.blob(&m, at: V3(sx * 0.2825, sy * 0.0535 - 0.02, zT + 0.0001), size: V3(0.004, rng.float(0.02...0.04), 0.0006), "metal.rust-grime") }
            }
        }
        for _ in 0..<8 {
            let a = V2(rng.float(-0.26...0.26), rng.float(-0.05...0.05))
            FSO.bar(&m, a, a + V2(rng.float(-0.03...0.03), rng.float(-0.02...0.02)), w: 0.0004, z: zT + 0.0001, t: 0.0003, "metal.painted:0E1E42")
        }
        FSO.blob(&m, at: V3(0, -H / 2 + 0.0075, zT + 0.0002), size: V3(0.5, 0.005, 0.0007), "stone.limestone-sooted")
        // Letter wear: a few white strokes chipped through to the blue.
        for _ in 0..<6 {
            FSO.blob(&m, at: V3(rng.float(-w / 2...w / 2), rng.float(-0.02...0.02), zT + 0.0021), size: V3(0.004, 0.004, 0.0008), blue)
        }
        groundAO(&m)
        return LODModel(FC.place(m))
    }
}
