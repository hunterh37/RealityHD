import simd
import Foundation

/// Roof drain dome: architectural facade customizer, Commercial, cast iron roof drain with domed strainer, clamping ring and membrane sump. Parts: cast iron drain body, clamping ring, bolts, wire dome strainer, sump plate, membrane flashing, debris.
public struct RoofDrainDome: RealAsset {
    public static let id = "roof-drain-dome"
    public static let summary = "Roof drain dome, 0.4 x 0.2 x 0.4 m: cast iron drain with dome strainer, clamp ring and sump."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Dome strainer height above the clamp ring in meters.
    public var domeHeight: Float = 0.15
    /// Drain body material key.
    public var iron: MaterialKey = "metal.cast-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let wire: MaterialKey = "metal.galvanized-aged", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime", mem: MaterialKey = "asphalt.worn"
        // Membrane sump plate with a welded lap, corner fasteners with square washers, and a stain ring.
        FA.box(&m, V3(0.4, 0.008, 0.4), V3(0, 0.004, 0), mem, r: 0.002)
        FA.box(&m, V3(0.4, 0.0012, 0.012), V3(0, 0.0086, 0.12), "metal.solder", r: 0.0004)
        FA.box(&m, V3(0.4, 0.0008, 0.03), V3(0, 0.0084, 0.135), mem, r: 0.0003)
        m.add(Prim.cylinder(radius: 0.178, height: 0.0008, bevel: 0.0003, segments: 36, bevelSegments: 1, material: rust), Xform(translation: V3(0, 0.008, 0)))
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                FA.box(&m, V3(0.024, 0.0025, 0.024), V3(sx * 0.18, 0.0092, sz * 0.18), wire, r: 0.0006)
                m.add(Prim.cylinder(radius: 0.004, height: 0.003, bevel: 0.0008, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: V3(sx * 0.18, 0.0105, sz * 0.18)))
            }
        }
        // Cast-iron body: flashing flange, sump throat, clamp ring with bolt lugs.
        let flange: [V2] = [V2(0.110, 0.008), V2(0.150, 0.0086), V2(0.155, 0.0105), V2(0.150, 0.0128), V2(0.128, 0.0145), V2(0.112, 0.020)]
        m.add(Prim.lathe(flange, segments: 40, seamTile: 0.3, material: iron))
        let clamp: [V2] = [V2(0.124, 0.0145), V2(0.136, 0.0150), V2(0.1395, 0.0185), V2(0.136, 0.0285), V2(0.124, 0.0295), V2(0.1135, 0.0270), V2(0.1135, 0.0190)]
        m.add(Prim.lathe(clamp, segments: 40, seamTile: 0.3, material: iron))
        // Membrane skirt trapped under the clamp ring, with a raised bead.
        m.add(Prim.torus(major: 0.141, minor: 0.0035, segments: 40, sides: 6, material: mem), Xform(translation: V3(0, 0.0125, 0)))
        for i in 0..<8 {
            let a = Float(i) / 8 * 2 * .pi + 0.2, r: Float = 0.1295
            let p = V3(r * cos(a), 0.0295, r * sin(a))
            m.add(Prim.cylinder(radius: 0.0072, height: 0.0065, bevel: 0.0012, segments: 6, bevelSegments: 1, material: i == 3 ? rust : zinc), Xform(translation: p, rotation: FA.q(rng.float(0...60), FA.Y)))
            m.add(Prim.torus(major: 0.0068, minor: 0.0015, segments: 10, sides: 4, material: wire), Xform(translation: V3(p.x, 0.0297, p.z)))
        }
        // Strainer base collar and a dark sump bore.
        let collar: [V2] = [V2(0.1135, 0.0285), V2(0.1135, 0.036), V2(0.1045, 0.0405), V2(0.098, 0.0405), V2(0.098, 0.0285)]
        m.add(Prim.lathe(collar, segments: 36, seamTile: 0.3, material: iron))
        m.add(Prim.cylinder(radius: 0.098, height: 0.001, bevel: 0.0003, segments: 28, bevelSegments: 1, material: "metal.rust"), Xform(translation: V3(0, 0.0295, 0)))
        // Dome: 16 meridian ribs, three hoops, top cap. Bars are tubes so the sump reads through them.
        let H = domeHeight, y0: Float = 0.040
        func dome(_ t: Float) -> V3 { let a = t * .pi / 2; return V3(0.1 * cos(a), y0 + H * sin(a), 0) }
        for i in 0..<16 {
            let a = Float(i) / 16 * 360
            let pts = (0...8).map { k -> V3 in let p = dome(Float(k) / 8 * 0.97); return FA.q(a, FA.Y).act(p) }
            FA.path(&m, pts, r: 0.0034, i == 5 ? rust : wire, sides: 5)
        }
        for t in [0.0, 0.32, 0.62, 0.86] as [Float] {
            let p = dome(t)
            m.add(Prim.torus(major: p.x + 0.001, minor: t == 0 ? 0.0042 : 0.0030, segments: 32, sides: 5, material: t == 0 ? iron : wire), Xform(translation: V3(0, p.y, 0)))
        }
        m.add(Prim.lathe([V2(0.0, y0 + H + 0.012), V2(0.018, y0 + H + 0.004), V2(0.027, y0 + H - 0.012), V2(0.027, y0 + H - 0.026), V2(0.0, y0 + H - 0.026)], segments: 20, seamTile: 0.1, material: iron))
        // Debris: leaves and a plastic scrap against the dome and on the plate, rust bloom on the flange.
        for i in 0..<5 {
            let a = rng.float(0...(2 * .pi)), r = rng.float(0.12...0.17)
            m.add(Prim.superellipsoid(V3(rng.float(0.02...0.04), 0.0025, rng.float(0.012...0.024)), exponent: 2, subdivisions: 4, material: i % 2 == 0 ? "wood.weathered" : "wood.deadwood"),
                  Xform(translation: V3(r * cos(a), 0.0105, r * sin(a)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        for i in 0..<3 {
            m.add(Prim.superellipsoid(V3(0.03, 0.014, 0.018), exponent: 2, subdivisions: 4, material: "wood.weathered"),
                  Xform(translation: V3(0.098 * cos(Float(i) * 2.1 + 0.4) * 0.97, 0.047 + Float(i) * 0.004, 0.098 * sin(Float(i) * 2.1 + 0.4) * 0.97), rotation: FA.q(Float(i) * 70, FA.Y)))
        }
        for _ in 0..<4 {
            let a = rng.float(0...(2 * .pi))
            m.add(Prim.superellipsoid(V3(0.03, 0.002, 0.018), exponent: 2, subdivisions: 4, material: "metal.rust"),
                  Xform(translation: V3(0.147 * cos(a), 0.0142, 0.147 * sin(a)), rotation: FA.q(-a * 57.3, FA.Y)))
        }
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
