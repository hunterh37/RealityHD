import simd
import Foundation

/// Gas lantern wall sconce, Victorian: a cast iron back plate with four bolts, a double scroll bracket
/// with a brass gas cock, a tapered four-pane lantern cage, a brass burner with a glowing mantle, a
/// vented cap with finial and a drop pendant. Soot above the vent and rust under the bolts.
public struct GasLanternWallSconce: RealAsset {
    public static let id = "gas-lantern-wall-sconce"
    public static let summary = "Gas lantern wall sconce, 0.6 m: plate, scroll bracket, gas cock, glass cage lantern, burner, vented cap."
    public static let tags = ["prop", "architecture", "facade", "light", "metal", "decor"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 10, distance: 1.2)

    /// Black painted cast iron.
    public var iron: MaterialKey = "metal.cast-iron"
    /// Cage and cap paint.
    public var paint: MaterialKey = "metal.powdercoat:1B1B1D"
    /// Burner, cock and finial.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Lantern panes.
    public var glass: MaterialKey = "glass.pane"
    /// Mantle glow.
    public var glow: MaterialKey = "emissive.warm"
    /// Rust staining.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let zc: Float = 0.18, py: Float = 0.335
        let y0: Float = 0.2, y1: Float = 0.475, h0: Float = 0.05, h1: Float = 0.085
        // Back plate: domed disc with a raised rim, four hex bolts and a rust tear.
        m.add(Prim.lathe([V2(0, 0.014), V2(0.075, 0.014), V2(0.08, 0.01), V2(0.08, 0.003), V2(0.077, 0), V2(0, 0)], segments: 36, material: iron),
              Xform(translation: V3(0, py, 0), rotation: FA.q(90, FA.X)))
        m.add(Prim.torus(major: 0.066, minor: 0.004, segments: 36, sides: 8, material: iron),
              Xform(translation: V3(0, py, 0.015), rotation: FA.q(90, FA.X)))
        FA.cylZ(&m, r: 0.026, h: 0.012, at: V3(0, py, 0.014), iron, bevel: 0.003, segments: 20)
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            let p = V3(0.053 * cos(a), py + 0.053 * sin(a), 0.014)
            FA.cylZ(&m, r: 0.0068, h: 0.006, at: p, paint, bevel: 0.0012, segments: 6)
            FA.cylZ(&m, r: 0.011, h: 0.0015, at: p + V3(0, 0, -0.0005), paint, bevel: 0.0004, segments: 12)
        }
        m.add(Prim.superellipsoid(V3(0.009, rng.float(0.04...0.06), 0.002), exponent: 2.4, subdivisions: 2, material: rust),
              Xform(translation: V3(0.037, py - 0.06, 0.0152)))
        // Lower arm: S-scroll from the boss down to the base cup, with a C-curl brace beneath.
        let arm = catmull([V3(0, py - 0.01, 0.02), V3(0, py - 0.05, 0.06), V3(0, py - 0.1, 0.12), V3(0, y0 - 0.035, zc - 0.03)], per: 6)
        m.add(Prim.tube(arm, radii: arm.indices.map { 0.0095 - 0.003 * Float($0) / Float(arm.count - 1) }, sides: 10, seamTile: 0.1, material: iron, capEnd: true))
        let curl = catmull([V3(0, py - 0.085, 0.022), V3(0, py - 0.14, 0.05), V3(0, py - 0.16, 0.1), V3(0, py - 0.135, 0.135), V3(0, py - 0.105, 0.125)], per: 6)
        m.add(Prim.tube(curl, radii: curl.indices.map { 0.0065 - 0.0025 * Float($0) / Float(curl.count - 1) }, sides: 8, seamTile: 0.1, material: iron, capEnd: true))
        FC.bead(&m, r: 0.0068, at: curl.last!, iron, sub: 3)
        // Upper stay to the cage back.
        FA.rod(&m, V3(0, py + 0.09, 0.018), V3(0, y1 - 0.05, zc - h1 + 0.002), r: 0.0075, iron, sides: 10)
        FA.cylZ(&m, r: 0.012, h: 0.012, at: V3(0, py + 0.09, 0.016), iron, bevel: 0.002, segments: 12)
        // Gas cock: brass barrel across the arm with a flat key handle.
        FA.cylX(&m, r: 0.011, h: 0.036, at: V3(-0.018, py - 0.075, 0.098), brass, bevel: 0.002, segments: 14)
        FA.box(&m, V3(0.05, 0.008, 0.006), V3(0.042, py - 0.075, 0.098), brass, r: 0.002)
        FC.bead(&m, r: 0.009, at: V3(0.067, py - 0.075, 0.098), brass, sub: 3)
        // Base cup, cage and cap.
        m.add(turned([(0, y0 - 0.075), (0.012, y0 - 0.075), (0.02, y0 - 0.064), (0.03, y0 - 0.045), (0.058, y0 - 0.012), (0.058, y0), (0, y0)], material: iron),
              Xform(translation: V3(0, 0, zc)))
        FC.lantern(&m, c: V3(0, 0, zc), y0: y0, y1: y1, h0: h0, h1: h1, post: 0.0045, frame: paint, glass: glass, muntins: true, rng: &rng)
        // Burner and mantle inside the cage.
        FA.rod(&m, V3(0, y0, zc), V3(0, y0 + 0.07, zc), r: 0.005, brass, sides: 8)
        m.add(Prim.superellipsoid(V3(0.032, 0.056, 0.032), exponent: 2, subdivisions: 6, material: glow), Xform(translation: V3(0, y0 + 0.105, zc)))
        m.add(turned([(0, y1), (0.12, y1), (0.126, y1 + 0.006), (0.114, y1 + 0.02), (0.078, y1 + 0.06), (0.036, y1 + 0.088), (0.03, y1 + 0.098), (0.015, y1 + 0.1), (0, y1 + 0.1)], material: paint),
              Xform(translation: V3(0, 0, zc)))
        FA.cylZ(&m, r: 0.003, h: 0.004, at: V3(0.03, y1 + 0.03, zc + 0.045), rust, bevel: 0.0005, segments: 6)
        FC.bead(&m, r: 0.013, at: V3(0, y1 + 0.113, zc), brass, sub: 4)
        // Soot above the vent and a drop pendant under the cup.
        m.add(Prim.superellipsoid(V3(0.05, 0.003, 0.05), exponent: 2, subdivisions: 4, material: "metal.rust-grime"), Xform(translation: V3(0, y1 + 0.0035, zc)))
        m.add(turned([(0, 0.0), (0.008, 0.012), (0.014, 0.03), (0.006, 0.05), (0.01, y0 - 0.075 - 0.01), (0, y0 - 0.075)], material: iron),
              Xform(translation: V3(0, 0, zc)))
        groundAO(&m, height: 0.05, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
