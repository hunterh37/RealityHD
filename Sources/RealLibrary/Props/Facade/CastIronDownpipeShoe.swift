import simd
import Foundation

/// Cast iron downpipe shoe, Victorian: 150 mm wide, 300 mm high, 200 mm out from the wall. A 100 mm socket with a raised
/// collar and a bead ring, a quarter bend of 100 mm centreline radius, a splayed outlet with a rolled lip, two cast ear
/// lugs bolted to the wall with hex bolts, a casting seam along the bend, and a cast maker mark. Wear: black paint
/// chipped to red lead and rust at the lip, rust weeps below the lugs, a wet dirt line inside the outlet.
public struct CastIronDownpipeShoe: RealAsset {
    public static let id = "cast-iron-downpipe-shoe"
    public static let summary = "Cast iron downpipe shoe, Victorian facade prop, 0.15 x 0.3 x 0.2 m."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 14, distance: 1.2)

    /// Painted cast iron.
    public var paint: MaterialKey = "metal.cast-iron-street"
    /// Bare iron where chipped.
    public var bare: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r: Float = 0.04, zc: Float = 0.045, R: Float = 0.1
        let yTop: Float = 0.30, yV: Float = 0.16            // top of socket, end of the straight run
        // Pipe path: vertical, quarter bend, short horizontal run to the outlet.
        var pts: [V3] = [V3(0, yTop, zc), V3(0, yV + 0.02, zc), V3(0, yV, zc)]
        let cy = yV, cz = zc + R
        for k in 1...8 {
            let a = Float(k) / 8 * .pi / 2
            pts.append(V3(0, cy - R * sin(a), cz - R * cos(a)))
        }
        let endY = cy - R, endZ = cz
        pts.append(V3(0, endY, endZ + 0.014)); pts.append(V3(0, endY, endZ + 0.034))
        var radii = pts.map { _ in r }
        radii[radii.count - 1] = r + 0.007; radii[radii.count - 2] = r + 0.002
        m.add(Prim.tube(pts, radii: radii, sides: 20, seamTile: 0.2, material: paint, capEnd: false))
        // Outlet: dark bore, rolled lip, inner dirt line.
        let lipC = V3(0, endY, endZ + 0.034)
        m.add(Prim.torus(major: r + 0.0065, minor: 0.0055, segments: 22, sides: 8, material: paint), Xform(translation: lipC, rotation: FA.q(90, FA.X)))
        m.add(Prim.cylinder(radius: r + 0.0005, height: 0.004, bevel: 0.0008, segments: 20, bevelSegments: 1, material: "metal.painted:121211"), Xform(translation: lipC - V3(0, 0, 0.012), rotation: FA.q(90, FA.X)))
        m.add(Prim.cylinder(radius: r - 0.0016, height: 0.002, bevel: 0.0004, segments: 20, bevelSegments: 1, material: "wood.deadwood"), Xform(translation: lipC - V3(0, 0, 0.0105), rotation: FA.q(90, FA.X)))
        // Socket: raised collar, bead ring, flared mouth.
        let collar: [(Float, Float)] = [(r - 0.005, yTop - 0.065), (r + 0.011, yTop - 0.065), (r + 0.013, yTop - 0.06), (r + 0.009, yTop - 0.05), (r + 0.009, yTop - 0.022), (r + 0.016, yTop - 0.016), (r + 0.016, yTop - 0.004), (r + 0.01, yTop), (r - 0.0045, yTop), (r - 0.0045, yTop - 0.065)]
        m.add(Prim.lathe(collar.map { V2($0.0, $0.1) }, segments: 22, seamTile: 0.2, material: paint), Xform(translation: V3(0, 0, zc)))
        // Bead ring where the bend starts and a bolt flange face on the elbow.
        m.add(Prim.torus(major: r + 0.0005, minor: 0.0048, segments: 20, sides: 8, material: paint), Xform(translation: V3(0, yV + 0.012, zc)))
        // Casting seam along the outside of the bend (small ridge).
        var seam: [V3] = []
        for k in 0...8 { let a = Float(k) / 8 * .pi / 2; seam.append(V3(0, cy - (R + r + 0.0006) * sin(a), cz - (R + r + 0.0006) * cos(a))) }
        FA.path(&m, seam, r: 0.0022, paint, sides: 6)
        // Ear lugs on the socket collar, bolted to the wall.
        for sgn: Float in [-1, 1] {
            let ex = sgn * 0.058
            FA.box(&m, V3(0.034, 0.04, 0.012), V3(ex, yTop - 0.035, 0.006 + 0.0), paint, r: 0.0035)
            FA.box(&m, V3(0.02, 0.028, 0.02), V3(sgn * 0.045, yTop - 0.035, 0.018), paint, r: 0.003)   // web to the collar
            hexBolt(&m, at: V3(ex, yTop - 0.035, 0.012), normal: FA.Z, size: 0.013, material: "metal.bolt-bright")
        }
        // Maker mark on the bend: raised cartouche with stroke letters.
        FA.box(&m, V3(0.03, 0.016, 0.0025), V3(0.0, yV - 0.012, zc + r + 0.0015), paint, r: 0.0008)
        // Weathering: chipped paint to red lead, rust arcs on the lip, grime on the bend.
        for _ in 0..<10 {
            let a = rng.float(0...(.pi * 2)), y = rng.float(yV + 0.02...yTop - 0.07)
            FSO.blob(&m, at: V3(sin(a) * (r + 0.0005), y, zc + cos(a) * (r + 0.0005)), size: V3(rng.float(0.008...0.02), rng.float(0.006...0.014), 0.0016), rng.chance(0.55) ? "metal.painted:8E3B2A" : bare, rot: FA.q(a * 180 / .pi, FA.Y))
        }
        for k in 0..<3 {
            m.add(Prim.torus(major: r + 0.0065, minor: 0.0058, segments: 8, sides: 8, arc: rng.float(0.5...1.1), material: bare),
                  Xform(translation: lipC, rotation: FA.q(90, FA.X) * FA.q(Float(k) * 120 + rng.float(0...60), FA.Y)))
        }
        for _ in 0..<5 {
            let t = rng.float(0.15...0.85), a = t * .pi / 2
            FSO.blob(&m, at: V3(rng.float(-0.025...0.025), cy - (R + r + 0.0006) * sin(a), cz - (R + r + 0.0006) * cos(a)), size: V3(rng.float(0.012...0.026), 0.0016, rng.float(0.01...0.02)), "wood.deadwood", rot: FA.q(-(1 - t) * 90, FA.X))
        }
        groundAO(&m)
        return LODModel(FC.place(m))
    }
}
