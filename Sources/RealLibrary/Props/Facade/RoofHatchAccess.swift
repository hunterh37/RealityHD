import simd
import Foundation

/// Roof hatch access: architectural facade customizer, Commercial, roof access hatch with curb, hinged lid, strut, latch and membrane flashing. Parts: insulated curb, hinged lid, gas strut, hasp latch, hinges, counterflashing, membrane skirt, fasteners.
public struct RoofHatchAccess: RealAsset {
    public static let id = "roof-hatch-access"
    public static let summary = "Roof access hatch, 1.0 x 0.5 x 1.0 m: curbed lid with hinges, strut, latch and flashing."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Curb side length in meters.
    public var curb: Float = 0.78
    /// Lid and curb paint material key.
    public var paint: MaterialKey = "metal.painted:8A8D8E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let inner: MaterialKey = "metal.galvanized-aged", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime", alu: MaterialKey = "metal.aluminum"
        let C = curb, h = C / 2
        let yb: Float = 0.014, yc: Float = 0.34 // membrane top, curb top
        // Membrane slab with a raised membrane skirt, counterflashing plate and fastener rows.
        FA.box(&m, V3(1.0, 0.012, 1.0), V3(0, 0.006, 0), "asphalt.worn", r: 0.004)
        FA.box(&m, V3(C + 0.1, 0.004, C + 0.1), V3(0, yb + 0.002, 0), inner, r: 0.0015)
        FA.box(&m, V3(C + 0.04, 0.05, C + 0.04), V3(0, yb + 0.025, 0), "asphalt.worn", r: 0.01)
        for s: Float in [-1, 1] {
            for i in 0..<7 {
                let t = -0.4 + Float(i) * 0.8 / 6
                for (px, pz) in [(t, s * (h + 0.04)), (s * (h + 0.04), t)] {
                    m.add(Prim.cylinder(radius: 0.0055, height: 0.003, bevel: 0.001, segments: 6, bevelSegments: 1, material: (i + Int(s) + 3) % 7 == 0 ? rust : zinc),
                          Xform(translation: V3(px, yb + 0.004, pz)))
                }
            }
        }
        // Insulated curb: clad walls with a cap flange and stiffener ribs.
        for (sx, sz, w, d) in [(0, -1, C, 0.02), (0, 1, C, 0.02), (-1, 0, 0.02, C), (1, 0, 0.02, C)] as [(Float, Float, Float, Float)] {
            FA.box(&m, V3(w, yc - yb - 0.05, d), V3(sx * (h - 0.01), (yc + yb + 0.05) / 2, sz * (h - 0.01)), paint, r: 0.003)
            for i in 0..<4 {
                let t = -0.27 + Float(i) * 0.18
                FA.box(&m, sx == 0 ? V3(0.012, yc - yb - 0.08, 0.006) : V3(0.006, yc - yb - 0.08, 0.012), V3(sx == 0 ? t : sx * (h + 0.0), (yc + yb + 0.05) / 2, sz == 0 ? t : sz * (h + 0.0)), inner, r: 0.0015)
            }
        }
        FA.box(&m, V3(C + 0.03, 0.012, C + 0.03), V3(0, yc + 0.003, 0), inner, r: 0.003)
        // Lid: shell, raised top skin, cross stiffeners, rolled edge, gasket line.
        FA.box(&m, V3(C + 0.05, 0.1, C + 0.05), V3(0, yc + 0.065, 0), paint, r: 0.012)
        m.add(Prim.superellipsoid(V3(C - 0.02, 0.05, C - 0.02), exponent: 5, subdivisions: 8, material: paint), Xform(translation: V3(0, yc + 0.13, 0)))
        FA.box(&m, V3(C + 0.056, 0.006, C + 0.056), V3(0, yc + 0.017, 0), "metal.painted:1E1E1E", r: 0.002)
        for dz: Float in [-0.18, 0.18] { FA.box(&m, V3(C - 0.1, 0.004, 0.02), V3(0, yc + 0.157, dz), inner, r: 0.0015) }
        for dx: Float in [-0.18, 0.18] { FA.box(&m, V3(0.02, 0.004, C - 0.1), V3(dx, yc + 0.158, 0), inner, r: 0.0015) }
        FA.cylZ(&m, r: 0.026, h: 0.006, at: V3(0, yc + 0.16, 0), alu, bevel: 0.0015, segments: 20)
        for i in 0..<4 { // lid corner screws
            let a = Float(i) * .pi / 2 + .pi / 4
            m.add(Prim.cylinder(radius: 0.006, height: 0.004, bevel: 0.001, segments: 6, bevelSegments: 1, material: zinc),
                  Xform(translation: V3(0.32 * cos(a) * 1.0, yc + 0.118, 0.32 * sin(a))))
        }
        // Hinges at the back: leaf plates, barrels, pins.
        for x: Float in [-0.25, 0.25] {
            FA.box(&m, V3(0.1, 0.004, 0.08), V3(x, yc + 0.0145, -h - 0.04), inner, r: 0.0012)
            FA.box(&m, V3(0.1, 0.07, 0.004), V3(x, yc + 0.065, -h - 0.033), inner, r: 0.0012)
            FA.cylX(&m, r: 0.011, h: 0.1, at: V3(x - 0.05, yc + 0.0145, -h - 0.04), alu, bevel: 0.0015, segments: 14)
            for dx: Float in [-0.035, 0.035] { m.add(Prim.cylinder(radius: 0.0045, height: 0.003, bevel: 0.001, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: V3(x + dx, yc + 0.0165, -h - 0.04))) }
        }
        // Gas strut folded along the right side, with its end brackets.
        FA.rod(&m, V3(h + 0.032, yc - 0.08, 0.2), V3(h + 0.032, yc + 0.06, -0.12), r: 0.008, "metal.chrome", sides: 10)
        FA.rod(&m, V3(h + 0.032, yc - 0.08, 0.2), V3(h + 0.032, yc - 0.015, 0.06), r: 0.0115, alu, sides: 10)
        FA.box(&m, V3(0.006, 0.05, 0.05), V3(h + 0.027, yc - 0.08, 0.2), inner, r: 0.002)
        FA.box(&m, V3(0.006, 0.03, 0.04), V3(h + 0.027, yc + 0.06, -0.12), inner, r: 0.002)
        // Front hasp, staple plate and padlock.
        FA.box(&m, V3(0.06, 0.12, 0.004), V3(0, yc - 0.06, h + 0.0215), inner, r: 0.0015)
        FA.box(&m, V3(0.05, 0.1, 0.004), V3(0, yc + 0.05, h + 0.0285), inner, r: 0.0015)
        FA.box(&m, V3(0.022, 0.03, 0.014), V3(0, yc - 0.01, h + 0.03), inner, r: 0.002)
        m.add(Prim.roundedBox(V3(0.04, 0.045, 0.02), radius: 0.005, bevelSegments: 1, material: "metal.brass-aged"), Xform(translation: V3(0, yc - 0.045, h + 0.045)))
        m.add(Prim.torus(major: 0.012, minor: 0.0028, segments: 16, sides: 6, material: "metal.steel"), Xform(translation: V3(0, yc - 0.02, h + 0.045), rotation: FA.q(90, FA.X)))
        for (x, y) in [(-0.018, -0.1), (0.018, -0.1), (-0.018, -0.02), (0.018, -0.02)] as [(Float, Float)] {
            m.add(Prim.cylinder(radius: 0.0045, height: 0.003, bevel: 0.001, segments: 6, bevelSegments: 1, material: zinc),
                  Xform(translation: V3(x, yc + y, h + 0.0235), rotation: FA.q(90, FA.X)))
        }
        // Caulk bead and dirt line where the curb meets the flashing, plus a transverse membrane lap.
        FA.box(&m, V3(C + 0.045, 0.008, C + 0.045), V3(0, yb + 0.012, 0), "metal.rust-grime", r: 0.003)
        FA.box(&m, V3(1.0, 0.0025, 0.03), V3(0, 0.0135, 0.3), "asphalt.patch", r: 0.001)
        FA.box(&m, V3(C - 0.1, 0.01, 0.014), V3(0, yc + 0.0145, h + 0.012), inner, r: 0.003)
        // Weathering: rust streaks down the curb, dirt ring at the base, debris on the roof.
        for _ in 0..<5 {
            FA.box(&m, V3(rng.float(0.006...0.02), rng.float(0.06...0.2), 0.001), V3(rng.float(-0.3...0.3), yc - 0.12, h + 0.0015), rust, r: 0.0004)
        }
        for _ in 0..<3 {
            FA.box(&m, V3(rng.float(0.006...0.012), rng.float(0.05...0.12), 0.001), V3(h + 0.0015, yc - 0.1, rng.float(-0.3...0.3)), rust, r: 0.0004, rot: FA.q(90, FA.Y))
        }
        for i in 0..<5 {
            m.add(Prim.superellipsoid(V3(rng.float(0.02...0.05), 0.004, rng.float(0.015...0.03)), exponent: 2, subdivisions: 6, material: i % 3 == 0 ? "metal.rust" : "wood.weathered"),
                  Xform(translation: V3(rng.float(-0.46...0.46), 0.014, rng.float(0.45...0.49) * (i % 2 == 0 ? 1 : -1)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        // Round 1: lid pull handle, bolted corner angles on the curb, base cleat, lid-edge drip hem, gasket on curb cap.
        m.add(barHandle(length: 0.16, standoff: 0.022, radius: 0.007, material: "metal.aluminum"), Xform(translation: V3(0, yc + 0.152, h - 0.07), rotation: FA.q(-90, FA.X)))
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            FA.box(&m, V3(0.03, yc - yb - 0.06, 0.008), V3(sx * (h + 0.0105), (yc + yb + 0.05) / 2 - 0.0, sz * (h - 0.012)), inner, r: 0.002)
            FA.box(&m, V3(0.008, yc - yb - 0.06, 0.03), V3(sx * (h - 0.012), (yc + yb + 0.05) / 2, sz * (h + 0.0105)), inner, r: 0.002)
            for k in 0..<2 {
                let yy = yb + 0.1 + Float(k) * 0.14
                FA.cylZ(&m, r: 0.0045, h: 0.003, at: V3(sx * (h + 0.0105), yy, sz * (h - 0.012) + sz * 0.0042), zinc, bevel: 0.0007, segments: 6)
            }
        } }
        for s: Float in [-1, 1] {
            FA.box(&m, V3(C + 0.02, 0.03, 0.012), V3(0, yb + 0.03, s * (h + 0.012)), inner, r: 0.003)
            FA.box(&m, V3(0.012, 0.03, C + 0.02), V3(s * (h + 0.012), yb + 0.03, 0), inner, r: 0.003)
        }
        FA.box(&m, V3(C + 0.052, 0.01, 0.012), V3(0, yc + 0.0125, h + 0.027), "metal.painted:1E1E1E", r: 0.003)
        m = FA.centerZ(m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
