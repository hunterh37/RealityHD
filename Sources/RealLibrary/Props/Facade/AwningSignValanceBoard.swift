import simd
import Foundation

/// Shopfront awning valance board: a moulded timber board with a raised bottom bead and ogee top cap,
/// hung from an aluminium channel on pressed clips, carrying gilt lettering with a black drop shadow
/// between two roundels and gilt rules. Brass screws fix the board; the paint is flaking and sun bleached.
public struct AwningSignValanceBoard: RealAsset {
    public static let id = "awning-sign-valance-board"
    public static let summary = "Shopfront awning valance board 2.0 m: moulded timber board, gilt lettering with shadow, aluminium channel, clips."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 1.1)

    /// Lettering (A-Z, 0-9).
    public var name = "TAYLOR BAKERY"
    public var board: MaterialKey = "wood.painted-exterior:1F3D2E"
    public var gilt: MaterialKey = "metal.gold-leaf"
    public var channel: MaterialKey = "metal.aluminum-brushed"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 2.0
        // Moulded board: profile (out, up), 0.27 m tall, field 20 mm, bead and cap to 32 mm.
        let prof: [V2] = [V2(0, 0), V2(0.026, 0), V2(0.026, 0.011), V2(0.021, 0.017), V2(0.017, 0.024), V2(0.017, 0.244), V2(0.021, 0.25), V2(0.026, 0.256), V2(0.026, 0.27), V2(0, 0.27)]
        FA.run(&m, prof, length: L, at: V3(0, 0, 0), board, bevel: 0.0015)
        // Top aluminium channel with a return lip and pressed clips hooking over the awning bar.
        FA.box(&m, V3(L, 0.03, 0.04), V3(0, 0.285, 0.0), channel, r: 0.003)
        FA.box(&m, V3(L - 0.01, 0.006, 0.042), V3(0, 0.298, -0.001), "metal.steel:2A2A2A", r: 0.001)
        for i in 0..<6 {
            let x = (Float(i) - 2.5) * 0.36
            FA.box(&m, V3(0.04, 0.12, 0.006), V3(x, 0.235, -0.017), "metal.galvanized", r: 0.002)
            FA.box(&m, V3(0.04, 0.006, 0.03), V3(x, 0.296, -0.005), "metal.galvanized", r: 0.002)
            FG.screw(&m, at: V3(x, 0.285, 0.02), r: 0.004, mat: "metal.stainless")
        }
        // Gilt rules above and below the lettering, roundels at both ends.
        let fz: Float = 0.017
        for y: Float in [0.205, 0.065] { FG.flat(&m, V3(1.62, 0.006, 0.0025), V3(0, y, fz + 0.001), gilt) }
        for sx: Float in [-1, 1] {
            m.add(Prim.torus(major: 0.052, minor: 0.0045, segments: 28, sides: 6, material: gilt), Xform(translation: V3(sx * 0.88, 0.135, fz + 0.003), rotation: FA.q(90, FA.X)))
            FA.cylZ(&m, r: 0.034, h: 0.003, at: V3(sx * 0.88, 0.135, fz), gilt, bevel: 0.001, segments: 20)
            FG.text(&m, "T", h: 0.034, stroke: 0.006, depth: 0.0015, at: V3(sx * 0.88, 0.135, fz + 0.003), "metal.painted:1F3D2E")
        }
        // Gilt letters over a black drop shadow, each letter a slightly different age.
        let h: Float = 0.105
        let w = FG.width(name, h: h)
        let pitch = 5.4 * h / 6
        for (i, c) in name.enumerated() where c != " " {
            let cx = -w / 2 + Float(i) * pitch + 2 * h / 6
            let at = V3(cx, 0.135, fz)
            FG.text(&m, String(c), h: h, stroke: 0.018, depth: 0.0012, at: at + V3(0.004, -0.005, 0.0002), "metal.painted:0C0C0E")
            FG.text(&m, String(c), h: h, stroke: 0.018, depth: 0.0022, at: at + V3(0, 0, 0.0008), rng.chance(0.25) ? "metal.brass-aged" : gilt)
        }
        // Worn paint: flaked patches through to bare timber, sun bleached strip at the left end, drip stains.
        for _ in 0..<9 {
            FG.flat(&m, V3(rng.float(0.02...0.09), rng.float(0.012...0.05), 0.0006), V3(rng.float(-0.95...0.95), rng.float(0.03...0.24), fz + 0.0006), "wood.painted-exterior:12241B", rot: FA.q(rng.float(-25...25), FA.Z))
        }
        FG.flat(&m, V3(0.18, 0.2, 0.0006), V3(-0.9, 0.14, fz + 0.0003), "wood.painted-exterior:3E6B54")
        for _ in 0..<6 {
            let len = rng.float(0.04...0.12)
            FG.flat(&m, V3(0.006, len, 0.0006), V3(rng.float(-0.95...0.95), 0.255 - len / 2, fz + 0.0004), "metal.rust-grime")
        }
        // Brass screws through the board face along the bead.
        for i in 0..<5 { FG.screw(&m, at: V3((Float(i) - 2) * 0.36, 0.02, 0.026), r: 0.0045) }
        groundAO(&m, height: 0.08, floor: 0.95)
        return LODModel(FC.place(m))
    }
}
