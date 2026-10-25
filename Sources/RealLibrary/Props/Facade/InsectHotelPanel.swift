import simd
import Foundation

/// Insect hotel panel: pine carcass with a plywood back, four compartments split by 16 mm shelves. Bamboo cane
/// lengths (some mud-plugged by mason bees), drilled hardwood log rounds, pine cones behind galvanised wire mesh
/// stapled to the frame, hay, and two courses of perforated clay brick in running bond. Mono-pitch roof of
/// boards under bitumen felt with a drip lip and clout nails; hung on two screws through the back.
public struct InsectHotelPanel: RealAsset {
    public static let id = "insect-hotel-panel"
    public static let summary = "Weathered pine insect hotel: bamboo canes, drilled logs, pine cones behind wire mesh, perforated brick, felt roof."
    public static let tags = ["prop", "architecture", "facade", "wood", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 1.7)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.60, 0.80, 0.20)
    /// Carcass boards.
    public var pine: MaterialKey = "wood.pine-aged:9A9080"
    /// Roof boards.
    public var roofBoard: MaterialKey = "wood.pine-aged:7E7668"
    /// Roofing felt.
    public var felt: MaterialKey = "roofing.shingle-granule:3A3A3C"
    public var bamboo: MaterialKey = "wood.bamboo-cane"
    public var mesh: MaterialKey = "glass.wire-mesh"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let t: Float = 0.018, D: Float = 0.17, W: Float = 0.6, ix: Float = W / 2 - t
        // Back: 12 mm exterior plywood hung on two screws.
        FA.box(&m, V3(W, 0.78, 0.012), V3(0, 0.39, 0.006), "wood.pine-aged:7C7366", r: 0.0015)
        // Uprights raked at the top (profile z out, y up), floor and three shelves.
        let up: [V2] = [V2(0.012, 0), V2(D, 0), V2(D, 0.745), V2(0.012, 0.78)]
        for s: Float in [-1, 1] { FA.side(&m, up, thick: t, at: V3(s * (W / 2 - t / 2), 0, 0), pine, bevel: 0.0015) }
        let shelfY: [Float] = [0.009, 0.249, 0.459, 0.609]
        for y in shelfY {
            FA.box(&m, V3(2 * ix - 0.001, 0.016, D - 0.012 - 0.002), V3(0, y, 0.012 + (D - 0.012) / 2), pine, r: 0.0015)
        }
        // Countersunk screws through the uprights into each shelf end (two per shelf per side, one slightly proud).
        for s in [Float(-1), 1] {
            for y in shelfY {
                for z: Float in [0.06] {
                    rivet(&m, at: V3(s * W / 2, y + rng.float(-0.0015...0.0015), z), normal: V3(s, 0, 0), radius: 0.0032, height: 0.0016, segments: 5, material: "metal.screw-zinc-yellow")
                }
            }
        }
        // Compartment 1: bamboo canes, 6 rows, hex-packed, cut flush at z = 0.165.
        let y1 = shelfY[0] + 0.008, y2 = shelfY[1] - 0.008
        var row = 0
        var yy = y1 + 0.011
        while yy < y2 - 0.009 {
            var x = -ix + 0.012 + (row % 2 == 0 ? 0 : 0.0095)
            while x < ix - 0.011 {
                let r = rng.float(0.0085...0.0112)
                let z0 = 0.016 + rng.float(0...0.01), z1 = 0.158 + rng.float(0...0.007)
                m.add(Prim.tube([V3(x, yy, z0), V3(x, yy, z1)], radii: [r, r], sides: 5, seamTile: 0.1, material: bamboo, capEnd: true))
                let plug = rng.chance(0.14)
                let disc: [V2] = [V2(r * (plug ? 0.9 : 0.68), 0), V2(0, 0)]
                m.add(Prim.lathe(disc, segments: 6, seamTile: 0.05, material: plug ? "stone.sandstone" : "wood.charred"),
                      Xform(translation: V3(x, yy, z1 + 0.0003), rotation: FA.q(90, FA.X)))
                x += 0.0245 + rng.float(0...0.003)
            }
            yy += 0.0235
            row += 1
        }
        // Compartment 2: drilled log rounds, bark flank, end grain face with 4-9 mm bores.
        let y3 = shelfY[1] + 0.008, y4 = shelfY[2] - 0.008
        for r in 0..<2 {
            var x = -ix + 0.045 + (r == 0 ? 0 : 0.045)
            while x < ix - 0.04 {
                let rad = rng.float(0.037...0.047)
                let y = y3 + rad + 0.002 + Float(r) * (y4 - y3 - 2 * rad - 0.004) * 0.96 + (r == 1 ? -0.0 : 0.0)
                let zf = 0.16 + rng.float(0...0.008)
                m.add(Prim.cylinder(radius: rad, height: zf - 0.016, bevel: 0.002, segments: 14, bevelSegments: 1, material: "bark.oak-dry"),
                      Xform(translation: V3(x, y, 0.016), rotation: FA.q(90, FA.X)))
                m.add(Prim.lathe([V2(rad * 0.97, 0), V2(0, 0)], segments: 14, seamTile: 0.1, material: "wood.endgrain-fresh"),
                      Xform(translation: V3(x, y, zf + 0.0004), rotation: FA.q(90, FA.X)))
                for _ in 0..<6 {
                    let p = rng.inDisc(radius: rad * 0.8)
                    m.add(Prim.lathe([V2(rng.float(0.002...0.0045), 0), V2(0, 0)], segments: 6, seamTile: 0.05, material: "wood.charred"),
                          Xform(translation: V3(x + p.x, y + p.y, zf + 0.0008), rotation: FA.q(90, FA.X)))
                }
                x += rad * 2 + 0.006
            }
        }
        // Compartment 3: pine cones (left), hay (right), wire mesh stapled over the opening.
        let y5 = shelfY[2] + 0.008, y6 = shelfY[3] - 0.008
        for i in 0..<7 {
            let cx = -ix + 0.04 + Float(i % 5) * 0.055 + rng.float(-0.006...0.006), cy = y5 + 0.03 + Float(i / 5) * 0.056
            m.add(Prim.superellipsoid(V3(0.04, 0.06, 0.04), exponent: 2.4, subdivisions: 2, material: "bark.pine"),
                  Xform(translation: V3(cx, cy, 0.04 + rng.float(0...0.09)), rotation: FA.q(rng.float(-30...30), FA.Z) * FA.q(rng.float(-70...(-30)), FA.X)))
        }
        for _ in 0..<14 {
            let x = rng.float(0.0...(ix - 0.01)) , y = rng.float((y5 + 0.004)...(y6 - 0.004)), z = rng.float(0.03...0.15)
            let len = rng.float(0.05...0.11), a = rng.float(-0.6...0.6)
            let p0 = V3(x, y, z), p1 = V3(x + len * 0.5 * cos(a), y + len * 0.5 * sin(a) + 0.005, z), p2 = V3(x + len * cos(a), y + len * sin(a), z + rng.float(-0.01...0.01))
            FA.path(&m, [p0, p1, p2], r: 0.0014, "plant.cane-culm", sides: 4)
        }
        FA.box(&m, V3(2 * ix - 0.002, y6 - y5 - 0.002, 0.0007), V3(0, (y5 + y6) / 2, D - 0.0008), mesh, r: 0.0002)
        for x in stride(from: -ix + 0.015, through: ix - 0.015, by: 0.06) {
            for y in [y5 + 0.004, y6 - 0.004] {
                FA.box(&m, V3(0.012, 0.0012, 0.0012), V3(x, y, D - 0.0004), "metal.galvanized", r: 0.0003)
            }
        }
        // Compartment 4: perforated clay brick, running bond, cores facing front.
        let courseH: Float = 0.0615
        for c in 0..<2 {
            let widths: [Float] = c == 0 ? [0.215, 0.215, 0.105] : [0.105, 0.215, 0.215]
            var x = -ix + 0.0035
            for w in widths {
                let cx = x + w / 2, cy = shelfY[3] + 0.008 + 0.0015 + courseH / 2 + Float(c) * (courseH + 0.003)
                let col = ["brick.unit-red", "brick.unit-red-dark", "brick.unit-red-light"][(c + Int(w * 10)) % 3]
                m.add(Prim.roundedBox(V3(w, courseH, 0.102), radius: 0.0025, bevelSegments: 1, material: col), Xform(translation: V3(cx, cy, 0.162 - 0.051)))
                let cols = w > 0.15 ? 3 : 1
                for k in 0..<(cols * 2) {
                    let hx = cx + (cols == 3 ? (Float(k % 3) - 1) * 0.062 : 0), hy = cy + (k / cols == 0 ? 0.0 : 0.0)
                    m.add(Prim.lathe([V2(0.0085, 0), V2(0, 0)], segments: 8, seamTile: 0.05, material: "wood.charred"),
                          Xform(translation: V3(hx, hy + (cols == 3 ? (k < 3 ? 0.0 : 0.0) : 0), 0.1621), rotation: FA.q(90, FA.X)))
                    if cols == 1 { break }
                }
                x += w + 0.0075
            }
        }
        // Roof: raked boards (profile z out, y up) 30 mm front overhang, felt with drip lip, fascia, clout nails.
        func roofY(_ z: Float) -> Float { 0.782 - 0.2059 * z }
        FA.run(&m, [V2(0, roofY(0)), V2(0.2, roofY(0.2)), V2(0.2, roofY(0.2) + 0.022), V2(0, roofY(0) + 0.022)], length: 0.62, roofBoard, bevel: 0.002)
        let ft: Float = 0.0035, top = { (z: Float) in roofY(z) + 0.022 }
        FA.run(&m, [V2(-0.003, top(-0.003)), V2(0.205, top(0.205)), V2(0.205, top(0.205) + ft), V2(-0.003, top(-0.003) + ft)], length: 0.636, felt, bevel: 0.0008)
        FA.run(&m, [V2(0.2, top(0.205) + ft), V2(0.205, top(0.205) + ft), V2(0.205, top(0.205) - 0.018), V2(0.2, top(0.205) - 0.018)], length: 0.636, felt, bevel: 0.0006)
        for x in stride(from: Float(-0.28), through: 0.28, by: 0.07) {
            for z: Float in [0.03, 0.19] {
                rivet(&m, at: V3(x + rng.float(-0.004...0.004), top(z) + ft, z), normal: FA.Y, radius: 0.004, height: 0.0025, material: "metal.galvanized-aged")
            }
        }
        // Weathering: moss clumps in the felt valley, rust-free; algae streak down the left upright face.
        for x: Float in [-0.25, -0.1, 0.18] {
            m.add(Prim.superellipsoid(V3(0.05, 0.012, 0.03), exponent: 2.2, subdivisions: 3, material: "moss.cushion"),
                  Xform(translation: V3(x, top(0.02) + ft + 0.004, 0.02)))
        }
        // Wear: algae-green splash line along the base of both uprights, white efflorescence on the brick faces,
        // bee mud smears on the lowest shelf.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.0006, 0.09, D - 0.03), V3(s * (W / 2 + 0.0003), 0.045, 0.012 + (D - 0.012) / 2), "moss.cushion", r: 0.0002)
        }
        for i in 0..<4 {
            m.add(Prim.superellipsoid(V3(rng.float(0.03...0.06), 0.006, 0.03), exponent: 2, subdivisions: 2, material: "stone.sandstone"),
                  Xform(translation: V3(rng.float(-0.25...0.25), shelfY[0] + 0.012, rng.float(0.06...0.15))))
        }
        groundAO(&m, height: 0.2, floor: 0.6)
        return LODModel(FC.fit(m, size))
    }
}
